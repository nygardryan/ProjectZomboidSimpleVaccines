
require("TimedActions/ISBaseTimedAction")
require "XpSystem/XpUpdate"


FAVExtractTimedAction = ISBaseTimedAction:derive("FAVExtractTimedAction")

function FAVExtractTimedAction:isValid() -- Check if the action can be done
    return true;
end

function FAVExtractTimedAction:update() -- Trigger every game update when the action is perform
end

function FAVExtractTimedAction:waitToStart()
    return false;
end

function FAVExtractTimedAction:start()
    self:setActionAnim("RipSheets")
end

function FAVExtractTimedAction:stop() -- Trigger if the action is cancel
    ISBaseTimedAction.stop(self);
end

function FAVExtractTimedAction:perform()
    self.character:getXp():AddXP(Perks.Doctor, (5 + ZombRand(5)))

    if ZombRand(21) < self.character:getPerkLevel(Perks.Doctor) then
        self.character:getInventory():AddItem('FAVACC.LooseZombieCells')        
    end

    self.corpse:getSquare():removeCorpse(self.corpse, false)
    ISBaseTimedAction.perform(self)
end

function FAVExtractTimedAction:new(character, extractionTool, corpse)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.extractionTool = extractionTool
    o.corpse = corpse
    o.stopOnWalk = true;
    o.stopOnRun = true;
    o.stopOnAim = true;
    o.maxTime = 200
    if o.character:isTimedActionInstant() then o.maxTime = 1 end
    return o
end


