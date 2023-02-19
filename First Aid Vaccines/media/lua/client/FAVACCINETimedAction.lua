
require("TimedActions/ISBaseTimedAction")
require ("XpSystem/XpUpdate")

local Utils = {}


local extractionTools = {"KitchenKnife", "HuntingKnife", "Scalpel", "FlintKnife"}
local properExtractionTools = {"Scalpel", nil}

function Utils.has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function Utils.IsExtractionTool(item)
    return Utils.has_value(extractionTools, item:getType())
end

function Utils.IsProperTool(item)
    return Utils.has_value(properExtractionTools, item:getType())
end

function Utils.DamageTool(item, player)
    if not Utils.IsProperTool(item) then
        item:setCondition(item:getCondition() - 0.001);
    end
end




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
    self.character:getXp():AddXP(Perks.Doctor, (2 + ZombRand(4)))

    if ZombRand(25) < self.character:getPerkLevel(Perks.Doctor) + 5 then
        self.character:getInventory():AddItem('FAVACCINE.LooseZombieCells')        
    end

    if not Utils.IsProperTool(self.extractionTool) then
        if self.character:getPerkLevel(Perks.Maintenance)/2 + 94 < ZombRand(100) then
            Utils.DamageTool(self.extractionTool, self.character)
        end
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


