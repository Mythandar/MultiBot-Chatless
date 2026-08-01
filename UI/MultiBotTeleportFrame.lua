if not MultiBot then return end
local T = MultiBot.TeleportBrowser or { items = {}, offset = 0, total = 0, mapIndex = 1 }
MultiBot.TeleportBrowser = T
local MAPS = {
 {"All", nil}, {"Eastern Kingdoms", 0, -15000, 4000, -5000, 15000},
 {"Kalimdor", 1, -12000, 8000, -8000, 8000}, {"Outland", 530, -7000, 6000, -7000, 6000},
 {"Northrend", 571, -6000, 9000, -7000, 6000},
}
local PAGE, ROWS = 18, 18
local function store()
 MultiBotGlobalSave = MultiBotGlobalSave or {}
 MultiBotGlobalSave.TeleportBrowser = MultiBotGlobalSave.TeleportBrowser or { favorites = {}, recent = {} }
 return MultiBotGlobalSave.TeleportBrowser
end
local function find(list, name) for i, value in ipairs(list or {}) do if value == name then return i end end end
local function remember(name)
 local list = store().recent; local i = find(list, name); if i then table.remove(list, i) end
 table.insert(list, 1, name); while #list > 15 do table.remove(list) end
end
local function go(name) if name and name ~= "" then remember(name); SendChatMessage(".tele " .. name, "SAY") end end
local function favorite(name)
 local list = store().favorites; local i = find(list, name)
 if i then table.remove(list, i) else table.insert(list, name) end
end
local function button(parent, label, width, height)
 local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate"); b:SetSize(width, height); b:SetText(label); return b
end
function T:Message(text) if self.status then self.status:SetText(text or "") end end
function T:ClearPins() for _, pin in ipairs(self.pins or {}) do pin:Hide() end self.pins = {} end
function T:DrawPins()
 self:ClearPins(); local m = MAPS[self.mapIndex]; if not m or not m[3] then return end
 for _, item in ipairs(self.items) do
  if item.mapId == m[2] then
   local px, py = (item.y - m[5]) / (m[6] - m[5]), (m[4] - item.x) / (m[4] - m[3])
   if px >= 0 and px <= 1 and py >= 0 and py <= 1 then
    local p = CreateFrame("Button", nil, self.canvas); p:SetSize(12, 12)
    p:SetPoint("CENTER", self.canvas, "BOTTOMLEFT", 8 + px * 334, 8 + py * 362)
    local tex = p:CreateTexture(nil, "ARTWORK"); tex:SetAllPoints(); tex:SetTexture("Interface\\Minimap\\POIIcons"); tex:SetTexCoord(0, .125, 0, .125)
    p:SetScript("OnClick", function() go(item.name) end)
    p:SetScript("OnEnter", function(x) GameTooltip:SetOwner(x, "ANCHOR_RIGHT"); GameTooltip:SetText(item.name); GameTooltip:AddLine("Click to teleport", .4, 1, .4); GameTooltip:Show() end)
    p:SetScript("OnLeave", function() GameTooltip:Hide() end); table.insert(self.pins, p)
   end
  end
 end
end
function T:Refresh()
 for i, row in ipairs(self.rows) do
  local item = self.items[i]; row.item = item
  if item then row.name:SetText(item.name); row.map:SetText(item.mapId and "Map " .. item.mapId or ""); row.star:SetText(find(store().favorites, item.name) and "|cffffd100*|r" or "*"); row:Show() else row:Hide() end
 end
 self.page:SetText((math.floor(self.offset / PAGE) + 1) .. " / " .. math.max(1, math.ceil(self.total / PAGE))); self:DrawPins()
end
function T:Local(kind)
 self.offset = 0; self.items = {}; local source = kind == "favorites" and store().favorites or store().recent
 for _, name in ipairs(source) do table.insert(self.items, {name=name}) end self.total=#self.items; self:Message(kind == "favorites" and "Favorites" or "Recent destinations"); self:Refresh()
end
function T:Request(offset)
 if not MultiBot.Comm or not MultiBot.Comm.RequestTeleports then self:Message("Teleport bridge unavailable"); return end
 self.offset = math.max(0, tonumber(offset) or 0); local map = MAPS[self.mapIndex]
 self:Message("Loading..."); if not MultiBot.Comm.RequestTeleports(self.search:GetText(), map[2], self.offset) then self:Message("Bridge unavailable") end
end
function T:Build()
 if self.frame then return self.frame end
 local f=CreateFrame("Frame","MultiBotTeleportBrowser",UIParent); f:SetSize(760,520); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG"); f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
 f:SetScript("OnDragStart",function(x)x:StartMoving()end); f:SetScript("OnDragStop",function(x)x:StopMovingOrSizing()end)
 f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}}); f:Hide(); self.frame=f
 local title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); title:SetPoint("TOP",0,-16); title:SetText("AzerothCore Teleport Browser")
 local close=CreateFrame("Button",nil,f,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",-5,-5)
 self.search=CreateFrame("EditBox",nil,f,"InputBoxTemplate"); self.search:SetSize(250,24); self.search:SetPoint("TOPLEFT",24,-48); self.search:SetAutoFocus(false); self.search:SetScript("OnEnterPressed",function(x)x:ClearFocus();T:Request(0)end)
 local search=button(f,"Search",70,24); search:SetPoint("LEFT",self.search,"RIGHT",8,0); search:SetScript("OnClick",function()T:Request(0)end)
 local fav=button(f,"Favorites",80,24); fav:SetPoint("TOPLEFT",380,-48); fav:SetScript("OnClick",function()T:Local("favorites")end)
 local recent=button(f,"Recent",70,24); recent:SetPoint("LEFT",fav,"RIGHT",6,0); recent:SetScript("OnClick",function()T:Local("recent")end)
 local previous
 for i,m in ipairs(MAPS) do local b=button(f,m[1],i==1 and 44 or 105,22); if previous then b:SetPoint("LEFT",previous,"RIGHT",3,0)else b:SetPoint("TOPLEFT",24,-80)end; b:SetScript("OnClick",function()T.mapIndex=i;T:Request(0)end);previous=b end
 self.rows={}
 for i=1,ROWS do
  local row=CreateFrame("Button",nil,f);row:SetSize(340,21);row:SetPoint("TOPLEFT",24,-112-(i-1)*21);row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
  row.star=CreateFrame("Button",nil,row);row.star:SetSize(20,20);row.star:SetPoint("LEFT");row.star:SetNormalFontObject("GameFontNormal");row.star:SetText("*");row.star:SetScript("OnClick",function()if row.item then favorite(row.item.name);T:Refresh()end end)
  row.name=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");row.name:SetPoint("LEFT",22,0);row.name:SetWidth(240);row.name:SetJustifyH("LEFT")
  row.map=row:CreateFontString(nil,"OVERLAY","GameFontDisableSmall");row.map:SetPoint("RIGHT",-4,0);row:SetScript("OnClick",function(x)if x.item then go(x.item.name)end end);self.rows[i]=row
 end
 self.canvas=CreateFrame("Frame",nil,f);self.canvas:SetSize(350,378);self.canvas:SetPoint("TOPRIGHT",-24,-112);self.canvas:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12,insets={left=3,right=3,top=3,bottom=3}});self.canvas:SetBackdropColor(.04,.10,.16,.92)
 local mt=self.canvas:CreateFontString(nil,"BACKGROUND","GameFontNormalLarge");mt:SetPoint("CENTER");mt:SetText("Destination map");mt:SetTextColor(.2,.35,.45)
 local prev=button(f,"Previous",80,24);prev:SetPoint("BOTTOMLEFT",24,20);prev:SetScript("OnClick",function()if T.offset>0 then T:Request(T.offset-PAGE)end end)
 local nxt=button(f,"Next",80,24);nxt:SetPoint("LEFT",prev,"RIGHT",8,0);nxt:SetScript("OnClick",function()if T.offset+PAGE<T.total then T:Request(T.offset+PAGE)end end)
 self.page=f:CreateFontString(nil,"OVERLAY","GameFontNormal");self.page:SetPoint("LEFT",nxt,"RIGHT",12,0)
 self.status=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");self.status:SetPoint("BOTTOMRIGHT",-24,26);self.status:SetWidth(350);self.status:SetJustifyH("RIGHT");return f
end
function T:Toggle() local f=self:Build();if f:IsShown()then f:Hide()else f:Show();self:Request(0)end end
function MultiBot.OnBridgeTeleports(result) T.items=result.items or {};T.total=result.total or #T.items;T.offset=result.offset or 0;T:Message(T.total.." destinations found");T:Refresh()end
function MultiBot.OnBridgeTeleportsError(reason)T:Message(reason=="UNAUTHORIZED" and "Your account cannot use .tele" or "Teleport error: "..tostring(reason))end
function MultiBot.InitializeTeleportBrowser()return T:Build()end
