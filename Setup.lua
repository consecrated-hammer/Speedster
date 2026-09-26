local addon, ns = ...
local HC = ns.HammerCore

-- Declares Speedster to HammerCore: commands, the floating-button verbs,
-- the minimap right-click, status, diagnostics and About.

local tips = {
	"Gotta go fast. Responsibly.",
	"The floating button floats. It does not, however, fly.",
	"Ghost Wolf: faster than walking, slower than explaining why you are a wolf.",
	"Aspect of the Pack: excellent for travel, terrible for friendships.",
	"Slow Fall: the art of arriving late but alive.",
	"Every second saved is a second spent waiting for the tank anyway.",
	"Speed macro armed. Destination: probably the flight master.",
	"Escape Artist: for gnomes who have simply had enough.",
	"Travel Form outdoors, cat form indoors, dignity optional.",
	"Water Walking: technically a shortcut. Legally a grey area.",
	"The fastest route is the one you were already on.",
	"Sprinting past the quest giver does not decline the quest.",
}

local function setFloating(shown)
	ns.db.show_floating_button = shown
	ns.refreshSpeedButton()
	HC.Print("floating button " .. (shown and "shown" or "hidden"))
end

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
	minimap = {
		rightClick = function() setFloating(not ns.db.show_floating_button) end,
		rightClickLabel = "show or hide the floating button",
	},
	toggle = { help = "Show or hide the floating button", run = function() setFloating(not ns.db.show_floating_button) end },
	resetPosition = function()
		local ok, reason = ns.resetFloatingButtonPosition()
		if not ok and reason then HC.Print(reason) end
	end,
	status = function()
		return table.concat({
			"Speed macro: " .. (ns.db.enabled and "on" or "off"),
			"Key: " .. ns.getBindingText(),
			"Floating button: " .. (ns.db.show_floating_button and "shown" or "hidden"),
		}, "\n")
	end,
	diagnostics = function() return ns.BuildDiagnosticReport() end,
	about = {
		note = "TRAVEL ADVISORY",
		tips = tips,
		action = "Hurry up",
	},
})

HC.Commands:Add({ name = "bind", args = "[key]", section = "Speed", help = "Bind the speed macro (default NUMPADMINUS)",
	run = function(args)
		local ok, result = ns.bindKey(args)
		if ok then
			HC.Print(("bound speed macro to %s"):format(GetBindingText(result, "KEY_") or result))
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
HC.Commands:AddAction({ section = "Speed", usage = "Click the floating button", help = "Use the speed macro" })
HC.Commands:AddAction({ section = "Speed", usage = "Shift-drag the floating button", help = "Move it" })
