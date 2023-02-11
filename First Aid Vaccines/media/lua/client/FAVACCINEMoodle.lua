if getActivatedMods():contains("MoodleFramework") == true then
    require("MF_ISMoodle");
    MF.createMoodle("vaccine_moodle");
end

isMoodleFrameWorkEnabled = getActivatedMods():contains("MoodleFramework");

vaccine_increment_amt = 0.0001

function FAVVaccineMoodlePlayers()
    print("THIS!!")
    local players = getOnlinePlayers();

    if players
    then
        for i = 0, players:size()-1 do
            FAVVaccineMoodleFunction(players:get(i));
        end
    else
        FAVVaccineMoodleFunction(getSpecificPlayer(0))
    end
end

function FAVVaccineMoodleFunction(player)
    InitializeTable(player)

    mod_data = player:getModData()

    print("***************************")
    print(mod_data.vac_increasing)

    print(mod_data.vaccine_power)

    print(isMoodleFrameWorkEnabled)
    print("HERE")

    if isMoodleFrameWorkEnabled
    then
        if mod_data.current_vaccine_level > (mod_data.vaccine_power * 0.7)
        then
            MF.getMoodle("vaccine_moodle"):setValue(0.8);   
            if mod_data.vac_increasing == 1
                then
                    MF.getMoodle("vaccine_moodle"):setChevronIsUp(true);
                else
                    MF.getMoodle("vaccine_moodle"):setChevronIsUp(false);
                end
            

        elseif mod_data.current_vaccine_level =< 0
        then
            MF.getMoodle("vaccine_moodle"):setValue(0.2)
            MF.getMoodle("vaccine_moodle"):setChevronIsUp(false);
        else
            MF.getMoodle("vaccine_moodle"):setValue(0.5)
        end
    end

end

Events.EveryHours.Add(FAVVaccineMoodlePlayers)
