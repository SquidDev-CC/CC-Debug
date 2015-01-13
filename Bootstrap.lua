local dir = shell.resolve("/"..fs.getDir(shell.getRunningProgram()))
local file = fs.open("log.txt", "w")

local env
env = setmetatable({
	loadfile = function(path)
		return setfenv(loadfile(fs.combine(dir, path)), env)
	end,
	dofile = function(path) 
		return env.loadfile(path)() 
	end,
	print = function(...)
		_G.print(...)

		local data = {...}

		for _, d in pairs(data) do
			file.writeLine(tostring(d))
		end
	end
}, {
	__index=getfenv(),
})

xpcall(setfenv(function()
	dofile("Stuff.lua")
end, env), function(err)
	printError(err)

	for i = 4, 15, 1 do
		local s, err = pcall(function() error("", i) end)
		if err:match("xpcall") then break end
		printError("Trace: " .. err)
	end
end)
file.close()