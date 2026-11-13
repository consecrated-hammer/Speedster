-- Loading: every TOC loads its files, a fresh install gets its defaults, an
-- older profile is migrated, and the secure buttons and bindings exist.
local S = dofile("tests/support.lua")
local equal, contains, wow = S.equal, S.contains, S.wow

-- Speedster ships one TOC, for WoW Forever. If a Retail TOC ever comes
-- back, add it to S.TOCS and every test here runs on both.
equal(#S.TOCS, 1, "one TOC")
do
    local handle = io.open("Speedster.toc")
    equal(handle, nil, "no Retail TOC ships")
    if handle then handle:close() end
end

for _, toc in ipairs(S.TOCS) do
    local meta = {}
    for line in io.lines(toc) do
        local key, value = line:match("^## ([%w%-]+):%s*(.-)%s*$")
        if key then meta[key] = value end
    end
    equal(meta.Interface, "16001", toc .. ": WoW Forever interface")
    equal(meta.AllowLoadGameType, "camelot", toc .. ": loads on Camelot only")
    equal(meta.SavedVariablesPerCharacter, "SpeedsterDB", toc .. ": per-character saved variables")
    equal(meta["X-Speedster-Target"], "Camelot", toc .. ": target")

    -- Fresh install.
    local ns, HC = S.load({ toc = toc, saved = nil, version = "1.3.0" })
    equal(ns.dbWasFresh, true, toc .. ": a fresh install is noticed")
    equal(SpeedsterDB, ns.db, toc .. ": the saved table is the db")
    equal(ns.db.enabled, true, toc .. ": speed macro starts on")
    equal(ns.db.druid_use_travel, true, toc .. ": Travel Form starts on")
    equal(ns.db.shaman_use_ghost_wolf, true, toc .. ": Ghost Wolf starts on")
    equal(ns.db.show_floating_button, true, toc .. ": floating button starts shown")
    equal(ns.db.hide_on_flights, true, toc .. ": Hide on flights starts on")
    equal(ns.db.walk_on_air_while_falling, false, toc .. ": Walk on Air while falling starts off")
    equal(wow.LastPrint(), "Speedster v1.3.0 loaded - type /speedster for settings, /speedster help for commands",
        toc .. ": login message")
    equal(HC.name, "Speedster", toc .. ": HammerCore knows the addon")
    equal(HC.VERSION, "0.5.2", toc .. ": vendored HammerCore 0.5.2")

    -- Secure buttons and their binding names.
    local primary = S.primary()
    equal(primary.template, "SecureActionButtonTemplate", toc .. ": the speed key clicks a secure button")
    equal(primary:GetAttribute("type"), "macro", toc .. ": which runs a macro")
    equal(primary.shown, false, toc .. ": the key's button is invisible")
    equal(_G.BINDING_HEADER_SPEEDSTER, "Speedster", toc .. ": key bindings header")
    equal(_G["BINDING_NAME_CLICK Speedster_SpeedButton:LeftButton"], "Use speed macro", toc .. ": speed key name")
    for _, id in ipairs(ns.getUtilityActionIDs()) do
        local name = "Speedster_SpeedButton_" .. id
        assert(_G[name], toc .. ": " .. id .. " has a button")
        assert(_G["BINDING_NAME_CLICK " .. name .. ":LeftButton"], toc .. ": " .. id .. " has a binding name")
    end
    equal(#ns.getUtilityActionIDs(), 9, toc .. ": nine extra movement actions")
    local floating = S.floating()
    equal(floating:IsShown(), true, toc .. ": the floating button shows")
    equal(floating:GetAttribute("type"), "macro", toc .. ": the floating button runs the same macro")
    local point, _, relativePoint, x, y = floating:GetPoint()
    equal(point .. relativePoint .. x .. y, "CENTERCENTER0-120", toc .. ": default floating position")

    -- An older profile: legacy keys move into HammerCore, retired keys go.
    ns, HC = S.load({ toc = toc, saved = { enabled = false, cancel_form_on_taxi = true,
        show_minimap_button = true, minimap_angle = 200, show_startup_message = false,
        show_floating_button = false,
        floating_button_point = { point = "TOP", relativePoint = "TOP", x = 5, y = -40 } } })
    equal(ns.dbWasFresh, false, toc .. ": an existing profile is loaded")
    equal(ns.db.cancel_form_on_taxi, nil, toc .. ": the Retail taxi setting is removed")
    equal(ns.db.show_startup_message, nil, toc .. ": the old startup key is moved")
    equal(HC.State().startupMessage, false, toc .. ": and keeps its value")
    equal(HC.State().minimap, true, toc .. ": the minimap choice is kept")
    equal(HC.State().minimapAngle, 200, toc .. ": and its angle")
    equal(ns.db.enabled, false, toc .. ": a disabled macro stays disabled")
    equal(ns.db.shaman_use_ghost_wolf, true, toc .. ": a missing Ghost Wolf choice is filled in")
    equal(ns.db.hide_on_flights, true, toc .. ": a missing Hide on flights is filled in")
    equal(S.floating():IsShown(), false, toc .. ": a hidden floating button stays hidden")
    point, _, relativePoint, x, y = S.floating():GetPoint()
    equal(point .. relativePoint .. x .. y, "TOPTOP5-40", toc .. ": a saved floating position is used")
    equal(#wow.printed, 0, toc .. ": startup message off means a quiet login")

    -- A broken saved value is replaced rather than crashing.
    ns = S.load({ toc = toc, saved = "broken" })
    equal(type(ns.db), "table", toc .. ": a broken saved value is replaced")
    equal(ns.dbWasFresh, true, toc .. ": and treated as fresh")

    -- Another addon's ADDON_LOADED is ignored.
    local before = ns.db
    ns.core.scripts.OnEvent(ns.core, "ADDON_LOADED", "SomethingElse")
    equal(ns.db, before, toc .. ": other addons' loads are ignored")

    -- Learning a spell rebuilds the macro.
    ns = S.load({ toc = toc, class = "ROGUE", known = {} })
    equal(S.primary():GetAttribute("macrotext"), "", toc .. ": nothing to cast yet")
    C_SpellBook.IsSpellKnown = function(id) return id == 2983 end
    ns.core.scripts.OnEvent(ns.core, "SPELLS_CHANGED")
    equal(S.primary():GetAttribute("macrotext"), "/cast Spell 2983", toc .. ": learning Sprint updates the key")
end

io.write("Speedster load tests passed\n")
