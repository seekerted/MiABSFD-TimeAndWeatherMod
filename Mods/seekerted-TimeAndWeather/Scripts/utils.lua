local Utils = {}

local RegisteredHooks = {}

Utils.ModName = "TimeAndWeather"
Utils.ModAuthor = "seekerted"
Utils.ModVer = "0.2.0"

function Utils.Log(Format, ...)
	print(string.format("[%s-%s] %s\n", Utils.ModAuthor, Utils.ModName, string.format(Format, ...)))
end

function Utils.RegisterHookOnce(FunctionName, Function)
	if not RegisteredHooks[FunctionName] then
		RegisteredHooks[FunctionName] = true
		RegisterHook(FunctionName, Function)
	end
end

-- Sends a message that the hooked function has been called, while showing the arguments.
function Utils.TestFunc(FunctionName)
	Utils.RegisterHookOnce(FunctionName, function(self, ...)
		local Args = ""
		for _, v in ipairs({...}) do
			Args = Args .. v:get() .. " "
		end

		Utils.Log("CALLED: %s %s", FunctionName, Args)
	end)
end

return Utils