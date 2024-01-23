return {
	-- Time constants
	MINS_IN_HOUR = 60,
	HOURS_IN_DAY = 24,

	-- Map stuff
	MAP_NO = {
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

	-- The times when each time segment will start
	TIME_SEGMENT_BEGIN = {
		MorningBegin = 400,
		DaytimeBegin = 600,
		EveningBegin = 1800,
		NightBegin = 2000,
	},
}