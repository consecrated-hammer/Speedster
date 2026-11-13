local addon, ns = ...
local HC = ns.HammerCore

-- Declares Speedster to HammerCore: commands, the floating-button verbs,
-- the minimap menu, flights, status, diagnostics and About.

local tips = {
	"Gotta go fast. Responsibly.",
	"The floating button floats. It does not, however, fly.",
	"Ghost Wolf: faster than walking, slower than explaining why you are a wolf.",
	"Aspect of the Pack: excellent for travel, terrible for friendships.",
	"Slow Fall: the art of arriving late but alive.",
	"Every second saved is a second spent waiting for the tank anyway.",
	"Speed key armed. Destination: probably the flight master.",
	"Escape Artist: for gnomes who have simply had enough.",
	"Travel Form outdoors, cat form indoors, dignity optional.",
	"Water Walking: technically a shortcut. Legally a grey area.",
	"The fastest route is the one you were already on.",
	"Sprinting past the quest giver does not decline the quest.",
}

local function setFloating(shown)
	ns.db.show_floating_button = shown
	ns.refreshSpeedButton()
	if shown and ns.hiddenForFlight() then
		HC.Print("floating button shown after you land")
	else
		HC.Print("floating button " .. (shown and "shown" or "hidden"))
	end
end

local function resetPosition()
	local ok, reason = ns.resetFloatingButtonPosition()
	if not ok and reason then HC.Print(reason) end
end

-- The minimap right-click menu, after HammerCore's own settings item.
local function menuItems()
	local db = ns.db or {}
	return {
		{ text = "Speed key", checked = db.enabled and true or false, func = function()
			db.enabled = not db.enabled
			ns.refreshSpeedButton()
			HC.Print("speed key " .. (db.enabled and "on" or "off"))
		end },
		{ text = "Show floating button", checked = db.show_floating_button and true or false,
			func = function() setFloating(not db.show_floating_button) end },
		{ text = "Re-centre button", func = resetPosition },
	}
end

-- Highlights for HammerCore's What's new window, newest first. Every
-- CurseForge release gets an entry, fixes included (Kevin, 2026-11-09);
-- HammerCore's tools/whatsnew_check.py fails the release without one. A
-- `page` adds a button that opens that settings page.
local WHATS_NEW = {
    { version = "1.4.1", date = "2026-11-14", items = {
        { title = "Cat got your speed key?", text = "Already in Cat Form? Press your speed key to Dash. Walk on Air still gets first dibs while falling outside combat. Toggle Use Dash in Cat Form on Speed.", kind = "new", page = "Speed" },
    } },
    { version = "1.4.0", date = "2026-11-13", items = {
        { title = "Find your speed key", text = "Key Bindings is second in the rail. Choose Speed key for your main key; optional utility actions have separate keys. Conflicts now offer Replace before taking a key.", page = "Key Bindings" },
        { title = "Clearer movement settings", text = "Speed shows your current key with Set key or Change, plus a fitted read-only macro. Search finds available preferences and individual binding actions, even after learning spells.", page = "Speed" },
        { title = "Floating button", text = "Visibility keeps the floating button, flight hiding and position reset together. Re-centre button keeps your other settings and bindings.", page = "Visibility" },
    } },
	{ version = "1.3.0", date = "2026-11-10", items = {
		{ title = "Hide on flights", text = "The floating button gets out of the way while you're on a flight path and comes back when you land. Turn it off on Visibility.",
			page = "Visibility" },
		{ title = "Minimap menu", text = "Right-click the minimap button for settings, the speed key, the floating button and its position.",
			kind = "improved" },
		{ title = "Settings search", text = "Type in the box at the top of settings to jump straight to any setting.",
			kind = "improved" },
	} },
	{ version = "1.2.0", items = {
		{ title = "What's new", text = "This window, shown once after an update, with news from any other Consecrated Hammer addons you use. Reopen it with /speedster whatsnew or from the What's new page.",
			page = "Visibility" },
		{ title = "A fresh coat of paint", text = "Settings got a new look: tabs, two columns, switches, and a What's new page with every release.",
			kind = "improved" },
		{ title = "Key bindings", text = "Your speed key and extra movement actions share one tidy bindings page.",
			kind = "improved", page = "Key Bindings" },
		{ title = "Support links", text = "Discord and Buy me a coffee sit at the bottom of the settings window. Hide them on Visibility.",
			kind = "improved", page = "Visibility" },
		{ title = "Speed page icons", text = "Each section has its own icon, and racial settings only show for races that have one.",
			kind = "improved", page = "Speed" },
	} },
	{ version = "1.1.0", date = "2026-11-05", items = {
		{ title = "Walk on Air", text = "Your normal speed key and floating button can cast it while you're falling outside combat. Off until you turn it on.",
			page = "Speed" },
	} },
	-- History: written after the fact for releases from before What's new.
	{ version = "1.0.0", date = "2026-10-28", history = true, items = {
		"Speedster is now a WoW Forever addon, and the licence links work.",
	} },
	{ version = "0.5.0", date = "2026-09-26", history = true, items = {
		"A lore quiz: the quest marker on the About page, or /speedster quiz.",
		"The same core commands and settings layout as every Consecrated Hammer addon.",
	} },
	{ version = "0.4.1", date = "2026-09-18", history = true, items = {
		{ text = "WoW Forever support: one key for the fastest way to move.", page = "Speed" },
	} },
}

HC:Init({
	name = "Speedster",
	command = "speedster",
	savedVariable = "SpeedsterDB",
	db = function() return ns.db end,
	icon = "Interface\\AddOns\\Speedster\\textures\\Speedster",
	legacy = {
		startupMessage = "show_startup_message",
		minimap = "show_minimap_button",
		minimapAngle = "minimap_angle",
	},
	clientLabel = function() return "WoW Forever" end,
	minimap = { menu = menuItems },
	-- Takeoff and landing only, for Hide on flights; no flight times.
	flights = { estimates = false },
	toggle = { help = "Show or hide the floating button", run = function() setFloating(not ns.db.show_floating_button) end },
	resetPosition = resetPosition,
	status = function()
		return table.concat({
			"Speed key: " .. (ns.db.enabled and "on" or "off"),
			"Key: " .. ns.getBindingText(),
			"Floating button: " .. (ns.db.show_floating_button and (ns.hiddenForFlight() and "hidden for the flight" or "shown") or "hidden"),
		}, "\n")
	end,
	diagnostics = function() return ns.BuildDiagnosticReport() end,
	whatsNew = WHATS_NEW,
	about = {
		note = "TRAVEL ADVISORY",
		tips = tips,
		action = "Hurry up",
	},
})

HC.Flights:OnTakeoff(function() ns.setOnFlight(true) end)
HC.Flights:OnLanding(function() ns.setOnFlight(false) end)

HC.Commands:Add({ name = "bind", args = "[key]", section = "Speed", help = "Bind the speed key (default NUMPADMINUS)",
	run = function(args)
		local ok, result = ns.bindKey(args)
		if ok then
			HC.Print(("bound speed key to %s"):format(GetBindingText(result, "KEY_") or result))
		else
			HC.Print(result)
		end
	end })
HC.Commands:Add({ name = "macro", section = "Speed", help = "Print the current speed macro",
	run = function()
		local macro = ns.getMacro()
		if macro == "" then return HC.Print("no speed macro yet for this class and level") end
		HC.Print("speed macro:")
		for line in macro:gmatch("[^\n]+") do print(line) end
	end })
HC.Commands:AddAction({ section = "Speed", usage = "Press your speed key", help = "Use the fastest known movement" })
HC.Commands:AddAction({ section = "Speed", usage = "Click the floating button", help = "Use the speed key" })
HC.Commands:AddAction({ section = "Speed", usage = "Shift-drag the floating button", help = "Move it" })
