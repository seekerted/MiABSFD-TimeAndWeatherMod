local Utils = require("utils")
local Config = require("config")

Utils.Log("Starting Time and Weather Mod by Ted the Seeker")
Utils.Log(string.format("Version %s", Utils.ModVer))
Utils.Log(_VERSION)

-- Table of the current loaded Save
local Save = {
	SlotIndex = nil,
	-- Surface Time always expressed in seconds
	SurfaceTime = nil,
}

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

local function GetLayerNoFromMapNo(MapNo)
	if MapNo <= 9 then
		return 1
	elseif MapNo <= 20 then
		return 2
	elseif MapNo <= 29 then
		return 3
	elseif MapNo <= 38 then
		return 4
	elseif MapNo <= 50 then
		return 5
	else
		-- Edge Cases

		-- Belchero Orphanage has MapNo 80.
		-- Orth has MapNo 60.
		if MapNo == 80 or MapNo == 60 then
			return 1
		end

		return 0
	end
end

-- Return a table based on the Surface Time.
-- {Minutes [0-59], Hours [0-23], Weekdate [0-6]}
local function GetSurfaceTimeDetailed(SurfaceTime)
	return {
		Minutes = SurfaceTime % MINS_IN_HOUR,
		Weekdate = SurfaceTime // (MINS_IN_DAY),
		Hours = (SurfaceTime % MINS_IN_DAY) // MINS_IN_HOUR,
	}
end

-- Return Surface Time in relation to player's current weekdate, hour, and minute. All 0-based.
local function GetSurfaceTimeFromOSDateTime()
	local CurrentDateTime = os.date("*t")

	return CurrentDateTime.min + (CurrentDateTime.hour * MINS_IN_HOUR) + ((CurrentDateTime.wday - 1) * MINS_IN_DAY)
end

local function MakeTimePresetTransitionInstantaneous()
	local BP_MapEnvironment_C = StaticFindObject("/Game/MadeInAbyss/Maps/Environment/BP_MapEnvironment.Default__BP_MapEnvironment_C")

	if not BP_MapEnvironment_C:IsValid() then
		Utils.Log("Default__BP_MapEnvironment_C is not valid.")
		return
	end

	BP_MapEnvironment_C.TransitionTime = 0
end

-- Index 0-3: Hello Abyss saves #1-4; 4-7: Deep in Abyss saves #5-8
local function LoadSaveDataFromSlot(Index)
	Utils.Log("Loading data from selected slot %d", Index)

	-- Get the data for the current save
	Save.SlotIndex = Index
	Save.SurfaceTime = tonumber(Config.Read(Index))

	if Save.SurfaceTime == nil then
		Save.SurfaceTime = GetSurfaceTimeFromOSDateTime()
		Utils.Log("No Surface Time entry. Setting to %d", Save.SurfaceTime)
	end
end

-- Set Abyss Time to match Surface Time
local function UpdateAbyssTimeToSurfaceTime(BP_MIAGameInstance_C, SurfaceTime)
	if not BP_MIAGameInstance_C:IsValid() then
		Utils.Log("BP_MIAGameInstance_C is not valid.")
		return
	end

	local DetailedSurfaceTime = GetSurfaceTimeDetailed(SurfaceTime)
	BP_MIAGameInstance_C.SetAbyssTime(DetailedSurfaceTime.Hours, DetailedSurfaceTime.Minutes)
	Utils.Log("Setting Abyss Time to match Surface Time of %d (%02d:%02d)", SurfaceTime, DetailedSurfaceTime.Hours, DetailedSurfaceTime.Minutes)
end

local function GetElapsedSurfaceTimeOnMap(BP_MIAGameInstance_C, MapNo)
	local ElapsedTimeInMap = 0

	local GameStateBase = FindFirstOf("GameStateBase")
	if not GameStateBase:IsValid() then
		Utils.Log("GameStateBase is not valid.")
	else
		ElapsedTimeInMap = math.floor(GameStateBase.ReplicatedWorldTimeSeconds)
	end

	-- By the time this hooked function is called BP_MIAGameInstance_C.MapNo has already updated to the next map, so
	-- we use PrevMapNo instead.
	local CurrentLayer = GetLayerNoFromMapNo(BP_MIAGameInstance_C.PrevMapNo)
	Utils.Log("Current layer of %d is %d", BP_MIAGameInstance_C.PrevMapNo, CurrentLayer)
	local TimeDilation = TIME_DILATION[CurrentLayer]
	local ElapsedTimeOnSurface = ElapsedTimeInMap * TimeDilation

	Utils.Log("Time elapsed: %dmin Surface Time (%ds IRL time); Time Dilation: %dx; Map: %d, Layer: %d", ElapsedTimeOnSurface,
			ElapsedTimeInMap, TimeDilation, BP_MIAGameInstance_C.PrevMapNo, CurrentLayer)
	return ElapsedTimeOnSurface
end

local function UpdateSurfaceTimeOnChangeLevel(BP_MIAGameInstance_C, MapNo)
	Utils.Log("On change to Map %d", MapNo)

	local TimeElapsed = GetElapsedSurfaceTimeOnMap(BP_MIAGameInstance_C, MapNo)
	SetSurfaceTime(Save.SurfaceTime + TimeElapsed)
end

-- Called when the player clicks on a save to load.
local function WBP_SaveLayout_C__LoadData(Param_WBP_SaveLayout_C, Param_Index)
	LoadSaveDataFromSlot(Param_Index:get())
end

-- Called just before the map changes, so we can still get the variables from the current map.
local function BP_MIAGameInstance_C__ChangeLevel(Param_BP_MIAGameInstance_C, Param_MapNo)
	UpdateSurfaceTimeOnChangeLevel(Param_BP_MIAGameInstance_C:get(), Param_MapNo:get())
end

-- Hook into this function in between map loads
local function BP_MIAGameInstance_C__InitializeWeatherOnLoaded(Param_BP_MIAGameInstance_C, Param_bInitState)
	UpdateAbyssTimeToSurfaceTime(Param_BP_MIAGameInstance_C:get(), Save.SurfaceTime)
end

local function BP_MapEnvironment_C__SetVariablesForChangeMapEnvironment(Param_BP_MapEnvironment_C, Param_TimeSegment, Param_EnvParams)
	Utils.Log("SetVariablesForChangeMapEnvironment")
	Utils.Log(Param_TimeSegment:get())
end

-- Hook into BP_MIAGameInstance_C instance (hot-reload friendly)
local function HookMIAGameInstance(New_MIAGameInstance)
	if New_MIAGameInstance:IsValid() then
		Utils.Log("MIAGameInstance has been found")

		Utils.RegisterHookOnce("/Game/MadeInAbyss/UI/Save/WBP_SaveLayout.WBP_SaveLayout_C:LoadData", WBP_SaveLayout_C__LoadData)
		Utils.RegisterHookOnce("/Game/MadeInAbyss/Core/GameModes/BP_MIAGameInstance.BP_MIAGameInstance_C:InitializeWeatherOnLoaded",
				BP_MIAGameInstance_C__InitializeWeatherOnLoaded)

		RegisterConsoleCommandHandler("sat", function(FullCommand, Parameters, OutputDevice)
			New_MIAGameInstance.SetAbyssTime(Parameters[1], Parameters[2])
			return true
		end)

		Utils.RegisterHookOnce("/Game/MadeInAbyss/Core/GameModes/BP_MIAGameInstance.BP_MIAGameInstance_C:ChangeLevel", BP_MIAGameInstance_C__ChangeLevel)

		-- MakeTimePresetTransitionInstantaneous()
		Utils.RegisterHookOnce("/Game/MadeInAbyss/Maps/Environment/BP_MapEnvironment.BP_MapEnvironment_C:SetVariablesForChangeMapEnvironment",
				BP_MapEnvironment_C__SetVariablesForChangeMapEnvironment)
	else
		NotifyOnNewObject("/Script/MadeInAbyss.MIAGameInstance", HookMIAGameInstance)
	end
end
HookMIAGameInstance(FindFirstOf("MIAGameInstance"))