local Utils = {}

local RegisteredHooks = {}

Utils.ModName = "TimeAndWeather"
Utils.ModAuthor = "seekerted"
Utils.ModVer = "0.3.4"

---Prints to console in the format of [<author>-<mod>] <message> in a new line.
---@param Format string
---@param ... (string | number)?
function Utils.Log(Format, ...)
	print(string.format("[%s-%s] %s\n", Utils.ModAuthor, Utils.ModName, string.format(Format, ...)))
end

---Wrapper to UE4SS' RegisterHook except it prevents creating any more duplicate hooks according to function name.
---@param FunctionName string
---@param Function function
function Utils.RegisterHookOnce(FunctionName, Function)
	if not RegisteredHooks[FunctionName] then
		RegisteredHooks[FunctionName] = true
		RegisterHook(FunctionName, Function)
	end
end

---Sends a message that the hooked function has been called, while showing the arguments.
---@param FunctionName string
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
-- Code inside the callback function must use Log() for logging, not Utils.Log.
---@param CommandName string Name of the command to be called in PIE. Will be prefixed with "st" to prevent collisions.
---@param Callback fun(FullCommand:string, Parameters:string, Log:fun(Message:string)):boolean If successful.
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

function Utils.PrintTable(Table)
	local Str = "{"

	for k, v in pairs(Table) do
		Str = string.format("%s%s: %s; ", Str, k, v)
	end

	Str = Str .. "}"
	Utils.Log(Str)
end

return Utils