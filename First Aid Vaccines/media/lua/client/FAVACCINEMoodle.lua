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

    print("***************************")
    print(mod_data.vac_increasing)
    print(mod_data.current_vaccine_level)
    print(mod_data.vaccine_power)

    print(isMoodleFrameWorkEnabled)
    print("HERE")
    print("******************************")

    if isMoodleFrameWorkEnabled
    then
        if mod_data.current_vaccine_level > (mod_data.vaccine_power * 0.7)
        then
            MF.getMoodle("vaccine_moodle_2"):setValue(0.6);   
            if mod_data.vac_increasing == 1
            then
                    MF.getMoodle("vaccine_moodle_2"):setChevronIsUp(true);
            else
                    MF.getMoodle("vaccine_moodle_2"):setChevronIsUp(false);
            end
            

        elseif mod_data.current_vaccine_level <= 0
        then
            MF.getMoodle("vaccine_moodle_2"):setValue(0.4)
            MF.getMoodle("vaccine_moodle_2"):setChevronIsUp(false);
        else
            MF.getMoodle("vaccine_moodle_2"):setValue(0.5)
        end
    end

end

Events.EveryHours.Add(FAVVaccineMoodlePlayers)
