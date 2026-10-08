local MOD_ID = "FAVACCINE";
local MOD_NAME = "Improved First Aid + Vaccines";
local MOD_VERSION = '1.0';
local MOD_AUTHOR = "BlueBerry Gravy";
local MOD_DESCRIPTION = "Adds easier ways to level first aid skill and craftable vaccines to help prevent zombie infections"


local function info()
	print("MOD Loaded: " .. MOD_NAME .. " by " .. MOD_AUTHOR .. " (v" .. MOD_VERSION .. ")");
end


Events.OnGameBoot.Add(info);
