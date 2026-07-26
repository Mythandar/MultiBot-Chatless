if not MultiBot then return end

local STATS_SAVED_KEY = "Stats"

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

local function applySavedStatsState(button)
    local enabled = MultiBot.GetSavedMainBarValue
        and MultiBot.GetSavedMainBarValue(STATS_SAVED_KEY) == "true"

    MultiBot.auto = MultiBot.auto or {}
    MultiBot.auto.stats = enabled and true or false
    setStatsButtonState(button, enabled)

    local statsFrame = MultiBot.EnsureStatsUI and MultiBot.EnsureStatsUI() or MultiBot.stats
    if not statsFrame then
        return
    end

    if not enabled then
        statsFrame:Hide()
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
    statsFrame:Show()
end

local function wireStatsPersistence(mainFrame)
    local button = mainFrame and mainFrame.buttons and mainFrame.buttons["Stats"]
    if not button or button._mbStatsPersistenceWired then
        return
    end

    button._mbStatsPersistenceWired = true
    local originalDoLeft = button.doLeft

    button.doLeft = function(statsButton)
        if originalDoLeft then
            originalDoLeft(statsButton)
        end

        if MultiBot.SetSavedMainBarValue then
            MultiBot.SetSavedMainBarValue(
                STATS_SAVED_KEY,
                (MultiBot.auto and MultiBot.auto.stats) and "true" or "false"
            )
        end
    end

    applySavedStatsState(button)
end

local originalInitializeMainUI = MultiBot.InitializeMainUI
if type(originalInitializeMainUI) == "function" then
    MultiBot.InitializeMainUI = function(...)
        local result = originalInitializeMainUI(...)
        local mainFrame = result and result.frame
        wireStatsPersistence(mainFrame)
        return result
    end
end
