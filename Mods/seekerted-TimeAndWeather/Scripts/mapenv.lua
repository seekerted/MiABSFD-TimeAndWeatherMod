local Utils = require("utils")
local Consts = require("consts")

local MapEnv = {}

-- L2, M12 Inverted Forest
local function OverrideMapEnv12(ME)
	-- Remove the harsh red tint on L2's morning
	ME.EnvParamsMorning.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6.R = 0.226493
	ME.EnvParamsMorning.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6.B = 0.186512
end

-- L2, M13 Hell's Crossing
local function OverrideMapEnv13(ME)
	-- Remove the harsh red tint on L2's morning
	ME.EnvParamsMorning.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6.R = 0.226493
	ME.EnvParamsMorning.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6.B = 0.186512
end

-- L2, M14 Inverted Arbor
local function OverrideMapEnv14(ME)
	-- Remove the harsh red tint on L2's morning
	ME.EnvParamsMorning.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6.R = 0.226493
	ME.EnvParamsMorning.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6.B = 0.186512
end

-- L2, M15 Seeker Camp
local function OverrideMapEnv15(ME)
	-- Remove the harsh red tint on L2's morning
	ME.EnvParamsMorning.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6.R = 0.226493
	ME.EnvParamsMorning.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6.B = 0.186512
end

local MapEnvOverrides = {
	[Consts.MAP_NO.INVERTED_FOREST] = OverrideMapEnv12,
	[Consts.MAP_NO.HELLS_CROSSING] = OverrideMapEnv13,
	[Consts.MAP_NO.INVERTED_ARBOR] = OverrideMapEnv14,
	[Consts.MAP_NO.SEEKER_CAMP] = OverrideMapEnv15,
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