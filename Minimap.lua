local addonName, addon = ...
local icon

local function position()
    local angle = math.rad(ChatCharacterMapDB.minimapAngle or 220)
    icon:ClearAllPoints()
    icon:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(angle) * (Minimap:GetWidth() / 2 + 8),
        math.sin(angle) * (Minimap:GetHeight() / 2 + 8))
end

function addon.UpdateMinimap()
    if icon then
        icon:SetShown(not ChatCharacterMapDB.hideMinimap)
        position()
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, _, name)
    if name ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")
    addon.Initialize()
    if not Minimap then return end
    icon = CreateFrame("Button", "ChatCharacterMapMinimapButton", Minimap)
    icon:SetSize(32, 32)
    icon:SetFrameStrata("MEDIUM")
    icon:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    icon:SetNormalTexture("Interface\\Icons\\INV_Misc_Book_09")
    icon:GetNormalTexture():SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    icon:RegisterForClicks("LeftButtonUp")
    icon:RegisterForDrag("LeftButton")
    icon:SetScript("OnClick", addon.Toggle)
    icon:SetScript("OnDragStart", function(self)
        GameTooltip:Hide()
        self:SetScript("OnUpdate", function()
            local x, y = GetCursorPosition()
            local cx, cy = Minimap:GetCenter()
            local scale = Minimap:GetEffectiveScale()
            ChatCharacterMapDB.minimapAngle = math.deg(math.atan2(y / scale - cy, x / scale - cx))
            position()
        end)
    end)
    icon:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    icon:SetScript("OnHide", function(self) self:SetScript("OnUpdate", nil); GameTooltip:Hide() end)
    icon:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Chat Character Map")
        GameTooltip:AddLine("Click to open. Drag to move.", 1, 1, 1)
        GameTooltip:AddLine("Hide the icon in the character map window.", 1, 1, 1)
        GameTooltip:Show()
    end)
    icon:SetScript("OnLeave", function() GameTooltip:Hide() end)
    addon.UpdateMinimap()
end)
