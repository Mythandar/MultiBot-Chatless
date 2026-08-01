if not MultiBot then return end

local T = MultiBot.TeleportBrowser or {}
MultiBot.TeleportBrowser = T

local VISIBLE_ROWS, PAGE_SIZE = 20, 18
local VIEW_W, VIEW_H = 610, 405

local CONTINENTS = {
    world = { key = "world", label = "World" },
    ek = { key = "ek", label = "Eastern Kingdoms", mapId = 0, uiIndex = 2, art = "Azeroth", bounds = { -15000, 4000, -5000, 15000 } },
    kalimdor = { key = "kalimdor", label = "Kalimdor", mapId = 1, uiIndex = 1, art = "Kalimdor", bounds = { -12000, 11000, -8000, 8000 } },
    outland = { key = "outland", label = "Outland", mapId = 530, uiIndex = 3, art = "Expansion01", bounds = { -7000, 6000, -7000, 6000 } },
    northrend = { key = "northrend", label = "Northrend", mapId = 571, uiIndex = 4, art = "Northrend", bounds = { -6000, 9000, -7000, 6000 } },
}

local CAPITALS = {
    { "Stormwind", "Stormwind", "ek", -8833, 629 }, { "Ironforge", "Ironforge", "ek", -4919, -940 },
    { "Undercity", "Undercity", "ek", 1584, 240 }, { "Silvermoon City", "SilvermoonCity", "ek", 9488, -7279 },
    { "Darnassus", "Darnassus", "kalimdor", 9950, 2284 }, { "The Exodar", "TheExodar", "kalimdor", -3966, -11654 },
    { "Orgrimmar", "Orgrimmar", "kalimdor", 1630, -4374 }, { "Thunder Bluff", "ThunderBluff", "kalimdor", -1277, 125 },
    { "Shattrath", "Shattrath", "outland", -1838, 5302 }, { "Dalaran", "Dalaran", "northrend", 5808, 588 },
}

local HUBS = {
    ek = {
        { "Aerie Peak", "AeriePeak", 260, -2125 }, { "Chillwind Camp", "ChillwindCamp", 968, -1444 },
        { "Menethil Harbor", "MenethilHarbor", -3769, -744 }, { "Thelsamar", "Thelsamar", -5353, -2949 },
        { "Sentinel Hill", "SentinelHill", -10624, 1097 }, { "Lakeshire", "Lakeshire", -9267, -2189 },
        { "Darkshire", "Darkshire", -10573, -1183 }, { "Booty Bay", "BootyBay", -14297, 531 },
    },
    kalimdor = {
        { "Auberdine", "Auberdine", 6501, 482 }, { "Astranaar", "Astranaar", 2676, -423 },
        { "Ratchet", "Ratchet", -957, -3755 }, { "Gadgetzan", "Gadgetzan", -7177, -3785 },
        { "Cenarion Hold", "CenarionHold", -6818, 734 },
    },
    outland = {
        { "Honor Hold", "HonorHold", -748, 2682 }, { "Thrallmar", "Thrallmar", 156, 2673 },
        { "Cenarion Refuge", "CenarionRefuge", -224, 5488 }, { "Area 52", "Area52", 3043, 3681 },
    },
    northrend = {
        { "Valiance Keep", "ValianceKeep", 2214, 5273 }, { "Warsong Hold", "WarsongHold", 2741, 6097 },
        { "Wyrmrest Temple", "WyrmrestTemple", 3556, 265 }, { "Argent Tournament", "ArgentTournament", 8516, 629 },
    },
}

local ZONE_VIEWS = {
    ["Elwynn Forest"] = { continent = "ek", bounds = { -10300, -8500, -900, 1600 }, destinations = { { "Elwynn Forest", "ElwynnForest", -9617, -289 }, { "Goldshire", "Goldshire", -9449, 68 } } },
    ["Westfall"] = { continent = "ek", bounds = { -11800, -9700, -300, 2000 }, destinations = { { "Westfall", "Westfall", -10235, 1222 }, { "Sentinel Hill", "SentinelHill", -10624, 1097 } } },
    ["Redridge Mountains"] = { continent = "ek", bounds = { -10150, -8600, -3000, -1500 }, destinations = { { "Redridge Mountains", "RedridgeMountains", -9552, -2205 }, { "Lakeshire", "Lakeshire", -9267, -2189 } } },
    ["Duskwood"] = { continent = "ek", bounds = { -11500, -9800, -1800, 200 }, destinations = { { "Duskwood", "Duskwood", -10898, -365 }, { "Darkshire", "Darkshire", -10573, -1183 } } },
    ["Stranglethorn Vale"] = { continent = "ek", bounds = { -14950, -11300, -1800, 1800 }, destinations = { { "Stranglethorn Vale", "StranglethornVale", -12644, -377 }, { "Booty Bay", "BootyBay", -14297, 531 } } },
    ["Dun Morogh"] = { continent = "ek", bounds = { -6200, -4400, -1500, 300 }, destinations = { { "Dun Morogh", "DunMorogh", -5452, -657 }, { "Kharanos", "Kharanos", -5597, -483 } } },
    ["Loch Modan"] = { continent = "ek", bounds = { -6100, -4400, -3700, -2200 }, destinations = { { "Loch Modan", "LochModan", -5203, -2855 }, { "Thelsamar", "Thelsamar", -5353, -2949 } } },
    ["Wetlands"] = { continent = "ek", bounds = { -4500, -2200, -3300, 300 }, destinations = { { "Wetlands", "Wetlands", -3243, -2469 }, { "Menethil Harbor", "MenethilHarbor", -3769, -744 } } },
    ["Arathi Highlands"] = { continent = "ek", bounds = { -2500, -500, -3600, -1800 }, destinations = { { "Arathi Highlands", "ArathiHighlands", -1509, -2732 }, { "Refuge Pointe", "RefugePointe", -1247, -2529 } } },
    ["Hinterlands"] = { continent = "ek", mapName = "The Hinterlands", bounds = { -800, 1400, -3900, -1300 }, destinations = { { "The Hinterlands", "AeriePeak", 120, -3190 }, { "Aerie Peak", "AeriePeak", 260, -2125 } } },
    ["Western Plaguelands"] = { continent = "ek", bounds = { 700, 2600, -2600, -700 }, destinations = { { "Western Plaguelands", "WesternPlaguelands", 1729, -1602 }, { "Chillwind Camp", "ChillwindCamp", 968, -1444 } } },
    ["Eastern Plaguelands"] = { continent = "ek", bounds = { 1300, 3300, -6000, -2800 }, destinations = { { "Eastern Plaguelands", "EasternPlaguelands", 2301, -4613 }, { "Light's Hope Chapel", "LightsHopeChapel", 2280, -5310 } } },
    ["Badlands"] = { continent = "ek", bounds = { -7600, -6100, -4300, -1800 }, destinations = { { "Badlands", "Badlands", -6779, -3424 }, { "Kargath", "Kargath", -6692, -2175 } } },
    ["Searing Gorge"] = { continent = "ek", bounds = { -7700, -6000, -1900, -400 }, destinations = { { "Searing Gorge", "SearingGorge", -7012, -1065 }, { "Thorium Point", "ThoriumPoint", -6506, -1150 } } },
    ["Burning Steppes"] = { continent = "ek", bounds = { -9000, -7400, -3100, -900 }, destinations = { { "Burning Steppes", "BurningSteppes", -8119, -1634 }, { "Morgan's Vigil", "MorgansVigil", -8373, -2754 } } },
    ["Swamp of Sorrows"] = { continent = "ek", bounds = { -11100, -9700, -3900, -2200 }, destinations = { { "Swamp of Sorrows", "SwampOfSorrows", -10345, -2773 }, { "Stonard", "Stonard", -10447, -3262 } } },
    ["Blasted Lands"] = { continent = "ek", bounds = { -11800, -10300, -4100, -2600 }, destinations = { { "Blasted Lands", "BlastedLands", -11182, -3017 }, { "Nethergarde Keep", "NethergardeKeep", -11000, -3380 } } },
}

local REGIONS = {
    ek = {
        { "Northern Kingdoms", { "Eversong Woods", "Ghostlands", "Tirisfal Glades", "Silverpine Forest", "Western Plaguelands", "Eastern Plaguelands", "Hinterlands" } },
        { "Central Kingdoms", { "Dun Morogh", "Loch Modan", "Wetlands", "Arathi Highlands", "Hillsbrad Foothills", "Alterac Mountains" } },
        { "Southern Kingdoms", { "Elwynn Forest", "Westfall", "Redridge Mountains", "Duskwood", "Stranglethorn Vale", "Badlands", "Searing Gorge", "Burning Steppes", "Swamp of Sorrows", "Blasted Lands" } },
    },
    kalimdor = {
        { "Northern Kalimdor", { "Teldrassil", "Darkshore", "Azuremyst Isle", "Bloodmyst Isle", "Winterspring", "Moonglade", "Felwood", "Ashenvale" } },
        { "Central Kalimdor", { "Durotar", "The Barrens", "Mulgore", "Stonetalon Mountains", "Desolace", "Dustwallow Marsh" } },
        { "Southern Kalimdor", { "Feralas", "Thousand Needles", "Tanaris", "Un'Goro Crater", "Silithus" } },
    },
    outland = {
        { "Outland Regions", { "Hellfire Peninsula", "Zangarmarsh", "Terokkar Forest", "Nagrand", "Blade's Edge Mountains", "Netherstorm", "Shadowmoon Valley" } },
        { "Major Hubs", { "Honor Hold", "Thrallmar", "Cenarion Refuge", "Area 52", "Wildhammer Stronghold", "Shadowmoon Village" } },
    },
    northrend = {
        { "Southern Northrend", { "Borean Tundra", "Howling Fjord", "Dragonblight", "Grizzly Hills" } },
        { "Northern Northrend", { "Zul'Drak", "Sholazar Basin", "The Storm Peaks", "Icecrown", "Wintergrasp" } },
        { "Major Hubs", { "Valiance Keep", "Warsong Hold", "Wyrmrest Temple", "Argent Tournament Grounds" } },
    },
}

local DUNGEONS = {
    { "Ragefire Chasm", "RagefireChasm", 13, 20 }, { "The Deadmines", "Deadmines", 15, 25 }, { "Wailing Caverns", "WailingCaverns", 15, 25 },
    { "Shadowfang Keep", "ShadowFangKeep", 18, 30 }, { "Blackfathom Deeps", "BlackfathomDeeps", 20, 30 }, { "The Stockade", "TheStockade", 22, 32 },
    { "Gnomeregan", "Gnomeregan", 24, 34 }, { "Razorfen Kraul", "RazorfenKraul", 25, 35 }, { "Scarlet Monastery", "ScarletMonastery", 26, 45 },
    { "Razorfen Downs", "RazorfenDowns", 35, 45 }, { "Uldaman", "Uldaman", 35, 45 }, { "Zul'Farrak", "ZulFarrak", 44, 54 },
    { "Maraudon", "Maraudon", 46, 55 }, { "The Sunken Temple", "TheSunkenTemple", 50, 60 }, { "Blackrock Depths", "BlackrockDepths", 52, 60 },
    { "Dire Maul", "DireMaulNorth", 55, 60 }, { "Scholomance", "Scholomance", 55, 60 }, { "Stratholme", "Stratholme", 55, 60 },
    { "Hellfire Ramparts", "HellfireRamparts", 58, 70 }, { "The Blood Furnace", "TheBloodFurnace", 59, 70 }, { "The Slave Pens", "TheSlavePens", 60, 70 },
    { "The Underbog", "TheUnderbog", 61, 70 }, { "Mana-Tombs", "ManaTombs", 63, 70 }, { "Auchenai Crypts", "AuchenaiCrypts", 64, 70 },
    { "Sethekk Halls", "SethekkHalls", 65, 70 }, { "Old Hillsbrad", "OldHillsbrad", 66, 70 }, { "The Mechanar", "TheMechanar", 68, 70 },
    { "The Botanica", "TheBotanica", 68, 70 }, { "Utgarde Keep", "UtgardeKeep", 68, 75 }, { "The Nexus", "TheNexus", 69, 75 },
    { "Azjol-Nerub", "AzjolNerub", 72, 77 }, { "Ahn'kahet", "AhnKahet", 73, 78 }, { "Drak'Tharon Keep", "DrakTharonKeep", 74, 79 },
    { "Violet Hold", "VioletHold", 75, 80 }, { "Gundrak", "Gundrak", 76, 80 }, { "Halls of Stone", "HallsOfStone", 77, 80 },
    { "Utgarde Pinnacle", "UtgardePinnacle", 78, 80 },
}

local RAIDS = {
    { "Molten Core", "MoltenCore", 60 }, { "Onyxia's Lair", "OnyxiasLair", 60 }, { "Blackwing Lair", "BlackwingLair", 60 },
    { "Ruins of Ahn'Qiraj", "RuinsOfAhnQiraj", 60 }, { "Temple of Ahn'Qiraj", "TempleOfAhnQiraj", 60 },
    { "Karazhan", "Karazhan", 70 }, { "Gruul's Lair", "GruulsLair", 70 }, { "Magtheridon's Lair", "MagtheridonsLair", 70 },
    { "Serpentshrine Cavern", "SerpentshrineCavern", 70 }, { "Tempest Keep", "TempestKeep", 70 }, { "Black Temple", "BlackTemple", 70 },
    { "Naxxramas", "Naxxramas", 80 }, { "The Eye of Eternity", "TheEyeOfEternity", 80 }, { "Ulduar", "Ulduar", 80 },
    { "Trial of the Crusader", "TrialOfTheCrusader", 80 }, { "Icecrown Citadel", "IcecrownCitadel", 80 }, { "Ruby Sanctum", "RubySanctum", 80 },
}

local function makeButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, height); button:SetText(text)
    return button
end

local function teleport(name)
    if name and name ~= "" then SendChatMessage(".tele " .. name, "SAY") end
end

local function capitalFor(key)
    local values = {}
    for _, capital in ipairs(CAPITALS) do if capital[3] == key then table.insert(values, capital) end end
    return values
end

function T:Message(text) if self.status then self.status:SetText(text or "") end end

function T:SetBreadcrumb(text)
    self.breadcrumb:SetText("World" .. (text and text ~= "" and ("  >  " .. text) or ""))
end

function T:ClearPins()
    for _, pin in ipairs(self.pins or {}) do pin:Hide() end
    self.pins = {}
end

function T:ClearZoneButtons()
    for _, button in ipairs(self.zoneButtons or {}) do button:Hide() end
    self.zoneButtons = {}
end

function T:MapPoint(continent, x, y)
    if not continent or not continent.bounds or not x or not y then return end
    local minX, maxX, minY, maxY = unpack(continent.bounds)
    return (y - minY) / (maxY - minY), (maxX - x) / (maxX - minX)
end

function T:AddPin(item, labeled, bounds, red)
    local continent = CONTINENTS[self.continentKey]
    if not continent or item.mapId ~= continent.mapId then return end
    local pointSource = bounds and { bounds = bounds } or continent
    local px, py = self:MapPoint(pointSource, item.x, item.y)
    if not px or px < 0 or px > 1 or py < 0 or py > 1 then return end
    local pin = CreateFrame("Button", nil, self.mapContent)
    pin:SetSize(labeled and 145 or 22, labeled and 24 or 22)
    pin:SetPoint("CENTER", self.mapContent, "TOPLEFT", px * self.mapWidth, -py * self.mapHeight)
    local glow = pin:CreateTexture(nil, "ARTWORK"); glow:SetSize(labeled and 24 or 21, labeled and 24 or 21); glow:SetPoint("LEFT")
    glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border"); glow:SetBlendMode("ADD"); glow:SetVertexColor(red and 1 or 1, red and .08 or .78, red and .08 or .1, 1)
    local dot = pin:CreateTexture(nil, "OVERLAY"); dot:SetSize(labeled and 17 or 15, labeled and 17 or 15); dot:SetPoint("CENTER", glow)
    dot:SetTexture("Interface\\Minimap\\POIIcons"); dot:SetTexCoord(0, .125, 0, .125)
    if labeled then
        local label = pin:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", glow, "RIGHT", 3, 0); label:SetText(item.label or item.name); label:SetJustifyH("LEFT")
        label:SetShadowColor(0, 0, 0, 1); label:SetShadowOffset(1, -1)
    end
    pin:SetScript("OnClick", function() teleport(item.tele or item.name) end)
    pin:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(item.label or item.name); GameTooltip:AddLine("Click to teleport", .4, 1, .4); GameTooltip:Show()
    end)
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    table.insert(self.pins, pin)
end


function T:AddZoneHotspot(name, zone)
    local continent = CONTINENTS[self.continentKey]
    local minX, maxX, minY, maxY = unpack(zone.bounds)
    local left, top = self:MapPoint(continent, maxX, minY)
    local right, bottom = self:MapPoint(continent, minX, maxY)
    if not left or not right then return end
    local button = CreateFrame("Button", nil, self.mapContent)
    button:SetPoint("TOPLEFT", self.mapContent, "TOPLEFT", left * self.mapWidth, -top * self.mapHeight)
    button:SetSize(math.max(24, (right - left) * self.mapWidth), math.max(20, (bottom - top) * self.mapHeight))
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    button:SetBackdropColor(1, .75, .05, 0); button:SetBackdropBorderColor(1, .75, .05, 0)
    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(1, .75, .05, .10); self:SetBackdropBorderColor(1, .75, .05, 1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(name); GameTooltip:AddLine("Click to open this zone", .4, 1, .4); GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self) self:SetBackdropColor(1, .75, .05, 0); self:SetBackdropBorderColor(1, .75, .05, 0); GameTooltip:Hide() end)
    button:SetScript("OnClick", function() T:ShowZone(name) end)
    table.insert(self.zoneButtons, button)
end

function T:AcquireMapTextures(continent, zoneName)
    local textures = {}
    if continent and continent.uiIndex and SetMapZoom then
        local oldContinent = GetCurrentMapContinent and GetCurrentMapContinent()
        local oldZone = GetCurrentMapZone and GetCurrentMapZone()
        local zoneIndex
        if zoneName and GetMapZones then
            local zones = { GetMapZones(continent.uiIndex) }
            for index, name in ipairs(zones) do if name == zoneName then zoneIndex = index; break end end
        end
        SetMapZoom(continent.uiIndex, zoneIndex or 0)
        if WorldMapFrame_Update then WorldMapFrame_Update() end
        for index = 1, 12 do
            local source = _G["WorldMapDetailTile" .. index]
            textures[index] = source and source:GetTexture()
        end
        if oldContinent and oldContinent > 0 then SetMapZoom(oldContinent, oldZone or 0) elseif SetMapToCurrentZone then SetMapToCurrentZone() end
    end
    return textures
end

function T:RenderMap()
    local continent = CONTINENTS[self.continentKey]
    self:ClearPins(); self:ClearZoneButtons()
    if not continent then
        for _, tile in ipairs(self.mapTiles) do tile:Hide() end
        self.mapHint:SetText("Choose a continent"); self.mapHint:Show(); return
    end
    self.mapHint:Hide()
    local oldWidth, oldHeight = self.mapWidth or VIEW_W, self.mapHeight or VIEW_H
    local oldX, oldY = self.mapScroll:GetHorizontalScroll(), self.mapScroll:GetVerticalScroll()
    local centerX, centerY = (oldX + VIEW_W / 2) / oldWidth, (oldY + VIEW_H / 2) / oldHeight
    self.mapWidth, self.mapHeight = VIEW_W * self.zoom, VIEW_H * self.zoom
    self.mapContent:SetSize(self.mapWidth, self.mapHeight)
    local zone = self.selectedZone and ZONE_VIEWS[self.selectedZone]
    local textures = self:AcquireMapTextures(continent, zone and (zone.mapName or self.selectedZone))
    for index, tile in ipairs(self.mapTiles) do
        local column, row = (index - 1) % 4, math.floor((index - 1) / 4)
        local sourceWidth, sourceHeight = column == 3 and 234 or 256, row == 2 and 156 or 256
        local x = (math.min(column, 3) * 256) * self.mapWidth / 1002
        local y = (math.min(row, 2) * 256) * self.mapHeight / 668
        tile:ClearAllPoints(); tile:SetSize(sourceWidth * self.mapWidth / 1002 + 1, sourceHeight * self.mapHeight / 668 + 1)
        tile:SetPoint("TOPLEFT", self.mapContent, "TOPLEFT", x, -y)
        tile:SetTexCoord(0, sourceWidth / 256, 0, sourceHeight / 256)
        tile:SetTexture(textures[index] or ("Interface\\WorldMap\\" .. continent.art .. "\\" .. continent.art .. index)); tile:Show()
    end
    self.mapScroll:SetHorizontalScroll(math.max(0, math.min(self.mapWidth - VIEW_W, centerX * self.mapWidth - VIEW_W / 2)))
    self.mapScroll:SetVerticalScroll(math.max(0, math.min(self.mapHeight - VIEW_H, centerY * self.mapHeight - VIEW_H / 2)))
    if zone then
        for _, destination in ipairs(zone.destinations) do
            self:AddPin({ label = destination[1], tele = destination[2], mapId = continent.mapId, x = destination[3], y = destination[4] }, true, zone.bounds, true)
        end
    else
        for _, capital in ipairs(capitalFor(self.continentKey)) do
            self:AddPin({ label = capital[1], tele = capital[2], mapId = continent.mapId, x = capital[4], y = capital[5] }, true)
        end
        if self.zoom >= 2 then
            for _, hub in ipairs(HUBS[self.continentKey] or {}) do
                self:AddPin({ label = hub[1], tele = hub[2], mapId = continent.mapId, x = hub[3], y = hub[4] }, true)
            end
        end
        for name, view in pairs(ZONE_VIEWS) do if view.continent == self.continentKey then self:AddZoneHotspot(name, view) end end
    end
    self.zoomText:SetText("Zoom " .. self.zoom .. "/3")
end

function T:SetZoom(value)
    self.zoom = math.max(1, math.min(3, tonumber(value) or 1))
    self:RenderMap()
end

function T:Display(entries, total, offset)
    self.displayItems, self.total, self.offset = entries or {}, total or #(entries or {}), offset or 0
    for index, row in ipairs(self.rows) do
        local item = self.displayItems[index]; row.item = item
        if item then
            local prefix = item.indent and string.rep("   ", item.indent) or ""
            row.name:SetText(prefix .. (item.header and "|cffffd100" or "") .. (item.arrow or "") .. item.label .. (item.header and "|r" or ""))
            row.detail:SetText(item.detail or "")
            if item.header then row:Disable() else row:Enable() end
            row:Show()
        else row:Hide() end
    end
    self.pageText:SetText(self.total > VISIBLE_ROWS and ((math.floor(self.offset / PAGE_SIZE) + 1) .. " / " .. math.max(1, math.ceil(self.total / PAGE_SIZE))) or "")
end

function T:ShowContinent(key)
    self.category, self.continentKey, self.selectedZone, self.zoom = "world", key, nil, 1
    local continent = CONTINENTS[key]; self:SetBreadcrumb(continent.label)
    local entries = { { label = continent.label:upper(), header = true }, { label = "CAPITALS", header = true } }
    for _, capital in ipairs(capitalFor(key)) do table.insert(entries, { label = capital[1], tele = capital[2], indent = 1, detail = "Capital" }) end
    table.insert(entries, { label = "REGIONS", header = true })
    for _, group in ipairs(REGIONS[key] or {}) do table.insert(entries, { label = group[1], group = group, arrow = "|cffffd100> |r", indent = 1, detail = "Region" }) end
    self:Display(entries); self:Message("Hover over a map region or choose one from the list"); self:RenderMap()
end

function T:ShowRegion(group)
    local continent = CONTINENTS[self.continentKey]
    self.zoom = 2; self:SetBreadcrumb(continent.label .. "  >  " .. group[1])
    local entries = { { label = "<  " .. continent.label, back = true }, { label = group[1]:upper(), header = true } }
    for _, zone in ipairs(group[2]) do
        if ZONE_VIEWS[zone] then table.insert(entries, { label = zone, zone = zone, indent = 1, detail = "Open map" }) end
    end
    self:Display(entries); self:Message("Choose a zone to show specific teleport destinations"); self:RenderMap()
end

function T:ShowZone(name)
    local zone = ZONE_VIEWS[name]
    if not zone then return self:Request(name, 0) end
    self.continentKey, self.selectedZone, self.zoom = zone.continent, name, 1
    local continent = CONTINENTS[self.continentKey]
    self:SetBreadcrumb(continent.label .. "  >  " .. name)
    local entries = { { label = "<  " .. continent.label, back = true }, { label = name:upper(), header = true } }
    for _, destination in ipairs(zone.destinations) do table.insert(entries, { label = destination[1], tele = destination[2], indent = 1, detail = destination == zone.destinations[1] and "Area" or "Town / hub" }) end
    self:Display(entries); self:Message("Select a red destination marker or use the list"); self:RenderMap()
end

function T:ShowWorld()
    self.category, self.continentKey, self.selectedZone, self.zoom = "world", nil, nil, 1; self:SetBreadcrumb(nil)
    local entries = { { label = "CONTINENTS", header = true } }
    for _, key in ipairs({ "ek", "kalimdor", "outland", "northrend" }) do table.insert(entries, { label = CONTINENTS[key].label, continent = key, arrow = ">  ", detail = "Open" }) end
    table.insert(entries, { label = "MAIN CAPITALS", header = true })
    for _, capital in ipairs(CAPITALS) do table.insert(entries, { label = capital[1], tele = capital[2], indent = 1 }) end
    self:Display(entries); self:Message("Choose a continent or category"); self:RenderMap()
end

function T:ShowInstances(kind, minimum, maximum)
    self.category, self.continentKey = kind, nil; self:SetBreadcrumb(kind == "dungeons" and "Dungeons" or "Raids")
    local level = UnitLevel("player") or 1; local entries = {}
    if kind == "dungeons" then
        if minimum then
            table.insert(entries, { label = "<  All level ranges", rangeHome = true })
            table.insert(entries, { label = minimum .. " - " .. maximum, header = true })
            for _, item in ipairs(DUNGEONS) do if item[3] <= maximum and item[4] >= minimum then table.insert(entries, { label = item[1], tele = item[2], indent = 1, detail = item[3] .. "-" .. item[4] }) end end
        else
            table.insert(entries, { label = "DUNGEONS BY LEVEL", header = true })
            local ranges = { { 15, 25 }, { 25, 35 }, { 35, 45 }, { 45, 60 }, { 60, 70 }, { 70, 80 } }
            for _, range in ipairs(ranges) do table.insert(entries, { label = range[1] .. " - " .. range[2], range = range, arrow = ">  ", detail = level >= range[1] and "" or "Above level" }) end
        end
        self:Message("Dungeon list by level; progression filtering still requires bridge data")
    else
        table.insert(entries, { label = "RAIDS", header = true })
        for _, item in ipairs(RAIDS) do if level >= item[3] - 10 then table.insert(entries, { label = item[1], tele = item[2], detail = "Level " .. item[3] }) end end
        self:Message("Raids near your current level")
    end
    self:Display(entries); self:RenderMap()
end

function T:Request(search, offset)
    local continent = CONTINENTS[self.continentKey]
    if not continent or not MultiBot.Comm or not MultiBot.Comm.RequestTeleports then self:Message("Teleport bridge unavailable"); return end
    self.pendingLabel = search or ""
    self.pendingSearch = self.pendingLabel:gsub("[^%w]", "")
    self.offset = math.max(0, tonumber(offset) or 0); self.loadingPins = nil
    self.search:SetText(self.pendingLabel); self.zoom = 3; self:RenderMap(); self:Message("Loading " .. self.pendingLabel .. "...")
    MultiBot.Comm.RequestTeleports(self.pendingSearch, continent.mapId, self.offset)
end

function T:LoadMapPins(key)
    local continent = CONTINENTS[key]
    if not continent or not MultiBot.Comm or not MultiBot.Comm.RequestTeleports then return end
    self.loadingPins, self.pinLoadKey, self.pinLoadItems = true, key, {}
    MultiBot.Comm.RequestTeleports("", continent.mapId, 0)
end

function T:Build()
    if self.frame then return self.frame end
    local frame = CreateFrame("Frame", "MultiBotTeleportBrowser", UIParent)
    frame:SetSize(1000, 660); frame:SetPoint("CENTER"); frame:SetFrameStrata("DIALOG"); frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end); frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 8, right = 8, top = 8, bottom = 8 } })
    frame:SetBackdropColor(0, 0, 0, .97)
    frame:Hide(); self.frame = frame
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); title:SetPoint("TOP", 0, -16); title:SetText("AzerothCore Teleport Browser")
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", -5, -5)
    self.search = CreateFrame("EditBox", nil, frame, "InputBoxTemplate"); self.search:SetSize(245, 25); self.search:SetPoint("TOPLEFT", 25, -47); self.search:SetAutoFocus(false)
    self.search:SetScript("OnEnterPressed", function(self) self:ClearFocus(); T:Request(self:GetText(), 0) end)
    local searchButton = makeButton(frame, "Search", 65, 25); searchButton:SetPoint("LEFT", self.search, "RIGHT", 7, 0); searchButton:SetScript("OnClick", function() T:Request(T.search:GetText(), 0) end)
    local back = makeButton(frame, "Back", 65, 25); back:SetPoint("LEFT", searchButton, "RIGHT", 10, 0); back:SetScript("OnClick", function() if T.continentKey then T:ShowContinent(T.continentKey) else T:ShowWorld() end end)
    local home = makeButton(frame, "Home", 65, 25); home:SetPoint("LEFT", back, "RIGHT", 7, 0); home:SetScript("OnClick", function() T:ShowWorld() end)
    self.breadcrumb = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal"); self.breadcrumb:SetPoint("TOPLEFT", 25, -82)
    local world = makeButton(frame, "WORLD", 95, 26); world:SetPoint("TOPLEFT", 25, -105); world:SetScript("OnClick", function() T:ShowWorld() end)
    local dungeons = makeButton(frame, "DUNGEONS", 105, 26); dungeons:SetPoint("LEFT", world, "RIGHT", 6, 0); dungeons:SetScript("OnClick", function() T:ShowInstances("dungeons") end)
    local raids = makeButton(frame, "RAIDS", 90, 26); raids:SetPoint("LEFT", dungeons, "RIGHT", 6, 0); raids:SetScript("OnClick", function() T:ShowInstances("raids") end)

    local leftPanel = CreateFrame("Frame", nil, frame); leftPanel:SetPoint("TOPLEFT", 18, -96); leftPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 365, 62)
    leftPanel:SetFrameLevel(frame:GetFrameLevel()); leftPanel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    leftPanel:SetBackdropColor(.015, .02, .025, .94); leftPanel:SetBackdropBorderColor(.55, .42, .18, 1)

    self.rows = {}
    for index = 1, VISIBLE_ROWS do
        local row = CreateFrame("Button", nil, frame); row:SetSize(330, 22); row:SetPoint("TOPLEFT", 25, -141 - (index - 1) * 22); row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); row.name:SetPoint("LEFT", 5, 0); row.name:SetWidth(245); row.name:SetJustifyH("LEFT")
        row.detail = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); row.detail:SetPoint("RIGHT", -4, 0)
        row:SetScript("OnClick", function(self)
            local item = self.item; if not item then return end
            if item.tele then teleport(item.tele) elseif item.continent then T:ShowContinent(item.continent) elseif item.group then T:ShowRegion(item.group)
            elseif item.zone then T:ShowZone(item.zone) elseif item.search then T:Request(item.search, 0) elseif item.range then T:ShowInstances("dungeons", item.range[1], item.range[2]) elseif item.rangeHome then T:ShowInstances("dungeons") elseif item.back then T:ShowContinent(T.continentKey) end
        end)
        self.rows[index] = row
    end

    self.mapScroll = CreateFrame("ScrollFrame", nil, frame); self.mapScroll:SetSize(VIEW_W, VIEW_H); self.mapScroll:SetPoint("TOPRIGHT", -25, -105); self.mapScroll:EnableMouse(true); self.mapScroll:EnableMouseWheel(true)
    self.mapScroll:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } }); self.mapScroll:SetBackdropColor(.02, .03, .05, 1)
    self.mapContent = CreateFrame("Frame", nil, self.mapScroll); self.mapContent:SetSize(VIEW_W, VIEW_H); self.mapScroll:SetScrollChild(self.mapContent)
    self.mapTiles = {}
    for index = 1, 12 do local tile = self.mapContent:CreateTexture(nil, "BACKGROUND"); self.mapTiles[index] = tile end
    self.mapHint = self.mapScroll:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); self.mapHint:SetPoint("CENTER"); self.mapHint:SetText("Choose a continent")
    self.pins, self.zoneButtons = {}, {}; self.zoom = 1; self.mapWidth, self.mapHeight = VIEW_W, VIEW_H
    self.mapScroll:SetScript("OnMouseWheel", function(_, delta) T:SetZoom(T.zoom + (delta > 0 and 1 or -1)) end)
    self.mapScroll:SetScript("OnMouseDown", function(self)
        local scale = UIParent:GetEffectiveScale(); local x, y = GetCursorPosition(); T.dragX, T.dragY = x / scale, y / scale; T.dragH, T.dragV = self:GetHorizontalScroll(), self:GetVerticalScroll(); T.dragging = true
    end)
    self.mapScroll:SetScript("OnMouseUp", function() T.dragging = nil end)
    self.mapScroll:SetScript("OnUpdate", function(self)
        if not T.dragging then return end
        local scale = UIParent:GetEffectiveScale(); local x, y = GetCursorPosition(); x, y = x / scale, y / scale
        self:SetHorizontalScroll(math.max(0, math.min(T.mapWidth - VIEW_W, T.dragH - (x - T.dragX))))
        self:SetVerticalScroll(math.max(0, math.min(T.mapHeight - VIEW_H, T.dragV + (y - T.dragY))))
    end)
    local zoomOut = makeButton(frame, "-", 28, 24); zoomOut:SetPoint("TOPRIGHT", self.mapScroll, "TOPRIGHT", -9, -10); zoomOut:SetScript("OnClick", function() T:SetZoom(T.zoom - 1) end)
    local zoomIn = makeButton(frame, "+", 28, 24); zoomIn:SetPoint("TOPRIGHT", zoomOut, "BOTTOMRIGHT", 0, -4); zoomIn:SetScript("OnClick", function() T:SetZoom(T.zoom + 1) end)
    self.zoomText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); self.zoomText:SetPoint("TOPRIGHT", zoomIn, "BOTTOMRIGHT", 0, -5); self.zoomText:SetText("Zoom 1/3")
    local previous = makeButton(frame, "Previous", 75, 24); previous:SetPoint("BOTTOMLEFT", 25, 25); previous:SetScript("OnClick", function() if T.offset > 0 then T:Request(T.pendingSearch, math.max(0, T.offset - PAGE_SIZE)) end end)
    local nextButton = makeButton(frame, "Next", 75, 24); nextButton:SetPoint("LEFT", previous, "RIGHT", 7, 0); nextButton:SetScript("OnClick", function() if T.offset + PAGE_SIZE < T.total then T:Request(T.pendingSearch, T.offset + PAGE_SIZE) end end)
    self.pageText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal"); self.pageText:SetPoint("LEFT", nextButton, "RIGHT", 10, 0)
    self.status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); self.status:SetPoint("BOTTOMRIGHT", -25, 31); self.status:SetWidth(610); self.status:SetJustifyH("RIGHT")
    return frame
end

function T:Toggle()
    local frame = self:Build()
    if frame:IsShown() then frame:Hide() else frame:Show(); self:ShowWorld() end
end

function MultiBot.OnBridgeTeleports(result)
    if T.loadingPins then
        if T.pinLoadKey ~= T.continentKey then T.loadingPins = nil; return end
        for _, item in ipairs(result.items or {}) do table.insert(T.pinLoadItems, item) end
        local nextOffset = (result.offset or 0) + (result.pageSize or 40)
        if nextOffset < (result.total or 0) and nextOffset < 240 then
            MultiBot.Comm.RequestTeleports("", CONTINENTS[T.pinLoadKey].mapId, nextOffset)
        else
            T.serverItems, T.loadingPins = T.pinLoadItems, nil; T:RenderMap()
        end
        return
    end
    T.serverItems = result.items or {}; local entries = { { label = (T.pendingLabel or "DESTINATIONS"):upper(), header = true } }
    for _, item in ipairs(T.serverItems) do table.insert(entries, { label = item.name, tele = item.name, detail = "Teleport" }) end
    T:Display(entries, result.total, result.offset); T:Message((result.total or #entries) .. " matching destinations"); T:RenderMap()
end

function MultiBot.OnBridgeTeleportsError(reason)
    T:Message(reason == "UNAUTHORIZED" and "Your account cannot use .tele" or ("Teleport error: " .. tostring(reason)))
end

function MultiBot.InitializeTeleportBrowser() return T:Build() end
