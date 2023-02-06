local Utils = {}


local extractionTools = {"KitchenKnife", "HuntingKnife", "Scalpel"}
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
    return has_value(extractionTools, item:getType())
end

function Utils.IsProperTool(item)
    return has_value(properExtractionTools, item:getType())
end

function Utils.DamageTool(item, player)
    if not Utils.IsProperTool(item) then
        item:setCondition(item:getCondition() - 0.001);
    end
end
