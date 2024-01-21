local Utils = require("utils")
local Config = require("config")

Utils.Log("Starting Time and Weather Mod by Ted the Seeker")
Utils.Log(string.format("Version %s", Utils.ModVer))
Utils.Log(_VERSION)

local MINS_IN_HOUR = 60
local HOURS_IN_DAY = 24

-- On each layer, the time is {TimeSpeed} times as fast relative to the first layer. e.g. 1 second in the fifth
-- layer is 6 seconds in the first layer.
local TIME_SPEED_PER_LAYER = {
	[1] = 1,
	[2] = 2,
	[3] = 3,
	[4] = 4,
	[5] = 6,
}

local SaveSession = {
	-- The Minute component is not an integer as delta values will be added to it.
	PlayerTime = {
		Hour = 0,
		Minute = 0,
	},
	PrevMapNo = nil,
	CurrentTimeSegment = nil,
	GI = nil,
}

-- 1 Morning [4-6); 2 Daytime [6-19); 3 Evening [19-20); 4 Night [20-4)
local function GetCorrectTimeSegment(Hour)
	if Hour < 4 then
		return 4
	elseif Hour < 6 then
		return 1
	elseif Hour < 19 then
		return 2
	elseif Hour < 20 then
		return 3
	else
		return 4
	end
end

-- Gets the hour and min properties of the DateTime table and returns it as a table with {Hour, Minute}
local function GetPlayerTimeFromOsDate(DateTime)
	return {
		Hour = DateTime.hour,
		Minute = DateTime.min,
	}
end

-- Adds Delta to PlayerTime (into its minutes component). Clamps the Hour and Minute values to [0-24) and [0-60) and
-- adjusts accordingly when it exceeds.
local function AddDeltaToPlayerTime(Delta, PlayerTime)
	if not Delta then return end

	PlayerTime.Minute = PlayerTime.Minute + Delta

	if PlayerTime.Minute >= MINS_IN_HOUR then
		PlayerTime.Hour = PlayerTime.Hour + math.floor(PlayerTime.Minute / MINS_IN_HOUR)
		PlayerTime.Minute = PlayerTime.Minute % MINS_IN_HOUR
	end

	if PlayerTime.Hour >= HOURS_IN_DAY then
		PlayerTime.Hour = PlayerTime.Hour % HOURS_IN_DAY
	end
end

-- Returns how long in IRL seconds the player spent on the current map
local function GetTimeElapsedInMap()
	local GameStateBase = FindFirstOf("GameStateBase")
	if not GameStateBase:IsValid() then
		Utils.Log("Couldn't get time elapsed in map as GameStateBase was invalid")
		return 0
	end

	return GameStateBase.ReplicatedWorldTimeSeconds
end

-- Returns time dilation factor, based on the depth difference of the two maps from PrevMapNo to CurrentMapNo
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
	local PrevMapInfo = MIADatabaseFunctionLibrary:GetMIAMapInfomation(PrevMapNo, 0)
	local NextMapInfo = MIADatabaseFunctionLibrary:GetMIAMapInfomation(CurrentMapNo, 0)

	local TimeDilation = 1

	if PrevMapInfo.Depth > NextMapInfo.Depth then
		TimeDilation = (PrevMapInfo.Depth - NextMapInfo.Depth) / 1000 + TIME_SPEED_PER_LAYER[PrevMapInfo.Floor]
	end

	Utils.Log("Time dilation from %s (MapNo: %d, Layer: %d, Depth: %dm) -> %s (MapNo: %d, Layer: %d, Depth: %dm) is %02.2fx",
			PrevMapInfo.Name:ToString(), PrevMapInfo.ID, PrevMapInfo.Floor, PrevMapInfo.Depth,
			NextMapInfo.Name:ToString(), NextMapInfo.ID, NextMapInfo.Floor, NextMapInfo.Depth, TimeDilation)

	return TimeDilation
end

local function ChangeGameTimeSegmentByHour(Hour)
	SaveSession.GI:SetAbyssTime(Hour, 0)
end

-- Called when player selects a save slot to load 
-- 0-3: Hello Abyss saves #1-4; 4-7: Deep in Abyss saves #5-8
local function WBP_SaveLayout_C__LoadData(Param_WBP_SaveLayout_C, Param_Index)
	-- Set the PlayerTime from OS time, and set the CurrentTimeSegment given the hour.
	SaveSession.PlayerTime = GetPlayerTimeFromOsDate(os.date("*t"))
	SaveSession.CurrentTimeSegment = GetCorrectTimeSegment(SaveSession.PlayerTime.Hour)

	Utils.Log("Loading Data (%02d:%02.0f, %d)", SaveSession.PlayerTime.Hour, SaveSession.PlayerTime.Minute, SaveSession.CurrentTimeSegment)
end

-- Called on the fade out into darkness on change map, or even any time the map is about the change (also called on Save
-- loading)
local function BP_MIAGameInstance_C__ChangeLevel(Param_BP_MIAGameInstance_C, Param_MapNo)
	local BP_MIAGameInstance_C = Param_BP_MIAGameInstance_C:get()

	local TimeElapsedInMap = GetTimeElapsedInMap()
	local TimeDilation = GetTimeDilation(SaveSession.PrevMapNo, BP_MIAGameInstance_C.PlayMapNo)

	-- Apply time dilation delta during map change (i.e. going upwards)
	local TimeDilationDelta = math.max(TimeElapsedInMap * (TimeDilation - 1), 0)
	if TimeDilationDelta > 0 then
		Utils.Log("Adding Time Dilation delta of (%02.2fs * %02.2fx =) %02.2fs", TimeElapsedInMap, TimeDilation - 1, TimeDilationDelta)
		AddDeltaToPlayerTime(TimeDilationDelta, SaveSession.PlayerTime)
	end

	Utils.Log("Current time: %02d:%02.0f", SaveSession.PlayerTime.Hour, SaveSession.PlayerTime.Minute)

	SaveSession.PrevMapNo = BP_MIAGameInstance_C.PlayMapNo

	-- Update time segment (instantly instead of transition)
	ChangeGameTimeSegmentByHour(SaveSession.PlayerTime.Hour)
end

-- Called on every tick of the Player Controller. Do NOT put anything too heavy in here, even Find*()
local function BP_AbyssPlayerController_C__ReceiveTick(Param_BP_AbyssPlayerController_C, Param_DeltaSeconds)
	AddDeltaToPlayerTime(Param_DeltaSeconds:get(), SaveSession.PlayerTime)

	-- If the current time segment is not aligned with the correct time segment (based on the hour), change the time
	-- segment to the correct one.
	local CorrectTimeSegment = GetCorrectTimeSegment(SaveSession.PlayerTime.Hour)
	if CorrectTimeSegment ~= SaveSession.CurrentTimeSegment then
		Utils.Log("It is now %02d:%02.0f. Changing time segment: %d -> %d", SaveSession.PlayerTime.Hour, SaveSession.PlayerTime.Minute,
				SaveSession.CurrentTimeSegment, CorrectTimeSegment)

		SaveSession.CurrentTimeSegment = CorrectTimeSegment
		ChangeGameTimeSegmentByHour(SaveSession.PlayerTime.Hour)
	end
end

-- Hook into BP_MIAGameInstance_C instance (hot-reload friendly)
local function HookMIAGameInstance(New_MIAGameInstance)
	if New_MIAGameInstance:IsValid() then
		Utils.Log("MIAGameInstance has been found")
		SaveSession.GI = New_MIAGameInstance

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

-- Hook into new instances of MIAPlayerController (hot-reload friendly)
local function HookMIAPlayerController(New_MIAPlayerController)
	if New_MIAPlayerController:IsValid() then
		-- Hook into the player controller's ReceiveTick
		Utils.RegisterHookOnce(
				"/Game/MadeInAbyss/Core/GameModes/BP_AbyssPlayerController.BP_AbyssPlayerController_C:ReceiveTick",
				BP_AbyssPlayerController_C__ReceiveTick)
	else
		NotifyOnNewObject("/Script/MadeInAbyss.MIAPlayerController", HookMIAPlayerController)
	end
end
HookMIAPlayerController(FindFirstOf("BP_AbyssPlayerController_C"))