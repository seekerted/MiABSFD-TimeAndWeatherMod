local Utils = require("utils")
local Consts = require("consts")

local SkySphere = {}

local function OverrideL2EdgeMaps(SS3, TimeSegment)
	SS3['Colors determined by sun position'] = true
	
	local SunHeight = 0
	if TimeSegment == 2 then
		SunHeight = 1
	elseif TimeSegment == 4 then
		SunHeight = -1
	end

	SS3['Sun height'] = SunHeight

	SS3:RefreshMaterial()
end

local SkySphere3Overrides = {
	[Consts.MAP_NO.HEAVENS_WATERFALL] = OverrideL2EdgeMaps,
	[Consts.MAP_NO.UPDRAFT_WASTELAND] = OverrideL2EdgeMaps,
}

local SkySphere1Overrides = {
}

-- Override a BP_Sky_Sphere*_C's variables if it exists for the specific map
function SkySphere.OverrideIfExists(MapNo, TimeSegment)
	-- Some maps use BP_Sky_Sphere3_C, some BP_Sky_Sphere1_C, etc. We check which one to override.

	if SkySphere3Overrides[MapNo] ~= nil then
		local BP_Sky_Sphere3_C = FindFirstOf("BP_Sky_Sphere3_C")
		if not BP_Sky_Sphere3_C:IsValid() then
			Utils.Log("Could not apply BP_Sky_Sphere3_C override as it is not valid")
		else
			Utils.Log("Applying BP_Sky_Sphere3_C overrides for MapNo: %d", MapNo)
			SkySphere3Overrides[MapNo](BP_Sky_Sphere3_C, TimeSegment)
		end
	end

	if SkySphere1Overrides[MapNo] ~= nil then
		local BP_Sky_Sphere1_C = FindFirstOf("BP_Sky_Sphere1_C")
		if not BP_Sky_Sphere1_C:IsValid() then
			Utils.Log("Could not apply BP_Sky_Sphere1_C override as it is not valid")
		else
			Utils.Log("Applying BP_Sky_Sphere1_C overrides for MapNo: %d", MapNo)
			SkySphere1Overrides[MapNo](BP_Sky_Sphere1_C, TimeSegment)
		end
	end
end

return SkySphere