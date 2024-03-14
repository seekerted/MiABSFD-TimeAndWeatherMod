local Utils = require("utils")

local WTime = {}

local WidgetTime = nil
local WIDGET_TIME_NAME = "ST_WidgetTime_C"

local function InterruptWidgetTime()
	if not WidgetTime or not WidgetTime:IsValid() or not WidgetTime:IsInViewport() then return end

	WidgetTime:RemoveFromViewport()
end

local function EndWidgetTime()
	if not WidgetTime or not WidgetTime:IsValid() or not WidgetTime:IsInViewport() then return end

	WidgetTime:AnimeOut(0)
end

local function ShowWidgetTime(PlayerTime)
	if not WidgetTime or not WidgetTime:IsValid() or not WidgetTime:IsInViewport() then return end

	-- os.date is just used for formatting.
	local TimeText = os.date("%I:%M %p", os.time({
		year = 1980,
		month = 1,
		day = 1,
		hour = PlayerTime.Hour,
		min = math.floor(PlayerTime.Minute),
	}))

	WidgetTime:OpenSubtitle(FText(TimeText))

	WidgetTime:AnimeIn(0)
end

function WTime.Start(PlayerTime, GI)
	local PrevWidgetTime = FindObject("WBP_SequenceText_C", WIDGET_TIME_NAME)

	if PrevWidgetTime:IsValid() then
		WidgetTime = PrevWidgetTime
	else
		WidgetTime = StaticConstructObject(StaticFindObject("/Game/MadeInAbyss/UI/Sequence/WBP_SequenceText.WBP_SequenceText_C"),
				GI, FName(WIDGET_TIME_NAME), 0, 0, nil, false, false, nil)
	end

	if not WidgetTime:IsValid() then
		Utils.Log("Unable to create Widget Time")
		return
	end

	WidgetTime:AddToViewport(1)

	-- I wasn't able to add the widget to the HUD, wherein it'll go underneath the pause overlay / menu.
	-- So instead, just hook into those functions and then immediately hide the widget.
	Utils.RegisterHookOnce("/Game/MadeInAbyss/Core/GameModes/BP_AbyssPlayerController.BP_AbyssPlayerController_C:ForceCloseRingMenu",
			InterruptWidgetTime)

	Utils.RegisterHookOnce("/Game/MadeInAbyss/Core/GameModes/BP_CommonPlayerController.BP_CommonPlayerController_C:HideHUD",
			InterruptWidgetTime)

	ShowWidgetTime(PlayerTime)

	-- After 3 seconds, hide the widget.
	ExecuteWithDelay(3000, EndWidgetTime)
end

return WTime