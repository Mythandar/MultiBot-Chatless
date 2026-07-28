if not MultiBot then return end

local POLL_INTERVAL_SECONDS = 25
local DURABILITY_TEXT_X = 70
local DURABILITY_TEXT_Y = -43
local DURABILITY_FONT_SIZE = 10
local STATS_FONT_PATH = "Fonts\\ARIALN.ttf"
local EQUIPMENT_DAMAGE_LABEL = "Equip Dmg"

local function shortLabel(key, fallback)
    if MultiBot.L then
        return MultiBot.L("info.shorts." .. key, fallback)
    end
    return fallback
end

local function getStatsUnitName(botName)
    if type(botName) ~= "string" or botName == "" then
        return nil
    end

    if MultiBot.toUnit then
        local unit = MultiBot.toUnit(botName)
        if unit and unit ~= "" then
            return unit
        end
    end

    return botName
end

local function ensureDurabilityText(statsFrame)
    if not statsFrame or not statsFrame.addText then
        return nil
    end

    statsFrame.texts = statsFrame.texts or {}
    if not statsFrame.texts["Durability"] then
        statsFrame.addText(
            "Durability",
            "|cff888888" .. EQUIPMENT_DAMAGE_LABEL .. " --|r",
            "TOPLEFT",
            DURABILITY_TEXT_X,
            DURABILITY_TEXT_Y,
            DURABILITY_FONT_SIZE
        )
    end

    return statsFrame.texts["Durability"]
end

local function durabilityColour(damagePercent)
    if damagePercent >= 75 then
        return "|cffff3333"
    elseif damagePercent >= 50 then
        return "|cffff8800"
    elseif damagePercent >= 25 then
        return "|cffffff00"
    end

    return "|cff33ff33"
end

local function updateDurabilityText(statsFrame, level, durabilityRemainingPercent)
    local text = ensureDurabilityText(statsFrame)
    if not text then
        return
    end

    level = tonumber(level) or 0
    if level >= 80 then
        text:Hide()
        return
    end

    text:Show()

    durabilityRemainingPercent = tonumber(durabilityRemainingPercent)
    if not durabilityRemainingPercent then
        text:SetText("|cff888888" .. EQUIPMENT_DAMAGE_LABEL .. " --|r")
        return
    end

    durabilityRemainingPercent = math.max(0, math.min(100, durabilityRemainingPercent))
    local damagePercent = 100 - durabilityRemainingPercent
    damagePercent = math.max(0, math.min(100, math.floor(damagePercent + 0.5)))

    text:SetFont(STATS_FONT_PATH, DURABILITY_FONT_SIZE, "PLAIN")
    text:SetText(
        durabilityColour(damagePercent)
        .. EQUIPMENT_DAMAGE_LABEL
        .. " "
        .. damagePercent
        .. "%|r"
    )
end

local function formatMoneyWithoutCopper(stats)
    local gold = tonumber(stats and stats.gold or 0) or 0
    local silver = tonumber(stats and stats.silver or 0) or 0
    return gold .. "g " .. silver .. "s"
end

local originalAddStats = MultiBot.addStats
if type(originalAddStats) == "function" then
    MultiBot.addStats = function(pFrame, pIndex, pX, pY, pSize, pWidth, pHeight)
        local result = originalAddStats(pFrame, pIndex, pX, pY, pSize, pWidth, pHeight)
        local statsFrame = pFrame and pFrame.frames and pFrame.frames[pIndex] or nil

        if statsFrame then
            ensureDurabilityText(statsFrame)

            local originalSetStats = statsFrame.setStats
            if type(originalSetStats) == "function" and not statsFrame._mbDurabilitySetStatsWrapped then
                statsFrame._mbDurabilitySetStatsWrapped = true
                statsFrame.setStats = function(pName, pLevel, pStats, oPlayer)
                    if type(pStats) == "string" then
                        pStats = pStats:gsub("(%d+g%s+%d+s)%s+%d+c", "%1", 1)
                    end
                    return originalSetStats(pName, pLevel, pStats, oPlayer)
                end
            end
        end

        return result
    end
end

local originalApplyBridgeStats = MultiBot.ApplyBridgeStats
if type(originalApplyBridgeStats) == "function" then
    MultiBot.ApplyBridgeStats = function(stats)
        local applied = originalApplyBridgeStats(stats)
        if not applied or type(stats) ~= "table" then
            return applied
        end

        local unit = getStatsUnitName(stats.name)
        local statsFrame = MultiBot.stats and MultiBot.stats.frames and unit and MultiBot.stats.frames[unit] or nil
        if not statsFrame then
            return applied
        end

        local level = tonumber(stats.level or 0) or 0
        if level <= 0 and unit and UnitExists and UnitExists(unit) then
            level = UnitLevel(unit) or 0
        end

        updateDurabilityText(statsFrame, level, stats.durabilityPct)

        local valuesText = statsFrame.texts and statsFrame.texts["Values"] or nil
        if valuesText then
            local bagUsed = tonumber(stats.bagUsed or 0) or 0
            local bagTotal = tonumber(stats.bagTotal or 0) or 0
            valuesText:SetText(
                "|cffffdd55"
                .. formatMoneyWithoutCopper(stats)
                .. "|r, "
                .. shortLabel("bag", "Bag")
                .. " "
                .. bagUsed
                .. "/"
                .. bagTotal
            )
        end

        return applied
    end
end

local function pollPartyStats()
    if not (MultiBot.auto and MultiBot.auto.stats) then
        return
    end

    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        return
    end

    local partyCount = GetNumPartyMembers and GetNumPartyMembers() or 0
    for index = 1, partyCount do
        local botName = UnitName("party" .. index)
        if botName and MultiBot.RequestStatsRefresh then
            MultiBot.RequestStatsRefresh(botName)
        end
    end
end

local pollFrame = CreateFrame("Frame")
local elapsedSincePoll = 0
local wasEnabled = false

pollFrame:SetScript("OnUpdate", function(_, elapsed)
    local enabled = MultiBot.auto and MultiBot.auto.stats

    if not enabled then
        elapsedSincePoll = 0
        wasEnabled = false
        return
    end

    if not wasEnabled then
        wasEnabled = true
        elapsedSincePoll = 0
        return
    end

    elapsedSincePoll = elapsedSincePoll + (tonumber(elapsed) or 0)
    if elapsedSincePoll < POLL_INTERVAL_SECONDS then
        return
    end

    elapsedSincePoll = 0
    pollPartyStats()
end)
