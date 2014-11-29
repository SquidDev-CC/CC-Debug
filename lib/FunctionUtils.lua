local function VisitFunctions(func)
	local queue = {func}
	local top = #queue
	local bottom = 1

	return function()
		local topFunction = queue[bottom]

		if topFunction then
			queue[bottom] = nil
			bottom = bottom + 1

			local protos = topFunction.Protos
			for i = 0, protos.Count - 1, 1 do
				top = top + 1
				queue[top] = protos[i]
			end
		end

		return topFunction
	end
end

return {
	VisitFunctions = VisitFunctions,
}