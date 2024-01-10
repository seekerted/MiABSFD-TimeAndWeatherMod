local Utils = require("utils")
local Config = require("config")

Utils.Log("Starting Time and Weather Mod by Ted the Seeker")
Utils.Log(string.format("Version %s", Utils.ModVer))
Utils.Log(_VERSION)

local MINS_IN_HOUR = 60
local HOURS_IN_DAY = 24

local SaveSession = {
	---The Minute component is not an integer as delta values will be added to it.
	---@class (exact) PlayerTime
	---@field Hour integer
	---@field Minute number
	PlayerTime = {
		Hour = 0,
		Minute = 0,
	}
}

---Gets the hour and min properties of the DateTime table and returns it as a table with {Hour, Minute}
---@param DateTime osdate
---@return table
local function GetHourMinuteFromDateTime(DateTime)
	return {
		Hour = DateTime.hour,
		Minute = DateTime.min,
	}
end

---Adds Delta to PlayerTime (into its minutes component). Clamps the Hour and Minute values to [0-24) and [0-60) and
---adjusts accordingly when it exceeds.
---@param Delta number
---@param PlayerTime PlayerTime
local function AddDeltaToPlayerTime(Delta, PlayerTime)
	PlayerTime.Minute = PlayerTime.Minute + Delta

	if PlayerTime.Minute >= MINS_IN_HOUR then
		PlayerTime.Hour = PlayerTime.Hour + math.floor(PlayerTime.Minute / MINS_IN_HOUR)
		PlayerTime.Minute = PlayerTime.Minute % MINS_IN_HOUR
	end

	if PlayerTime.Hour >= HOURS_IN_DAY then
		PlayerTime.Hour = PlayerTime.Hour % HOURS_IN_DAY
	end
end

---Called when player selects a save slot to load 
---@param Param_WBP_SaveLayout_C RemoteObject
---@param Param_Index RemoteObject 0-3: Hello Abyss saves #1-4; 4-7: Deep in Abyss saves #5-8
local function WBP_SaveLayout_C__LoadData(Param_WBP_SaveLayout_C, Param_Index)
	SaveSession.PlayerTime = GetHourMinuteFromDateTime(os.date("*t"))
end

---Called on the fade out into darkness on change map.
---@param Param_BP_MIAGameInstance_C RemoteObject
---@param Param_MapNo RemoteObject Map number of the next map
local function BP_MIAGameInstance_C__ChangeLevel(Param_BP_MIAGameInstance_C, Param_MapNo)
end

---@param Param_BP_AbyssPlayerController_C RemoteObject 
---@param Param_DeltaSeconds RemoteObject
local function BP_AbyssPlayerController_C__ReceiveTick(Param_BP_AbyssPlayerController_C, Param_DeltaSeconds)
	AddDeltaToPlayerTime(Param_DeltaSeconds:get(), SaveSession.PlayerTime)
	Utils.PrintTable(SaveSession.PlayerTime)
end

---Hook into BP_MIAGameInstance_C instance (hot-reload friendly)
---@param New_MIAGameInstance UBP_MIAGameInstance_C
local function HookMIAGameInstance(New_MIAGameInstance)
	if New_MIAGameInstance:IsValid() then
		Utils.Log("MIAGameInstance has been found")

		Utils.RegisterHookOnce("/Game/MadeInAbyss/UI/Save/WBP_SaveLayout.WBP_SaveLayout_C:LoadData",
				WBP_SaveLayout_C__LoadData)

		Utils.RegisterHookOnce("/Game/MadeInAbyss/Core/GameModes/BP_MIAGameInstance.BP_MIAGameInstance_C:ChangeLevel",
				BP_MIAGameInstance_C__ChangeLevel)

		require("dev")
	else
		NotifyOnNewObject("/Script/MadeInAbyss.MIAGameInstance", HookMIAGameInstance)
	end
end
HookMIAGameInstance(FindFirstOf("BP_MIAGameInstance_C"))

---@param New_BP_AbyssPlayerController_C ABP_AbyssPlayerController_C
local function HookBP_AbyssPlayerController_C(New_BP_AbyssPlayerController_C)
	-- Only use this function to hook into the player controller's ReceiveTick
	Utils.RegisterHookOnce(
			"/Game/MadeInAbyss/Core/GameModes/BP_AbyssPlayerController.BP_AbyssPlayerController_C:ReceiveTick",
			BP_AbyssPlayerController_C__ReceiveTick)
end
NotifyOnNewObject("/Game/MadeInAbyss/Core/GameModes/BP_AbyssPlayerController.BP_AbyssPlayerController_C",
		HookBP_AbyssPlayerController_C)