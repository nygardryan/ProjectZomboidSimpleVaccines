local MOD_ID = "FAVACCINE";
local MOD_NAME = "Improved First Aid + Vaccines";
local MOD_VERSION = '1.0';
local MOD_AUTHOR = "BlueBerry Gravy";
local MOD_DESCRIPTION = "Adds easier ways to level first aid skill and craftable vaccines to help prevent zombie infections"
local debugItems = TRUE;


local function info()
	print("MOD Loaded: " .. MOD_NAME .. " by " .. MOD_AUTHOR .. " (v" .. MOD_VERSION .. ")");
end

local function giveItems()
	if debugItems then
	    print("DEBUGGING VACCINES")
		local player = getSpecificPlayer(0);
		player:getBodyDamage():setInfectionLevel(0.0);
		player:getInventory():AddItem("FAVACC.ConcentratedZombieCells");
	end
end

Events.OnGameBoot.Add(info);
Events.OnGameStart.Add(giveItems);
