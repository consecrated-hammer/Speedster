local addon, ns = ...
local HC = ns.HammerCore
local UI, T = HC.UI, HC.Theme
local ADDON_ICON = "Interface\\AddOns\\Speedster\\textures\\Speedster"

-- Spellbook events must refresh hidden pages too: search reads their live rows.
function ns.refreshOptions()
    for _, page in pairs(HC.Settings.pages) do
        if page.hcRefreshAll then page.hcRefreshAll() end
    end
    if HC.Settings.searchBox and HC.Settings.searchBox:HasFocus() then HC.Settings:UpdateSearch() end
end

local function spellIcon(id)
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, icon = pcall(C_Spell.GetSpellTexture, id)
        if ok and icon then return icon end
    end
    if GetSpellTexture then
        local ok, icon = pcall(GetSpellTexture, id)
        if ok then return icon end
    end
end

-- Small sections reflow when an unavailable or dependent group disappears.
-- Search ownership stays on the page body, and hidden dependencies name their switch.
local function sections(panel, start)
    local groups = {}
    local function add(columns, parentRow, visible)
        local frame = CreateFrame("Frame", nil, panel)
        frame:SetWidth(UI.CONTENT_WIDTH + UI.PAD * 2)
        frame.hcHeaderOwner = panel.hcHeaderOwner or panel
        frame.hcRefresh, frame.hcRefreshAll = panel.hcRefresh, panel.hcRefreshAll
        frame.hcParentRow = parentRow
        UI.Columns(frame, columns)
        groups[#groups + 1] = { frame = frame, visible = visible }
        return frame, groups[#groups]
    end
    local function finish()
        local function layout()
            local y = start
            for _, group in ipairs(groups) do
                local shown = not group.visible or group.visible()
                group.frame:SetShown(shown)
                if shown then
                    group.frame:ClearAllPoints()
                    group.frame:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, y)
                    group.frame:SetHeight(group.height)
                    y = y - group.height - 8
                end
            end
            if panel.hcSetBottom then panel.hcSetBottom(y) end
            return y
        end
        UI.OnRefresh(panel, layout)
        return layout()
    end
    return add, finish
end

HC.Settings:NewPage({ name = "Speed", description = "Choose your movement preferences, then set a key on Key Bindings." }, function(panel, y)
    local add, finish = sections(panel, y)
    local setup, group = add(1)
    local sy = 0
    _, sy = UI.Header(setup, "Your speed key", sy, ADDON_ICON)
    _, sy = UI.Text(setup, "Press your speed key or click the floating button to use a known movement spell. Nothing casts automatically.", sy)
    local master
    master, sy = UI.Check(setup, "Enable speed macro", "Enable the primary speed key and floating-button action. Optional utility keys keep working independently. Changes made in combat apply when combat ends.", sy,
        function() return ns.db.enabled end,
        function(v) ns.db.enabled = v; ns.refreshSpeedButton() end)
    local link
    link, sy = UI.PageLink(setup, sy, "Choose your speed key", "Key Bindings")
    UI.AttachHint(link, "Choose your speed key", "Open Key Bindings to bind the primary Speed macro action. No key is assigned automatically.")
    UI.RegisterRow(setup, link, "Choose your speed key")
    group.height = -sy + 4

    local _, class = UnitClass("player")
    local classText = {
        DRUID = "Aquatic Form in water, Cat Form indoors, Travel Form outdoors and Flight Form where flying is allowed. Dash has its own optional key.",
        SHAMAN = "Your speed key uses Ghost Wolf. Water Walking has its own optional key.",
        HUNTER = "Your speed key uses Aspect of the Cheetah once learned. Aspect of the Pack has its own optional key.",
        ROGUE = "Your speed key uses Sprint once learned.",
        MAGE = "Your speed key uses Blink once learned. Slow Fall has its own optional key.",
    }
    local preferences, cg = add(2, master, function() return ns.db.enabled end)
    local cy = 0
    _, cy = UI.Header(preferences, "Class movement", cy, spellIcon(({ DRUID = 783, SHAMAN = 2645, HUNTER = 5118, ROGUE = 2983, MAGE = 1953 })[class]))
    _, cy = UI.Text(preferences, classText[class] or "This class has no primary speed spell. Learned utility actions can still have their own keys on Key Bindings.", cy)
    if class == "DRUID" or class == "SHAMAN" then
        local key = class == "DRUID" and "druid_use_travel" or "shaman_use_ghost_wolf"
        local function known()
            if class == "SHAMAN" then return ns.isSpellKnownSafe(2645) end
            return ns.isSpellKnownSafe(783) or ns.isSpellKnownSafe(33943) or ns.isSpellKnownSafe(40120)
        end
        local row
        row, cy = UI.Check(preferences, class == "DRUID" and "Use Travel Form outdoors" or "Use Ghost Wolf",
            class == "DRUID" and "Use Travel Form outdoors and Flight Form where allowed. Turn off to keep Aquatic Form in water and Cat Form elsewhere. Requires learned forms; a saved preference can always be turned off."
                or "Use learned Ghost Wolf on your speed key. Water Walking remains a separate utility action. A saved preference can always be turned off.", cy,
            function() return ns.db[key] end,
            function(v)
                if not ns.db.enabled or (not known() and not ns.db[key]) then return end
                ns.db[key] = v; ns.refreshSpeedButton()
            end)
        UI.OnRefresh(panel, function()
            row:SetShown(known() or ns.db[key])
            UI.SetEnabled(row.hcCheckbox, ns.db.enabled and (known() or ns.db[key]))
        end)
        cy = UI.Flush(preferences, cy)
        local note
        note, cy = UI.Text(preferences, "Not learned yet. Learn the form to enable it here; a saved preference is kept until you change it.", cy)
        UI.OnRefresh(panel, function() note:SetShown(not known()) end)
    end
    cg.height = -UI.Flush(preferences, cy) + 4

    local function racialAvailable() return ns.isSpellKnownSafe(1259416) or ns.db.walk_on_air_while_falling end
    local racial, rg = add(1, nil, function() return racialAvailable() and ns.db.enabled end)
    local ry = 0
    _, ry = UI.Header(racial, "Racial movement", ry, function() return spellIcon(1259416) end)
    local racialRow
    racialRow, ry = UI.Check(racial, "Walk on Air while falling", "Skyborne opt-in: press your normal speed key while falling outside combat. Falling alone never casts. A failed cast does not try your class spell on the same press. Ordinary movement and the separate racial key remain; combat keeps the secure class fallback.", ry,
        function() return ns.db.walk_on_air_while_falling end,
        function(v)
            if not ns.db.enabled or not racialAvailable() then return end
            ns.db.walk_on_air_while_falling = v; ns.refreshSpeedButton()
        end)
    UI.OnRefresh(panel, function()
        -- Unavailable racial rows have no search parent; a genuine dependency does.
        racial.hcParentRow = racialAvailable() and master or nil
        UI.SetEnabled(racialRow.hcCheckbox, ns.db.enabled and racialAvailable())
    end)
    rg.height = -ry + 4

    local inspect, ig = add(1)
    local iy = 0
    _, iy = UI.Header(inspect, "Current macro", iy, "Interface\\Icons\\INV_Misc_Note_01")
    _, iy = UI.Text(inspect, "Already applied to your speed key and floating button. No copy/paste needed. Changes in combat wait until combat ends.", iy)
    local macro = CreateFrame("EditBox", nil, inspect, "BackdropTemplate")
    macro:SetSize(UI.CONTENT_WIDTH - 24, 88)
    macro:SetPoint("TOPLEFT", UI.PAD + 12, iy)
    macro:SetAutoFocus(false)
    macro:SetMultiLine(true)
    macro:SetFontObject(ChatFontNormal)
    macro:SetTextInsets(8, 8, 8, 8)
    T.Surface(macro, "rail", "edge")
    local function macroText()
        if not ns.db.enabled then return "Speed macro disabled. Enable it above to use your speed key." end
        local text = ns.getMacro()
        return text ~= "" and text or "No speed macro yet for this class and level. Learn a supported spell or check your movement preferences."
    end
    local updating
    local function render()
        local text = macroText()
        if updating or macro:GetText() == text then return end
        updating = true
        macro:SetText(text)
        updating = false
    end
    macro:SetScript("OnTextChanged", render)
    macro:SetScript("OnEscapePressed", function(self) render(); self:ClearFocus() end)
    UI.AttachHint(macro, "Current macro", "Read-only generated movement macro; select to copy for inspection. Class conditions choose water, indoors, outdoors and flight. Walk on Air is prepared on each press outside combat; this view is refreshed with settings and spellbook changes.")
    UI.RegisterRow(inspect, macro, "Current macro")
    UI.OnRefresh(panel, render)
    render()
    ig.height = -iy + 96
    return finish()
end)

local function actionItems(includeUnavailable)
    local items = {}
    for _, action in ipairs(ns.getUtilityActions(includeUnavailable)) do
        items[#items + 1] = {
            id = action.bindingCommand, name = action.label,
            icon = spellIcon(action.spellName or action.spellID),
            detail = (action.warning or "Optional utility action; separate from your primary speed key.")
                .. (not action.spellName and " Not currently learned; you can remove its saved binding." or ""),
        }
    end
    return items
end
local function speedItem()
    return { id = ns.getPrimaryBindingCommand(), name = "Speed macro", icon = ADDON_ICON,
        detail = "Primary movement key: uses your Speed page preferences and known class spells. Optional utility keys are separate." }
end

HC.Settings:NewPage({ name = "Key Bindings", columns = 1, description = "Start with Speed macro. Extra movement keys are optional and independent." }, function(panel, y)
    return HC.Bindings.Page(panel, y, {
        inputs = { keys = true, mouse = true, wheel = true },
        empty = "No keys assigned. Choose Speed macro on the right to get started.",
        poolHint = "Click an action, then press a key, mouse button or wheel. Modifiers work too.",
        pool = function() return {
            { title = "Primary speed key", items = { speedItem() } },
            { title = "Optional utility keys", items = actionItems(), empty = "No extra movement spells learned yet." },
        } end,
        label = function(keys)
            if type(keys) ~= "table" then return HC.Bindings.Label(keys) end
            local labels = {}
            for _, key in ipairs(keys) do labels[#labels + 1] = HC.Bindings.Label(key) end
            return table.concat(labels, ", ")
        end,
        bound = function()
            local bound, all = {}, actionItems(true)
            table.insert(all, 1, speedItem())
            for _, item in ipairs(all) do
                local keys = { GetBindingKey(item.id) }
                if #keys > 0 then
                    item.key = keys
                    bound[#bound + 1] = item
                end
            end
            return bound
        end,
        bind = function(item, key)
            local function apply(replace)
                local ok, why, conflict = HC.Bindings.BindCommand(item.id, key, replace)
                if ok then
                    ns.refreshOptions()
                    HC.Print(("bound %s to %s"):format(item.name, HC.Bindings.Label(key)))
                end
                return ok, why, conflict
            end
            local ok, why, conflict = apply(false)
            if conflict == "conflict" then return false, why, function() return apply(true) end end
            return ok, why
        end,
        unbind = function(id)
            local ok, problem = ns.unbindAction(id)
            if not ok then HC.Print(problem) end
        end,
        clearAll = function()
            local all = actionItems(true)
            table.insert(all, 1, speedItem())
            for _, item in ipairs(all) do
                local ok, problem = ns.unbindAction(item.id)
                if not ok then HC.Print(problem); return end
            end
        end,
    })
end)

HC.Settings:AddVisibility()
HC.spec.visibility = function(panel, y)
    _, y = UI.Header(panel, "Floating button", y, ADDON_ICON)
    local show
    show, y = UI.Check(panel, "Show floating button", "A clickable speed button on screen. Shift-left-drag to move it. Uses the same movement preferences as your primary speed key.", y,
        function() return ns.db.show_floating_button end,
        function(v) ns.db.show_floating_button = v; ns.refreshSpeedButton() end)
    local flights
    flights, y = UI.Check(panel, "Hide on flights", "Hide the floating button from takeoff to landing on a flight path. Requires Show floating button; protected visibility changes wait until combat ends.", y,
        function() return ns.db.hide_on_flights end,
        function(v) if ns.db.show_floating_button then ns.db.hide_on_flights = v; ns.refreshSpeedButton() end end)
    -- Keep position reset accessible even while the button is hidden.
    UI.OnRefresh(panel, function()
        UI.SetEnabled(flights.hcCheckbox, ns.db.show_floating_button)
        flights:EnableMouse(ns.db.show_floating_button)
    end)
    _, y = UI.ActionButton(panel, y, "Reset button position", function() HC.Commands:Dispatch("reset position") end,
        "Move only the floating button back to the centre. Keeps all settings, visibility choices and key bindings. Shift-left-drag to position it yourself.", nil, 200)
    return y
end
