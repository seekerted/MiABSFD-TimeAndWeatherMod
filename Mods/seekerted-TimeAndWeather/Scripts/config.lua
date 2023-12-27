local Utils = require("Utils")

local Config = {}

local ConfigFileName = "config.txt"
local ResourceDirectory = "Mods/" .. Utils.ModAuthor .. "-" .. Utils.ModName .. "/"

-- Opens the config file, and returns it.
-- If it doesn't exist, create it but return nil.
local function Open()
	local ConfigFullFileName = ResourceDirectory .. ConfigFileName
	Utils.Log("Opening config file: %s", ConfigFullFileName)
	local ConfigFile = io.open(ConfigFullFileName, "r")

	if ConfigFile == nil then
		Utils.Log("Config file doesn't exist. Creating %s", ConfigFullFileName)
		io.open(ConfigFullFileName, "w")
		io.close()

		return nil
	else
		return ConfigFile
	end
end

-- Read a value from the config file, given key.
-- If it doesn't exist, returns nil.
function Config.Read(ReadKey)
	Utils.Log("Reading from config file this key: %s", ReadKey)

	local ConfigFile = OpenConfigFile()
	local ReturnValue = nil

	if ConfigFile == nil then
		ReturnValue = nil
	else
		for Line in ConfigFile:lines() do
			local Key, Value = Line:match("([^=]+)=(.*)")
			Utils.Log("%s, %s", Key, Value)
			if ReadKey == Key then
				ReturnValue = Value
				break
			end
		end
	end

	ConfigFile:close()

	Utils.Log("Retrieved value: %s", ReturnValue)
	return ReturnValue
end

return Config