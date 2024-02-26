local Utils = require("utils")
local Consts = require("consts")
local WidgetTime = require("w_time")
local MapEnv = require("mapenv")
local SS = require("skysphere")

Utils.Init("seekerted", "TimeAndWeather", "0.4.3")

local SaveSession = {
	-- The Minute component is not an integer as delta values will be added to it.
	PlayerTime = {
		Hour = 0,
		Minute = 0,
	},
	PrevMapNo = nil,
}

-- On each layer, the time is {TimeSpeed} times as fast relative to the first layer. e.g. 1 second in the fifth
-- layer is 6 seconds in the first layer.
local TIME_SPEED_PER_LAYER = {
	[1] = 1,
	[2] = 2,
	[3] = 3,
	[4] = 4,
	[5] = 6,
}

-- Time Segment now depends on the consts values
local function GetTimeSegmentNoFromHour(Hour)
	Hour = Hour * 100

	if Hour < Consts.TIME_SEGMENT_BEGIN.MorningBegin then
		return 4
	elseif Hour < Consts.TIME_SEGMENT_BEGIN.DaytimeBegin then
		return 1
	elseif Hour < Consts.TIME_SEGMENT_BEGIN.EveningBegin then
		return 2
	elseif Hour < Consts.TIME_SEGMENT_BEGIN.NightBegin then
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
local function AddDeltaToPlayerTime(Delta, PlayerTime, OutParam)
	if not Delta then return end

	-- In case the optional OutParam is not used
	OutParam = OutParam or {}

	PlayerTime.Minute = PlayerTime.Minute + Delta

	if math.floor(PlayerTime.Minute) >= Consts.MINS_IN_HOUR then
		OutParam.IsHourChanged = true
		PlayerTime.Hour = PlayerTime.Hour + math.floor(PlayerTime.Minute / Consts.MINS_IN_HOUR)
		PlayerTime.Minute = math.floor(PlayerTime.Minute % Consts.MINS_IN_HOUR)
	end

	if PlayerTime.Hour >= Consts.HOURS_IN_DAY then
		OutParam.IsHourChanged = true
		PlayerTime.Hour = PlayerTime.Hour % Consts.HOURS_IN_DAY
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

-- Change default BP_MapEnvironment_C (CDO) here.
local function InitDefaultMapEnvironment()
	local BP_MapEnvironment_C = StaticFindObject("/Game/MadeInAbyss/Maps/Environment/BP_MapEnvironment.Default__BP_MapEnvironment_C")
	if not BP_MapEnvironment_C:IsValid() then
		Utils.Log("BP_MapEnvironment_C is not valid. Cannot init Map Environment changes.")
		return
	end

	-- Transition time in seconds
	BP_MapEnvironment_C.TransitionTime = 60

	-- Set the time segment begins from the consts
	BP_MapEnvironment_C.TimeSegmentInfo.MorningBegin_3_586EAB8541F79C4E67CC12AB11B70CC4 = Consts.TIME_SEGMENT_BEGIN.MorningBegin
	BP_MapEnvironment_C.TimeSegmentInfo.DaytimeBegin_6_7F3B82CD41CB381CB7FE53B883B8F3A9 = Consts.TIME_SEGMENT_BEGIN.DaytimeBegin
	BP_MapEnvironment_C.TimeSegmentInfo.EveningBegin_8_BFB529A749F9C849F092DA9A2B459A8E = Consts.TIME_SEGMENT_BEGIN.EveningBegin
	BP_MapEnvironment_C.TimeSegmentInfo.NightBegin_10_41484B7E45F89103EACA158873AB0A63 = Consts.TIME_SEGMENT_BEGIN.NightBegin
end

local function ChangeGameTimeSegmentByHour(Hour)
	Utils.GI:SetAbyssTime(Hour, 0)
end

local function UpdateSeekerCampBackground(New_MIAEventPictureWidget)
	-- Check if we're in the Seeker Camp Interior
	if Consts.MAP_NO.SEEKER_CAMP_INTERIOR ~= Utils.GI.PlayMapNo then return end

	local TimeSegmentNo = GetTimeSegmentNoFromHour(SaveSession.PlayerTime.Hour)

	New_MIAEventPictureWidget:SetColorAndOpacity(Consts.SEEKER_CAMP_INTERIOR_TIME_SEGMENT[TimeSegmentNo])
end

local function UpdateBelcheroBackground(New_MIAEventPictureWidget)
	-- Check if we're in Belchero
	if Consts.MAP_NO.BELCHERO ~= Utils.GI.PlayMapNo then return end

	-- Check if the MIAEventPictureWidget is the right one we are looking for.
	local WBP_EVENTBG_C = "WBP_EventBG_C"
	if WBP_EVENTBG_C ~= New_MIAEventPictureWidget:GetClass():GetFName():ToString() or Utils.GI:GetFName():ToString() ~=
			New_MIAEventPictureWidget:GetOuter():GetFName():ToString() then return end

	local BP_MapEnvironment_C = FindFirstOf("BP_MapEnvironment_C")
	if not BP_MapEnvironment_C:IsValid() or not BP_MapEnvironment_C.EnvParamsCurrent:IsValid() then
		Utils.Log("BP_MapEnvironment_C is not valid.")
		return
	end

	local WBP_EventBG_C = New_MIAEventPictureWidget

	-- Simply copy the sun light color of the current map setting and apply it to the rgba of the background image.
	local NewColor = BP_MapEnvironment_C.EnvParamsCurrent.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6

	WBP_EventBG_C:SetColorAndOpacity({
		R = NewColor.R,
		G = NewColor.G,
		B = NewColor.B,
		A = NewColor.A,
	})
end

-- Update the background visuals in Orth to match the current time.
local function UpdateOrthBackground(New_MIAEventPictureWidget)
	-- Check that we are on the Orth map.
	if Utils.GI.PlayMapNo ~= Consts.MAP_NO.ORTH then return end

	-- Validate if the MIAEventPictureWidget is actually the WBP_EvPic3006_C that we need.

	if not New_MIAEventPictureWidget:IsValid() or not New_MIAEventPictureWidget:GetOuter():IsValid() or not New_MIAEventPictureWidget:GetOuter():GetOuter():IsValid()
			then return end

	-- Grab the current instance of WBP_StageSelectOrth_C, and verify if the MIAEventPictureWidget grand-outer is that.
	local WBP_StageSelectOrth_C = FindFirstOf("WBP_StageSelectOrth_C")
	if not WBP_StageSelectOrth_C:IsValid() then return end

	if New_MIAEventPictureWidget:GetOuter():GetOuter():GetFName():ToString() ~= WBP_StageSelectOrth_C:GetFName():ToString()
			then return end

	-- At this point, we've established that New_MIAEventPictureWidget == WBP_EvPic3006_C.
	local WBP_EvPic3006_C = New_MIAEventPictureWidget

	local TimeSegmentNo = GetTimeSegmentNoFromHour(SaveSession.PlayerTime.Hour)

	WBP_EvPic3006_C:SetColorAndOpacity(Consts.ORTH_TIME_SEGMENT[TimeSegmentNo])
end

-- Also update the background of other Orth locations, like Relic Appraisal
local function UpdateOrthSubBackground(WBP_EventBG_C)
	local WBP_StageSelectOrth_C = FindFirstOf("WBP_StageSelectOrth_C")
	if not WBP_StageSelectOrth_C:IsValid() then
		Utils.Log("WBP_StageSelectOrth_C is not valid.")
		return
	end

	if WBP_StageSelectOrth_C.OldBGIndex ~= Consts.ORTH_SUB_LOCATIONS.RELIC_APPRAISAL then return end

	local TimeSegmentNo = GetTimeSegmentNoFromHour(SaveSession.PlayerTime.Hour)

	WBP_EventBG_C:SetColorAndOpacity(Consts.ORTH_TIME_SEGMENT[TimeSegmentNo])
end

-- Called when player selects a save slot to load 
-- 0-3: Hello Abyss saves #1-4; 4-7: Deep in Abyss saves #5-8
local function WBP_SaveLayout_C__LoadData(Param_WBP_SaveLayout_C, Param_Index)
	-- Set the PlayerTime from OS time
	SaveSession.PlayerTime = GetPlayerTimeFromOsDate(os.date("*t"))
	ChangeGameTimeSegmentByHour(SaveSession.PlayerTime.Hour)

	Utils.Log("Loading OS Time of %02d:%02.0f", SaveSession.PlayerTime.Hour, SaveSession.PlayerTime.Minute)
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
end

local function TickPlayerTime(DeltaSeconds)
	local Info = {}
	AddDeltaToPlayerTime(DeltaSeconds, SaveSession.PlayerTime, Info)

	-- Update time segment when the hour changes
	if Info and Info.IsHourChanged then
		Utils.Log("Hour has changed (%02d:%02.0f)", SaveSession.PlayerTime.Hour, SaveSession.PlayerTime.Minute)
		ChangeGameTimeSegmentByHour(SaveSession.PlayerTime.Hour)

		-- Also update the Sky Sphere
		SS.OverrideIfExists(Utils.GI.PlayMapNo, GetTimeSegmentNoFromHour(SaveSession.PlayerTime.Hour))
	end
end

local function WBP_EventBG_C__OnLoaded_6C51(Param_WBP_EventBG_C, Param_Loaded)
	if Utils.GI.PlayMapNo == Consts.MAP_NO.ORTH then
		UpdateOrthSubBackground(Param_WBP_EventBG_C:get())
	end
end

-- Called on every unpaused tick of gameplay.
local function BP_MIAGameModeBase_C__ReceiveTick(Param_BP_MIAGameModeBase_C, Param_DeltaSeconds)
	TickPlayerTime(Param_DeltaSeconds:get())
end

-- Called when the widget that shows layer and map name has finished playing
local function WBP_MapNameLayout_C__OnAnimationFinished(Param_WBP_MapNameLayout_C, Param_Animation)
	ExecuteWithDelay(500, function()
		WidgetTime.Start(SaveSession.PlayerTime, Utils.GI)
	end)
end

-- Called after the Map Environment has already been established given the specific Map and Layer
local function BP_MapEnvironment_C__InitMapEnvActors(Param_BP_MapEnvironment_C)
	MapEnv.OverrideIfExists(Param_BP_MapEnvironment_C:get())
end

RegisterInitGameStatePostHook(function(Param_AGameStateBase)
	local IsAbyssGameMode = Param_AGameStateBase:get():IsA("/Game/MadeInAbyss/Core/GameModes/BP_AbyssGameMode.BP_AbyssGameMode_C")
	local IsOrthGameMode = Param_AGameStateBase:get():IsA("/Game/MadeInAbyss/Core/GameModes/BP_OrthGameMode.BP_OrthGameMode_C")

	if not IsAbyssGameMode and not IsOrthGameMode then return end

	-- Update time segment (instantly instead of transition)
	ChangeGameTimeSegmentByHour(SaveSession.PlayerTime.Hour)

	if IsAbyssGameMode then
		-- Apply overrides to the BP_Sky_Sphere*_C, depending on time of day
		SS.OverrideIfExists(Utils.GI.PlayMapNo, GetTimeSegmentNoFromHour(SaveSession.PlayerTime.Hour))
	end
end)

ExecuteInGameThread(function()
	Utils.RegisterHookOnce("/Game/MadeInAbyss/UI/Save/WBP_SaveLayout.WBP_SaveLayout_C:LoadData",
			WBP_SaveLayout_C__LoadData)

	Utils.RegisterHookOnce("/Game/MadeInAbyss/Core/GameModes/BP_MIAGameInstance.BP_MIAGameInstance_C:ChangeLevel",
			BP_MIAGameInstance_C__ChangeLevel)

	Utils.RegisterHookOnce("/Game/MadeInAbyss/UI/Event/WBP_EventBG.WBP_EventBG_C:OnLoaded_6C51A9624A6DCC627F3F8DBFEE7EF1D0",
			WBP_EventBG_C__OnLoaded_6C51)

	Utils.RegisterHookOnce("/Game/MadeInAbyss/UI/MapName/WBP_MapNameLayout.WBP_MapNameLayout_C:OnAnimationFinished",
			WBP_MapNameLayout_C__OnAnimationFinished)

	Utils.RegisterHookOnce("/Game/MadeInAbyss/Maps/Environment/BP_MapEnvironment.BP_MapEnvironment_C:InitMapEnvActors",
			BP_MapEnvironment_C__InitMapEnvActors)

	InitDefaultMapEnvironment()
end)

-- Hook into new instances of MIAEventPictureWidget
local function HookMIAEventPictureWidget(New_MIAEventPictureWidget)
	if not Utils.GI then return end

	UpdateOrthBackground(New_MIAEventPictureWidget)
	UpdateBelcheroBackground(New_MIAEventPictureWidget)
	UpdateSeekerCampBackground(New_MIAEventPictureWidget)
end
NotifyOnNewObject("/Script/MadeInAbyss.MIAEventPictureWidget", HookMIAEventPictureWidget)

-- Hook into new instances of MIAGameModeBase (hot-reload friendly)
local function HookMIAGameModeBase(New_MIAGameModeBase)
	if New_MIAGameModeBase:IsValid() then
		-- Hook into GameModeBase's ReceiveTick, but this function is only available on subclasses of
		-- BP_MIAGameModeBase_C.
		if New_MIAGameModeBase:IsA("/Game/MadeInAbyss/Core/GameModes/BP_MIAGameModeBase.BP_MIAGameModeBase_C") then
			Utils.RegisterHookOnce("/Game/MadeInAbyss/Core/GameModes/BP_MIAGameModeBase.BP_MIAGameModeBase_C:ReceiveTick",
					BP_MIAGameModeBase_C__ReceiveTick)
		end
	else
		NotifyOnNewObject("/Script/MadeInAbyss.MIAGameModeBase", HookMIAGameModeBase)
	end
end
HookMIAGameModeBase(FindFirstOf("BP_MIAGameModeBase_C"))

Utils.RegisterCommand("spt", function(FullCommand, Parameters, Log)
	local NewHour = tonumber(Parameters[1])

	if not NewHour then
		Log("Failed to manually set PlayerTime")
		return false
	end

	Log("Manually setting PlayerTime")

	SaveSession.PlayerTime.Hour = NewHour
	SaveSession.PlayerTime.Minute = tonumber(Parameters[2]) or 0

	return true
end)