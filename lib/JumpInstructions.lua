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

		if current.Opcode == "RETURN" then
			output[#output + 1] = current
		end
	end

	return output
end

return {
	JumpsTo = JumpsTo,
	ExitPoints = ExitPoints,
}