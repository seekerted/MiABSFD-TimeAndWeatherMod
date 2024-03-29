local Utils = require("utils")
local Consts = require("consts")

local Weather = {}

local IsInstantTransition = true

-- Actually apply the weather change depending on the weather type
local function SetAbyssWeather(WeatherType)
	local BP_TPSCamera_C = FindFirstOf("BP_TPSCamera_C")
	if not BP_TPSCamera_C:IsValid() then
		Utils.Log("BP_TPSCamera_C is not valid.")
		return
	end

	local TransitionTime = 0
	if not IsInstantTransition then
		TransitionTime = Consts.WEATHER_TRANSITION_TIME
	end

	BP_TPSCamera_C:WeatherTypeToEmitterIndex(WeatherType, {})
	BP_TPSCamera_C:FadeOutWeatherEmitter(WeatherType, TransitionTime)
	BP_TPSCamera_C:CreateWeatherEmitter(WeatherType, TransitionTime)
	BP_TPSCamera_C.WindDirection = {Pitch = 180, Yaw = 0, Roll = 180}

	local BP_MapEnvironment_C = FindFirstOf("BP_MapEnvironment_C")
	if not BP_MapEnvironment_C:IsValid() then
		Utils.Log("BP_MapEnvironment_C is not valid.")
	else
		BP_MapEnvironment_C:TransitionWeatherEnvironment(WeatherType, TransitionTime)
		BP_MapEnvironment_C:UpdateMapEnvironment()
	end

	Utils.Log("Changed weather to type %d", WeatherType)
end

-- Calculate the probability of bad weather via a sine curve. It is bad weather if the y value is above a certain
-- theshold, which is dependent on the player's whistle rank (the higher the rank, the lower the threshold, meaning
-- more chances of bad weather)
local function IsBadWeather(PlayTime, WhistleRank)
	local BadWeatherProbability = math.sin(PlayTime * math.pi / 200)
	local BadWeatherThreshold = 1.3 - (WhistleRank / 5)

	return BadWeatherProbability >= BadWeatherThreshold
end

local function GetRainType(PlayTime)
	local RainY = math.sin(PlayTime * math.pi * 13 / 4000)

	if RainY >= 0.5 then
		return Consts.WEATHER.RAIN
	elseif RainY <= -0.5 then
		return Consts.WEATHER.THUNDER
	else
		return Consts.WEATHER.HEAVY_RAIN
	end
end

local function GetOneFourthChance(PlayTime)
	return math.sin(PlayTime * math.pi * 17 / 4000) > 0.5
end

-- For Layer 1:
-- Good weather is 75% none, 25% petals
-- Bad weather is equal distribution of rain, heavy rain, and thunder
local function SetL1Weather(IsBadWeather, PlayTime)
	if IsBadWeather then
		local BadWeatherType = GetRainType(PlayTime)
		SetAbyssWeather(BadWeatherType)
	else
		local IsPetalWeather = GetOneFourthChance(PlayTime)

		if IsPetalWeather then
			SetAbyssWeather(Consts.WEATHER.PETALS)
		else
			SetAbyssWeather(Consts.WEATHER.NONE)
		end
	end
end

-- For Layer 2 Forest of Temptation, Corpse-Weeper Den
-- Good weather is none
-- Bad weather is equal distribution of rain, heavy rain, and thunder
local function SetL2Weather(IsBadWeather, PlayTime)
	if IsBadWeather then
		local BadWeatherType = GetRainType(PlayTime)
		SetAbyssWeather(BadWeatherType)
	else
		SetAbyssWeather(Consts.WEATHER.NONE)
	end
end

-- For Layer 2 Edge of the Abyss
-- Good weather is none
-- Bad weather is ice
local function SetEdgeOfTheAbyssWeather(IsBadWeather, PlayTime)
	if IsBadWeather then
		SetAbyssWeather(Consts.WEATHER.ICE)
	else
		SetAbyssWeather(Consts.WEATHER.NONE)
	end
end

-- For Layer 4 Goblet of Giants, Floating Rocks, Crystal Valley
-- Good weather is none
-- Bad weather is ice
local function SetL4InteriorsWeather(IsBadWeather)
	if IsBadWeather then
		SetAbyssWeather(Consts.WEATHER.ICE)
	else
		SetAbyssWeather(Consts.WEATHER.NONE)
	end
end

-- For Layer 4 Hidden Hot Spring, Giant Vine Bridge, Eternal Fortunes
-- Good weather is none
-- Bad weather is equal distribution of rain, heavy rain, and thunder
local function SetL4OutdoorsWeather(IsBadWeather, PlayTime)
	if IsBadWeather then
		local BadWeatherType = GetRainType(PlayTime)
		SetAbyssWeather(BadWeatherType)
	else
		SetAbyssWeather(Consts.WEATHER.NONE)
	end
end

-- For Layer 5 (except Water Crystals 1 and 2 no weather, and Eternal Garden, which is just 75% ice, 25% none; also
-- except Ido Front, Ido Front Area, where they cannot have bad weather because it gets too dark and I can't change it)
-- Good weather is 25% none, 25% ice, 50% snow
-- Bad weather is equal distribution of rain, heavy rain, and thunder
local function SetL5Weather(IsBadWeather, PlayMapNo, PlayTime)
	if PlayMapNo == Consts.MAP_NO.ETERNAL_GARDEN then
		if GetOneFourthChance(PlayTime) then
			SetAbyssWeather(Consts.WEATHER.NONE)
		else
			SetAbyssWeather(Consts.WEATHER.ICE)
		end

		return
	end

	local IsIdoFrontMap = PlayMapNo == Consts.MAP_NO.IDOFRONT or PlayMapNo == Consts.MAP_NO.IDOFRONT_AREA

	if IsBadWeather and not IsIdoFrontMap then
		local BadWeatherType = GetRainType(PlayTime)
		SetAbyssWeather(BadWeatherType)
	else
		local GoodWeatherType = GetOneFourthChance(PlayTime)

		if GoodWeatherType == 1 then
			SetAbyssWeather(Consts.WEATHER.NONE)
		elseif GoodWeatherType == 2 then
			SetAbyssWeather(Consts.WEATHER.ICE)
		else
			SetAbyssWeather(Consts.WEATHER.SNOW)
		end
	end
end

-- Change the weather depending on the PlayTime and the map the player is in
function Weather.SetWeather(PlayTime, PlayMapNo, WhistleRank, IsInstant)
	local IsBadWeather = IsBadWeather(PlayTime, WhistleRank)
	IsInstantTransition = IsInstant

	if Consts.MAP_NO.NETHERWORLD_GATE <= PlayMapNo and PlayMapNo <= Consts.MAP_NO.MULTILAYER_HILL then
		SetL1Weather(IsBadWeather, PlayTime)
		return
	end

	if PlayMapNo == Consts.MAP_NO.FOREST_OF_TEMPTATION or PlayMapNo == Consts.MAP_NO.CORPSE_WEEPER_DEN then
		SetL2Weather(IsBadWeather, PlayTime)
		return
	end

	if PlayMapNo == Consts.MAP_NO.EDGE_OF_THE_ABYSS then
		SetEdgeOfTheAbyssWeather(IsBadWeather, PlayTime)
		return
	end

	if PlayMapNo == Consts.MAP_NO.GOBLETS_OF_GIANTS or PlayMapNo == Consts.MAP_NO.FLOATING_ROCKS or
			PlayMapNo == Consts.MAP_NO.CRYSTAL_VALLEY then
		SetL4InteriorsWeather(IsBadWeather)
		return
	end

	if PlayMapNo == Consts.MAP_NO.HIDDEN_HOT_SPRING or PlayMapNo == Consts.MAP_NO.GIANT_VINE_BRIDGE or
			PlayMapNo == Consts.MAP_NO.ETERNAL_FORTUNES then
		SetL4OutdoorsWeather(IsBadWeather, PlayTime)
		return
	end

	if Consts.MAP_NO.SEA_OF_CORPSES_1 <= PlayMapNo and PlayMapNo <= Consts.MAP_NO.IDOFRONT then
		if PlayMapNo ~= Consts.MAP_NO.WATER_CRYSTALS_1 and PlayMapNo ~= Consts.MAP_NO.WATER_CRYSTALS_2 then
			SetL5Weather(IsBadWeather, PlayMapNo, PlayTime)
			return
		end
	end

	SetAbyssWeather(Consts.WEATHER.NONE)
end

-- Some maps have weather volumes that when the player steps inside them changes the weather. This disables all of them
function Weather.OverrideWeatherVolumes()
	local MIAWeatherVolumes = FindAllOf("MIAWeatherVolume")
	if not MIAWeatherVolumes then
		Utils.Log("No instances of MIAWeatherVolume were found")
		return
	end

	for _, MIAWeatherVolume in pairs(MIAWeatherVolumes) do
		MIAWeatherVolume:K2_DestroyActor()
	end

	Utils.Log("Overrode weather volumes in map")
end

return Weather