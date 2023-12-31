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
	Save.LocalTime = tonumber(Config.Read(Index .. "-LocalTime"))

	if Save.LocalTime == nil then
		Save.LocalTime = GetLocalTimeFromOSDate(os.date("*t"))
		Utils.Log("No Local Time entry. Setting to %d", Save.LocalTime)
	end
end

-- Set Abyss Time to match Local Time
local function UpdateAbyssTimeToLocalTime(BP_MIAGameInstance_C, LocalTime)
	if not BP_MIAGameInstance_C:IsValid() then
		Utils.Log("BP_MIAGameInstance_C is not valid.")
		return
	end

	local DetailedLocalTime = GetLocalTimeDetailed(LocalTime)
	BP_MIAGameInstance_C.SetAbyssTime(DetailedLocalTime.Hours, DetailedLocalTime.Minutes)
	Utils.Log("Update Abyss Time to match Local Time of %d (%02d:%02d)", LocalTime, DetailedLocalTime.Hours, DetailedLocalTime.Minutes)
end

local function GetElapsedLocalTimeOnMapChange(BP_MIAGameInstance_C, MapNo)
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

	if Save.PrevMapNo == nil then
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
	
	Save.PrevMapNo = MapNo
	return ElapsedTimeOnSurface
end

local function UpdateLocalTimeOnChangeLevel(BP_MIAGameInstance_C, MapNo)
	local TimeElapsed = GetElapsedLocalTimeOnMapChange(BP_MIAGameInstance_C, MapNo)
	-- SetSurfaceTime(Save.SurfaceTime + TimeElapsed)
end

-- Called when the player clicks on a save to load.
local function WBP_SaveLayout_C__LoadData(Param_WBP_SaveLayout_C, Param_Index)
	LoadSaveDataFromSlot(Param_Index:get())
end

-- Called just before the map changes, so we can still get the variables from the current map.
local function BP_MIAGameInstance_C__ChangeLevel(Param_BP_MIAGameInstance_C, Param_MapNo)
	UpdateLocalTimeOnChangeLevel(Param_BP_MIAGameInstance_C:get(), Param_MapNo:get())
end

-- Hook into this function in between map loads
local function BP_MIAGameInstance_C__InitializeWeatherOnLoaded(Param_BP_MIAGameInstance_C, Param_bInitState)
	UpdateAbyssTimeToLocalTime(Param_BP_MIAGameInstance_C:get(), Save.LocalTime)
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

		MakeTimePresetTransitionInstantaneous()

		Utils.RegisterHookOnce("/Script/MadeInAbyss.MIAAngelScriptLevel:ChangeMap", function(self, MapNo, MapPoint)
			Utils.Log("ChangeMap %d", MapNo:get())
		end)
	else
		NotifyOnNewObject("/Script/MadeInAbyss.MIAGameInstance", HookMIAGameInstance)
	end
end
HookMIAGameInstance(FindFirstOf("MIAGameInstance"))