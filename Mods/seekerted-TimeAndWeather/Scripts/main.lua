---@alias float number
---@alias int32 integer

local Utils = require("utils")
local Config = require("config")

Utils.Log("Starting Time and Weather Mod by Ted the Seeker")
Utils.Log(string.format("Version %s", Utils.ModVer))
Utils.Log(_VERSION)

local MINS_IN_HOUR = 60
local HOURS_IN_DAY = 24

---On each layer, the time is {TimeSpeed} times as fast relative to the first layer. e.g. 1 second in the fifth
---layer is 6 seconds in the first layer.
---@enum (LayerNo) TimeSpeed
local TIME_SPEED_PER_LAYER = {
	[1] = 1,
	[2] = 2,
	[3] = 3,
	[4] = 4,
	[5] = 6,
}

---@class (exact) SaveSession
---@field PlayerTime PlayerTime
---@field PrevMapNo number?
local SaveSession = {
	---The Minute component is not an integer as delta values will be added to it.
	---@class (exact) PlayerTime
	---@field Hour integer
	---@field Minute number
	PlayerTime = {
		Hour = 0,
		Minute = 0,
	},
	PrevMapNo = nil,
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

---Returns how long in IRL seconds the player spent on the current map
---@return number #GameStateBase.ReplicatedWorldTimeSeconds (0 if GameStateBase was invalid)
local function GetTimeElapsedInMap()
	---@type AGameStateBase
	local GameStateBase = FindFirstOf("GameStateBase")
	if not GameStateBase:IsValid() then
		Utils.Log("Couldn't get time elapsed in map as GameStateBase was invalid")
		return 0
	end

	return GameStateBase.ReplicatedWorldTimeSeconds
end

---Returns time dilation factor, based on the depth difference of the two maps from PrevMapNo to CurrentMapNo
---@param PrevMapNo integer
---@param CurrentMapNo integer
---@return number
local function GetTimeDilation(PrevMapNo, CurrentMapNo)
	local MIADatabaseFunctionLibrary = StaticFindObject("/Script/MadeInAbyss.Default__MIADatabaseFunctionLibrary")
	if not MIADatabaseFunctionLibrary:IsValid() then
		Utils.Log("Could not get time dilation as MIADatabaseFunctionLibrary is invalid. Returning 1")
		return 1
	end

	if not PrevMapNo or not CurrentMapNo then
		Utils.Log("Could not get time dilation as either PrevMapNo or CurrentMapNo are nil. Returning 1")
		return 1
	end

	-- ChangeLevel doesn't fire when changing between submaps/levels anyway, so just set the sub ID to 0.
	local PrevMapInfo = MIADatabaseFunctionLibrary.GetMIAMapInfomation(PrevMapNo, 0)
	local NextMapInfo = MIADatabaseFunctionLibrary.GetMIAMapInfomation(CurrentMapNo, 0)

	local TimeDilation = 1

	if PrevMapInfo.Depth > NextMapInfo.Depth then
		TimeDilation = (PrevMapInfo.Depth - NextMapInfo.Depth) / 1000 + TIME_SPEED_PER_LAYER[PrevMapInfo.Floor]
	end

	Utils.Log("Time dilation from %s (MapNo: %d, Layer: %d, Depth: %dm) -> %s (MapNo: %d, Layer: %d, Depth: %dm) is %.2fx",
			PrevMapInfo.Name:ToString(), PrevMapInfo.ID, PrevMapInfo.Floor, PrevMapInfo.Depth,
			NextMapInfo.Name:ToString(), NextMapInfo.ID, NextMapInfo.Floor, NextMapInfo.Depth, TimeDilation)

	return TimeDilation
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
	---@type UBP_MIAGameInstance_C
	local BP_MIAGameInstance_C = Param_BP_MIAGameInstance_C:get()
	if not BP_MIAGameInstance_C:IsValid() then
		Utils.Log("BP_MIAGameInstance_C was invalid on BP_MIAGameInstance_C:ChangeLevel")
		return
	end

	local TimeElapsedInMap = GetTimeElapsedInMap()
	local TimeDilation = GetTimeDilation(SaveSession.PrevMapNo, BP_MIAGameInstance_C.PlayMapNo)
	SaveSession.PrevMapNo = BP_MIAGameInstance_C.PlayMapNo

	Utils.Log("Time spent: %f", TimeElapsedInMap)
end

---@param Param_BP_AbyssPlayerController_C RemoteObject 
---@param Param_DeltaSeconds RemoteObject
local function BP_AbyssPlayerController_C__ReceiveTick(Param_BP_AbyssPlayerController_C, Param_DeltaSeconds)
	AddDeltaToPlayerTime(Param_DeltaSeconds:get(), SaveSession.PlayerTime)
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

---@param New_MIAPlayerController AMIAPlayerController
local function HookMIAPlayerController(New_MIAPlayerController)
	-- Only use this function to hook into the player controller's ReceiveTick
	Utils.RegisterHookOnce(
			"/Game/MadeInAbyss/Core/GameModes/BP_AbyssPlayerController.BP_AbyssPlayerController_C:ReceiveTick",
			BP_AbyssPlayerController_C__ReceiveTick)
end
NotifyOnNewObject("/Script/MadeInAbyss.MIAPlayerController", HookMIAPlayerController)