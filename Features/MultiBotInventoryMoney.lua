if not MultiBot then return end

local function formatInventoryMoney(summary)
    summary = summary or {}
    local gold = tonumber(summary.gold) or 0
    local silver = tonumber(summary.silver) or 0
    local label = MultiBot.L("info.inventory.money_label", "Money")

    return string.format(
        "|cffffff00%s:|r %d|cffffd700g|r %d|cffc7c7cfs|r",
        label,
        gold,
        silver
    )
end

local function refreshInventoryMoney(inventory)
    if not inventory or not inventory.moneyLabel then
        return
    end

    inventory.moneyLabel:SetText(formatInventoryMoney(inventory.summary))
end

local function wrapInventoryMoney(inventory)
    if not inventory or inventory._mbMoneyDisplayWrapped then
        return inventory
    end

    inventory._mbMoneyDisplayWrapped = true

    local originalBeginPayload = inventory.beginPayload
    inventory.beginPayload = function(self, ...)
        local result = originalBeginPayload and originalBeginPayload(self, ...)
        refreshInventoryMoney(self)
        return result
    end

    local originalApplySummaryLine = inventory.applySummaryLine
    inventory.applySummaryLine = function(self, ...)
        local result = originalApplySummaryLine and originalApplySummaryLine(self, ...)
        refreshInventoryMoney(self)
        return result
    end

    local originalApplySummaryData = inventory.applySummaryData
    inventory.applySummaryData = function(self, ...)
        local result = originalApplySummaryData and originalApplySummaryData(self, ...)
        refreshInventoryMoney(self)
        return result
    end

    refreshInventoryMoney(inventory)
    return inventory
end

local originalInitializeInventoryFrame = MultiBot.InitializeInventoryFrame
if type(originalInitializeInventoryFrame) == "function" then
    MultiBot.InitializeInventoryFrame = function(...)
        return wrapInventoryMoney(originalInitializeInventoryFrame(...))
    end
end
