-- Settings: every page builds for every class in both themes, Speedster's
-- switches change what they say, and settings search finds them.
local S = dofile("tests/support.lua")
local equal, contains, wow = S.equal, S.contains, S.wow

local RAIL = "Speed,Visibility,Key Bindings,What's new,Commands,Troubleshooting,About"

for _, toc in ipairs(S.TOCS) do
    for _, class in ipairs({ "DRUID", "SHAMAN", "HUNTER", "ROGUE", "MAGE", "PRIEST", "WARRIOR" }) do
        for _, theme in ipairs({ "modern", "classic" }) do
            local label = toc .. " " .. class .. " " .. theme
            local ns, HC = S.load({ toc = toc, class = class,
                saved = { enabled = true, hammerCore = { theme = theme } } })
            if theme == "classic" then HC.Theme.registry.classic.available = true end
            HC.Settings:Show()
            local names = {}
            for _, spec in ipairs(HC.Settings.order) do names[#names + 1] = spec.name end
            equal(table.concat(names, ","), RAIL, label .. ": rail order")
            equal(S.pageErrors(HC), "", label .. ": every page builds")
            for _, spec in ipairs(HC.Settings.order) do
                HC.Settings:Show(spec.name)
                equal(HC.Settings.selected, spec.name, label .. ": " .. spec.name .. " opens")
            end
            HC.Settings:Show("Speed")
            equal(S.switch("Enable speed macro") ~= nil, true, label .. ": speed macro switch")
            equal(S.switch("Use Travel Form outdoors") ~= nil, class == "DRUID", label .. ": Travel Form only for druids")
            equal(S.switch("Use Ghost Wolf") ~= nil, class == "SHAMAN", label .. ": Ghost Wolf only for shamans")
        end
    end
end

-- Visibility: the floating button section, Hide on flights and the
-- HammerCore rows that come with 0.5.0.
for _, toc in ipairs(S.TOCS) do
    local ns, HC = S.load({ toc = toc, saved = { enabled = true, druid_use_travel = true, show_floating_button = true } })
    HC.Settings:Show("Visibility")
    for _, label in ipairs({ "Show floating button", "Hide on flights" }) do
        assert(S.switch(label), toc .. ": Visibility has " .. label)
    end
    assert(wow.FindButton("Reset button position"), toc .. ": Visibility has Reset button position")
    assert(wow.FindText("Minimap right-click"), toc .. ": Visibility has Minimap right-click")
    assert(wow.FindText("Settings search"), toc .. ": Visibility has Settings search")
    equal(wow.Visible(wow.FindText("Reload UI")), false, toc .. ": no standing Reload UI button")

    equal(S.switch("Hide on flights").checked, true, toc .. ": Hide on flights shows on")
    wow.Click(S.switch("Hide on flights"))
    equal(ns.db.hide_on_flights, false, toc .. ": clicking turns it off")
    wow.Click(S.switch("Hide on flights"))
    equal(ns.db.hide_on_flights, true, toc .. ": and on again")

    wow.Click(S.switch("Show floating button"))
    equal(ns.db.show_floating_button, false, toc .. ": Show floating button off")
    equal(S.floating():IsShown(), false, toc .. ": hides the button")
    wow.Click(S.switch("Show floating button"))
    equal(S.floating():IsShown(), true, toc .. ": and shows it again")

    ns.db.floating_button_point = { point = "TOP", relativePoint = "TOP", x = 1, y = 1 }
    wow.Click(wow.FindButton("Reset button position"))
    equal(ns.db.floating_button_point, nil, toc .. ": Reset button position clears the saved spot")

    -- Speed page switches rebuild the macro.
    HC.Settings:Show("Speed")
    equal(ns.getMacro(), "/cast [flyable,nocombat]!Spell 783;!Spell 783", toc .. ": travel macro")
    wow.Click(S.switch("Use Travel Form outdoors"))
    equal(ns.db.druid_use_travel, false, toc .. ": Travel Form switch off")
    equal(S.primary():GetAttribute("macrotext"), "", toc .. ": no Travel Form and no Cat Form means no macro")
    assert(wow.FindText("No speed macro yet for this class and level."), toc .. ": Current macro says so")
    wow.Click(S.switch("Use Travel Form outdoors"))
    wow.Click(S.switch("Enable speed macro"))
    equal(ns.db.enabled, false, toc .. ": Enable speed macro off")
    equal(S.primary():GetAttribute("macrotext"), "", toc .. ": empties the key")
    wow.Click(S.switch("Enable speed macro"))
    equal(S.primary():GetAttribute("macrotext"), "/cast [flyable,nocombat]!Spell 783;!Spell 783", toc .. ": and refills it")

    -- Settings search finds Speedster's rows and jumps to them.
    local function find(query, wanted)
        for _, match in ipairs(HC.Settings:Search(query)) do
            if match.label == wanted then return match end
        end
    end
    local match = find("flights", "Hide on flights")
    assert(match, toc .. ": search finds Hide on flights")
    equal(match.page, "Visibility", toc .. ": on Visibility")
    match = find("travel", "Use Travel Form outdoors")
    assert(match, toc .. ": search finds Travel Form")
    equal(match.page, "Speed", toc .. ": on Speed")
    assert(find("floating", "Show floating button"), toc .. ": search finds the floating button")
    HC.Settings:Focus("Visibility", "Hide on flights")
    equal(HC.Settings.selected, "Visibility", toc .. ": focusing a result opens its page")

    -- Troubleshooting shows Speedster's status card.
    HC.Settings:Show("Troubleshooting")
    local status = HC.spec.status()
    equal(status, "Speed macro: on\nKey: Not bound\nFloating button: shown", toc .. ": status card")
end

io.write("Speedster settings tests passed\n")
