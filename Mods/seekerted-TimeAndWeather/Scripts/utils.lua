-- Ted the Seeker's utils.lua 2024-02-19
local Utils = {}

local RegisteredHooks = {}

Utils.ModName = nil
Utils.ModAuthor = nil
Utils.ModVer = nil

Utils.GI = nil

-- Init values and start
function Utils.Init(Author, Name, Ver)
	Utils.ModAuthor = Author
	Utils.ModName = Name
	Utils.ModVer = Ver

	Utils.Log("Starting %s (%s) by %s", Utils.ModName, Utils.ModVer, Utils.ModAuthor)
	Utils.Log(_VERSION)
end

-- Prints to console in the format of [<author>-<mod>] <message> in a new line.
function Utils.Log(Format, ...)
	print(string.format("[%s-%s] %s\n", Utils.ModAuthor, Utils.ModName, string.format(Format, ...)))
end

-- Wrapper to UE4SS' RegisterHook except it prevents creating any more duplicate hooks according to function name.
function Utils.RegisterHookOnce(FunctionName, Function)
	if not RegisteredHooks[FunctionName] then
		local PreID, PostID = RegisterHook(FunctionName, Function)
		RegisteredHooks[FunctionName] = true

		Utils.Log("Hooked (once) onto %s (%d, %d)", FunctionName, PreID, PostID)
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
-- Code inside the callback function must use Log() for logging, not Utils.Log.
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

-- Register a hook that will unregister itself after it is called
function Utils.RegisterSingleUseHook(FunctionName, Function)
	local PreID = nil
	local PostID = nil
	PreID, PostID = RegisterHook(FunctionName, function(...)
		Function(...)
		UnregisterHook(FunctionName, PreID, PostID)

		Utils.Log("Unhooked (Was single use) %s (%d, %d)", FunctionName, PreID, PostID)
	end)

	Utils.Log("Hooked (Single use) onto %s (%d, %d)", FunctionName, PreID, PostID)
end

function Utils.PrintTable(Table)
	local Str = "{"

	for k, v in pairs(Table) do
		Str = string.format("%s%s: %s; ", Str, k, v)
	end

	Str = Str .. "}"
	Utils.Log(Str)
end

ExecuteInGameThread(function()
	Utils.GI = FindFirstOf("BP_MIAGameInstance_C")

	Utils.Log("Got game instance for Utils.GI")
end)

return Utils