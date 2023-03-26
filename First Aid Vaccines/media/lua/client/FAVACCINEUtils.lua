--require "XpSystem/XpUpdate"

FAVUtils = {}
local syringeVaccines = {"KitchenKnife", "HuntingKnife", "Scalpel", "FlintKnife"}

vaccine_increment_amt = 0.0001



function FAVUtils.VaccineFunction(player)

    FAVUtils.InitializeTable(player)
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


    local bodyDamage = player:getBodyDamage();
    if bodyDamage:IsInfected()
    then
        local random_number = ZombRand(101)

        -- if (mod_data.current_vaccine_level)/72 > 0
        if (mod_data.current_vaccine_level) > random_number and mod_data.cure_attempted == 0.0
        then
            
            bodyDamage:setInfected(false);
            bodyDamage:setInfectionMortalityDuration(-1);
            bodyDamage:setInfectionTime(-1);
            bodyDamage:setInfectionLevel(0);
            local bodyParts = bodyDamage:getBodyParts();
            for i=bodyParts:size()-1, 0, -1  do
                local bodyPart = bodyParts:get(i);
                bodyPart:SetInfected(false);
            end
            bodyDamage:setInfected(false);
            bodyDamage:setInfectionLevel(0);
            mod_data.cure_attempted = 0.0
        else
            mod_data.cure_attempted = 1.0
        end
    else
        mod_data.cure_attempted = 0.0
    end

end

function FAVUtils.getSingleVsOnlinePlayer(func)
    local players = getOnlinePlayers();

    if players
    then
        for i = 0, players:size()-1 do
            func(players:get(i));
        end
    else
        return func(getSpecificPlayer(0))
    end
end


function FAVUtils.IncrementVaccine()
    FAVUtils.getSingleVsOnlinePlayer(FAVUtils.VaccineFunction)
end

function SetVaccine(player, items)
    FAVUtils.InitializeTable(player)

    mod_data = player:getModData()


    if items:getName() == 'Boiled Zombie Cells'
    then
        mod_data.vaccine_power = 15
    end

    if items:getName() == 'Crude Zombie Vaccine'
    then
        mod_data.vaccine_power = 35
        player:getInventory():AddItem('FAVACCINE.DirtySyringe')
    end

    if items:getName() == 'Simple Zombie Vaccine'
    then
        mod_data.vaccine_power = 60
        player:getInventory():AddItem('FAVACCINE.DirtySyringe')
    end

    if items:getName() == 'Perfect Zombie Vaccine'
    then
        mod_data.vaccine_power = 95
        player:getInventory():AddItem('FAVACCINE.DirtySyringe')
    end

    if mod_data.current_vaccine_level < mod_data.vaccine_power
    then

        mod_data.vac_increasing = 1
    end
    if isMoodleFrameWorkEnabled
        then
        FAVVaccineMoodleFunction(player)
    end
end


--player:getBodyDamage():setInfected(false)
--player:getBodyDamage():setInfectionLevel(0.0)
--print(player:getBodyDamage():IsInfected())
--print(player:getBodyDamage():getInfectionLevel())

function FAVUtils.InitializeTable(player)
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

    if not mod_data.cure_attempted
        then
        mod_data.cure_attempted = 0.0
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

Events.EveryHours.Add(FAVUtils.IncrementVaccine)


--EveryHours and EveryDays
--https://pzwiki.net/wiki/Modding:Lua_Events
-- Special Thanks to albion