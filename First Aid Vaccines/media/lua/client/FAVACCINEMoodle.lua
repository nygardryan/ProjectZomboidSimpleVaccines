if getActivatedMods():contains("MoodleFramework") == true then
    require("MF_ISMoodle");
    MF.createMoodle("vaccine_moodle_2");
end

isMoodleFrameWorkEnabled = getActivatedMods():contains("MoodleFramework");

vaccine_increment_amt = 0.0001

function FAVVaccineMoodlePlayers()
    FAVUtils.getSingleVsOnlinePlayer(FAVVaccineMoodleFunction)
end

function FAVVaccineMoodleFunction(player)
    FAVUtils.InitializeTable(player)

    mod_data = player:getModData()

    print(mod_data.current_vaccine_level)
    print(mod_data.vaccine_power)
    print(mod_data.vac_increasing)

    if isMoodleFrameWorkEnabled
    then
        if mod_data.current_vaccine_level > (mod_data.vaccine_power * 0.7)
        then
            MF.getMoodle("vaccine_moodle_2"):setValue(1.0);   
            if mod_data.vac_increasing == 1
            then
                    MF.getMoodle("vaccine_moodle_2"):setChevronIsUp(true);
            else
                    MF.getMoodle("vaccine_moodle_2"):setChevronIsUp(false);
            end
            

        elseif mod_data.current_vaccine_level > 0 and mod_data.vac_increasing == 1
        then
            MF.getMoodle("vaccine_moodle_2"):setValue(0.8)
            MF.getMoodle("vaccine_moodle_2"):setChevronIsUp(true);
        elseif mod_data.current_vaccine_level > 0 and mod_data.vac_increasing == 0
            then
            MF.getMoodle("vaccine_moodle_2"):setValue(0.6)
            MF.getMoodle("vaccine_moodle_2"):setChevronIsUp(false);
        else
            MF.getMoodle("vaccine_moodle_2"):setValue(0.5)
        end
    end

end

Events.EveryHours.Add(FAVVaccineMoodlePlayers)
