local addonName, addon = ...
local icons

function addon.UpdateMinimap()
    if not icons then return end
    ChatCharacterMapDB.minimap.hide = not not ChatCharacterMapDB.hideMinimap
    icons:Refresh(addonName, ChatCharacterMapDB.minimap)
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, _, name)
    if name ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")
    addon.Initialize()
    if not Minimap then return end
    icons = LibStub("LibDBIcon-1.0")
    if type(ChatCharacterMapDB.minimap) ~= "table" then
        ChatCharacterMapDB.minimap = {
            minimapPos = ChatCharacterMapDB.minimapAngle or 220,
        }
    end
    ChatCharacterMapDB.minimap.hide = not not ChatCharacterMapDB.hideMinimap
    local launcher = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
        type = "launcher",
        text = "Chat Character Map",
        icon = "Interface\\Icons\\INV_Misc_Book_09",
        OnClick = function(_, button)
            if button == "LeftButton" then addon.Toggle() end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("Chat Character Map")
            tooltip:AddLine("Click to open. Drag to move around the map.", 1, 1, 1)
            tooltip:AddLine("Hide the icon in the character map window.", 1, 1, 1)
        end,
    })
    icons:Register(addonName, launcher, ChatCharacterMapDB.minimap)
    -- Centre the face on the visible hole in the 64px tracking-ring texture.
    do
        local button = icons:GetMinimapButton(addonName)
        if button and button.border and button.icon then
            local x, y = button.border:GetWidth() * 20 / 64, -button.border:GetHeight() * 19 / 64
            -- Fill the tracking ring's opening; keep its border and hit area standard.
            local faceSize = button.border:GetWidth() * 26 / 64
            button.icon:SetSize(faceSize, faceSize)
            if not button.foreverFaceMask then
                local mask = button:CreateMaskTexture(nil, "ARTWORK")
                mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                mask:SetAllPoints(button.icon)
                button.icon:AddMaskTexture(mask)
                button.foreverFaceMask = mask
            end
            button.icon:ClearAllPoints()
            button.icon:SetPoint("CENTER", button.border, "TOPLEFT", x, y)
            if button.background then
                button.background:ClearAllPoints()
                button.background:SetPoint("CENTER", button.border, "TOPLEFT", x, y)
            end
        end
    end
end)
