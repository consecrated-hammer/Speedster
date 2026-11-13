-- What Speedster puts on screen and on the key: the macro it builds for each
-- class, the Current macro box, the floating button and its tooltip, and
-- the binding text it reports.
local S = dofile("tests/support.lua")
local equal, contains, wow = S.equal, S.contains, S.wow

local function macroFor(class, known, saved)
    saved = saved or { enabled = true, druid_use_travel = true, shaman_use_ghost_wolf = true, show_floating_button = true }
    local ns = S.load({ class = class, known = known, saved = saved })
    return ns.getMacro(), ns
end

local function set(...)
    local result = {}
    for _, id in ipairs({ ... }) do result[id] = true end
    return result
end

-- Class macros.
equal(macroFor("DRUID", set(768, 1066, 783, 40120)),
    "/cast [swimming]!Spell 1066;[indoors]!Spell 768;[flyable,nocombat]!Spell 40120;!Spell 783",
    "druid: aquatic, cat, flight and travel")
equal(macroFor("DRUID", set(768, 1066, 783, 33943)),
    "/cast [swimming]!Spell 1066;[indoors]!Spell 768;[flyable,nocombat]!Spell 33943;!Spell 783",
    "druid: the older Flight Form")
equal(macroFor("DRUID", set(768, 783)), "/cast [indoors]!Spell 768;[flyable,nocombat]!Spell 783;!Spell 783",
    "druid: Travel Form doubles as the air form")
equal(macroFor("DRUID", set(768, 1066, 783), { enabled = true, druid_use_travel = false }),
    "/cast [swimming]!Spell 1066;!Spell 768", "druid: Travel Form off keeps aquatic and cat")
equal(macroFor("DRUID", set(1066)), "/cast [swimming]!Spell 1066", "druid: aquatic only")
equal(macroFor("DRUID", set(768)), "/cast !Spell 768", "druid: cat only")
equal(macroFor("DRUID", {}), "", "druid: nothing learned")
equal(macroFor("SHAMAN", set(2645)), "/cast !Spell 2645", "shaman: Ghost Wolf")
equal(macroFor("SHAMAN", set(2645), { enabled = true, shaman_use_ghost_wolf = false }), "", "shaman: Ghost Wolf off")
equal(macroFor("HUNTER", set(5118)), "/cast !Spell 5118", "hunter: Aspect of the Cheetah")
equal(macroFor("ROGUE", set(2983)), "/cast Spell 2983", "rogue: Sprint")
equal(macroFor("MAGE", set(1953)), "/cast Spell 1953", "mage: Blink")
equal(macroFor("WARRIOR", set(2983, 1953)), "", "warrior: other classes' spells don't count")
equal(macroFor("ROGUE", set(2983), { enabled = false }), "", "a disabled macro is empty")

-- The legacy spellbook checks still count on Forever.
do
    local ns = S.load({ class = "HUNTER", known = {} })
    IsPlayerSpell = function(id) return id == 5118 end
    equal(ns.getMacro(), "/cast !Spell 5118", "IsPlayerSpell is merged in")
    IsPlayerSpell = nil
    IsSpellKnown = function(id) return id == 5118 end
    equal(ns.getMacro(), "/cast !Spell 5118", "IsSpellKnown is merged in")
    C_SpellBook.IsSpellKnown = function() error("bad API") end
    equal(ns.getMacro(), "/cast !Spell 5118", "a failing modern API falls back")
    IsSpellKnown = nil
end

-- Extra movement actions: only known ones, self-cast where it matters.
do
    local ns = S.load({ class = "SHAMAN", known = set(546, 1044, 13159) })
    local byID = {}
    for _, action in ipairs(ns.getUtilityActions()) do byID[action.id] = action end
    equal(byID.shamanWaterWalking.macro, "/cast [@player] Spell 546", "Water Walking casts on yourself")
    equal(byID.paladinFreedom.macro, "/cast [@player] Spell 1044", "Freedom casts on yourself")
    equal(byID.hunterPack.macro, "/cast Spell 13159", "Aspect of the Pack is a plain cast")
    contains(byID.hunterPack.warning, "dazes", "Aspect of the Pack warns about dazes")
    equal(byID.druidDash, nil, "unknown actions are left out")
    equal(_G.Speedster_SpeedButton_shamanWaterWalking:GetAttribute("macrotext"), "/cast [@player] Spell 546",
        "the Water Walking key is ready")
    equal(_G.Speedster_SpeedButton_druidDash:GetAttribute("macrotext"), "", "an unknown action's key is empty")
end

-- The Current macro box follows changes made anywhere.
do
    local ns, HC = S.load({ class = "ROGUE", known = set(2983) })
    HC.Settings:Show("Speed")
    local box = wow.FindText("/cast Spell 2983")
    assert(box, "Current macro shows the macro")
    equal(box.kind, "EditBox", "in a copyable box")
    SlashCmdList.SPEEDSTER("toggle")
    ns.db.enabled = false
    ns.refreshSpeedButton()
    equal(box:GetText(), "Speed macro disabled. Enable it above to use your speed key.", "turning the macro off updates the box")
    ns.db.enabled = true
    ns.refreshSpeedButton()
    equal(box:GetText(), "/cast Spell 2983", "turning it on fills it again")
    box:SetText("edited")
    box.scripts.OnEscapePressed(box)
    equal(box:GetText(), "/cast Spell 2983", "Escape puts the macro back")
end

-- The floating button: icon, tooltip, shift-drag and its saved spot.
do
    local ns, HC, world = S.load({ class = "ROGUE", known = set(2983) })
    local button = S.floating()
    -- The headless client loads no textures, so the button falls back to the
    -- question mark; in game it shows Speedster's icon.
    equal(button.icon.texture, "Interface\\Icons\\INV_Misc_QuestionMark", "an icon when the texture is missing")
    equal(button:GetAttribute("macrotext"), "/cast Spell 2983", "the button carries the macro")
    local lines = {}
    GameTooltip.SetText = function(_, text) lines[#lines + 1] = text end
    GameTooltip.AddLine = function(_, text) lines[#lines + 1] = text end
    button.scripts.OnEnter(button)
    equal(table.concat(lines, "|"), "Speedster|Left-click: use speed macro|Shift + left-drag: move button", "tooltip")

    button.scripts.OnMouseDown(button, "LeftButton")
    equal(button._isDragging, nil, "a plain click doesn't drag")
    IsShiftKeyDown = function() return true end
    world.combat = true
    button.scripts.OnMouseDown(button, "LeftButton")
    equal(button._isDragging, nil, "no dragging in combat")
    world.combat = false
    button.scripts.OnMouseDown(button, "LeftButton")
    equal(button._isDragging, true, "shift-drag starts a move")
    button:ClearAllPoints()
    button:SetPoint("BOTTOM", UIParent, "BOTTOM", 12, 80)
    button.scripts.OnMouseUp(button)
    local spot = ns.db.floating_button_point
    equal(spot.point .. spot.relativePoint .. spot.x .. spot.y, "BOTTOMBOTTOM1280", "dropping saves the spot")
end

-- Reset position waits for combat to end.
do
    local ns, HC, world = S.load({ saved = { enabled = true, show_floating_button = true,
        floating_button_point = { point = "TOP", relativePoint = "TOP", x = 3, y = 4 } } })
    world.combat = true
    local ok, reason = ns.resetFloatingButtonPosition()
    equal(ok, false, "reset in combat is deferred")
    equal(reason, SPELL_FAILED_AFFECTING_COMBAT, "with the combat reason")
    equal(S.floating():GetPoint(), "TOP", "the button hasn't moved yet")
    S.regen(ns)
    equal(S.floating():GetPoint(), "CENTER", "it moves when combat ends")
end

-- Binding text: one key, two keys, none.
do
    local ns, HC, world = S.load({})
    equal(ns.getBindingText(), "Not bound", "nothing bound")
    world.bindings.F = ns.getPrimaryBindingCommand()
    equal(ns.getBindingText(), "F", "one key")
    world.bindings.G = ns.getPrimaryBindingCommand()
    equal(ns.getBindingText(), "F, G", "two keys")
    contains(HC.spec.status(), "Key: F, G", "status shows both keys")
end

io.write("Speedster display tests passed\n")
