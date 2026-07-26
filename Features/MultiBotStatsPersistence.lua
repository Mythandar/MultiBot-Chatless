if not MultiBot then return end

local STATS_SAVED_KEY = "Stats"
local statsButton = nil
local restoreApplied = false

local function setStatsButtonState(button, enabled)
    if not button then
        return
    end

    button.state = enabled and true or false
    button.mbActive = button.state

    if button.setEnable and button.setDisable then
        if button.state then
            button.setEnable()
        else
            button.setDisable()
        end
        return
    end

    if button.icon and button.icon.SetDesaturated then
        button.icon:SetDesaturated(not button.state)
    end
    if button.border then
        if button.state then
            button.border:Show()
        else
            button.border:Hide()
        end
    end
end

local function refreshPartyStats()
    if not (MultiBot.auto and MultiBot.auto.stats) then
        return
    end
    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        return
    end

    for index = 1, GetNumPartyMembers() do
        local botName = UnitName("party" .. index)
        if botName and MultiBot.RequestStatsRefresh then
            MultiBot.RequestStatsRefresh(botName)
        end
    end
end

local function applySavedStatsState()
    if not statsButton then
        return
    end

    local enabled = MultiBot.GetSavedMainBarValue
        and MultiBot.GetSavedMainBarValue(STATS_SAVED_KEY) == "true"

    MultiBot.auto = MultiBot.auto or {}
    MultiBot.auto.stats = enabled and true or false
    setStatsButtonState(statsButton, enabled)

    local statsFrame = MultiBot.EnsureStatsUI and MultiBot.EnsureStatsUI() or MultiBot.stats
    if not statsFrame then
        return
    end

    if enabled then
        refreshPartyStats()
        statsFrame:Show()
    else
        for _, value in pairs(statsFrame.frames or {}) do
            value:Hide()
        end
        statsFrame:Hide()
    end

    restoreApplied = true
end

local function wireStatsPersistence(mainFrame)
    local button = mainFrame and mainFrame.buttons and mainFrame.buttons["Stats"]
    if not button or button._mbStatsPersistenceWired then
        return
    end

    button._mbStatsPersistenceWired = true
    statsButton = button

    local originalDoLeft = button.doLeft
    button.doLeft = function(clickedButton)
        if originalDoLeft then
            originalDoLeft(clickedButton)
        end

        if MultiBot.SetSavedMainBarValue then
            MultiBot.SetSavedMainBarValue(
                STATS_SAVED_KEY,
                (MultiBot.auto and MultiBot.auto.stats) and "true" or "false"
            )
        end
    end
end

local originalInitializeMainUI = MultiBot.InitializeMainUI
if type(originalInitializeMainUI) == "function" then
    MultiBot.InitializeMainUI = function(...)
        local result = originalInitializeMainUI(...)
        wireStatsPersistence(result and result.frame)
        return result
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" then
        applySavedStatsState()
        return
    end

    if restoreApplied then
        refreshPartyStats()
    end
end)
