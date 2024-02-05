local Utils = require("utils")
local Consts = require("consts")

local MapEnv = {}

local function OverrideMapEnv12(ME)
	ME.EnvParamsMorning.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6.R = 0.226493
	ME.EnvParamsMorning.SunLightColor_10_DEFB79DF4935B10FC66149A8CCBB15C6.B = 0.5
end

local MapEnvOverrides = {
	[Consts.MAP_NO.INVERTED_FOREST] = OverrideMapEnv12,
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