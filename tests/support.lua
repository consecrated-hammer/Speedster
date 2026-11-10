-- Shared loader for Speedster's tests: installs the headless client from
-- tests/hammercore/wow.lua, a small spellbook, key bindings and a taxi, then
-- loads a TOC in order and fires ADDON_LOADED.

package.path = "./tests/hammercore/?.lua;" .. package.path
local wow = require("wow")

local S = { wow = wow, TOCS = { "Speedster_Camelot.toc" } }

function S.equal(actual, expected, label)
    if actual ~= expected then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

function S.contains(text, part, label)
    if type(text) ~= "string" or not text:find(part, 1, true) then
        error(label .. ": expected '" .. tostring(part) .. "' in " .. tostring(text), 2)
    end
end

-- Every chat line printed since `from`, colour codes stripped.
function S.printedSince(from)
    local lines = {}
    for i = from + 1, #wow.printed do lines[#lines + 1] = wow.Plain(wow.printed[i]) end
    return table.concat(lines, "\n")
end

-- options: toc, saved, class, known (spell ID set), version, taxi (start on
-- a taxi), combat.
function S.load(options)
    options = options or {}
    local toc = options.toc or S.TOCS[1]
    wow.Install({ Speedster = { Version = options.version or "1.3.0-dev1",
        ["X-Speedster-Target"] = toc:find("Camelot") and "Camelot" or nil } })
    local world = { clock = 100, taxi = options.taxi or false, combat = options.combat or false,
        falling = false, hooks = {}, bindings = {} }
    S.world = world
    GetTime = function() return world.clock end
    GetServerTime = function() return 5000 + world.clock end
    UnitOnTaxi = function() return world.taxi end
    hooksecurefunc = function(name, fn) world.hooks[name] = fn end
    TakeTaxiNode = function() end
    TaxiRequestEarlyLanding = function() end
    IsFalling = function() return world.falling end
    InCombatLockdown = function() return world.combat end
    C_Timer = { After = function() end }
    UnitClass = function() return options.class or "DRUID", options.class or "DRUID" end
    IsIndoors, IsOutdoors, IsMounted = function() return false end, function() return true end, function() return false end
    IsShiftKeyDown = function() return false end
    GetBindingKey = function(command)
        local keys = {}
        for key, bound in pairs(world.bindings) do if bound == command then keys[#keys + 1] = key end end
        table.sort(keys)
        return keys[1], keys[2]
    end
    GetBindingAction = function(key) return world.bindings[key] or "" end
    GetBindingText = function(key) return key end
    GetBindingName = function(action) return action end
    SetBinding = function(key, command) world.bindings[key] = command; return true end
    SaveBindings, GetCurrentBindingSet = function() end, function() return 1 end
    NOT_BOUND = "Not bound"
    SPELL_FAILED_AFFECTING_COMBAT = "You are in combat"
    local known = options.known or { [783] = true, [1850] = true }
    C_SpellBook = { IsSpellKnown = function(id) return known[id] == true end }
    IsSpellKnown, IsPlayerSpell = nil, nil
    Enum = { SpellBookSpellBank = { Player = 0 } }
    C_Spell = { GetSpellInfo = function(id) return { name = "Spell " .. id, iconID = 1 } end }
    GetSpellInfo = function(id) return "Spell " .. id end
    GetBuildInfo = function() return "1.16.1", "1", "Nov 1 2026", 16001 end
    SpeedsterDB = options.saved
    local ns = {}
    for line in io.lines(toc) do
        local entry = line:gsub("\r", ""):gsub("\\", "/")
        if not entry:match("^#") then
            if entry:match("%.xml$") then
                wow.LoadHammerCore(entry:match("^(.*)/[^/]+$"), "Speedster", ns)
            elseif entry:match("%.lua$") then
                assert(loadfile(entry))("Speedster", ns)
            end
        end
    end
    local core = _G.SpeedsterCore
    core.scripts.OnEvent(core, "ADDON_LOADED", "Speedster")
    return ns, ns.HammerCore, world
end

-- Taxi helpers, driving HammerCore's Flights the way the client does.
local function fire(HC, event) HC.Flights.frame.scripts.OnEvent(HC.Flights.frame, event) end
S.fire = fire

function S.takeOff(HC, slot)
    S.world.hooks.TakeTaxiNode(slot or 2)
    S.world.taxi = true
    fire(HC, "PLAYER_CONTROL_LOST")
end

function S.land(HC, seconds)
    S.world.clock = S.world.clock + (seconds or 60)
    S.world.taxi = false
    fire(HC, "PLAYER_CONTROL_GAINED")
end

function S.regen(ns)
    S.world.combat = false
    ns.core.scripts.OnEvent(ns.core, "PLAYER_REGEN_ENABLED")
end

function S.floating() return _G.SpeedsterFloatingButton end
function S.primary() return _G.Speedster_SpeedButton end

-- Settings-window helpers.
function S.pageErrors(HC)
    local failures = {}
    for name, err in pairs(HC.Settings.errors) do failures[#failures + 1] = name .. ": " .. err end
    table.sort(failures)
    return table.concat(failures, "; ")
end

function S.menuItem(HC, text)
    for _, item in ipairs(HC.Minimap:MenuItems()) do
        if item.text == text then return item end
    end
end

-- The switch (or Classic checkbox) of the settings row with this label.
-- What's new can show the same words as a title, so only a font string on a
-- row's own control counts.
function S.switch(label)
    for _, region in ipairs(wow.regions) do
        local control = region.parent
        if region.text == label and type(control) == "table" and control.parent
            and rawget(control.parent, "hcCheckbox") == control then
            return control
        end
    end
end

return S
