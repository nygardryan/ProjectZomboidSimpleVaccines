-- Simple Vaccines (Build 42) - "Attempt to Extract DNA" timed action.
-- Build 42 timed actions live in shared/ and do their real work in complete(),
-- which runs in single player and on the server in multiplayer.
require "TimedActions/ISBaseTimedAction"
require "FAVACCINEUtils"

FAVExtractTimedAction = ISBaseTimedAction:derive("FAVExtractTimedAction")

FAVExtractTimedAction.properTools = { Scalpel = true }

-- One DNA extraction per corpse: the corpse is kept and marked in its mod data.
function FAVExtractTimedAction.isSampled(corpse)
    return corpse ~= nil and corpse:getModData().FAVSampled == true
end

function FAVExtractTimedAction.isProperTool(item)
    return item ~= nil and FAVExtractTimedAction.properTools[item:getType()] == true
end

function FAVExtractTimedAction:isValid()
    return self.corpse ~= nil
        and self.corpse:getSquare() ~= nil
        and not FAVExtractTimedAction.isSampled(self.corpse)
        and self.extractionTool ~= nil
        and self.character:getInventory():containsRecursive(self.extractionTool)
end

function FAVExtractTimedAction:waitToStart()
    self.character:faceThisObject(self.corpse)
    return self.character:shouldBeTurning()
end

function FAVExtractTimedAction:update()
    self.character:faceThisObject(self.corpse)
end

function FAVExtractTimedAction:start()
    -- custom kneeling dissection clip (Bob_FAV_ExtractDNA) with the knife/scalpel in the right hand
    self:setActionAnim("FAVExtractDNA")
    self:setOverrideHandModels(self.extractionTool, nil)
end

function FAVExtractTimedAction:stop()
    ISBaseTimedAction.stop(self)
end

function FAVExtractTimedAction:perform()
    ISBaseTimedAction.perform(self)
end

function FAVExtractTimedAction:complete()
    local square = self.corpse and self.corpse:getSquare()
    if not square then return false end

    local character = self.character
    addXp(character, Perks.Doctor, 2 + ZombRand(5))

    if ZombRand(25) < character:getPerkLevel(Perks.Doctor) + 5 then
        FAVUtils.addItem(character, "FAVACCINE.LooseZombieCells")
    end

    -- Non-scalpel tools occasionally lose condition (less often with Maintenance skill).
    local tool = self.extractionTool
    if tool and not FAVExtractTimedAction.isProperTool(tool) then
        if character:getPerkLevel(Perks.Maintenance) / 2 + 94 < ZombRand(100) then
            tool:setCondition(math.max(0, tool:getCondition() - 1))
            if instanceof(tool, "HandWeapon") then
                syncHandWeaponFields(character, tool)
            else
                syncItemFields(character, tool)
            end
        end
    end

    -- keep the body, but mark it so nobody can sample it again (synced to all clients in MP)
    self.corpse:getModData().FAVSampled = true
    if isServer() then
        self.corpse:transmitModData()
    end
    return true
end

function FAVExtractTimedAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 256      -- two loops of the 2.67 s Bob_FAV_ExtractDNA clip
end

function FAVExtractTimedAction:new(character, extractionTool, corpse)
    local o = ISBaseTimedAction.new(self, character)
    o.extractionTool = extractionTool
    o.corpse = corpse
    o.stopOnWalk = true
    o.stopOnRun = true
    o.stopOnAim = true
    o.maxTime = o:getDuration()
    return o
end
