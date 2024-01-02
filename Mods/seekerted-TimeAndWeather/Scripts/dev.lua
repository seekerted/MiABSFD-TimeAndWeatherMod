local Utils = require("utils")

-- /Script/MadeInAbyss.MIAGameInstance:SetAbyssTime(const int32 Hour, const int32 Minute);
Utils.RegisterCommand("sat", function(FullCommand, Parameters, Log)
	local GI = FindFirstOf("MIAGameInstance")
	if not GI:IsValid() then
		Log("MIAGameInstance is not valid.")
		return false
	end

	GI.SetAbyssTime(Parameters[1], Parameters[2])

	return true
end)

-- /Script/MadeInAbyss.MIAGameInstance:AddAbyssTime(const int32 Hour, const int32 Minute);
Utils.RegisterCommand("aat", function(FullCommand, Parameters, Log)
	local GI = FindFirstOf("MIAGameInstance")
	if not GI:IsValid() then
		Log("MIAGameInstance is not valid.")
		return false
	end

	GI.AddAbyssTime(Parameters[1], Parameters[2])

	return true
end)