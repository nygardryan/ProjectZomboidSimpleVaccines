local MOD_NAME = "Simple Vaccines"
local MOD_VERSION = "2.0"
local MOD_AUTHOR = "BlueBerry Gravy"

local function info()
    print("MOD Loaded: " .. MOD_NAME .. " by " .. MOD_AUTHOR .. " (v" .. MOD_VERSION .. ", Build 42)")
end

Events.OnGameBoot.Add(info)
