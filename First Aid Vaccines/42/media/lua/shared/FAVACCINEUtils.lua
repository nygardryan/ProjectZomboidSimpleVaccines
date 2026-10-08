-- Simple Vaccines (Build 42) - core vaccine logic.
-- Lives in shared/ so it runs in single player and on a multiplayer server.
-- In MP the server owns the vaccine state and pushes it to the client for the moodle.

FAVUtils = FAVUtils or {}

FAVUtils.MODULE = "FAVACCINE"

-- Vaccine items -> sandbox option and whether a dirty syringe is returned.
FAVUtils.VaccineTypes = {
    ["FAVACCINE.BoiledZombieCells"]      = { option = "BoiledZombieCellsEffectiveness", syringe = false },
    ["FAVACCINE.CrudeVaccine"]           = { option = "CrudeVaccineEffectiveness",      syringe = true },
    ["FAVACCINE.ZombieVaccine"]          = { option = "SimpleVaccineEffectiveness",     syringe = true },
    ["FAVACCINE.PerfectedZombieVaccine"] = { option = "PerfectVaccineEffectiveness",    syringe = true },
}

local DEFAULTS = {
    BoiledZombieCellsEffectiveness = 15,
    CrudeVaccineEffectiveness = 35,
    SimpleVaccineEffectiveness = 60,
    PerfectVaccineEffectiveness = 95,
}

-- Immunity builds over 7 days (168 h) and fades over 24 days (576 h).
local HOURS_TO_PEAK = 168
local HOURS_TO_FADE = 576

function FAVUtils.getOption(name)
    local sv = SandboxVars and SandboxVars.SimpleVaccines
    if sv and sv[name] ~= nil then
        return sv[name]
    end
    return DEFAULTS[name]
end

function FAVUtils.InitializeTable(player)
    local md = player:getModData()
    if md.vac_increasing == nil then md.vac_increasing = 0 end
    if md.vaccine_power == nil then md.vaccine_power = 0.0 end
    if md.current_vaccine_level == nil then md.current_vaccine_level = 0.0 end
    if md.cure_attempted == nil then md.cure_attempted = 0.0 end
    return md
end

function FAVUtils.addItem(player, fullType)
    local inv = player:getInventory()
    local item = inv:AddItem(fullType)
    if item and isServer() then
        sendAddItemToContainer(inv, item)
    end
    return item
end

-- Called whenever vaccine state changes: update the moodle/messages locally, or tell the client in MP.
-- cured = a dose just stopped an infection, dosed = a vaccine was just taken.
function FAVUtils.onStateChanged(player, cured, dosed)
    local md = FAVUtils.InitializeTable(player)
    if isServer() then
        sendServerCommand(player, FAVUtils.MODULE, "state", {
            onlineID = player:getOnlineID(),
            vac_increasing = md.vac_increasing,
            vaccine_power = md.vaccine_power,
            current_vaccine_level = md.current_vaccine_level,
            cure_attempted = md.cure_attempted,
            cured = cured and true or false,
            dosed = dosed and true or false,
        })
    elseif FAVMoodle and FAVMoodle.update then
        FAVMoodle.update(player)
        FAVMoodle.notify(player, cured, dosed)
    end
end

function FAVUtils.CureInfection(player)
    local bodyDamage = player:getBodyDamage()
    bodyDamage:setInfected(false)
    bodyDamage:setInfectionMortalityDuration(-1)
    bodyDamage:setInfectionTime(-1)
    bodyDamage:setInfectionLevel(0)
    local bodyParts = bodyDamage:getBodyParts()
    for i = bodyParts:size() - 1, 0, -1 do
        bodyParts:get(i):SetInfected(false)
    end
    if isServer() then
        -- push the cure to the player's client (same calls the game's own health code uses)
        for i = 0, bodyParts:size() - 1 do
            syncBodyPart(bodyParts:get(i), 0xFFFFFFFFFFF)
        end
        sendDamage(player)
    end
end

function FAVUtils.SetVaccine(player, fullType)
    if not player or not fullType then return end
    local info = FAVUtils.VaccineTypes[fullType]
    if not info then return end

    local md = FAVUtils.InitializeTable(player)

    -- Guard against the same dose being applied twice (e.g. OnEat firing on both client and server in MP).
    local now = getTimestampMs()
    if md.fav_last_dose_type == fullType and md.fav_last_dose_ms and (now - md.fav_last_dose_ms) < 2000 then
        return
    end
    md.fav_last_dose_type = fullType
    md.fav_last_dose_ms = now

    md.vaccine_power = FAVUtils.getOption(info.option)
    if info.syringe then
        FAVUtils.addItem(player, "FAVACCINE.DirtySyringe")
    end
    if md.current_vaccine_level < md.vaccine_power then
        md.vac_increasing = 1
    end
    FAVUtils.onStateChanged(player, false, true)
end

-- Hourly update for one player.
function FAVUtils.VaccineFunction(player)
    if not player or player:isDead() then return end
    local md = FAVUtils.InitializeTable(player)

    if md.vac_increasing == 1 then
        md.current_vaccine_level = md.current_vaccine_level + (md.vaccine_power / HOURS_TO_PEAK)
    elseif md.current_vaccine_level > 0 then
        md.current_vaccine_level = md.current_vaccine_level - (md.vaccine_power / HOURS_TO_FADE)
    end
    if md.current_vaccine_level < 0 then
        md.current_vaccine_level = 0
    end
    if md.current_vaccine_level > md.vaccine_power then
        md.vac_increasing = 0
    end

    -- One roll per infection: if it fails, no more rolls until the player is no longer infected.
    local cured = false
    if player:getBodyDamage():IsInfected() then
        if md.cure_attempted == 0.0 and md.current_vaccine_level > ZombRand(101) then
            FAVUtils.CureInfection(player)
            cured = true
            md.cure_attempted = 0.0
        else
            md.cure_attempted = 1.0
        end
    else
        md.cure_attempted = 0.0
    end

    FAVUtils.onStateChanged(player, cured)
end

-- Run fn for every player whose state this side owns:
-- single player -> local players, MP server -> all online players, MP client -> nobody.
function FAVUtils.forEachOwnedPlayer(fn)
    if isClient() then return end
    if isServer() then
        local players = getOnlinePlayers()
        if players then
            for i = 0, players:size() - 1 do
                fn(players:get(i))
            end
        end
    else
        for i = 0, getNumActivePlayers() - 1 do
            local player = getSpecificPlayer(i)
            if player then fn(player) end
        end
    end
end

function FAVUtils.IncrementVaccine()
    FAVUtils.forEachOwnedPlayer(FAVUtils.VaccineFunction)
end

Events.EveryHours.Add(FAVUtils.IncrementVaccine)

-- OnEat handler referenced by the vaccine item scripts.
function FAVConsumeVaccine(food, character, percent)
    if not food or not character then return end
    if isClient() then
        -- MP client: let the server apply it (it owns the state and the inventory).
        sendClientCommand(character, FAVUtils.MODULE, "consume", { fullType = food:getFullType() })
        return
    end
    FAVUtils.SetVaccine(character, food:getFullType())
end
