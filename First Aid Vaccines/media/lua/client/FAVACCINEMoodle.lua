if getActivatedMods():contains("MoodleFramework") == true then
    require("MF_ISMoodle");
    MF.createMoodle("vaccine_moodle");
end

isMoodleFrameWorkEnabled = getActivatedMods():contains("MoodleFramework");

vaccine_increment_amt = 0.0001

function FAVVaccineMoodlePlayers()
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
    -- InitializeTable(player)

    -- mod_data = player:getModData()

    print(getActivatedMods())

    if isMoodleFrameWorkEnabled
    then
        MF.getMoodle("vaccine_moodle"):setValue(0.8);
        MF.getMoodle("vaccine_moodle"):setChevronIsUp(true);
    end
    -- if mod_data.vac_increasing == 1
    -- then
    --     MF.getMoodle("vaccine_moodle"):setValue(0.8);
    --     MF.getMoodle("vaccine_moodle"):setChevronIsUp(true);
    -- elseif mod_data.current_vaccine_level > 0
    -- then
    --     MF.getMoodle("vaccine_moodle"):setValue(0.2)
    --     MF.getMoodle("vaccine_moodle"):setChevronIsUp(false);
    -- else
    --     MF.getMoodle("vaccine_moodle"):setValue(0.0)
    -- end

end

Events.EveryHours.Add(FAVVaccineMoodlePlayers)
