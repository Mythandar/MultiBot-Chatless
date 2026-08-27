if not MultiBot then return end

local MODE_FRAME_NAME = "Mode"
local MODE_BUTTON_NAME = "Mode"
local MODE_BUTTON_ICON = "Interface\\AddOns\\MultiBot\\Icons\\mode_passive.blp"
local MODE_FRAME_X = -172
local MODE_FRAME_Y = 34

local function runModeCommands(commands)
    if type(commands) == "string" then
        return MultiBot.ActionToGroup(commands)
    end

    for _, command in ipairs(commands) do
        if not MultiBot.ActionToGroup(command) then
            return false
        end
    end

    return true
end

local function bindModeToggleAction(modeButton, enableCommands, disableCommands)
    modeButton.setDisable().doLeft = function(button)
        if button.state then
            if runModeCommands(disableCommands) then
                button.setDisable()
            end
        elseif runModeCommands(enableCommands) then
            button.setEnable()
        end
    end
end

local function selectMode(button, enableCommands, disableCommands)
    local modeRoot = button.parent.parent
    if MultiBot.Select(modeRoot, MODE_FRAME_NAME, button.texture) then
        bindModeToggleAction(modeRoot.buttons[MODE_BUTTON_NAME], enableCommands, disableCommands)
    end
end

local function createModeUI(tLeft)
    local modeButton = tLeft.addButton(MODE_BUTTON_NAME, -170, 0, MODE_BUTTON_ICON, MultiBot.L("tips.mode.master")).setDisable()

    modeButton.doRight = function(button)
        MultiBot.ShowHideSwitch(button.parent.frames[MODE_FRAME_NAME])
    end

    modeButton.doLeft = function(button)
        if MultiBot.OnOffSwitch(button) then
            MultiBot.ActionToGroup("co +passive,?")
        else
            MultiBot.ActionToGroup("co -passive,?")
        end
    end

    local modeFrame = tLeft.addFrame(MODE_FRAME_NAME, MODE_FRAME_X, MODE_FRAME_Y)
    modeFrame:Hide()

    modeFrame.addButton("Passive", 0, 0, MODE_BUTTON_ICON, MultiBot.L("tips.mode.passive")).doLeft = function(button)
        selectMode(button, "co +passive,?", "co -passive,?")
    end

    modeFrame.addButton("Grind", 0, 30, "Interface\\AddOns\\MultiBot\\Icons\\mode_grind.blp", MultiBot.L("tips.mode.grind")).doLeft = function(button)
        selectMode(button, "grind", "follow")
    end

    modeFrame.addButton("Flee", 0, 60, "Interface\\AddOns\\MultiBot\\Icons\\flee.blp", MultiBot.L("tips.mode.flee")).doLeft = function(button)
        selectMode(button, "flee", "follow")
    end

    modeFrame.addButton("Guard", 0, 90, "Interface\\AddOns\\MultiBot\\Icons\\formation_shield.blp", MultiBot.L("tips.mode.guard")).doLeft = function(button)
        selectMode(button, {
            "position guard set",
            "nc -follow,-stay,-passive,-grind,+guard,?",
            "co -stay,-guard,-passive,-grind,?",
        }, {
            "nc -guard,?",
            "follow",
        })
    end
end

local function createStayFollowUI(tLeft)
    tLeft.addButton("Stay", -136, 0, "Interface\\AddOns\\MultiBot\\Icons\\command_stay.blp", MultiBot.L("tips.stallow.stay")).doLeft = function(button)
        if MultiBot.ActionToGroup("stay") then
            button.parent.buttons["Follow"].doShow()
            button.parent.buttons["ExpandFollow"].setDisable()
            button.parent.buttons["ExpandStay"].setEnable()
            button.doHide()
        end
    end

    tLeft.addButton("Follow", -136, 0, "Interface\\AddOns\\MultiBot\\Icons\\command_follow.blp", MultiBot.L("tips.stallow.follow")).doHide().doLeft = function(button)
        if MultiBot.ActionToGroup("follow") then
            button.parent.buttons["Stay"].doShow()
            button.parent.buttons["ExpandFollow"].setEnable()
            button.parent.buttons["ExpandStay"].setDisable()
            button.doHide()
        end
    end

    tLeft.addButton("ExpandStay", -136, 0, "Interface\\AddOns\\MultiBot\\Icons\\command_stay.blp", MultiBot.tips.expand.stay).doHide().setDisable().doLeft = function(button)
        MultiBot.ActionToGroup("stay")
        button.parent.buttons["ExpandFollow"].setDisable()
        button.setEnable()
    end

    tLeft.addButton("ExpandFollow", -170, 0, "Interface\\AddOns\\MultiBot\\Icons\\command_follow.blp", MultiBot.tips.expand.follow).doHide().doLeft = function(button)
        MultiBot.ActionToGroup("follow")
        button.parent.buttons["ExpandStay"].setDisable()
        button.setEnable()
    end
end

function MultiBot.InitializeLeftCoreUI(tLeft)
    if not tLeft or not tLeft.addButton or not tLeft.addFrame then
        return nil
    end

    if MultiBot.BuildBotRTIActionUI then
        MultiBot.BuildBotRTIActionUI(tLeft, -306, 0)
    end

    if MultiBot.BuildDisperseUI then
        MultiBot.BuildDisperseUI(tLeft)
    end

    if MultiBot.BuildLootUI then
        MultiBot.BuildLootUI(tLeft)
    end

    tLeft.addButton("Tanker", -238, 0, "ability_warrior_shieldbash", MultiBot.L("tips.tanker.master")).doLeft = function()
        if MultiBot.isTarget() then
            MultiBot.ActionToGroup("@tank do attack my target")
        end
    end

    createModeUI(tLeft)
    createStayFollowUI(tLeft)

    if MultiBot.BindShiftRightSwapButtons then
        MultiBot.BindShiftRightSwapButtons(tLeft, "LeftRoot", {
            { name = "BotRTI", id = "BotRTIActionButton", frameName = "BotRTIAction" },
            { name = "Disperse", frameName = "DisperseMenu" },
            { name = "Loot", frameName = "LootMenu" },
            { name = "Tanker" },
            { name = "Mode", frameName = "Mode" },
            { name = "Stay" },
            { name = "Follow" },
        })
    end

    return tLeft
end
