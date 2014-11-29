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

return {
	InjectPushStack = InjectPushStack,
}