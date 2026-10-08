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

-- Inventory: right-click a vaccine -> "Inject" (custom FAVInject animation)
require "TimedActions/FAVInjectAction"

local injectable = {
    ["FAVACCINE.CrudeVaccine"] = true,
    ["FAVACCINE.ZombieVaccine"] = true,
    ["FAVACCINE.PerfectedZombieVaccine"] = true,
}

local function onInject(item, playerNum)
    local playerObj = getSpecificPlayer(playerNum)
    ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item)
    ISTimedActionQueue.add(FAVInjectAction:new(playerObj, item))
end

local function onFillInventoryMenu(playerNum, context, items)
    for _, v in ipairs(items) do
        local item = v
        if not instanceof(v, "InventoryItem") then item = v.items[1] end
        if item and injectable[item:getFullType()] then
            context:addOption(getText("UI_FAV_Inject"), item, onInject, playerNum)
            return
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryMenu)
