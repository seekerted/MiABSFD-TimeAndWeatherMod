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

local function OverrideL4Forests(SS3, TimeSegment)
	local Tint = {
		{R = 0.25, G = 0.15, B = 0.1, A = 1},
		{R = 0.5, G = 0.5, B = 0.5, A = 1},
		{R = 0.25, G = 0.1, B = 0.05, A = 1},
		{R = 0, G = 0, B = 0, A = 1},
	}

	SS3['Cloud color'] = {R = 1, G = 1, B = 1, A = 1}

	SS3['Overall color'] = Tint[TimeSegment]
	SS3:RefreshMaterial()
end

local SkySphere3Overrides = {
	-- Layer 2
	[Consts.MAP_NO.HEAVENS_WATERFALL] = OverrideL2EdgeMaps,
	[Consts.MAP_NO.UPDRAFT_WASTELAND] = OverrideL2EdgeMaps,

	-- Layer 4
	[Consts.MAP_NO.HIDDEN_HOT_SPRING] = OverrideL4Forests,
	[Consts.MAP_NO.ETERNAL_FORTUNES] = OverrideL4Forests,
	[Consts.MAP_NO.DEEP_TREE_REMAINS] = OverrideL4Forests,
}

local function OverrideL3EdgeMaps(SS1, TimeSegment)
	if TimeSegment == 4 then
		SS1['Overall color'] = {R = 0, G = 0, B = 0, A = 1}
	else
		SS1['Overall color'] = {R = 1, G = 1, B = 1, A = 1}
	end

	SS1:RefreshMaterial()
end

local function ManualSkySphere(SS1, TimeSegment)
	local Tint = {
		{R = 0.50, G = 0.48, B = 0.45, A = 1},
		{R = 1, G = 1, B = 1, A = 1},
		{R = 0.8, G = 0.5, B = 0.2, A = 1},
		{R = 0, G = 0, B = 0, A = 1},
	}

	SS1['Overall color'] = Tint[TimeSegment]

	SS1:RefreshMaterial()
end

local function WaterCrystalsOverride(SS1, TimeSegment)
	SS1['Cloud color'] = {R = 1, G = 1, B = 1, A = 1},

	ManualSkySphere(SS1, TimeSegment)
end

local function OverrideSandyIceAreas(SS1, TimeSegment)
	local Tint = {
		{R = 0.6, G = 0.2, B = 0.1, A = 1},
		{R = 1, G = 1, B = 1, A = 1},
		{R = 0.8, G = 0.5, B = 0.2, A = 1},
		{R = 0, G = 0, B = 0, A = 1},
	}

	SS1['Colors determined by sun position'] = false
	SS1['Overall color'] = Tint[TimeSegment]

	SS1:RefreshMaterial()
end

local SkySphere1Overrides = {
	-- Layer 3
	[Consts.MAP_NO.THE_GREAT_FAULT] = OverrideL3EdgeMaps,
	[Consts.MAP_NO.TRAPPED_PIRATE_SHIP] = OverrideL3EdgeMaps,
	[Consts.MAP_NO.QUADRUPLE_PIT] = OverrideL3EdgeMaps,
	[Consts.MAP_NO.ROCK_SLIDE_HALL] = OverrideL3EdgeMaps,

	-- Layer 4
	[Consts.MAP_NO.GOBLETS_OF_GIANTS] = ManualSkySphere,
	[Consts.MAP_NO.GIANT_VINE_BRIDGE] = ManualSkySphere,

	-- Layer 5
	[Consts.MAP_NO.SANDY_ICE_AREA_1] = OverrideSandyIceAreas,
	[Consts.MAP_NO.SANDY_ICE_AREA_2] = OverrideSandyIceAreas,
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