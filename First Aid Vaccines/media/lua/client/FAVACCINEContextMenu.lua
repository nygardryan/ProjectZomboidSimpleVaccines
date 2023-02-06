
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
    local extractionTool = playerInv:getFirstEvalRecurse(FAVExtract.IsExtractionTool)

    if extractionTool then
		context:addOption(getText("UI_FAV_Extract"), worldobjects, FAVExtract.doAction, player);
	end
	return
end

FAVExtract.doAction = function (worldobjects, player)
	local playerObj = getSpecificPlayer(player)
    local playerInv = playerObj:getInventory()
    local equipped = playerObj:getPrimaryHandItem()
    local extractionTool = playerInv:getFirstEvalRecurse(FAVExtract.IsExtractionTool)

     if FAVCorpse.corpse:getSquare() and extractionTool and luautils.walkAdj(playerObj, FAVCorpse.corpse:getSquare()) then
        ISInventoryPaneContextMenu.equipWeapon(extractionTool, true, false, playerObj:getPlayerNum());
        ISTimedActionQueue.add(FAVExtractTimedAction:new(playerObj, extractionTool, FAVCorpse.corpse));

    end
	
end

Events.OnFillWorldObjectContextMenu.Add(FAVExtract.doMenu)
