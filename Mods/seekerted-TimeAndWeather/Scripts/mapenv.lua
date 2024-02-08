local Utils = require("utils")
local Consts = require("consts")

local MapEnv = {}

-- L2, M12 Inverted Forest, M13 Hell's Crossing, M14 Inverted Arbor, M15 Seeker Camp
-- In the inverted maps of the 2nd Layer, there's a harsh red tint on mornings, and a harsh purple tint on the distance
-- fog in the evenings. Remove those.
local function OverrideL2InvertedMaps(ME)
	-- Remove the harsh red tint on L2's morning
	ME.EnvParamsMorning.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6.R = 0.226493
	ME.EnvParamsMorning.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6.B = 0.186512
	
	-- Remove the harsh purple tint on L2's evening
	ME.EnvParamsEvening.BG_EmissiveColor_36_8C47B07A43219E7C2FBB4B9C402C0DFD.G = 0.276
	ME.EnvParamsEvening.BG_EmissiveColor_36_8C47B07A43219E7C2FBB4B9C402C0DFD.R = 0.276
end

local MapEnvOverrides = {
	[Consts.MAP_NO.INVERTED_FOREST] = OverrideL2InvertedMaps,
	[Consts.MAP_NO.HELLS_CROSSING] = OverrideL2InvertedMaps,
	[Consts.MAP_NO.INVERTED_ARBOR] = OverrideL2InvertedMaps,
	[Consts.MAP_NO.SEEKER_CAMP] = OverrideL2InvertedMaps,
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