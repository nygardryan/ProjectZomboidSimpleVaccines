--require "XpSystem/XpUpdate"


vaccine_increment_amt = 0.0001

function VaccineFunction(player)

    InitializeTable(player)
    mod_data = player:getModData()

    if mod_data.vac_increasing == 1
    then
        mod_data.current_vaccine_level = mod_data.current_vaccine_level + (mod_data.vaccine_power/168)
    elseif mod_data.current_vaccine_level > 0
    then
        mod_data.current_vaccine_level = mod_data.current_vaccine_level - (mod_data.vaccine_power/900)
    else
        mod_data.current_vaccine_level = 0
    end

    if mod_data.current_vaccine_level > mod_data.vaccine_power
    then
        mod_data.vac_increasing = 0
    end

    -- print("Player Infected")
    -- print(player:getBodyDamage():IsInfected())
    -- print(mod_data.current_vaccine_level)

    if player:getBodyDamage():IsInfected()
    then
        local random_number = ZombRand(101)

        if (mod_data.current_vaccine_level)/72 > random_number
        then
            player:Say(getText("UI_FAV_Cured"))
            player:getBodyDamage():setInfected(false)
            player:getBodyDamage():setInfectionLevel(0.0)
        end
    end

end

local function getSingleVsOnlinePlayer()
    local players = getOnlinePlayers();

    if players
    then
        for i = 0, players:size()-1 do
            players:get(i);
        end
    else
        return getSpecificPlayer(0)
    end
end


function IncrementVaccine()

    local players = getOnlinePlayers();

    if players
    then
        for i = 0, players:size()-1 do
            VaccineFunction(players:get(i));
        end
    else
        VaccineFunction(getSpecificPlayer(0))
    end
end

function SetVaccine(player, items)
    InitializeTable(player)

    mod_data = player:getModData()


    if items:getName() == 'Boiled Zombie Cells'
    then
        print('Vaccine Power set to 12')
        mod_data.vaccine_power = 12
    end

    if items:getName() == 'Crude Vaccine'
    then
        print('Vaccine Power set to 25')
        mod_data.vaccine_power = 25
    end

    if items:getName() == 'Zombie Vaccine'
    then
        print('Vaccine Power set to 50')
        mod_data.vaccine_power = 50
    end

    if items:getName() == 'Perfect Zombie Vaccine'
    then
        print('Vaccine Power set to 100')
        mod_data.vaccine_power = 100
    end

    if mod_data.current_vaccine_level < mod_data.vaccine_power
    then
        mod_data.vac_increasing = 1
    end
    --player:setModData(mod_data)
end


--player:getBodyDamage():setInfected(false)
--player:getBodyDamage():setInfectionLevel(0.0)
--print(player:getBodyDamage():IsInfected())
--print(player:getBodyDamage():getInfectionLevel())

function InitializeTable(player)
    mod_data = player:getModData()

    if not mod_data.vac_increasing
        then
        mod_data.vac_increasing = 0
    end

    if not mod_data.vaccine_power
        then
        mod_data.vaccine_power = 0.0
    end

    if not mod_data.current_vaccine_level
        then
        mod_data.current_vaccine_level = 0.0
    end
end

function ConsumeVaccine(items, player, result)
    SetVaccine(player, items)
end

function FavGiveXP(item, recipe, player)
    player:getXp():AddXP(Perks.Doctor, 12)
end

function PrintStuff()
    print("------ CONNECTED MESSAGE -----")
end


function PrintAllFunctions()
    for n in pairs(_G) do print(n) end
end
--Events.EveryHours.Add(IncrementVaccine())


--Events.EveryOneMinute.Add(IncrementVaccine)

Events.EveryHours.Add(IncrementVaccine)


--EveryHours and EveryDays
--https://pzwiki.net/wiki/Modding:Lua_Events
-- Special Thanks to albion