if not MultiBot then return end

local T = MultiBot.TeleportBrowser or {}
MultiBot.TeleportBrowser = T

local PAGE_SIZE, VISIBLE_ROWS = 18, 18
local CONTINENTS = {
    { key = "world", label = "World" },
    { key = "ek", label = "Eastern Kingdoms", mapId = 0, art = "Azeroth", bounds = { -15000, 4000, -5000, 15000 } },
    { key = "kalimdor", label = "Kalimdor", mapId = 1, art = "Kalimdor", bounds = { -12000, 11000, -8000, 8000 } },
    { key = "outland", label = "Outland", mapId = 530, art = "Expansion01", bounds = { -7000, 6000, -7000, 6000 } },
    { key = "northrend", label = "Northrend", mapId = 571, art = "Northrend", bounds = { -6000, 9000, -7000, 6000 } },
    { key = "dungeons", label = "Dungeons" },
}

local NAVIGATION = {
    world = {
        { section = "Main capitals" },
        { "Stormwind", "Stormwind", 0, -8833, 629, 1 }, { "Ironforge", "Ironforge", 0, -4919, -940, 1 },
        { "Darnassus", "Darnassus", 1, 9950, 2284, 1 }, { "The Exodar", "TheExodar", 530, -3966, -11654, 1 },
        { "Orgrimmar", "Orgrimmar", 1, 1630, -4374, 1 }, { "Thunder Bluff", "ThunderBluff", 1, -1277, 125, 1 },
        { "Undercity", "Undercity", 0, 1584, 240, 1 }, { "Silvermoon City", "SilvermoonCity", 530, 9488, -7279, 1 },
        { "Shattrath", "Shattrath", 530, -1838, 5302, 1 }, { "Dalaran", "Dalaran", 571, 5808, 588, 1 },
    },
    ek = {
        { section = "Capitals" }, { "Stormwind", "Stormwind", 0, -8833, 629, 1 }, { "Ironforge", "Ironforge", 0, -4919, -940, 1 },
        { "Undercity", "Undercity", 0, 1584, 240, 1 }, { "Silvermoon City", "SilvermoonCity", 530, 9488, -7279, 1 },
        { section = "Main areas" },
        { "Elwynn Forest", nil, 0, nil, nil, 2 }, { "Westfall", nil, 0, nil, nil, 2 }, { "Redridge Mountains", nil, 0, nil, nil, 2 },
        { "Duskwood", nil, 0, nil, nil, 2 }, { "Dun Morogh", nil, 0, nil, nil, 2 }, { "Loch Modan", nil, 0, nil, nil, 2 },
        { "Wetlands", nil, 0, nil, nil, 2 }, { "Arathi Highlands", nil, 0, nil, nil, 2 }, { "Hinterlands", nil, 0, nil, nil, 2 },
        { "Stranglethorn Vale", nil, 0, nil, nil, 2 }, { "Western Plaguelands", nil, 0, nil, nil, 2 }, { "Eastern Plaguelands", nil, 0, nil, nil, 2 },
    },
    kalimdor = {
        { section = "Capitals" }, { "Darnassus", "Darnassus", 1, 9950, 2284, 1 }, { "The Exodar", "TheExodar", 530, -3966, -11654, 1 },
        { "Orgrimmar", "Orgrimmar", 1, 1630, -4374, 1 }, { "Thunder Bluff", "ThunderBluff", 1, -1277, 125, 1 },
        { section = "Main areas" },
        { "Teldrassil", nil, 1, nil, nil, 2 }, { "Darkshore", nil, 1, nil, nil, 2 }, { "Ashenvale", nil, 1, nil, nil, 2 },
        { "Durotar", nil, 1, nil, nil, 2 }, { "The Barrens", nil, 1, nil, nil, 2 }, { "Mulgore", nil, 1, nil, nil, 2 },
        { "Stonetalon Mountains", nil, 1, nil, nil, 2 }, { "Desolace", nil, 1, nil, nil, 2 }, { "Feralas", nil, 1, nil, nil, 2 },
        { "Tanaris", nil, 1, nil, nil, 2 }, { "Un'Goro Crater", nil, 1, nil, nil, 2 }, { "Winterspring", nil, 1, nil, nil, 2 },
    },
    outland = {
        { section = "Capital and hubs" }, { "Shattrath", "Shattrath", 530, -1838, 5302, 1 }, { "Honor Hold", nil, 530, nil, nil, 2 },
        { "Thrallmar", nil, 530, nil, nil, 2 }, { "Area 52", nil, 530, nil, nil, 2 },
        { section = "Main areas" }, { "Hellfire Peninsula", nil, 530, nil, nil, 2 }, { "Zangarmarsh", nil, 530, nil, nil, 2 },
        { "Terokkar Forest", nil, 530, nil, nil, 2 }, { "Nagrand", nil, 530, nil, nil, 2 }, { "Blade's Edge Mountains", nil, 530, nil, nil, 2 },
        { "Netherstorm", nil, 530, nil, nil, 2 }, { "Shadowmoon Valley", nil, 530, nil, nil, 2 },
    },
    northrend = {
        { section = "Capital and hubs" }, { "Dalaran", "Dalaran", 571, 5808, 588, 1 }, { "Valiance Keep", nil, 571, nil, nil, 2 },
        { "Warsong Hold", nil, 571, nil, nil, 2 }, { "Wyrmrest Temple", nil, 571, nil, nil, 2 },
        { section = "Main areas" }, { "Borean Tundra", nil, 571, nil, nil, 2 }, { "Howling Fjord", nil, 571, nil, nil, 2 },
        { "Dragonblight", nil, 571, nil, nil, 2 }, { "Grizzly Hills", nil, 571, nil, nil, 2 }, { "Zul'Drak", nil, 571, nil, nil, 2 },
        { "Sholazar Basin", nil, 571, nil, nil, 2 }, { "The Storm Peaks", nil, 571, nil, nil, 2 }, { "Icecrown", nil, 571, nil, nil, 2 },
    },
}

local DUNGEONS = {
    { "Ragefire Chasm", "RagefireChasm", 13, 20 }, { "The Deadmines", "Deadmines", 15, 25 },
    { "Wailing Caverns", "WailingCaverns", 15, 25 }, { "Shadowfang Keep", "ShadowFangKeep", 18, 30 },
    { "Blackfathom Deeps", "BlackfathomDeeps", 20, 30 }, { "The Stockade", "TheStockade", 22, 32 },
    { "Gnomeregan", "Gnomeregan", 24, 34 }, { "Razorfen Kraul", "RazorfenKraul", 25, 35 },
    { "Scarlet Monastery", "ScarletMonastery", 26, 45 }, { "Razorfen Downs", "RazorfenDowns", 35, 45 },
    { "Uldaman", "Uldaman", 35, 45 }, { "Zul'Farrak", "ZulFarrak", 44, 54 }, { "Maraudon", "Maraudon", 46, 55 },
    { "The Sunken Temple", "TheSunkenTemple", 50, 60 }, { "Blackrock Depths", "BlackrockDepths", 52, 60 },
    { "Dire Maul", "DireMaulNorth", 55, 60 }, { "Scholomance", "Scholomance", 55, 60 },
    { "Stratholme", "Stratholme", 55, 60 }, { "Blackrock Spire", "BlackrockSpire", 55, 60 },
    { "Hellfire Ramparts", "HellfireRamparts", 58, 70 }, { "The Blood Furnace", "TheBloodFurnace", 59, 70 },
    { "The Slave Pens", "TheSlavePens", 60, 70 }, { "The Underbog", "TheUnderbog", 61, 70 },
    { "Mana-Tombs", "ManaTombs", 63, 70 }, { "Auchenai Crypts", "AuchenaiCrypts", 64, 70 },
    { "Sethekk Halls", "SethekkHalls", 65, 70 }, { "Old Hillsbrad", "OldHillsbrad", 66, 70 },
    { "The Mechanar", "TheMechanar", 68, 70 }, { "The Botanica", "TheBotanica", 68, 70 },
    { "Utgarde Keep", "UtgardeKeep", 68, 75 }, { "The Nexus", "TheNexus", 69, 75 },
    { "Azjol-Nerub", "AzjolNerub", 72, 77 }, { "Ahn'kahet", "AhnKahet", 73, 78 },
    { "Drak'Tharon Keep", "DrakTharonKeep", 74, 79 }, { "Violet Hold", "VioletHold", 75, 80 },
    { "Gundrak", "Gundrak", 76, 80 }, { "Halls of Stone", "HallsOfStone", 77, 80 }, { "Utgarde Pinnacle", "UtgardePinnacle", 78, 80 },
}

local function saved()
    MultiBotGlobalSave = MultiBotGlobalSave or {}
    MultiBotGlobalSave.TeleportBrowser = MultiBotGlobalSave.TeleportBrowser or { favorites = {}, recent = {} }
    return MultiBotGlobalSave.TeleportBrowser
end

local function find(list, name)
    for index, value in ipairs(list or {}) do if value == name then return index end end
end

local function teleport(name)
    if not name or name == "" then return end
    local recent = saved().recent
    local index = find(recent, name)
    if index then table.remove(recent, index) end
    table.insert(recent, 1, name)
    while #recent > 15 do table.remove(recent) end
    SendChatMessage(".tele " .. name, "SAY")
end

local function makeButton(parent, label, width, height)
    local result = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    result:SetSize(width, height)
    result:SetText(label)
    return result
end

function T:Message(text) if self.status then self.status:SetText(text or "") end end

function T:SetMapArt(continent)
    for index, texture in ipairs(self.mapTiles or {}) do
        if continent and continent.art then
            texture:SetTexture("Interface\\WorldMap\\" .. continent.art .. "\\" .. continent.art .. index)
            texture:Show()
        else
            texture:Hide()
        end
    end
    if self.mapHint then
        if continent and continent.art then self.mapHint:Hide() else self.mapHint:Show() end
    end
end

function T:ClearPins()
    for _, pin in ipairs(self.pins or {}) do pin:Hide() end
    self.pins = {}
end

function T:AddPin(item, continent, withLabel)
    if not item.x or not item.y or not continent or not continent.bounds or item.mapId ~= continent.mapId then return end
    local minX, maxX, minY, maxY = unpack(continent.bounds)
    local px = (item.y - minY) / (maxY - minY)
    local py = (maxX - item.x) / (maxX - minX)
    if px < 0 or px > 1 or py < 0 or py > 1 then return end
    local pin = CreateFrame("Button", nil, self.canvas)
    pin:SetSize(withLabel and 90 or 14, 18)
    pin:SetPoint("CENTER", self.canvas, "BOTTOMLEFT", 8 + px * 484, 8 + py * 394)
    local dot = pin:CreateTexture(nil, "OVERLAY")
    dot:SetSize(13, 13); dot:SetPoint("LEFT"); dot:SetTexture("Interface\\Minimap\\POIIcons"); dot:SetTexCoord(0, .125, 0, .125)
    if withLabel then
        local label = pin:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", dot, "RIGHT", 2, 0); label:SetText(item.label or item.name); label:SetJustifyH("LEFT")
    end
    pin:SetScript("OnClick", function() teleport(item.tele or item.name) end)
    pin:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(item.label or item.name)
        GameTooltip:AddLine("Click to teleport", .4, 1, .4); GameTooltip:Show()
    end)
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    table.insert(self.pins, pin)
end

function T:DrawPins()
    self:ClearPins()
    local continent = CONTINENTS[self.sectionIndex or 1]
    if not continent or not continent.mapId then return end
    local seen = {}
    for _, entry in ipairs(NAVIGATION[continent.key] or {}) do
        if not entry.section and entry[4] and entry[6] <= (self.zoom or 1) then
            local item = { label = entry[1], tele = entry[2], mapId = entry[3], x = entry[4], y = entry[5] }
            self:AddPin(item, continent, true); seen[entry[1]] = true
        end
    end
    if (self.zoom or 1) >= 3 then
        for _, item in ipairs(self.serverItems or {}) do
            if not seen[item.name] then self:AddPin(item, continent, false) end
        end
    end
end

function T:Display(entries, total, offset)
    self.displayItems = entries or {}
    self.total = total or #self.displayItems
    self.offset = offset or 0
    for index, row in ipairs(self.rows or {}) do
        local item = self.displayItems[index]
        row.item = item
        if item then
            row.name:SetText(item.header and ("|cffffd100" .. item.label .. "|r") or item.label)
            row.detail:SetText(item.detail or "")
            if item.header then row:Disable() else row:Enable() end
            row:Show()
        else row:Hide() end
    end
    self.pageText:SetText(self.total > VISIBLE_ROWS and ((math.floor(self.offset / PAGE_SIZE) + 1) .. " / " .. math.max(1, math.ceil(self.total / PAGE_SIZE))) or "")
    self:DrawPins()
end

function T:ShowNavigation()
    local continent = CONTINENTS[self.sectionIndex or 1]
    self:SetMapArt(continent)
    if continent.key == "dungeons" then return self:ShowDungeons() end
    local source = NAVIGATION[continent.key] or NAVIGATION.world
    local entries = {}
    local pendingHeader
    for _, value in ipairs(source) do
        if value.section then
            pendingHeader = value.section
        elseif value[6] <= (self.zoom or 1) then
            if pendingHeader then
                table.insert(entries, { label = pendingHeader, header = true })
                pendingHeader = nil
            end
            table.insert(entries, { label = value[1], tele = value[2], search = value[2] and nil or value[1], detail = value[6] == 1 and "Capital" or "Area" })
        end
    end
    self.mode = "navigation"
    self:Message(continent.label .. " - select a capital or area")
    self:Display(entries)
end

function T:ShowDungeons()
    self:SetMapArt(nil)
    local level = UnitLevel("player") or 1
    local entries = { { label = "Available near level " .. level, header = true } }
    for _, dungeon in ipairs(DUNGEONS) do
        if level >= dungeon[3] - 2 and level <= dungeon[4] + 5 then
            table.insert(entries, { label = dungeon[1], tele = dungeon[2], detail = dungeon[3] .. "-" .. dungeon[4] })
        end
    end
    self.mode = "dungeons"
    self:Message("Level-filtered dungeons; progression filtering requires bridge data")
    self:Display(entries)
end

function T:Request(search, offset)
    local continent = CONTINENTS[self.sectionIndex or 1]
    if not MultiBot.Comm or not MultiBot.Comm.RequestTeleports then self:Message("Teleport bridge unavailable"); return end
    self.mode = "server"
    self.pendingSearch = search or self.search:GetText() or ""
    self.offset = math.max(0, tonumber(offset) or 0)
    self:Message("Loading " .. (self.pendingSearch ~= "" and self.pendingSearch or "destinations") .. "...")
    MultiBot.Comm.RequestTeleports(self.pendingSearch, continent and continent.mapId, self.offset)
end

function T:SetZoom(value)
    self.zoom = math.max(1, math.min(3, value or 1))
    self.zoomText:SetText("Zoom " .. self.zoom .. "/3")
    if self.zoom == 1 then self:ShowNavigation() elseif self.zoom == 2 and self.mode ~= "server" then self:ShowNavigation() else self:DrawPins() end
end

function T:Build()
    if self.frame then return self.frame end
    local frame = CreateFrame("Frame", "MultiBotTeleportBrowser", UIParent)
    frame:SetSize(920, 610); frame:SetPoint("CENTER"); frame:SetFrameStrata("DIALOG"); frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end); frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 8, right = 8, top = 8, bottom = 8 } })
    frame:Hide(); self.frame = frame
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); title:SetPoint("TOP", 0, -16); title:SetText("AzerothCore Teleport Browser")
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", -5, -5)
    self.search = CreateFrame("EditBox", nil, frame, "InputBoxTemplate"); self.search:SetSize(260, 24); self.search:SetPoint("TOPLEFT", 24, -48); self.search:SetAutoFocus(false)
    self.search:SetScript("OnEnterPressed", function(self) self:ClearFocus(); T:Request(self:GetText(), 0) end)
    local searchButton = makeButton(frame, "Search", 70, 24); searchButton:SetPoint("LEFT", self.search, "RIGHT", 8, 0); searchButton:SetScript("OnClick", function() T:Request(T.search:GetText(), 0) end)
    local home = makeButton(frame, "Home", 60, 24); home:SetPoint("LEFT", searchButton, "RIGHT", 8, 0); home:SetScript("OnClick", function() T:ShowNavigation() end)

    local previous
    for index, continent in ipairs(CONTINENTS) do
        local tab = makeButton(frame, continent.label, index == 1 and 55 or (index == 6 and 85 or 130), 23)
        if previous then tab:SetPoint("LEFT", previous, "RIGHT", 3, 0) else tab:SetPoint("TOPLEFT", 24, -80) end
        tab:SetScript("OnClick", function() T.sectionIndex = index; T.zoom = 1; T:SetZoom(1); T:ShowNavigation() end)
        previous = tab
    end

    self.rows = {}
    for index = 1, VISIBLE_ROWS do
        local row = CreateFrame("Button", nil, frame); row:SetSize(340, 23); row:SetPoint("TOPLEFT", 24, -116 - ((index - 1) * 23)); row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); row.name:SetPoint("LEFT", 6, 0); row.name:SetWidth(245); row.name:SetJustifyH("LEFT")
        row.detail = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); row.detail:SetPoint("RIGHT", -4, 0)
        row:SetScript("OnClick", function(self)
            if not self.item then return end
            if self.item.tele then teleport(self.item.tele) elseif self.item.search then T.search:SetText(self.item.search); T:SetZoom(3); T:Request(self.item.search, 0) end
        end)
        self.rows[index] = row
    end

    self.canvas = CreateFrame("Frame", nil, frame); self.canvas:SetSize(500, 410); self.canvas:SetPoint("TOPRIGHT", -24, -116)
    self.canvas:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } }); self.canvas:SetBackdropColor(.02, .03, .05, 1)
    self.mapTiles = {}
    for index = 1, 12 do
        local texture = self.canvas:CreateTexture(nil, "BACKGROUND")
        texture:SetSize(125, 137); texture:SetPoint("TOPLEFT", ((index - 1) % 4) * 125, -math.floor((index - 1) / 4) * 137)
        self.mapTiles[index] = texture
    end
    self.mapHint = self.canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge"); self.mapHint:SetPoint("CENTER"); self.mapHint:SetText("Choose a continent")
    self.pins = {}
    local zoomOut = makeButton(frame, "-", 28, 24); zoomOut:SetPoint("TOPLEFT", self.canvas, "BOTTOMLEFT", 0, -6); zoomOut:SetScript("OnClick", function() T:SetZoom((T.zoom or 1) - 1) end)
    local zoomIn = makeButton(frame, "+", 28, 24); zoomIn:SetPoint("LEFT", zoomOut, "RIGHT", 4, 0); zoomIn:SetScript("OnClick", function() T:SetZoom((T.zoom or 1) + 1) end)
    self.zoomText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal"); self.zoomText:SetPoint("LEFT", zoomIn, "RIGHT", 8, 0)
    local prev = makeButton(frame, "Previous", 80, 24); prev:SetPoint("BOTTOMLEFT", 24, 25); prev:SetScript("OnClick", function() if T.mode == "server" and T.offset > 0 then T:Request(T.pendingSearch, math.max(0, T.offset - PAGE_SIZE)) end end)
    local nextButton = makeButton(frame, "Next", 80, 24); nextButton:SetPoint("LEFT", prev, "RIGHT", 8, 0); nextButton:SetScript("OnClick", function() if T.mode == "server" and T.offset + PAGE_SIZE < T.total then T:Request(T.pendingSearch, T.offset + PAGE_SIZE) end end)
    self.pageText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal"); self.pageText:SetPoint("LEFT", nextButton, "RIGHT", 12, 0)
    self.status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); self.status:SetPoint("BOTTOMRIGHT", -24, 31); self.status:SetWidth(500); self.status:SetJustifyH("RIGHT")
    self.sectionIndex, self.zoom = 1, 1; self.zoomText:SetText("Zoom 1/3")
    return frame
end

function T:Toggle()
    local frame = self:Build()
    if frame:IsShown() then frame:Hide() else frame:Show(); self:ShowNavigation() end
end

function MultiBot.OnBridgeTeleports(result)
    T.serverItems = result.items or {}
    local entries = {}
    for _, item in ipairs(T.serverItems) do table.insert(entries, { label = item.name, tele = item.name, detail = "Map " .. item.mapId }) end
    T:Message((result.total or #entries) .. " matching destinations")
    T:Display(entries, result.total, result.offset)
end

function MultiBot.OnBridgeTeleportsError(reason)
    T:Message(reason == "UNAUTHORIZED" and "Your account cannot use .tele" or ("Teleport error: " .. tostring(reason)))
end

function MultiBot.InitializeTeleportBrowser() return T:Build() end
