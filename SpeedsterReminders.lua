local addon, ns = ...

local bar, handle, dragging, preview
local slots = {}
local ready = {}
local entries = {
    { key = "stopwatch", name = "Nifty Stopwatch", texture = "Interface\\Icons\\INV_Misc_PocketWatch_01" },
    { key = "dash", name = "Dash", texture = "Interface\\Icons\\Ability_Druid_Dash" },
}

-- Buffsmith's informational icons and fixed top-left grip.
local IDLE = { 0.49, 0.35, 0.13, 0.96 }
local HOVER = { 0.78, 0.59, 0.20, 1 }
local X = { LEFT = 0, TOPLEFT = 0, BOTTOMLEFT = 0, CENTER = 0.5, TOP = 0.5, BOTTOM = 0.5,
    RIGHT = 1, TOPRIGHT = 1, BOTTOMRIGHT = 1 }
local Y = { BOTTOM = 0, BOTTOMLEFT = 0, BOTTOMRIGHT = 0, CENTER = 0.5, LEFT = 0.5, RIGHT = 0.5,
    TOP = 1, TOPLEFT = 1, TOPRIGHT = 1 }

local function coordinate(value)
    return type(value) == "number" and math.abs(value) < math.huge
end

local function applyPosition()
    local saved = ns.db.movement_reminder_point
    local relative, x, y = "CENTER", -22, 115
    if type(saved) == "table" and X[saved[1]] and coordinate(saved[2]) and coordinate(saved[3]) then
        relative, x, y = unpack(saved)
    end
    bar:ClearAllPoints()
    bar:SetPoint("TOPLEFT", UIParent, relative, x, y)
end

local function closeTooltip(self)
    if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
end

local function finishDrag()
    if not dragging then return end
    dragging = nil
    bar:StopMovingOrSizing()
    if bar.SetUserPlaced then bar:SetUserPlaced(false) end
    local point, _, relative, x, y = bar:GetPoint()
    if X[point] and X[relative] and coordinate(x) and coordinate(y) then
        ns.db.movement_reminder_point = { relative, x - X[point] * bar:GetWidth(),
            y + (1 - Y[point]) * bar:GetHeight() }
    end
    applyPosition()
end

local function createBar()
    bar = CreateFrame("Frame", addon .. "MovementReminderBar", UIParent)
    bar:SetMovable(true)
    applyPosition()
    for _, entry in ipairs(entries) do
        local slot = CreateFrame("Button", addon .. "MovementReminder" .. entry.name:gsub("%s", ""), bar)
        if slot.SetMouseClickEnabled then slot:SetMouseClickEnabled(false) end
        local icon = slot:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexture(entry.texture)
        slot:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(entry.name)
            GameTooltip:AddLine(preview and "Movement reminder preview." or "Ready. Use your speed key.", 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end)
        slot:SetScript("OnLeave", closeTooltip)
        slot:SetScript("OnHide", closeTooltip)
        slots[entry.key] = slot
    end

    handle = CreateFrame("Button", addon .. "MovementReminderHandle", bar, "BackdropTemplate")
    handle:SetSize(12, 10)
    handle:SetFrameLevel(bar:GetFrameLevel() + 10)
    handle:SetPoint("BOTTOMLEFT", bar, "TOPLEFT", 0, 2)
    handle:RegisterForDrag("LeftButton")
    handle:RegisterForClicks("RightButtonUp")
    handle:EnableMouse(true)
    handle:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    handle:SetBackdropColor(unpack(IDLE))
    handle:SetBackdropBorderColor(0.08, 0.06, 0.02, 1)
    local dots = handle:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    dots:SetPoint("CENTER", 0, 1)
    dots:SetText(":")
    handle:SetScript("OnDragStart", function()
        if InCombatLockdown() then return end
        dragging = true
        bar:StartMoving()
    end)
    handle:SetScript("OnDragStop", function()
        finishDrag()
        ns.renderMovementReminders()
    end)
    handle:SetScript("OnClick", function(_, button)
        if button ~= "RightButton" then return end
        local menu = ns.HammerCore.Minimap
        if menu.RightClickMode and menu.RightClickMode() == "menu" then
            menu:OpenMenu(handle)
        else
            ns.HammerCore.Settings:Show("Visibility")
        end
    end)
    handle:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(HOVER))
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Speedster")
        GameTooltip:AddLine("Drag: move the bar", 0.85, 0.85, 0.85)
        local menu = ns.HammerCore.Minimap
        local action = menu.RightClickMode and menu.RightClickMode() == "menu" and "menu" or "open settings"
        GameTooltip:AddLine("Right-click: " .. action, 0.85, 0.85, 0.85)
        GameTooltip:Show()
    end)
    local function restoreHandle(self)
        self:SetBackdropColor(unpack(IDLE))
        closeTooltip(self)
    end
    handle:SetScript("OnLeave", restoreHandle)
    handle:SetScript("OnHide", restoreHandle)
end

function ns.renderMovementReminders(stopwatch, dash)
    if not ns.db then return end
    if stopwatch ~= nil then ready.stopwatch, ready.dash = stopwatch, dash end
    if InCombatLockdown() then
        preview = nil
        if bar then finishDrag(); bar:Hide() end
        return
    end
    if dragging then return end
    if not bar and not (preview or ready.stopwatch or ready.dash) then return end
    if not bar then createBar() end
    local strata = preview and "FULLSCREEN_DIALOG" or "MEDIUM"
    if bar.reminderStrata ~= strata then
        bar:SetFrameStrata(strata)
        bar.reminderStrata = strata
    end

    local size = ns.db.movement_reminder_size
    local horizontal = ns.db.movement_reminder_horizontal
    local count = 0
    for _, entry in ipairs(entries) do
        local slot = slots[entry.key]
        local shown = not not (preview or ready[entry.key])
        if shown then
            local offset = count * (size + 6)
            local x, y = 2 + (horizontal and offset or 0), -2 - (horizontal and 0 or offset)
            if x ~= slot.x or y ~= slot.y or size ~= slot.size then
                slot:ClearAllPoints()
                slot:SetPoint("TOPLEFT", bar, "TOPLEFT", x, y)
                slot:SetSize(size, size)
                slot.x, slot.y, slot.size = x, y, size
            end
            count = count + 1
        end
        if slot:IsShown() ~= shown then slot:SetShown(shown) end
    end
    local span = size + math.max(0, count - 1) * (size + 6)
    local width, height = (horizontal and span or size) + 4, (horizontal and size or span) + 4
    if width ~= bar:GetWidth() or height ~= bar:GetHeight() then bar:SetSize(width, height) end
    local showHandle = preview or ns.db.show_movement_reminder_handle
    if handle:IsShown() ~= showHandle then handle:SetShown(showHandle) end
    if bar:IsShown() ~= (count > 0) then bar:SetShown(count > 0) end
end

function ns.toggleMovementReminderPreview()
    preview = not preview
    ns.renderMovementReminders()
end

function ns.resetMovementReminderPosition()
    if dragging then finishDrag() end
    ns.db.movement_reminder_point = nil
    if bar then applyPosition() end
end
