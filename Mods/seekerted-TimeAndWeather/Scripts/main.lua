local Utils = require("utils")
local Config = require("config")

Utils.Log("Starting Time and Weather Mod by Ted the Seeker")
Utils.Log(string.format("Version %s", Utils.ModVer))
Utils.Log(_VERSION)

-- Table of the current loaded Save
local Save = {
	SlotIndex = nil,
	-- Local Time always expressed in seconds
	LocalTime = nil,
	PrevMapNo = nil,
}

local ElapsedTimeInMap = nil
local PreviousTimeSegment = nil

local MINS_IN_HOUR = 60
local MINS_IN_DAY = MINS_IN_HOUR * 24

-- 1 minute (or 1 second of IRL game time) in these layers = n minutes Surface Time
local TIME_DILATION = {
	[1] = 1,
	[2] = 2,
	[3] = 3,
	[4] = 4,
	[5] = 6,
}

-- Set Surface Time while constraining it to one week.
local function SetSurfaceTime(NewSurfaceTime)
	Save.SurfaceTime = NewSurfaceTime % (MINS_IN_DAY * 7)
end

-- Return a table based on the provided Local Time.
-- {Minutes [0-59], Hours [0-23], Weekdate [0-6]}
local function GetLocalTimeDetailed(LocalTime)
	return {
		Minutes = LocalTime % MINS_IN_HOUR,
		Weekdate = LocalTime // (MINS_IN_DAY),
		Hours = (LocalTime % MINS_IN_DAY) // MINS_IN_HOUR,
	}
end

-- Return Local Time in relation to system's current weekdate, hour, and minute. All 0-based.
local function GetLocalTimeFromOSDate(CurrentDateTime)
	return CurrentDateTime.min + (CurrentDateTime.hour * MINS_IN_HOUR) + ((CurrentDateTime.wday - 1) * MINS_IN_DAY)
end

local function SetTimeSegmentTransitionTime()
	local BP_MapEnvironment_C = StaticFindObject("/Game/MadeInAbyss/Maps/Environment/BP_MapEnvironment.Default__BP_MapEnvironment_C")

	if not BP_MapEnvironment_C:IsValid() then
		Utils.Log("BP_MapEnvironment_C is not valid.")
		return
	end

	BP_MapEnvironment_C.TransitionTime = 60
end

-- Index 0-3: Hello Abyss saves #1-4; 4-7: Deep in Abyss saves #5-8
local function LoadSaveDataFromSlot(Index)
	Utils.Log("Loading data from selected slot %d", Index)

	-- Get the data for the current save
	Save.SlotIndex = Index
	Save.LocalTime = tonumber(Config.Read(Index .. "-LocalTime"))

	if not Save.LocalTime then
		Save.LocalTime = GetLocalTimeFromOSDate(os.date("*t"))
		Utils.Log("No Local Time entry. Setting to %d", Save.LocalTime)
	end
end

-- Update Abyss Time to match the time elapsed
local function AddElapsedTimeToAbyssTime(BP_MIAGameInstance_C, ElapsedTime)
	if not BP_MIAGameInstance_C:IsValid() then
		Utils.Log("BP_MIAGameInstance_C is not valid.")
		return
	end

	local DetailedTimeElapsed = GetLocalTimeDetailed(ElapsedTime)

	BP_MIAGameInstance_C.AddAbyssTime(DetailedTimeElapsed.Hours, DetailedTimeElapsed.Minutes)

	local GetAbyssTimeOutParams = {}
	BP_MIAGameInstance_C.GetAbyssTime(GetAbyssTimeOutParams, {})
	Utils.Log("New Abyss Time: %02d:%02d (%02d:%02d+)", GetAbyssTimeOutParams.Hour, GetAbyssTimeOutParams.Minute, DetailedTimeElapsed.Hours,
			DetailedTimeElapsed.Minutes)
end

-- Compute the elapsed time on change of map. 1s of IRL game time is 1min of time elapsed in-game, multiplied by the
-- time dilation. Time dilation is only affected when ascending to a map of lower depth, and is computed by how much
-- was ascended (including fast travel).
local function GetElapsedLocalTimeOnMapChange(BP_MIAGameInstance_C)
	if not BP_MIAGameInstance_C:IsValid() then
		Utils.Log("BP_MIAGameInstance_C is not valid.")
		return 0
	end

	local GameStateBase = FindFirstOf("GameStateBase")
	if not GameStateBase:IsValid() then
		Utils.Log("GameStateBase is not valid.")
		return 0
	end

	local ElapsedTimeInMap = math.floor(GameStateBase.ReplicatedWorldTimeSeconds)

	local MIADatabaseFunctionLibrary = StaticFindObject("/Script/MadeInAbyss.Default__MIADatabaseFunctionLibrary")
	if not MIADatabaseFunctionLibrary:IsValid() then
		Utils.Log("MIADatabaseFunctionLibrary is not valid.")
		return 0
	end

	if not Save.PrevMapNo then
		Utils.Log("Save.PrevMapNo is nil.")
		Save.PrevMapNo = BP_MIAGameInstance_C.PlayMapNo
		return 0
	end

	local PrevMapInfo = MIADatabaseFunctionLibrary.GetMIAMapInfomation(Save.PrevMapNo, 0)
	local NextMapInfo = MIADatabaseFunctionLibrary.GetMIAMapInfomation(BP_MIAGameInstance_C.PlayMapNo, 0)
	Utils.Log("Changing maps from %s (MapNo: %d, Layer: %d, Depth: %dm) -> %s (MapNo: %d, Layer: %d, Depth: %dm)", PrevMapInfo.Name:ToString(),
			PrevMapInfo.ID, PrevMapInfo.Floor, PrevMapInfo.Depth, NextMapInfo.Name:ToString(), NextMapInfo.ID, NextMapInfo.Floor,
			NextMapInfo.Depth)

	local TimeDilation = 1
	
	if PrevMapInfo.Depth > NextMapInfo.Depth then
		TimeDilation = (PrevMapInfo.Depth - NextMapInfo.Depth) / 1000 + TIME_DILATION[PrevMapInfo.Floor]
	end
	
	local ElapsedTimeOnSurface = math.floor(ElapsedTimeInMap * TimeDilation)

	Utils.Log("Time elapsed: %dmin Surface Time (%ds IRL time); Time Dilation: %.2fx", ElapsedTimeOnSurface, ElapsedTimeInMap,
			TimeDilation)
	
	Save.PrevMapNo = BP_MIAGameInstance_C.PlayMapNo
	return ElapsedTimeOnSurface
end

-- Update the background image in Belchero Image to match the current time.
local function UpdateBelcheroBackground(WBP_EventBG_C)
	local BP_MapEnvironment_C = FindFirstOf("BP_MapEnvironment_C")
	if not BP_MapEnvironment_C:IsValid() then
		Utils.Log("BP_MapEnvironment_C is not valid.")
		return
	end

	-- Simply copy the sun light color of the current map setting and apply it to the rgba of the background image.
	local NewColor = BP_MapEnvironment_C.EnvParamsCurrent.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6

	if WBP_EventBG_C:IsValid() then
		WBP_EventBG_C:SetColorAndOpacity({
			R = NewColor.R,
			G = NewColor.G,
			B = NewColor.B,
			A = NewColor.A,
		})
	end
end

local function UpdateElapsedTimeInMapOnChangeLevel(BP_MIAGameInstance_C)
	ElapsedTimeInMap = GetElapsedLocalTimeOnMapChange(BP_MIAGameInstance_C)
end

local function BP_MIAGameInstance_C__OnSuccess_A025(Param_BP_MIAGameInstance_C)
	AddElapsedTimeToAbyssTime(Param_BP_MIAGameInstance_C:get(), ElapsedTimeInMap)
end

-- Called when the player clicks on a save to load.
local function WBP_SaveLayout_C__LoadData(Param_WBP_SaveLayout_C, Param_Index)
	LoadSaveDataFromSlot(Param_Index:get())
end

-- Called just before the map changes, so we can still get the variables from the current map.
local function BP_MIAGameInstance_C__ChangeLevel(Param_BP_MIAGameInstance_C, Param_MapNo)
	UpdateElapsedTimeInMapOnChangeLevel(Param_BP_MIAGameInstance_C:get())
end

local function WBP_EventBG_C__OnLoaded_6C51(Param_WBP_EventBG_C, Param_Loaded)
	UpdateBelcheroBackground(Param_WBP_EventBG_C:get())
end

-- Hook into BP_MIAGameInstance_C instance (hot-reload friendly)
local function HookMIAGameInstance(New_MIAGameInstance)
	if New_MIAGameInstance:IsValid() then
		Utils.Log("MIAGameInstance has been found")

		Utils.RegisterHookOnce("/Game/MadeInAbyss/UI/Save/WBP_SaveLayout.WBP_SaveLayout_C:LoadData", WBP_SaveLayout_C__LoadData)

		Utils.RegisterHookOnce("/Game/MadeInAbyss/Core/GameModes/BP_MIAGameInstance.BP_MIAGameInstance_C:ChangeLevel", BP_MIAGameInstance_C__ChangeLevel)

		SetTimeSegmentTransitionTime()

		Utils.RegisterHookOnce("/Game/MadeInAbyss/Core/GameModes/BP_MIAGameInstance.BP_MIAGameInstance_C:OnSuccess_A02554634B6C75B4B65022A3C3C5C24D",
				BP_MIAGameInstance_C__OnSuccess_A025)

		Utils.RegisterHookOnce("/Game/MadeInAbyss/UI/Event/WBP_EventBG.WBP_EventBG_C:OnLoaded_6C51A9624A6DCC627F3F8DBFEE7EF1D0",
				WBP_EventBG_C__OnLoaded_6C51)
		
		require("dev")
	else
		NotifyOnNewObject("/Script/MadeInAbyss.MIAGameInstance", HookMIAGameInstance)
	end
end
HookMIAGameInstance(FindFirstOf("MIAGameInstance"))