--require "XpSystem/XpUpdate"



vaccine_increment_amt = 0.0001

function VaccineFunction(player)

    InitializeTable(player)
    mod_data = player:getModData()

    if mod_data.vac_increasing == 1
    then
        mod_data.current_vaccine_level = mod_data.current_vaccine_level + vaccine_increment_amt
    elseif (mod_data.current_vaccine_level > 0)
    then
        mod_data.current_vaccine_level = mod_data.current_vaccine_level - vaccine_increment_amt
    end

    if mod_data.current_vaccine_level > mod_data.vaccine_power
    then
        mod_data.vac_increasing = 0
    end

    print("Player Infected")
    print(player:getBodyDamage():IsInfected())

    if player:getBodyDamage():IsInfected()
    then
        local random_number = ZombRand(101)

        if mod_data.current_vaccine_level > random_number
        then
            print("Healing Infection")
            player:getBodyDamage():setInfected(false)
            player:getBodyDamage():setInfectionLevel(0.0)
        end
    end
    print('VaccineManager.increasing')
    print(mod_data.vac_increasing)
    print('VaccineManager.current_vaccine_level')
    print(mod_data.current_vaccine_level)
    print("VaccinePower.vaccine_power")
    print(mod_data.vaccine_power)

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

    if items:getName() == 'Concentrated Zombie Cells'
    then
        print('Vaccine Power set to 5')
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
    player:getXp():AddXP(Perks.Doctor, 4)
end

function PrintStuff()
    print("------ CONNECTED MESSAGE -----")
end


function PrintAllFunctions()
    for n in pairs(_G) do print(n) end
end
--Events.EveryHours.Add(IncrementVaccine())


--Events.EveryOneMinute.Add(IncrementVaccine)

Events.OnLoad.Add(PrintStuff)

Events.EveryTenMinutes.Add(IncrementVaccine)

--EveryHours and EveryDays
--https://pzwiki.net/wiki/Modding:Lua_Events
-- Special Thanks to albion