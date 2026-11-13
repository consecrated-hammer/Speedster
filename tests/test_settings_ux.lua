-- Search, dynamic spell availability, persisted settings and binding lifecycle.
local S = dofile("tests/support.lua")
local eq, wow = S.equal, S.wow
local function row(HC, page, label)
    local body = HC.Settings.pages[page].bodies[page]
    return body.hcRows[label]
end
local function match(HC, query, label)
    for _, result in ipairs(HC.Settings:Search(query, 1000)) do
        if result.label == label then return result end
    end
end
local function spellEvent(ns) ns.core.scripts.OnEvent(ns.core, "SPELLS_CHANGED") end

for _, scale in ipairs({ 0.7, 1.3 }) do
    for _, class in ipairs({ "DRUID", "SHAMAN", "HUNTER", "ROGUE", "MAGE", "PRIEST", "PALADIN", "WARRIOR" }) do
        local saved = { enabled = true, druid_use_travel = false, shaman_use_ghost_wolf = false,
            walk_on_air_while_falling = false, show_floating_button = false, hide_on_flights = false,
            floating_button_point = { point = "TOP", relativePoint = "TOP", x = 123, y = -72 },
            hammerCore = { settingsScale = scale, minimap = false, startupMessage = false } }
        local ns, HC = S.load({ class = class, saved = saved, known = {} })
        -- Catch duplicate registrations at construction, before a table overwrite can hide them.
        local register = HC.UI.RegisterRow
        HC.UI.RegisterRow = function(parent, widget, label)
            local owner = parent.hcHeaderOwner or parent
            if type(label) == "string" and owner.hcRows and owner.hcRows[label] then
                eq(owner.hcRows[label], widget, "unique row: " .. label)
            end
            return register(parent, widget, label)
        end
        HC.Settings:Show("Speed")
        eq(S.pageErrors(HC), "", class .. " every page builds at " .. scale)
        for _, spec in ipairs(HC.Settings.order) do
            local body = HC.Settings.pages[spec.name].bodies[spec.name]
            for label in pairs(body.hcRows or {}) do
                if match(HC, label, label) then assert(HC.Settings:Focus(spec.name, label), "focus " .. label) end
            end
        end
        for _, label in ipairs({ "Enable speed macro", "Choose your speed key", "Current macro",
            "Show floating button", "Hide on flights", "Reset button position", "Show minimap button",
            "Minimap right-click", "Show startup message", "Show what's new after updates",
            "Mark unread What's new", "Turn-in sound", "Settings search", "Show support links", "Window scale", "Copy report" }) do
            assert(match(HC, label, label), "required control searchable: " .. label)
        end
        eq(saved.enabled, true, "enabled survives page building")
        eq(saved.druid_use_travel, false, "travel preference survives")
        eq(saved.shaman_use_ghost_wolf, false, "wolf preference survives")
        eq(saved.walk_on_air_while_falling, false, "racial opt-in survives")
        eq(saved.hide_on_flights, false, "flight preference survives")
        eq(saved.floating_button_point.x, 123, "position survives")
        eq(saved.hammerCore.settingsScale, scale, "window scale survives")
        eq(#HC.Settings:Search("Walk on Air while falling"), 0, "unavailable racial excluded")
        HC.Settings:Show("Visibility")
        eq(S.switch("Hide on flights").enabled, false, "dependent flight control disabled")
        wow.Click(S.switch("Hide on flights")) -- direct handler must still be safe
        eq(saved.hide_on_flights, false, "disabled dependent cannot mutate")
        wow.Click(wow.FindButton("Reset button position"))
        eq(saved.floating_button_point, nil, "position alone reset")
        eq(saved.show_floating_button, false, "position reset keeps visibility")
        eq(saved.druid_use_travel, false, "position reset keeps class choice")
        eq(saved.hammerCore.minimap, false, "position reset keeps shared choices")
    end
end

do
    local known = { [768] = true }
    local ns, HC, world = S.load({ known = known, saved = { enabled = true, druid_use_travel = true } })
    HC.Settings:Show("Speed")
    eq(S.switch("Use Travel Form outdoors").enabled, true, "saved unlearned preference can be disabled")
    wow.Click(S.switch("Use Travel Form outdoors"))
    eq(ns.db.druid_use_travel, false, "saved unlearned preference disabled")
    eq(#HC.Settings:Search("Use Travel Form outdoors"), 0, "unlearned off control excluded")
    HC.Settings:Show("Visibility") -- learn while both owning pages are hidden
    known[783], known[1850], known[1259416] = true, true, true
    spellEvent(ns)
    assert(match(HC, "Use Travel Form outdoors", "Use Travel Form outdoors"), "new form indexed")
    assert(match(HC, "Walk on Air while falling", "Walk on Air while falling"), "new racial indexed")
    assert(match(HC, "Dash", "Bind: Druid: Dash"), "new utility tile indexed")
    HC.Settings:Show("Speed")
    wow.Click(S.switch("Use Travel Form outdoors"))
    local macro = row(HC, "Speed", "Current macro")
    eq(macro:GetText(), ns.getMacro(), "macro refreshed after preferences")
    macro:SetText("/cast Something unsafe")
    macro.scripts.OnTextChanged(macro, true)
    eq(macro:GetText(), ns.getMacro(), "generated macro is read-only")
    known[783] = nil
    spellEvent(ns)
    eq(macro:GetText(), ns.getMacro(), "macro refreshed after spell removal")
    wow.Click(S.switch("Enable speed macro"))
    eq(HC.Settings:Focus("Speed", "Use Travel Form outdoors"), row(HC, "Speed", "Enable speed macro"), "hidden child focuses enable switch")
    wow.Click(S.switch("Enable speed macro"))

    local command = ns.getPrimaryBindingCommand()
    local dash = "CLICK Speedster_SpeedButton_druidDash:LeftButton"
    world.bindings.F, world.bindings.G = command, command
    world.bindings.H = dash
    ns.refreshOptions()
    local active = row(HC, "Key Bindings", "Change binding: Speed macro")
    S.contains(active.key:GetText(), "F, G", "all current keys are displayed")
    known[1850] = nil
    spellEvent(ns)
    eq(match(HC, "Dash", "Bind: Druid: Dash"), nil, "removed spell tile not stale")
    assert(match(HC, "Dash", "Remove binding: Druid: Dash"), "unavailable saved binding remains removable")
    wow.Click(row(HC, "Key Bindings", "Remove binding: Druid: Dash"))
    eq(world.bindings.H, nil, "unlearned binding removed")
    eq(match(HC, "Dash", "Remove binding: Druid: Dash"), nil, "removed bound row not stale")

    -- Drive the real shared capture prompt and conflict replacement.
    local function capture()
        HC.Settings:Show("Key Bindings")
        wow.Click(row(HC, "Key Bindings", "Bind: Speed macro"))
        return HC.Bindings.Capture.frame
    end
    world.bindings.X = "JUMP"
    local catcher = capture()
    catcher.scripts.OnKeyDown(catcher, "X")
    eq(world.bindings.X, "JUMP", "conflict preserved before Replace")
    eq(catcher.prompt.replace:IsShown(), true, "explicit Replace offered")
    wow.Click(catcher.prompt.replace)
    eq(world.bindings.X, command, "Replace applies chosen key")
    eq(world.bindings.F, nil, "old first key removed")
    eq(world.bindings.G, nil, "old second key removed")
    IsControlKeyDown = function() return true end
    catcher = capture()
    catcher.scripts.OnMouseDown(catcher, "Button4")
    eq(world.bindings["CTRL-BUTTON4"], command, "modified mouse binding")
    IsControlKeyDown = function() return false end
    IsShiftKeyDown = function() return true end
    catcher = capture()
    catcher.scripts.OnMouseWheel(catcher, -1)
    eq(world.bindings["SHIFT-MOUSEWHEELDOWN"], command, "modified wheel binding")
    IsShiftKeyDown = function() return false end
    catcher = capture()
    catcher.scripts.OnMouseDown(catcher, "LeftButton")
    eq(world.bindings.BUTTON1, nil, "bare left click rejected")
    S.contains(catcher.prompt.error:GetText(), "Add Shift", "unsafe mouse feedback")
    HC.Bindings.Capture:Stop()
    world.combat = true
    catcher = capture()
    catcher.scripts.OnKeyDown(catcher, "Q")
    eq(world.bindings.Q, nil, "combat binding refused")
    S.contains(catcher.prompt.error:GetText(), "combat", "combat error visible")
    local ok = ns.unbindAction(command)
    eq(ok, false, "combat removal refused")
    world.combat = false
    HC.Bindings.Capture:Stop()
    local setBinding = SetBinding
    SetBinding = function() return false end
    catcher = capture()
    catcher.scripts.OnKeyDown(catcher, "Q")
    S.contains(catcher.prompt.error:GetText(), "game refused", "binding failure visible")
    eq(ns.unbindAction(command), false, "failed removal reported")
    SetBinding = setBinding
    HC.Bindings.Capture:Stop()
    -- Slash shortcut intentionally retains its established conflict policy.
    world.bindings.Z = "JUMP"
    assert(ns.bindKey("Z"))
    eq(world.bindings.Z, command, "slash bind keeps replacement behaviour")
    world.bindings.H = dash -- no longer learned; clear must still remove it
    world.bindings.K = "JUMP"
    HC.Settings:Show("Key Bindings")
    wow.Click(row(HC, "Key Bindings", "Clear all bindings"))
    wow.Click(HC.Dialog.frame.accept)
    eq(world.bindings.Z, nil, "clear removes primary")
    eq(world.bindings.H, nil, "clear removes unavailable utility")
    eq(world.bindings.K, "JUMP", "clear preserves unrelated binding")
end
io.write("Speedster settings UX tests passed\n")
