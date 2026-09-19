local _, addon = ...
local entries = addon.characters
local window, search, composer, detail, copyBox, pageLabel, favoriteButton
local cells, filters, matches = {}, {}, {}
local category, page, selected = "All", 1, entries[1]
local pageSize = 60
local categories = {"All", "Favorites", "Symbols", "Letters", "Arrows", "Math", "Raid marks"}
local refresh
local fontPath = "Fonts\\ARIALN.TTF"
local fontKey = "ARIALN.TTF"
local showAll = false

function addon.Initialize()
    if type(ChatCharacterMapDB) ~= "table" then ChatCharacterMapDB = {} end
    if type(ChatCharacterMapDB.favorites) ~= "table" then ChatCharacterMapDB.favorites = {} end
end

local function applyCharacterFont(region, size)
    region:SetFont(fontPath, size, "")
end

local function label(parent, text, x, y, template)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetText(text)
    return fs
end

local function button(parent, text, x, y, width, action)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 24)
    b:SetPoint("TOPLEFT", x, y)
    b:SetText(text)
    b:SetScript("OnClick", action)
    return b
end

local function edit(parent, x, y, width, maxBytes)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(width, 28)
    box:SetPoint("TOPLEFT", x, y)
    box:SetAutoFocus(false)
    box:SetMaxBytes(maxBytes)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    return box
end

local function code(entry)
    return entry.code or string.format("U+%04X", entry.cp)
end

local function selectEntry(entry, keepFocus)
    selected = entry
    local extra = entry.alt and ("Windows Western Alt+" .. entry.alt) or "No Windows Alt code listed"
    if entry.code then extra = "Type this token in WoW chat to show a raid icon." end
    detail:SetText(entry.name .. "\n" .. code(entry) .. "   |   " .. extra)
    copyBox:SetText(entry.text)
    if not keepFocus then
        copyBox:SetFocus()
        copyBox:HighlightText()
    end
    favoriteButton:SetText(ChatCharacterMapDB.favorites[entry.text] and "Unfavorite" or "Favorite")
end

refresh = function()
    wipe(matches)
    local query = string.lower(search:GetText() or ""):match("^%s*(.-)%s*$")
    for _, entry in ipairs(entries) do
        local inCategory = category == "All" or category == entry.category
            or (category == "Favorites" and ChatCharacterMapDB.favorites[entry.text])
        local haystack = string.lower(entry.name .. " " .. entry.text .. " " .. code(entry) .. " " .. (entry.alt or ""))
        local supported = not entry.cp or addon.fontCharacters[fontKey][entry.cp]
        if (showAll or supported) and inCategory and (query == "" or haystack:find(query, 1, true)) then
            matches[#matches + 1] = entry
        end
    end
    local pages = math.max(1, math.ceil(#matches / pageSize))
    page = math.min(page, pages)
    pageLabel:SetText(string.format("%d characters  |  Page %d / %d", #matches, page, pages))
    for i, cell in ipairs(cells) do
        local entry = matches[(page - 1) * pageSize + i]
        cell.entry = entry
        cell:SetShown(entry ~= nil)
        if entry then
            cell:SetText(entry.display or entry.text)
            applyCharacterFont(cell:GetFontString(), 20)
        end
    end
    for name, b in pairs(filters) do b:SetEnabled(name ~= category) end
    window.previous:SetEnabled(page > 1)
    window.next:SetEnabled(page < pages)
    applyCharacterFont(copyBox, 18)
    applyCharacterFont(composer, 16)
end

local function insertIntoChat(text, fallback)
    if text == "" then return end
    local util = ChatFrameUtil
    local active = (util and util.GetActiveWindow) or ChatEdit_GetActiveWindow
    local choose = (util and util.ChooseBoxForSend) or ChatEdit_ChooseBoxForSend
    local activate = (util and util.ActivateChat) or ChatEdit_ActivateChat
    local box = active and active()
    if not box and choose then box = choose() end
    if not box or not activate then
        fallback:SetFocus()
        fallback:HighlightText()
        detail:SetText("Chat insertion is unavailable. Press Ctrl+C, then paste into chat.")
        return
    end
    local limit = box.GetMaxBytes and box:GetMaxBytes() or 255
    if limit == 0 then limit = 255 end
    if #(box:GetText() or "") + #text > limit then
        detail:SetText("This text will not fit in the current chat box. Shorten it first.")
        return
    end
    composer:ClearFocus()
    copyBox:ClearFocus()
    search:ClearFocus()
    activate(box)
    box:HighlightText(0, 0)
    box:SetCursorPosition(#box:GetText())
    box:Insert(text)
end

local function createWindow()
    window = CreateFrame("Frame", "ChatCharacterMapFrame", UIParent, "BasicFrameTemplateWithInset")
    window:SetSize(720, 632)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        ChatCharacterMapDB.position = {point, relativePoint, x, y}
    end)
    local p = ChatCharacterMapDB.position
    if type(p) == "table" and type(p[1]) == "string" and type(p[2]) == "string"
        and type(p[3]) == "number" and type(p[4]) == "number" then
        window:ClearAllPoints()
        window:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    end
    window.TitleText:SetText("Chat Character Map")
    table.insert(UISpecialFrames, "ChatCharacterMapFrame")
    label(window, "Search by name, character, U+ code, or Alt code", 20, -40)
    search = edit(window, 24, -60, 670, 100)
    for i, name in ipairs(categories) do
        local filterName = name
        filters[name] = button(window, name, 18 + (i - 1) * 98, -98, 94, function()
            category, page = filterName, 1
            refresh()
        end)
    end
    for i = 1, pageSize do
        local cell = button(window, "", 20 + ((i - 1) % 10) * 68,
            -136 - math.floor((i - 1) / 10) * 34, 62, function(self, mouseButton)
                if mouseButton == "RightButton" then
                    selectEntry(self.entry, true)
                    insertIntoChat(self.entry.text, copyBox)
                else
                    selectEntry(self.entry)
                    if IsShiftKeyDown() then composer:Insert(self.entry.text) end
                end
            end)
        cell:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        cell:SetHeight(30)
        cell:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.entry.name)
            GameTooltip:AddLine(code(self.entry), 1, 1, 1)
            if self.entry.alt then GameTooltip:AddLine("Windows Western Alt+" .. self.entry.alt, 1, 1, 1) end
            GameTooltip:AddLine("Click to copy. Shift-click to add to your message.", 0.7, 0.8, 1, true)
            GameTooltip:AddLine("Right-click to insert directly into chat.", 0.7, 0.8, 1, true)
            GameTooltip:Show()
        end)
        cell:SetScript("OnLeave", function() GameTooltip:Hide() end)
        cells[i] = cell
    end
    window.previous = button(window, "Previous", 20, -344, 90, function() page = math.max(1, page - 1); refresh() end)
    pageLabel = label(window, "", 130, -350)
    window.next = button(window, "Next", 608, -344, 90, function() page = page + 1; refresh() end)
    button(window, "Font: Chat (Arial)", 20, -377, 175, function(self)
        if fontKey == "ARIALN.TTF" then
            fontKey, fontPath = "FRIZQT__.TTF", "Fonts\\FRIZQT__.TTF"
            self:SetText("Font: Buttons (Friz)")
        else
            fontKey, fontPath = "ARIALN.TTF", "Fonts\\ARIALN.TTF"
            self:SetText("Font: Chat (Arial)")
        end
        page = 1
        refresh()
    end)
    local all = CreateFrame("CheckButton", nil, window, "UICheckButtonTemplate")
    all:SetPoint("TOPLEFT", 210, -374)
    label(window, "Show unsupported characters", 244, -382, "GameFontHighlightSmall")
    all:SetScript("OnClick", function(self) showAll = self:GetChecked(); page = 1; refresh() end)
    detail = label(window, "", 20, -414, "GameFontHighlightSmall")
    detail:SetSize(675, 36)
    detail:SetJustifyH("LEFT")
    copyBox = edit(window, 24, -457, 260, 100)
    button(window, "Add to message", 306, -459, 145, function() composer:Insert(selected.text) end)
    favoriteButton = button(window, "Favorite", 466, -459, 110, function()
        local favorites = ChatCharacterMapDB.favorites
        favorites[selected.text] = not favorites[selected.text] or nil
        selectEntry(selected)
        refresh()
    end)
    button(window, "To chat", 586, -459, 112, function() insertIntoChat(selected.text, copyBox) end)
    label(window, "Message (Ctrl+C to copy, Ctrl+V to paste)", 20, -500)
    composer = edit(window, 24, -522, 670, 255)
    button(window, "Select message", 20, -559, 140, function() composer:SetFocus(); composer:HighlightText() end)
    button(window, "Insert into chat", 170, -559, 140, function() insertIntoChat(composer:GetText(), composer) end)
    button(window, "Clear", 320, -559, 80, function() composer:SetText("") end)
    local minimap = CreateFrame("CheckButton", nil, window, "UICheckButtonTemplate")
    minimap:SetPoint("TOPLEFT", 440, -555)
    minimap:SetChecked(not ChatCharacterMapDB.hideMinimap)
    label(window, "Minimap icon", 474, -563, "GameFontHighlightSmall")
    minimap:SetScript("OnClick", function(self)
        ChatCharacterMapDB.hideMinimap = not self:GetChecked()
        if addon.UpdateMinimap then addon.UpdateMinimap() end
    end)
    window:SetScript("OnShow", function() minimap:SetChecked(not ChatCharacterMapDB.hideMinimap) end)
    label(window, "Filtered to the selected client font. Other players' fonts may differ. Insertion does not send.", 20, -600, "GameFontHighlightSmall")
    search:SetScript("OnTextChanged", function() page = 1; refresh() end)
    window:SetScript("OnHide", function() search:ClearFocus(); composer:ClearFocus(); copyBox:ClearFocus(); GameTooltip:Hide() end)
    refresh()
    selectEntry(selected)
    copyBox:ClearFocus()
end

SLASH_CHATCHARACTERMAP1 = "/charmap"
SLASH_CHATCHARACTERMAP2 = "/ccmap"
SlashCmdList.CHATCHARACTERMAP = function(message)
    addon.Initialize()
    if message == "minimap" then
        ChatCharacterMapDB.hideMinimap = not ChatCharacterMapDB.hideMinimap
        if addon.UpdateMinimap then addon.UpdateMinimap() end
        return
    end
    if not window then createWindow()
    elseif message == "" then window:SetShown(not window:IsShown()) end
    if message and message ~= "" then
        window:Show()
        category = "All"
        search:SetText(message)
        refresh()
    end
end
addon.Toggle = function() SlashCmdList.CHATCHARACTERMAP("") end
