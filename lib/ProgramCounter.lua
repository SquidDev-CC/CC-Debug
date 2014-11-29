local function PcAtLine(chunk, line)
	local instructions = chunk.Instructions

	local startPc = -1
	local endPc = -1
	for pc = 1, instructions.Count do
		local currentLine = instructions[pc -1].LineNumber
		if currentLine <= line then
			startPc = pc
		elseif currentLine > line then
			endPc = pc - 1
			break
		end
	end

	if endPc == -1 then
		endPc = startPc
	end

	return startPc, endPc
end

local function AtLine(chunk, line)
	local startPc, endPc = PcAtLine(chunk, line)
	local output = {}
	local locals = chunk.Locals
	for i = 0, locals.Count -1 do
		local l = locals[i]
		if l.StartPC <= endPc and l.EndPC >= startPc then
			output[i + 1] = l
		end
	end

	return output
end

return {
	PcAtLine = PcAtLine,
	AtLine = AtLine,
}