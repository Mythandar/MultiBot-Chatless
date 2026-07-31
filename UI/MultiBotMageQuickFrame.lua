if not MultiBot then return end

local FRAME_KEY, SIZE, GAP, PAD = "MageQuick", 25, 4, 5
local MageQuick = MultiBot.MageQuick or { rows = {} }
MultiBot.MageQuick = MageQuick

local ACTIONS = {
    { key = "food", command = "cast conjure food", icon = "Interface\\Icons\\Ability_Mage_ConjureFoodRank10", tip = "Conjure Food" },
    { key = "water", command = "cast conjure water", icon = "Interface\\Icons\\Ability_Mage_ConjureWater11", tip = "Conjure Water" },
    { key = "ritual", command = "cast ritual of refreshment", spellId = 43987, icon = "Interface\\Icons\\Spell_Arcane_MassDispel", tip = "Ritual of Refreshment (level 70+)", level = 70 },
}

local function texture(path)
    return MultiBot.SafeTexturePath and MultiBot.SafeTexturePath(path) or path
end

local function sanitize(name)
    return tostring(name or ""):gsub("[^%w_]", "_")
end

local function iconButton(parent, name, path, tip)
    local button = CreateFrame("Button", name, parent)
    button:SetSize(SIZE, SIZE)
    button:RegisterForClicks("LeftButtonUp")
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(button)
    icon:SetTexture(texture(path))
    button.icon, button.tooltipText = icon, tip
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    button:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.tooltipText or "", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    return button
end

local function setDisabled(button, disabled)
    button.__mbDisabled = disabled and true or false
    if button.icon.SetDesaturated then button.icon:SetDesaturated(button.__mbDisabled) end
    local shade = button.__mbDisabled and 0.45 or 1
    button.icon:SetVertexColor(shade, shade, shade, 1)
    button:SetAlpha(button.__mbDisabled and 0.5 or 1)
end

local function actionIcon(action)
    if action.spellId and GetSpellTexture then
        local path = GetSpellTexture(action.spellId)
        if path then return path end
    end
    return action.icon
end

local function collectMages()
    local mages = {}
    local function consider(unit)
        if not UnitExists(unit) then return end
        local name = GetUnitName and GetUnitName(unit, true) or UnitName(unit)
        local _, classToken = UnitClass(unit)
        if classToken ~= "MAGE" or not name then return end
        if MultiBot.IsBot and not MultiBot.IsBot(name) then return end
        table.insert(mages, { name = name, level = tonumber(UnitLevel(unit)) or 0 })
    end
    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        for index = 1, GetNumRaidMembers() do consider("raid" .. index) end
    else
        consider("player")
        local count = GetNumPartyMembers and GetNumPartyMembers() or 0
        for index = 1, count do consider("party" .. index) end
    end
    table.sort(mages, function(left, right) return left.name < right.name end)
    return mages
end

function MageQuick:SavePosition()
    if not self.frame or not MultiBot.SetQuickFramePosition then return end
    local point, _, relPoint, x, y = self.frame:GetPoint()
    MultiBot.SetQuickFramePosition(FRAME_KEY, point, relPoint, x, y)
end

function MageQuick:EnsureFrame()
    if self.frame then return self.frame end
    local frame = CreateFrame("Frame", "MultiBotMageQuickFrame", UIParent)
    frame:SetSize(PAD * 2 + SIZE * 4 + GAP * 3, PAD * 2 + SIZE)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("RightButton")
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    frame:SetBackdropColor(0.04, 0.04, 0.06, 0.88)
    frame:SetBackdropBorderColor(0.35, 0.65, 0.95, 0.95)
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        MageQuick:SavePosition()
    end)
    self.frame = frame
    local saved = MultiBot.GetQuickFramePosition and MultiBot.GetQuickFramePosition(FRAME_KEY)
    saved = saved or { point = "TOP", relPoint = "TOP", x = 0, y = -30 }
    frame:SetPoint(saved.point or "TOP", UIParent, saved.relPoint or "TOP", saved.x or 0, saved.y or -30)
    frame:Hide()
    return frame
end

function MageQuick:ClearRows()
    for _, row in ipairs(self.rows or {}) do
        row:Hide()
        row:SetParent(nil)
    end
    self.rows = {}
end

function MageQuick:BuildRow(mage, index)
    local row = CreateFrame("Frame", nil, self.frame)
    row:SetSize(SIZE * 4 + GAP * 3, SIZE)
    row:SetPoint("TOPLEFT", self.frame, "TOPLEFT", PAD, -PAD - ((index - 1) * (SIZE + GAP)))
    row.actionButtons = {}

    local mageButton = iconButton(row, nil,
        "Interface\\AddOns\\MultiBot\\Icons\\class_mage.blp",
        string.format("%s (level %d) - right-drag panel to move", mage.name, mage.level))
    mageButton:SetPoint("TOPLEFT", 0, 0)
    mageButton:SetScript("OnClick", function()
        for _, button in ipairs(row.actionButtons) do
            if button:IsShown() then button:Hide() else button:Show() end
        end
    end)

    for actionIndex, action in ipairs(ACTIONS) do
        local actionDef = action
        local button = iconButton(row, nil,
            actionIcon(actionDef), actionDef.tip)
        button:SetPoint("LEFT", mageButton, "RIGHT", GAP + ((actionIndex - 1) * (SIZE + GAP)), 0)
        setDisabled(button, actionDef.level and mage.level < actionDef.level)
        button:SetScript("OnClick", function(self)
            if self.__mbDisabled then
                if UIErrorsFrame then UIErrorsFrame:AddMessage("Ritual of Refreshment requires level 70", 1, 0.2, 0.2, 1) end
                return
            end
            SendChatMessage(actionDef.command, "WHISPER", nil, mage.name)
        end)
        table.insert(row.actionButtons, button)
    end
    table.insert(self.rows, row)
end

function MageQuick:RefreshFromGroup()
    self:EnsureFrame()
    self:ClearRows()
    local mages = collectMages()
    if #mages == 0 then self.frame:Hide() return end
    for index, mage in ipairs(mages) do self:BuildRow(mage, index) end
    self.frame:SetHeight(PAD * 2 + (#mages * SIZE) + ((#mages - 1) * GAP))
    local visible = not MultiBot.GetQuickFrameVisibleConfig or MultiBot.GetQuickFrameVisibleConfig(FRAME_KEY)
    if visible then self.frame:Show() else self.frame:Hide() end
end

function MultiBot.InitMageQuick()
    MageQuick:EnsureFrame()
    if MultiBot.TimerAfter then
        MultiBot.TimerAfter(0.5, function() MageQuick:RefreshFromGroup() end)
    else
        MageQuick:RefreshFromGroup()
    end
    return MageQuick
end

MultiBot.InitMageQuick()
