-- Simple Vaccines (Build 42) - inject a vaccine into the upper arm (custom "FAVInject" animation).
-- complete() runs in single player and on the server in multiplayer.
require "TimedActions/ISBaseTimedAction"
require "FAVACCINEUtils"

FAVInjectAction = ISBaseTimedAction:derive("FAVInjectAction")

function FAVInjectAction:isValid()
    if isClient() and self.item then
        return self.character:getInventory():containsID(self.item:getID())
    end
    return self.character:getInventory():contains(self.item)
end

function FAVInjectAction:update()
    self.item:setJobDelta(self:getJobDelta())
end

function FAVInjectAction:start()
    if isClient() and self.item then
        self.item = self.character:getInventory():getItemById(self.item:getID())
    end
    self.item:setJobType(getText("UI_FAV_Inject"))
    self.item:setJobDelta(0.0)
    self:setActionAnim("FAVInject")
    -- syringe in the right hand (Bip01_Prop1)
    self:setOverrideHandModels(self.item, nil)
end

function FAVInjectAction:stop()
    self.item:setJobDelta(0.0)
    ISBaseTimedAction.stop(self)
end

function FAVInjectAction:perform()
    self.item:setJobDelta(0.0)
    if self.item:getContainer() then
        self.item:getContainer():setDrawDirty(true)
    end
    ISBaseTimedAction.perform(self)
end

function FAVInjectAction:complete()
    local inv = self.character:getInventory()
    local item = self.item
    if isServer() and item then
        item = inv:getItemById(item:getID()) or item
    end
    if not item or not inv:contains(item) then
        return false
    end
    local fullType = item:getFullType()
    inv:Remove(item)
    sendRemoveItemFromContainer(inv, item)
    FAVUtils.SetVaccine(self.character, fullType)
    return true
end

function FAVInjectAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 150      -- matches the 3 s Bob_FAV_Inject clip
end

function FAVInjectAction:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    o.item = item
    o.stopOnWalk = false
    o.stopOnRun = true
    o.stopOnAim = true
    o.maxTime = o:getDuration()
    return o
end
