-- Slash commands, the minimap menu and profiles.
local S = dofile("tests/support.lua")
local equal, contains, wow = S.equal, S.contains, S.wow

for _, toc in ipairs(S.TOCS) do
    local ns, HC, world = S.load({ toc = toc, class = "ROGUE", known = { [2983] = true },
        saved = { enabled = true, show_floating_button = true } })
    local speedKey = ns.getPrimaryBindingCommand()

    -- help lists Speedster's own commands and actions.
    local mark = #wow.printed
    SlashCmdList.SPEEDSTER("help")
    local help = S.printedSince(mark)
    for _, part in ipairs({ "bind", "macro", "toggle", "reset position", "Press your speed key",
        "Shift-drag the floating button" }) do
        contains(help, part, toc .. ": help mentions " .. part)
    end
    SlashCmdList.SPEEDSTER("version")
    contains(wow.LastPrint(), "1.3.0-dev1", toc .. ": version prints the loaded version")

    -- bind.
    SlashCmdList.SPEEDSTER("bind")
    equal(world.bindings.NUMPADMINUS, speedKey, toc .. ": bind with no key uses NUMPADMINUS")
    equal(wow.LastPrint(), "Speedster: bound speed key to NUMPADMINUS", toc .. ": and says so")
    SlashCmdList.SPEEDSTER("bind  f ")
    equal(world.bindings.F, speedKey, toc .. ": keys are trimmed and upper-cased")
    equal(world.bindings.NUMPADMINUS, nil, toc .. ": the old key is released")
    world.bindings.G = "JUMP"
    mark = #wow.printed
    SlashCmdList.SPEEDSTER("bind G")
    contains(S.printedSince(mark), "'G' replaced previous binding 'JUMP'.", toc .. ": replacing a binding warns")
    equal(world.bindings.G, speedKey, toc .. ": and binds")
    world.combat = true
    SlashCmdList.SPEEDSTER("bind H")
    equal(world.bindings.H, nil, toc .. ": no binding in combat")
    equal(wow.LastPrint(), "Speedster: You are in combat", toc .. ": and says why")
    equal(ns.unbindAction(speedKey), false, toc .. ": no unbinding in combat either")
    world.combat = false

    -- macro.
    mark = #wow.printed
    SlashCmdList.SPEEDSTER("macro")
    equal(S.printedSince(mark), "Speedster: speed macro:\n/cast Spell 2983", toc .. ": macro prints the macro")
    ns.db.enabled = false
    SlashCmdList.SPEEDSTER("macro")
    equal(wow.LastPrint(), "Speedster: no speed macro yet for this class and level", toc .. ": an empty macro says so")
    ns.db.enabled = true

    -- toggle and reset position.
    SlashCmdList.SPEEDSTER("toggle")
    equal(S.floating():IsShown(), false, toc .. ": toggle hides the button")
    equal(wow.LastPrint(), "Speedster: floating button hidden", toc .. ": and says so")
    SlashCmdList.SPEEDSTER("toggle")
    equal(S.floating():IsShown(), true, toc .. ": toggle shows it")
    equal(wow.LastPrint(), "Speedster: floating button shown", toc .. ": and says so")
    ns.db.floating_button_point = { point = "TOP", relativePoint = "TOP", x = 1, y = 2 }
    S.floating():ClearAllPoints()
    S.floating():SetPoint("TOP", UIParent, "TOP", 1, 2)
    world.combat = true
    mark = #wow.printed
    SlashCmdList.SPEEDSTER("reset position")
    contains(S.printedSince(mark), "Speedster: You are in combat", toc .. ": reset in combat waits")
    equal(S.floating():GetPoint(), "TOP", toc .. ": without moving yet")
    S.regen(ns)
    equal(S.floating():GetPoint(), "CENTER", toc .. ": and moves after combat")

    -- Minimap: HammerCore's menu with Speedster's items.
    equal(HC.Minimap.RightClickMode(), "menu", toc .. ": right-click opens the menu")
    equal(HC.Minimap.RightClickLabel(), "menu", toc .. ": tooltip says menu")
    local texts = {}
    for _, item in ipairs(HC.Minimap:MenuItems()) do texts[#texts + 1] = item.separator and "-" or item.text end
    equal(table.concat(texts, ","), "Speedster settings,-,Speed key,Show floating button,Reset button position",
        toc .. ": menu items")
    local item = S.menuItem(HC, "Speed key")
    equal(item.checked, true, toc .. ": Speed key is ticked")
    item.func()
    equal(ns.db.enabled, false, toc .. ": Speed key turns the macro off")
    equal(S.primary():GetAttribute("macrotext"), "", toc .. ": and empties the key")
    equal(wow.LastPrint(), "Speedster: speed key off", toc .. ": and says so")
    equal(S.menuItem(HC, "Speed key").checked, false, toc .. ": unticked")
    S.menuItem(HC, "Speed key").func()
    equal(S.primary():GetAttribute("macrotext"), "/cast Spell 2983", toc .. ": and back on")
    S.menuItem(HC, "Show floating button").func()
    equal(S.floating():IsShown(), false, toc .. ": Show floating button hides it")
    equal(S.menuItem(HC, "Show floating button").checked, false, toc .. ": unticked")
    S.menuItem(HC, "Show floating button").func()
    equal(S.floating():IsShown(), true, toc .. ": and shows it")
    ns.db.floating_button_point = { point = "TOP", relativePoint = "TOP", x = 1, y = 2 }
    S.menuItem(HC, "Reset button position").func()
    equal(ns.db.floating_button_point, nil, toc .. ": Reset button position works")
    S.menuItem(HC, "Speedster settings").func()
    equal(HC.Settings:IsShown(), true, toc .. ": the settings item opens settings")
    HC.Minimap:RightClick()
    equal(HC.Menu:IsShown(), true, toc .. ": right-click opens the menu")
    HC.Menu:Close()

    -- Old commands stay gone.
    for _, old in ipairs({ "options", "diagnostics" }) do
        SlashCmdList.SPEEDSTER(old)
        equal(wow.LastPrint(), "Speedster: unknown command. Type /speedster help for the list.",
            toc .. ": old command '" .. old .. "' is removed")
    end

    -- Profiles: Speedster saves per character and has none of its own.
    equal(HC.Profiles and HC.Profiles.enabled or false, false, toc .. ": no profiles")
    equal(S.menuItem(HC, "Profiles"), nil, toc .. ": so the menu has no Profiles item")
    equal(HC.Commands.byName.profile, nil, toc .. ": and no profile command")
    for _, spec in ipairs(HC.Settings.order) do
        equal(spec.name ~= "Profiles", true, toc .. ": and no Profiles page")
    end
    SlashCmdList.SPEEDSTER("profile")
    equal(wow.LastPrint(), "Speedster: unknown command. Type /speedster help for the list.", toc .. ": profile is unknown")
end

-- Minimap right-click set to Settings opens settings instead.
do
    local ns, HC = S.load({ saved = { enabled = true, hammerCore = { minimapRightClick = "settings" } } })
    equal(HC.Minimap.RightClickMode(), "settings", "the saved choice is used")
    HC.Minimap:RightClick()
    equal(HC.Settings:IsShown(), true, "right-click opens settings")
end

io.write("Speedster command tests passed\n")
