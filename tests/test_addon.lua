package.path = "./tests/hammercore/?.lua;" .. package.path
local wow = require("wow")

local function equal(actual, expected, label)
    if actual ~= expected then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local bindings, movement
local function loadAddon(tocName, saved, class, knownSpells)
    local camelot = tocName:find("Camelot") and "Camelot" or nil
    wow.Install({ Speedster = { Version = "0.4.11-dev1", ["X-Speedster-Target"] = camelot } })
    bindings = {}
    movement = { falling = false, combat = false }
    IsFalling = function() return movement.falling end
    InCombatLockdown = function() return movement.combat end
    C_Timer = { After = function() end }
    UnitClass = function() return class, class end
    IsIndoors, IsOutdoors, IsMounted = function() return false end, function() return true end, function() return false end
    GetBindingKey = function(command)
        for key, bound in pairs(bindings) do if bound == command then return key end end
    end
    GetBindingAction = function(key) return bindings[key] or "" end
    GetBindingText = function(key) return key end
    GetBindingName = function(action) return action end
    SetBinding = function(key, command) bindings[key] = command; return true end
    SaveBindings, GetCurrentBindingSet = function() end, function() return 1 end
    NOT_BOUND = "Not bound"
    C_SpellBook = { IsSpellKnown = function(id)
        if knownSpells then return knownSpells[id] == true end
        return id == 783 or id == 1850
    end }
    Enum = { SpellBookSpellBank = { Player = 0 } }
    C_Spell = { GetSpellInfo = function(id) return { name = "Spell " .. id, iconID = 1 } end }
    GetSpellInfo = function(id) return "Spell " .. id end
    SpeedsterDB = saved
    local ns = {}
    for line in io.lines(tocName) do
        local entry = line:gsub("\r", ""):gsub("\\", "/")
        if entry:match("%.xml$") then
            wow.LoadHammerCore(entry:match("^(.*)/[^/]+$"), "Speedster", ns)
        elseif entry:match("%.lua$") then
            assert(loadfile(entry))("Speedster", ns)
        end
    end
    local core = _G.SpeedsterCore
    core.scripts.OnEvent(core, "ADDON_LOADED", "Speedster")
    return ns
end

for _, toc in ipairs({ "Speedster_Camelot.toc" }) do
    local ns = loadAddon(toc, { enabled = true, druid_use_travel = true, show_floating_button = true,
        show_minimap_button = false, minimap_angle = 15, show_startup_message = true }, "DRUID")
    local HC = ns.HammerCore
    equal(wow.LastPrint(), "Speedster v0.4.11-dev1 loaded - type /speedster for settings, /speedster help for commands",
        toc .. ": standard login message")
    equal(HC.State().minimap, false, toc .. ": a hidden minimap stays hidden")
    equal(HC.State().minimapAngle, 15, toc .. ": minimap position is kept")
    equal(SpeedsterDB.show_minimap_button, nil, toc .. ": the old minimap key is removed")

    SlashCmdList.SPEEDSTER("")
    equal(HC.Settings:IsShown(), true, toc .. ": the bare command opens settings")
    local names = {}
    for _, spec in ipairs(HC.Settings.order) do names[#names + 1] = spec.name end
    equal(table.concat(names, ","), "Speed,Visibility,Key Bindings,Commands,Troubleshooting,About",
        toc .. ": rail order")
    local failures = {}
    for name, err in pairs(HC.Settings.errors) do failures[#failures + 1] = name .. ": " .. err end
    equal(table.concat(failures, "; "), "", toc .. ": every settings page builds")
    for _, spec in ipairs(HC.Settings.order) do
        HC.Settings:Show(spec.name)
        equal(HC.Settings.selected, spec.name, toc .. ": " .. spec.name .. " opens")
    end
    equal(wow.FindText("Use Travel Form outdoors") ~= nil, true, toc .. ": a druid sees the Travel Form option")
    equal(wow.FindText("Use Ghost Wolf"), nil, toc .. ": a druid does not see Ghost Wolf")

    SlashCmdList.SPEEDSTER("bind F")
    equal(bindings.F, "CLICK Speedster_SpeedButton:LeftButton", toc .. ": bind sets the speed key")
    equal(wow.LastPrint(), "Speedster: bound speed macro to F", toc .. ": and says so")
    SlashCmdList.SPEEDSTER("toggle")
    equal(ns.db.show_floating_button, false, toc .. ": toggle hides the floating button")
    SlashCmdList.SPEEDSTER("toggle")
    equal(ns.db.show_floating_button, true, toc .. ": toggle shows it again")
    ns.db.floating_button_point = { "TOP", "TOP", 1, 1 }
    SlashCmdList.SPEEDSTER("reset position")
    equal(ns.db.floating_button_point, nil, toc .. ": reset position clears the floating position")
    SlashCmdList.SPEEDSTER("debug")
    equal(HC.Copy.frame.edit:GetText():find("Primary binding:", 1, true) ~= nil, true,
        toc .. ": debug includes Speedster's report")

    for _, old in ipairs({ "options", "diagnostics" }) do
        SlashCmdList.SPEEDSTER(old)
        equal(wow.LastPrint(), "Speedster: unknown command. Type /speedster help for the list.",
            toc .. ": old command '" .. old .. "' is removed")
    end
    equal(SlashCmdList.SPEEDSTER_BIND, nil, toc .. ": /speedsterbind is gone")
    equal(SlashCmdList.SPEEDSTER_MACRO, nil, toc .. ": /speedstermacro is gone")
    equal(SlashCmdList.SPEEDSTER_LOADMSG, nil, toc .. ": /speedsterloadmsg is gone")
end

-- Every page also builds under HammerCore's Classic theme.
for _, toc in ipairs({ "Speedster_Camelot.toc" }) do
    local ns = loadAddon(toc, { enabled = true, hammerCore = { theme = "classic" } }, "SHAMAN")
    local HC = ns.HammerCore
    -- Classic is switched off for players until it is reworked; keep it building.
    HC.Theme.registry.classic.available = true
    equal(HC.Theme.IsClassic(), true, toc .. ": classic theme is active")
    HC.Settings:Show()
    local failures = {}
    for name, err in pairs(HC.Settings.errors) do failures[#failures + 1] = name .. ": " .. err end
    equal(table.concat(failures, "; "), "", toc .. ": every settings page builds in classic")
    for _, spec in ipairs(HC.Settings.order) do
        HC.Settings:Show(spec.name)
        equal(HC.Settings.selected, spec.name, toc .. ": " .. spec.name .. " opens in classic")
    end
end

-- The shared key selects the racial only when explicitly enabled, known and
-- falling outside combat. No attributes may be rewritten during combat.
do
    local ns = loadAddon("Speedster_Camelot.toc", nil, "DRUID",
        { [768] = true, [1066] = true, [783] = true, [1259416] = true })
    local normal = ns.getMacro()
    equal(ns.db.walk_on_air_while_falling, false, "falling racial starts opt-in")
    ns.HammerCore.Settings:Show("Speed")
    equal(wow.FindText("Walk on Air while falling") ~= nil, true, "known racial exposes the option")
    movement.falling = true
    equal(ns.getMacro(), normal, "disabled option preserves class macro while falling")
    ns.db.walk_on_air_while_falling = true
    local primary, floating = _G.Speedster_SpeedButton, _G.SpeedsterFloatingButton
    primary.scripts.PreClick(primary, "LeftButton", true)
    local fallingMacro = ns.getMacro()
    equal(primary:GetAttribute("macrotext"), fallingMacro, "key click prepares the current falling action")
    equal(floating:GetAttribute("macrotext"), fallingMacro, "floating button shares the same action")
    equal(fallingMacro:find("/cast [nocombat] !Spell 1259416", 1, true) ~= nil, true, "falling uses learned racial")
    equal(fallingMacro:find("/stopmacro [nocombat]\n" .. normal, 1, true) ~= nil, true, "frozen falling macro retains secure combat fallback")
    local racial = _G.Speedster_SpeedButton_skyborneWalkOnAir
    equal(racial:GetAttribute("macrotext"), "/cast Spell 1259416", "separate racial binding remains available")
    movement.combat = true
    local fallingGetter = IsFalling
    IsFalling = function() error("falling query during combat click") end
    local original = primary.SetAttribute
    primary.SetAttribute = function() error("protected attribute write in combat") end
    floating.SetAttribute = primary.SetAttribute
    for _, down in ipairs({ true, false }) do
        primary.scripts.PreClick(primary, "LeftButton", down)
        floating.scripts.PreClick(floating, "LeftButton", down)
    end
    equal(primary:GetAttribute("macrotext"), fallingMacro, "combat click does not rewrite frozen macro")
    ns.refreshSpeedButton()
    movement.combat, movement.falling = false, false
    IsFalling = fallingGetter
    primary.SetAttribute, floating.SetAttribute = original, original
    ns.core.scripts.OnEvent(ns.core, "PLAYER_REGEN_ENABLED")
    equal(primary:GetAttribute("macrotext"), normal, "regen restores class macro after deferred refresh")
    movement.falling = true
    floating.scripts.PreClick(floating, "LeftButton", true)
    equal(primary:GetAttribute("macrotext"), fallingMacro, "floating click also selects falling action")
    movement.falling = false
    primary.scripts.PreClick(primary, "LeftButton", true)
    equal(primary:GetAttribute("macrotext"), normal, "landing restores class movement on next press")
    ns.db.enabled = false
    movement.falling = true
    equal(ns.getMacro(), "", "disabled speed macro stays empty while falling")

    ns = loadAddon("Speedster_Camelot.toc", { enabled = true, walk_on_air_while_falling = true }, "DRUID", { [768] = true })
    movement.falling = true
    equal(ns.getMacro(), "/cast !Spell 768", "unknown racial keeps normal class movement")
    ns.HammerCore.Settings:Show("Speed")
    equal(wow.FindText("Walk on Air while falling").parent.enabled, true, "saved opt-in can be turned off even if racial is unavailable")
    local learned = { [768] = true }
    ns = loadAddon("Speedster_Camelot.toc", nil, "DRUID", learned)
    ns.HammerCore.Settings:Show("Speed")
    equal(wow.FindText("Walk on Air while falling").parent.enabled, false, "unknown racial keeps new option disabled")
    learned[1259416] = true
    ns.core.scripts.OnEvent(ns.core, "SPELLS_CHANGED")
    equal(wow.FindText("Walk on Air while falling").parent.enabled, true, "spellbook refresh makes existing checkbox available")
    ns = loadAddon("Speedster_Camelot.toc", { enabled = true, walk_on_air_while_falling = true }, "PRIEST", { [1259416] = true })
    movement.falling = true
    equal(ns.getMacro(), "/cast [nocombat] !Spell 1259416\n/stopmacro [nocombat]", "racial works for a class with no primary speed spell")
end

io.write("Speedster addon tests passed\n")
