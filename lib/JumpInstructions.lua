local returnOne = function(instruction) return 1 end
local returnsBx = function(instruction) return instruction.sBx end
local jumps = {
	JMP      = returnsBx,
	EQ       = returnOne,
	LT       = returnOne,
	LE       = returnOne,
	TEST     = returnOne,
	TESTSET  = returnOne,
	FORPREP  = returnsBx,
	FORLOOP  = returnsBx,
	TFORLOOP = returnOne,
}

local exits = {
	RETURN   = true,
	TAILCALL = true,
}

local function JumpsTo(chunk, target)
	local instructions = chunk.Instructions
	local output = {}

	for pc = 1, instructions.Count do
		local current = instructions[pc -1]

		local jumpToFunction = jumps[current.Opcode]
		if jumpToFunction then
			if current.Number + 1 + jumpToFunction(current) == target then
				output[#output + 1] = current
			end
		end
	end

	return output
end

local function ExitPoints(chunk)
	local instructions = chunk.Instructions
	local output = {}

	for pc = 1, instructions.Count do
		local current = instructions[pc -1]

		if exits[current.Opcode] then
			output[#output + 1] = current
		end
	end

	return output
end

local function TrimExitPoints(chunk, exitPoints)
	local output = {}
	local instructions = chunk.Instructions
	for _, instr in pairs(exitPoints) do
		-- Starts with 0 indexing (so -1), and use the previous one (so -1 again)
		-- If previous instruction is a return instruction and nothing is jumped to this then we can safely ignore this.
		-- And so not bother to inject code near it.
		if instr.Number == nil or instructions[instr.Number - 2].Opcode ~= "RETURN" or #JumpsTo(chunk, instr) > 0 then
			output[#output + 1] = instr
		end
	end
	return output
end

return {
	JumpsTo = JumpsTo,
	ExitPoints = ExitPoints,
	TrimExitPoints = TrimExitPoints
}