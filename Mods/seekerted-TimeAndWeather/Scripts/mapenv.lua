local Utils = require("utils")
local Consts = require("consts")

-- In hindsight, I shouldn't have been doing this by hand
-- This was just incredibly tedious and I have gone insane

local MapEnv = {}

local function OverrideL2InvertedMaps(ME)
	-- Remove the harsh red tint in the morning
	ME.EnvParamsMorning.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6.R = 0.226493
	ME.EnvParamsMorning.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6.B = 0.186512

	-- Makes the mornings more "sunrise-y"
	ME.EnvParamsMorning.SkyLightColor_79_3781F62A4D6EE8E1246DCE8BB23A25CE.G = 0.3
	ME.EnvParamsMorning.CloudBrightness_7_BBBB75084906A0B773143EA238D08647 = 0
	ME.EnvParamsMorning.BG_EmissiveColor_36_8C47B07A43219E7C2FBB4B9C402C0DFD = {R = 0.6, G = 0.2, B = 0.2, A = 1}

	-- Makes the evenings more "sunset-y"
	ME.EnvParamsEvening.CloudColor_34_943E82CD453753C24EAE5F8EEB8D0466.R = 0.636326
	ME.EnvParamsEvening.CloudBrightness_7_BBBB75084906A0B773143EA238D08647 = 0
	ME.EnvParamsEvening.BG_EmissiveColor_36_8C47B07A43219E7C2FBB4B9C402C0DFD = {R = 0.5, G = 0.3, B = 0.2, A = 1}

	-- Make the evenings darker
	ME.EnvParamsNight.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6 = {R = 0.31, G = 0.32, B = 0.40, A = 1}
end

local function OverrideL5Outside(ME)
	-- Removes the harsh purple tint in the morning
	-- Makes the mornings more "sunrise-y"
	ME.EnvParamsMorning.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6 = {R = 0.1, G = 0.06, B = 0.03, A = 1}
	ME.EnvParamsMorning.ExpFogColor_30_D55BFE85467585991BAC7A95C3A5B09B = {R = 0.1, G = 0.06, B = 0.03, A = 1}
	ME.EnvParamsMorning.ExpFogColorInBadWeatherNight_76_B581C0FC45E9A92824F8F3BCCDCBF320 = {R = 0.1, G = 0.06, B = 0.03, A = 1}
	ME.EnvParamsMorning.UCelSceneLightScale_65_23914E5F475F9EEC9F441B90AE7561C5 = 5
	ME.EnvParamsMorning.UCelSceneLightScaleInBadWeatherNight_73_FAC89C414F3607BC23020CB533036262 = 5

	-- Removes the harsh purple tint in the evening
	ME.EnvParamsEvening.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6 = {R = 0.7, G = 0.2, B = 0.1, A = 1}
	ME.EnvParamsEvening.SkyBPSunHeight_21_DF1E731740B6C1D15D9023871BB26C92 = 0.2
	ME.EnvParamsEvening.ExpFogColor_30_D55BFE85467585991BAC7A95C3A5B09B = {R = 0.5, G = 0.2, B = 0.1, A = 1}
	ME.EnvParamsEvening.ExpFogColorInBadWeatherNight_76_B581C0FC45E9A92824F8F3BCCDCBF320 = {R = 0.5, G = 0.2, B = 0.1, A = 1}
	ME.EnvParamsEvening.UCelSceneLightScale_65_23914E5F475F9EEC9F441B90AE7561C5 = 5
	ME.EnvParamsEvening.UCelSceneLightScaleInBadWeatherNight_73_FAC89C414F3607BC23020CB533036262 = 5

	-- Make the nights not too dark
	ME.EnvParamsNight.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6 = {R = 0.06, G = 0.09, B = 0.1, A = 1}
	ME.EnvParamsNight.UCelSceneLightScale_65_23914E5F475F9EEC9F441B90AE7561C5 = 5
	ME.EnvParamsNight.UCelSceneLightScaleInBadWeatherNight_73_FAC89C414F3607BC23020CB533036262 = 5
end

local function OverrideL1(ME)
	-- Makes the mornings more "sunrise-y"
	ME.EnvParamsMorning.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6 = {R = 0.50, G = 0.48, B = 0.45, A = 1}
	ME.EnvParamsMorning.ExpFogColor_30_D55BFE85467585991BAC7A95C3A5B09B = {R = 0.2, G = 0.19, B = 0.18, A = 1}
	ME.EnvParamsMorning.ExpFogColorInBadWeatherNight_76_B581C0FC45E9A92824F8F3BCCDCBF320 = {R = 0.2, G = 0.19, B = 0.18, A = 1}
end

local function OverrideL4Outside(ME)
	-- Makes the mornings more "sunrise-y"
	ME.EnvParamsMorning.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6 = {R = 0.50, G = 0.48, B = 0.45, A = 1}
	ME.EnvParamsMorning.ExpFogColor_30_D55BFE85467585991BAC7A95C3A5B09B = {R = 0.2, G = 0.19, B = 0.18, A = 1}
	ME.EnvParamsMorning.ExpFogColorInBadWeatherNight_76_B581C0FC45E9A92824F8F3BCCDCBF320 = {R = 0.2, G = 0.19, B = 0.18, A = 1}

	-- Makes the evenings more "sunset-y"
	ME.EnvParamsEvening.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6 = {R = 0.8, G = 0.5, B = 0.2, A = 1}
	ME.EnvParamsEvening.ExpFogColor_30_D55BFE85467585991BAC7A95C3A5B09B = {R = 0.2, G = 0.19, B = 0.18, A = 1}
	ME.EnvParamsEvening.ExpFogColorInBadWeatherNight_76_B581C0FC45E9A92824F8F3BCCDCBF320 = {R = 0.2, G = 0.19, B = 0.18, A = 1}

	-- Tweak the nights so it's actually dark
	ME.EnvParamsNight.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6 = {R = 0.35, G = 0.50, B = 0.77, A = 1}
	ME.EnvParamsNight.ExpFogColor_30_D55BFE85467585991BAC7A95C3A5B09B = {R = 0, G = 0.01, B = 0.03, A = 1}
	ME.EnvParamsNight.ExpFogColorInBadWeatherNight_76_B581C0FC45E9A92824F8F3BCCDCBF320 = {R = 0, G = 0.01, B = 0.03, A = 1}
	ME.EnvParamsNight.SkyLightColor_79_3781F62A4D6EE8E1246DCE8BB23A25CE = {R = 0, G = 0, B = 0, A = 0}
	ME.EnvParamsNight.UCelSceneLightScale_65_23914E5F475F9EEC9F441B90AE7561C5 = 0.5
	ME.EnvParamsNight.UCelSceneLightScaleInBadWeatherNight_73_FAC89C414F3607BC23020CB533036262 = 0.5
end

local function OverrideL3EdgeMaps(ME)
	-- The Layer 3 edge maps all have some weird lighting in it. There are some random lights pointed at the cave
	-- holes in the edges, so when you look outside the light changes. Should be fine.

	-- Makes the mornings "sunrise-y" as the default ones are *not* sunrise-y at all.
	ME.EnvParamsMorning.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6 = {R = 0.6, G = 0.4, B = 0.43, A = 0.1}
	ME.EnvParamsMorning.ExpFogDirectionalColor_59_3798EC654A193C89E50A0EA32CB2BE8C = {R = 0.6, G = 0.4, B = 0.43, A = 1}
	ME.EnvParamsMorning.ExpFogMaxOpacity_56_DB46BE6A4188009ABADD22A7A9E5F0E8 = 0
	ME.EnvParamsMorning.CloudOpacity_62_C3FC50A842497B687EB71EB618ED6FC5 = 1

	-- Makes the evenings "sunset-y" as the default ones are *not* sunset-y at all.
	ME.EnvParamsEvening.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6 = {R = 0.6, G = 0.4, B = 0.43, A = 0.1}
	ME.EnvParamsEvening.ExpFogDirectionalColor_59_3798EC654A193C89E50A0EA32CB2BE8C = {R = 0.8, G = 0.4, B = 0.43, A = 1}
	ME.EnvParamsEvening.ExpFogMaxOpacity_56_DB46BE6A4188009ABADD22A7A9E5F0E8 = 0
	ME.EnvParamsEvening.CloudOpacity_62_C3FC50A842497B687EB71EB618ED6FC5 = 1

	-- Make the nights actually dark
	ME.EnvParamsNight.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6 = {R = 0.04, G = 0.09, B = 0.15, A = 1}
	ME.EnvParamsNight.ExpFogColor_30_D55BFE85467585991BAC7A95C3A5B09B.A = 0.01
	ME.EnvParamsNight.ExpFogColorInBadWeatherNight_76_B581C0FC45E9A92824F8F3BCCDCBF320.A = 0.01
	ME.EnvParamsNight.ExpFogDirectionalColor_59_3798EC654A193C89E50A0EA32CB2BE8C = {R = 0.04, G = 0.09, B = 0.25, A = 1}
	ME.EnvParamsNight.ExpFogMaxOpacity_56_DB46BE6A4188009ABADD22A7A9E5F0E8= 0.01
	ME.EnvParamsNight.CloudOpacity_62_C3FC50A842497B687EB71EB618ED6FC5 = 0.01
end

local function OverrideIdoFrontAreas(ME)
	-- Makes the mornings "sunrise-y" as the default ones are *not* sunrise-y at all.
	ME.EnvParamsMorning.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6 = {R = 0.3, G = 0.2, B = 0.2, A = 1}
	ME.EnvParamsMorning.ExpFogColor_30_D55BFE85467585991BAC7A95C3A5B09B = {R = 0.006, G = 0.004, B = 0.004, A = 1}
	ME.EnvParamsMorning.ExpFogColorInBadWeatherNight_76_B581C0FC45E9A92824F8F3BCCDCBF320 = {R = 0.006, G = 0.004, B = 0.004, A = 1}

	-- Makes the mornings "sunrise-y" as the default ones are *not* sunrise-y at all.
	ME.EnvParamsEvening.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6 = {R = 0.4, G = 0.2, B = 0.1, A = 1}
	ME.EnvParamsEvening.ExpFogColor_30_D55BFE85467585991BAC7A95C3A5B09B = {R = 0.006, G = 0.004, B = 0.004, A = 1}
	ME.EnvParamsEvening.ExpFogColorInBadWeatherNight_76_B581C0FC45E9A92824F8F3BCCDCBF320 = {R = 0.006, G = 0.004, B = 0.004, A = 1}

	ME.EnvParamsNight.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6 = {R = 0.04, G = 0.06, B = 0.08, A = 1}
end

local function OverrideIdoFrontInternal(ME)
	-- For some reason the fog here is too intense, so turn them down a bit
	ME.EnvParamsDaytime.ExpFogColor_30_D55BFE85467585991BAC7A95C3A5B09B = {R = 0.02, G = 0.02, B = 0.02, A = 1}
	ME.EnvParamsDaytime.ExpFogColorInBadWeatherNight_76_B581C0FC45E9A92824F8F3BCCDCBF320 = {R = 0.02, G = 0.02, B = 0.02, A = 1}

	OverrideIdoFrontAreas(ME)
end

local MapEnvOverrides = {
	-- Layer 1
	[Consts.MAP_NO.NETHERWORLD_GATE] = OverrideL1,
	[Consts.MAP_NO.TREE_FOSSIL_ABODE] = OverrideL1,
	[Consts.MAP_NO.GRAND_BRIDGE_WAY] = OverrideL1,
	[Consts.MAP_NO.WATERFALL_GONDOLA] = OverrideL1,
	[Consts.MAP_NO.TWIN_FALLS] = OverrideL1,
	[Consts.MAP_NO.WIND_RIDING_WINDMILL] = OverrideL1,
	[Consts.MAP_NO.STONE_ARK] = OverrideL1,
	[Consts.MAP_NO.JUMPING_ROCK] = OverrideL1,
	[Consts.MAP_NO.MULTILAYER_HILL] = OverrideL1,

	-- Layer 2
	[Consts.MAP_NO.FOREST_OF_TEMPTATION] = OverrideL1,
	[Consts.MAP_NO.CORPSE_WEEPER_DEN] = OverrideL1,
	[Consts.MAP_NO.INVERTED_FOREST] = OverrideL2InvertedMaps,
	[Consts.MAP_NO.HELLS_CROSSING] = OverrideL2InvertedMaps,
	[Consts.MAP_NO.INVERTED_ARBOR] = OverrideL2InvertedMaps,
	[Consts.MAP_NO.SEEKER_CAMP] = OverrideL2InvertedMaps,

	-- Layer 3
	[Consts.MAP_NO.THE_GREAT_FAULT] = OverrideL3EdgeMaps,
	[Consts.MAP_NO.ROCK_SLIDE_HALL] = OverrideL3EdgeMaps,

	-- Layer 4
	[Consts.MAP_NO.GOBLETS_OF_GIANTS] = OverrideL4Outside,
	[Consts.MAP_NO.HIDDEN_HOT_SPRING] = OverrideL4Outside,
	[Consts.MAP_NO.GIANT_VINE_BRIDGE] = OverrideL4Outside,

	-- Layer 5
	[Consts.MAP_NO.SEA_OF_CORPSES_1] = OverrideL5Outside,
	[Consts.MAP_NO.SEA_OF_CORPSES_2] = OverrideL5Outside,
	[Consts.MAP_NO.HAIL_JAIL] = OverrideL5Outside,
	[Consts.MAP_NO.IDOFRONT_AREA] = OverrideIdoFrontAreas,
	[Consts.MAP_NO.SANDY_ICE_AREA_1] = OverrideL5Outside,
	[Consts.MAP_NO.SANDY_ICE_AREA_2] = OverrideL5Outside,
	[Consts.MAP_NO.IDOFRONT] = OverrideIdoFrontAreas,
	[Consts.MAP_NO.IDOFRONT_INTERNAL] = OverrideIdoFrontInternal,
}

-- Override a BP_MapEnvironment_C's variables if it exists for the specific map
function MapEnv.OverrideIfExists(BP_MapEnvironment_C)
	local MapNo = BP_MapEnvironment_C.MapNo

	if MapEnvOverrides[MapNo] ~= nil then
		Utils.Log("Applying BP_MapEnvironment_C overrides for MapNo: %d", MapNo)

		MapEnvOverrides[MapNo](BP_MapEnvironment_C)
	end
end

return MapEnv