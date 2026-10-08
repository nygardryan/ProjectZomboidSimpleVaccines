-- Simple Vaccines (Build 42) - right-click a corpse to "Attempt to Extract DNA".
require "TimedActions/FAVExtractTimedAction"

local FAVExtract = {}

FAVExtract.extractionTools = {
    KitchenKnife = true,
    HuntingKnife = true,
    Scalpel = true,
    FlintKnife = true,
}

local function isUsableTool(item)
    return FAVExtract.extractionTools[item:getType()] == true and item:getCondition() > 0
end

local function isUsableProperTool(item)
    return FAVExtractTimedAction.isProperTool(item) and item:getCondition() > 0
end

-- Prefer a scalpel; otherwise any usable knife.
function FAVExtract.findTool(playerObj)
    local inv = playerObj:getInventory()
    return inv:getFirstEvalRecurse(isUsableProperTool) or inv:getFirstEvalRecurse(isUsableTool)
end

function FAVExtract.doAction(worldobjects, playerNum, corpse)
    local playerObj = getSpecificPlayer(playerNum)
    local tool = FAVExtract.findTool(playerObj)
    if not tool or not corpse or not corpse:getSquare() then return end

    if luautils.walkAdj(playerObj, corpse:getSquare()) then
        ISInventoryPaneContextMenu.equipWeapon(tool, true, false, playerNum)
        ISTimedActionQueue.add(FAVExtractTimedAction:new(playerObj, tool, corpse))
    end
end

function FAVExtract.doMenu(playerNum, context, worldobjects, test)
    if test then return end
    local corpse = IsoObjectPicker.Instance:PickCorpse(getMouseX(), getMouseY())
    if not corpse then return end

    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj or not FAVExtract.findTool(playerObj) then return end

    context:addOption(getText("UI_FAV_Extract"), worldobjects, FAVExtract.doAction, playerNum, corpse)
end

Events.OnFillWorldObjectContextMenu.Add(FAVExtract.doMenu)
