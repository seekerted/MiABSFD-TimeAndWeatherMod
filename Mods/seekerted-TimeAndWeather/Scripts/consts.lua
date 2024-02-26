return {
	-- Time constants
	MINS_IN_HOUR = 60,
	HOURS_IN_DAY = 24,

	-- Map stuff
	MAP_NO = {
		-- Layer 1
		NETHERWORLD_GATE = 1,
		TREE_FOSSIL_ABODE = 2,
		GRAND_BRIDGE_WAY = 3,
		WATERFALL_GONDOLA = 4,
		TWIN_FALLS = 5,
		WIND_RIDING_WINDMILL = 6,
		STONE_ARK = 7,
		JUMPING_ROCK = 8,
		MULTILAYER_HILL = 9,

		-- Layer 2
		FOREST_OF_TEMPTATION = 10,
		CORPSE_WEEPER_DEN = 11,
		INVERTED_FOREST = 12,
		HELLS_CROSSING = 13,
		INVERTED_ARBOR = 14,
		SEEKER_CAMP = 15,
		SEEKER_CAMP_INTERIOR = 16,
		HEAVENS_WATERFALL = 19,
		UPDRAFT_WASTELAND = 20,

		-- Layer 3
		THE_GREAT_FAULT = 21,
		TRAPPED_PIRATE_SHIP = 22,
		QUADRUPLE_PIT = 25,
		ROCK_SLIDE_HALL = 28,

		-- Layer 4
		GOBLETS_OF_GIANTS = 30,
		GIANT_VINE_BRIDGE = 33,
		ETERNAL_FORTUNES = 37,
		DEEP_TREE_REMAINS = 38,

		-- Layer 5
		SEA_OF_CORPSES_1 = 39,
		SEA_OF_CORPSES_2 = 40,
		HAIL_JAIL = 41,
		SANDY_ICE_AREA_1 = 46,
		SANDY_ICE_AREA_2 = 47,

		-- Surface
		ORTH = 60,
		BELCHERO = 80,
	},
	ORTH_SUB_LOCATIONS = {
		RELIC_APPRAISAL = 3,
	},

	-- RGBA colors for the Orth visuals. Taken from Netherworld Gate's sunlight colors.
	ORTH_TIME_SEGMENT = {
		{R = 0.85, G = 0.8, B = 0.7, A = 1},
		{R = 1, G = 1, B = 1, A = 1},
		{R = 0.8, G = 0.5, B = 0.2, A = 1},
		{R = 0.05, G = 0.1, B = 0.25, A = 1},
	},

	-- RGBA colors for the Seeker Camp Interior visuals.
	SEEKER_CAMP_INTERIOR_TIME_SEGMENT = {
		{R = 0.42, G = 0.41, B = 0.23, A = 1},
		{R = 1, G = 1, B = 1, A = 1},
		{R = 0.5, G = 0.3, B = 0.28, A = 1},
		{R = 0.31, G = 0.32, B = 0.40, A = 1},
	},

	-- The times when each time segment will start
	TIME_SEGMENT_BEGIN = {
		MorningBegin = 400,
		DaytimeBegin = 600,
		EveningBegin = 1800,
		NightBegin = 2000,
	},
}