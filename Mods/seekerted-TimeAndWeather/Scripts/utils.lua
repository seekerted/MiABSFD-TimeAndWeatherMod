local Utils = {}

local RegisteredHooks = {}

Utils.ModName = "TimeAndWeather"
Utils.ModAuthor = "seekerted"
Utils.ModVer = "0.3.1"

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
			Args = string.format("%s[%s] ", Args, v:get())
		end

		Utils.Log("CALLED: %s %s", FunctionName, Args)
	end)
end

-- Wraps around RegisterConsoleCommandHandler. To provide better context on which command said which log.
-- Callback function takes in parameters: (FullCommand, Parameters, Log) and return true/false regarding its success status.
-- Code inside the callback function must use Log() for logging, not Utils.Log
function Utils.RegisterCommand(CommandName, Callback)
	RegisterConsoleCommandHandler("st" .. CommandName, function(FullCommand, Parameters, OutputDevice)
		Utils.Log("> %s", FullCommand)

		local function Log(Format, ...)
			Utils.Log("[%s] %s", FullCommand, string.format(Format, ...))
		end

		local exitVal = Callback(FullCommand, Parameters, Log)

		Log("End Command. Successful? %s", tostring(exitVal))

		return true
	end)
end

return Utils