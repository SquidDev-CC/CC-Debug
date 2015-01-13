local Chunk = LAT.Lua51.Chunk
local Instruction = LAT.Lua51.Instruction
local Upvalue = LAT.Lua51.Upvalue
local Constant = LAT.Lua51.Constant

local pushStack = Constant:new("String", "__pushStack")
local popStack = Constant:new("String", "__popStack")

-- Basic factory method for Instructions
local function MkInstr(opcode, options)
	local instr = Instruction:new(opcode)
	for k,v in pairs(options) do
		instr[k] = v
	end
	return instr
end

local function InjectPushStack(chunk)
	-- Add pushStack constant to the function
	chunk.Constants:Add(pushStack)
	local pushIndex = chunk.Constants.Count - 1

	-- Get local count
	local localCount = chunk.Locals.Count

	-- Create our inject chunk
	local injectChunk = Chunk:new()
	injectChunk.UpvalueCount = localCount -- Both will be the same as the number of locals
	injectChunk.MaxStackSize = localCount

	-- Cache some basic values
	local injectUpvalues = injectChunk.Upvalues
	local injectInstructions = injectChunk.Instructions

	-- Add the debug function to the main function
	chunk.Protos:Add(injectChunk)
	local protoIndex = chunk.Protos.Count - 1
	
	-- We want go get the pushStack function and create a closure
	local baseInject = {
		MkInstr("GETGLOBAL", {A = localCount, Bx = pushIndex}),
		MkInstr("CLOSURE", {A = localCount + 1, Bx = protoIndex}),
	}

	-- Create closure and getupvalues
	local injectLength = #baseInject + 1
	for i = 0, localCount - 1, 1 do
		-- 'Move' upvalue into closure
		baseInject[injectLength] = MkInstr("MOVE", {A = 0, B = i}) 

		injectUpvalues:Add(Upvalue:new("")) -- Add upvalue
		injectInstructions:Add(MkInstr("GETUPVAL", { A = i, B = i})) -- Add 'return upvalue' to debug function

		injectLength = injectLength + 1
	end

	-- We return localCount values
	injectInstructions:Add(MkInstr("RETURN", {B = localCount + 1}))

	-- Add call for pushStack function, Pass 2-1 Arguments (B), and store 1-1 values(C)
	baseInject[injectLength] = MkInstr("CALL", { A = localCount, B = 2, C = 1})

	-- Slighly hacky: Inject function for instructions
	local instructions = chunk.Instructions
	instructions.Count = instructions.Count + injectLength
	local baseInstructions = getmetatable(instructions).table

	for i, v in pairs(baseInject) do
		table.insert(baseInstructions, i - 1, v)
	end

	return chunk
end

local function TrimExitPoints(chunk, exitPoints)
	local output = {}
	local instructions = chunk.Instructions
	for _, instr in pairs(exitPoints) do
		-- Starts with 0 indexing (so -1), and use the previous one (so -1 again)
		-- If previous instruction is a return instruction and nothing jumps to this then we can safely ignore this.
		-- And so not bother to inject code near it.
		-- Using #JumpsTo is ineffecient but...
		if instr.Number == nil or instructions[instr.Number - 2].Opcode ~= "RETURN" or #JumpsTo(chunk, instr) > 0 then
			output[#output + 1] = instr
		end
	end
	return output
end

local function InjectPopStack(chunk)
	chunk.Constants:Add(popStack)
	local popIndex = chunk.Constants.Count - 1

	local instructions = chunk.Instructions

	-- Get local count
	local localCount = chunk.Locals.Coun

	-- Gather exit points and trim the inaccessible ones
	for _, exitPoint in pairs(chunkJumpInstructions.ExitPoints(chunk)) do
		local jumps = JumpInstructions.JumpsTo(chunk, exitPoint)

		local previous = instructions[exitPoint.Number - 2]

		-- No point injecting if unreachable code
		if previous.OPCODE ~= "RETURN" or #jumps > 0 then
			local startingRegister = exitPoint.A
			local returnCount = exitPoint.B - 1
			local endRegister = startingRegister +  returnCount

			if startingRegister > 0 then
				-- Inject at 0
			elseif returnCount >= 0 then
				-- Inject at returnCount + 1
			else
				-- Inject higher in the list
			end
		end
	end
end

return {
	InjectPushStack = InjectPushStack,
}