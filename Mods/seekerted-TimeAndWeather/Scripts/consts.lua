return {
	-- Time constants
	MINS_IN_HOUR = 60,
	HOURS_IN_DAY = 24,

	-- Map stuff
	MAP_NO = {
		INVERTED_FOREST = 12,
		HELLS_CROSSING = 13,
		INVERTED_ARBOR = 14,
		SEEKER_CAMP = 15,
		EDGE_OF_THE_ABYSS = 18,

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