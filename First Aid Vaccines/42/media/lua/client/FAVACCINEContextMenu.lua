
local FAVExtract = {}
local FAVCorpse = {}


local extractionTools = {"KitchenKnife", "HuntingKnife", "Scalpel", "FlintKnife"}
local properExtractionTools = {"Scalpel", nil}

local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function FAVExtract.IsExtractionTool(item)
    return has_value(extractionTools, item:getType())
end

function FAVExtract.IsProperTool(item)
    return has_value(properExtractionTools, item:getType())
end

function FAVExtract.ToolConditionGood(item)
    if item:getCondition() > 0
    then
        return true
    else
        return false
    end
end

function FAVExtract.FindExtractionTool(item)
    return FAVExtract.IsExtractionTool(item) and FAVExtract.ToolConditionGood(item)
end

function FAVExtract.DamageTool(item, player)
    if not FAVExtract.IsProperTool(item) then
        item:setCondition(item:getCondition() - 0.01);
    end
end


FAVExtract.doMenu = function (player, context, worldobjects, test)

	local corpse = IsoObjectPicker.Instance:PickCorpse(getMouseX(), getMouseY());
	if not corpse then return end
    FAVCorpse.corpse = corpse

    local playerObj = getSpecificPlayer(player)
    local playerInv = playerObj:getInventory()

    local extractionTool = nil
    local proper_extraction_tool = playerInv:getFirstEvalRecurse(FAVExtract.IsProperTool)

    if proper_extraction_tool
        then
            if FAVExtract.ToolConditionGood(proper_extraction_tool)
            then
                extractionTool = proper_extraction_tool
            end
    end
    
    if not extractionTool
        then
        extractionTool = playerInv:getFirstEvalRecurse(FAVExtract.FindExtractionTool)
    end

    if extractionTool then
		context:addOption(getText("UI_FAV_Extract"), worldobjects, FAVExtract.doAction, player);    
	end
	return
end

FAVExtract.doAction = function (worldobjects, player)
	local playerObj = getSpecificPlayer(player)
    local playerInv = playerObj:getInventory()
    local equipped = playerObj:getPrimaryHandItem()

    local proper_extraction_tool = playerInv:getFirstEvalRecurse(FAVExtract.IsProperTool)
    if proper_extraction_tool
        then
            if FAVExtract.ToolConditionGood(proper_extraction_tool)
            then
                extractionTool = proper_extraction_tool
            end
    end
    
    if not extractionTool
        then
        extractionTool = playerInv:getFirstEvalRecurse(FAVExtract.FindExtractionTool)
    end

     if FAVCorpse.corpse:getSquare() and extractionTool and luautils.walkAdj(playerObj, FAVCorpse.corpse:getSquare()) then
        ISInventoryPaneContextMenu.equipWeapon(extractionTool, true, false, playerObj:getPlayerNum());
        ISTimedActionQueue.add(FAVExtractTimedAction:new(playerObj, extractionTool, FAVCorpse.corpse));

    end
	
end

Events.OnFillWorldObjectContextMenu.Add(FAVExtract.doMenu)
