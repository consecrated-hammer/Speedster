package.path = "./tests/hammercore/?.lua;" .. package.path
local wow = require("wow")

local function equal(actual, expected, label)
    if actual ~= expected then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local bindings
local function loadAddon(tocName, saved, class)
    local camelot = tocName:find("Camelot") and "Camelot" or nil
    wow.Install({ Speedster = { Version = "0.4.11-dev1", ["X-Speedster-Target"] = camelot } })
    bindings = {}
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
    C_SpellBook = { IsSpellKnown = function(id) return id == 783 or id == 1850 end }
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

for _, toc in ipairs({ "Speedster.toc", "Speedster_Camelot.toc" }) do
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
    equal(table.concat(names, ","), "Speed,Visibility,Key Bindings,Theme,Commands,Troubleshooting,About",
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
for _, toc in ipairs({ "Speedster.toc", "Speedster_Camelot.toc" }) do
    local ns = loadAddon(toc, { enabled = true, hammerCore = { theme = "classic" } }, "SHAMAN")
    local HC = ns.HammerCore
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

io.write("Speedster addon tests passed\n")
