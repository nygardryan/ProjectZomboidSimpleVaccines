-- Simple Vaccines (Build 42) - multiplayer server side.
require "FAVACCINEUtils"

local function onClientCommand(module, command, player, args)
    if module ~= FAVUtils.MODULE then return end
    if command == "consume" and args and args.fullType then
        FAVUtils.SetVaccine(player, args.fullType)
    elseif command == "requestState" then
        FAVUtils.onStateChanged(player)
    end
end

Events.OnClientCommand.Add(onClientCommand)
