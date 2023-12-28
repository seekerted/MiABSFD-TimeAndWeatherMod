local Utils = require("utils")
local Config = require("config")

Utils.Log("Starting Time and Weather Mod by Ted the Seeker")
Utils.Log(string.format("Version %s", Utils.ModVer))
Utils.Log(_VERSION)

local SaveSlot = nil
local SurfaceTime = nil
local CurrentLayer = 1

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
	SurfaceTime = NewSurfaceTime % (MINS_IN_DAY * 7)
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
		if MapNo == 80 then
			return 1
		end

		return 0
	end
end

-- Return a table based on the Surface Time.
-- {Minutes [0-59], Hours [0-23], Weekdate [0-6]}
local function GetSimpleSurfaceTime()
	return {
		Minutes = SurfaceTime % MINS_IN_HOUR,
		Weekdate = SurfaceTime // (MINS_IN_DAY),
		Hours = (SurfaceTime % MINS_IN_DAY) // MINS_IN_HOUR,
	}
end

-- Return Surface Time in relation to player's current weekdate, hour, and minute.
local function GetSurfaceTimeFromOSDateTime()
	local CurrentDateTime = os.date("*t")

	return CurrentDateTime.min + (CurrentDateTime.hour * MINS_IN_HOUR) + ((CurrentDateTime.wday - 1) * MINS_IN_DAY)
end

-- Called when the player selects a save to load.
-- Index 0-3: Hello Abyss saves #1-4; 4-7: Deep in Abyss saves #5-8
local function WBP_SaveLayout_C__LoadData(Param_WBP_SaveLayout_C, Param_Index)
	Utils.Log("Player loaded save in slot %d", Param_Index:get())

	SaveSlot = Param_Index:get()
	SurfaceTime = Config.Read(SaveSlot)

	if SurfaceTime == nil then
		SurfaceTime = GetSurfaceTimeFromOSDateTime()
		Utils.Log("No Surface Time entry. Setting to %d", SurfaceTime)
	end
end

local function MakeTimePresetTransitionInstantaneous()
	local BP_MapEnvironment_C = StaticFindObject("/Game/MadeInAbyss/Maps/Environment/BP_MapEnvironment.Default__BP_MapEnvironment_C")

	if not BP_MapEnvironment_C:IsValid() then
		Utils.Log("Default__BP_MapEnvironment_C is not valid.")
		return
	end

	BP_MapEnvironment_C.TransitionTime = 0
end

-- Called just before the map changes, so we can still get the variables from the current map.
local function BP_MIAGameInstance_C__ChangeLevel(Param_BP_MIAGameInstance_C, Param_MapNo)
	Utils.Log("Change Level %d", Param_MapNo:get())

	-- Use MIASpawnManager as it keeps time on how long the player spent in each map.
	local MapStayTime = nil
	local MIASpawnManager = FindFirstOf("MIASpawnManager")
	if not MIASpawnManager:IsValid() then
		Utils.Log("MIASpawnManager is not valid.")
		MapStayTime = 0
	else
		MapStayTime = math.floor(MIASpawnManager.MapStayTime)
	end

	local CurrentLayer = GetLayerNoFromMapNo(Param_BP_MIAGameInstance_C:get().PrevMapNo)

	local TimeElapsed = MapStayTime * TIME_DILATION[CurrentLayer]
	Utils.Log("Time elapsed: %dmin Surface Time (%ds IRL time); Time Dilation: %dx", TimeElapsed, MapStayTime, TIME_DILATION[CurrentLayer])
	SetSurfaceTime(SurfaceTime + TimeElapsed)

	CurrentLayer = Param_BP_MIAGameInstance_C:get().GetStageFloorNo()
	Utils.Log("Set current layer to %d", CurrentLayer)
end

-- Called when a level has been successfully loaded and everything (I think)
local function BP_MIAGameInstance_C__OnSuccess_884D(Param_BP_MIAGameInstance_C)
	local SimpleSurfaceTime = GetSimpleSurfaceTime()
	Param_BP_MIAGameInstance_C:get().SetAbyssTime(SimpleSurfaceTime.Hours, SimpleSurfaceTime.Minutes)
end

-- Just for logging purposes.
local function MIAGameInstance__SetAbyssTime(Param_MIAGameInstance, Param_Hour, Param_Minute)
	Utils.Log("Setting Abyss Time to %d, %d", Param_Hour:get(), Param_Minute:get())
end

-- Hook into BP_MIAGameInstance_C instance (hot-reload friendly)
local function HookMIAGameInstance(New_MIAGameInstance)
	if New_MIAGameInstance:IsValid() then
		Utils.Log("MIAGameInstance has been found")

		Utils.RegisterHookOnce("/Game/MadeInAbyss/UI/Save/WBP_SaveLayout.WBP_SaveLayout_C:LoadData", WBP_SaveLayout_C__LoadData)
		Utils.RegisterHookOnce("/Script/MadeInAbyss.MIAGameInstance:SetAbyssTime", MIAGameInstance__SetAbyssTime)

		RegisterConsoleCommandHandler("sat", function(FullCommand, Parameters, OutputDevice)
			New_MIAGameInstance.SetAbyssTime(Parameters[1], Parameters[2])
			return true
		end)

		Utils.RegisterHookOnce("/Game/MadeInAbyss/Core/GameModes/BP_MIAGameInstance.BP_MIAGameInstance_C:OnSuccess_884DEFA44E0E3C73A1DE44B096F9A105",
				BP_MIAGameInstance_C__OnSuccess_884D)

		Utils.RegisterHookOnce("/Game/MadeInAbyss/Core/GameModes/BP_MIAGameInstance.BP_MIAGameInstance_C:ChangeLevel", BP_MIAGameInstance_C__ChangeLevel)

		MakeTimePresetTransitionInstantaneous()
	else
		NotifyOnNewObject("/Script/MadeInAbyss.MIAGameInstance", HookMIAGameInstance)
	end
end
HookMIAGameInstance(FindFirstOf("MIAGameInstance"))