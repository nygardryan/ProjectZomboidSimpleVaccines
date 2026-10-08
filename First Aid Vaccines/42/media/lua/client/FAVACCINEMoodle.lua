-- Simple Vaccines (Build 42) - optional Moodle Framework integration + MP state sync.
require "FAVACCINEUtils"

FAVMoodle = FAVMoodle or {}
FAVMoodle.NAME = "vaccine_moodle_2"
FAVMoodle.enabled = false

local function moodleFrameworkActive()
    local mods = getActivatedMods()
    return mods:contains("MoodleFramework") or mods:contains("\\MoodleFramework")
end

if moodleFrameworkActive() then
    local ok = pcall(require, "MF_ISMoodle")
    if ok and MF and MF.createMoodle then
        MF.createMoodle(FAVMoodle.NAME)
        FAVMoodle.enabled = true
    end
end

function FAVMoodle.update(player)
    if not FAVMoodle.enabled or not player or not player:isLocalPlayer() then return end
    local moodle = MF.getMoodle(FAVMoodle.NAME, player:getPlayerNum())
    if not moodle then return end

    local md = FAVUtils.InitializeTable(player)
    if md.current_vaccine_level > (md.vaccine_power * 0.7) then
        moodle:setValue(1.0)
        moodle:setChevronIsUp(md.vac_increasing == 1)
    elseif md.current_vaccine_level > 0 and md.vac_increasing == 1 then
        moodle:setValue(0.8)
        moodle:setChevronIsUp(true)
    elseif md.current_vaccine_level > 0 then
        moodle:setValue(0.6)
        moodle:setChevronIsUp(false)
    else
        moodle:setValue(0.5)
    end
end

-- Floating text over the player: when a vaccine is taken and when it stops an infection.
function FAVMoodle.notify(player, cured, dosed)
    if not player or not player:isLocalPlayer() then return end
    if cured then
        HaloTextHelper.addGoodText(player, getText("UI_FAV_Cured"))
    elseif dosed then
        HaloTextHelper.addGoodText(player, getText("UI_FAV_Dose"))
    end
end

-- MP: the server owns vaccine state; mirror it into the local player's mod data.
local function findLocalPlayer(onlineID)
    for i = 0, getNumActivePlayers() - 1 do
        local p = getSpecificPlayer(i)
        if p and (onlineID == nil or p:getOnlineID() == onlineID) then
            return p
        end
    end
    return nil
end

local function onServerCommand(module, command, args)
    if module ~= FAVUtils.MODULE or command ~= "state" or not args then return end
    local player = findLocalPlayer(args.onlineID)
    if not player then return end

    local md = FAVUtils.InitializeTable(player)
    md.vac_increasing = args.vac_increasing
    md.vaccine_power = args.vaccine_power
    md.current_vaccine_level = args.current_vaccine_level
    md.cure_attempted = args.cure_attempted
    if args.cured then
        FAVUtils.CureInfection(player)
    end
    FAVMoodle.update(player)
    FAVMoodle.notify(player, args.cured, args.dosed)
end

Events.OnServerCommand.Add(onServerCommand)

local function onCreatePlayer(playerNum, player)
    if isClient() then
        sendClientCommand(player, FAVUtils.MODULE, "requestState", {})
    else
        FAVMoodle.update(player)
    end
end

Events.OnCreatePlayer.Add(onCreatePlayer)
