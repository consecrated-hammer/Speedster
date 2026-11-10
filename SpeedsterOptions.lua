local addon, ns = ...
local HC = ns.HammerCore
local UI, T = HC.UI, HC.Theme

-- Speedster's own settings pages on HammerCore's window: Speed, Key
-- Bindings (HammerCore's shared bindings page), and the floating button on
-- Visibility.  HammerCore adds the
-- minimap button, startup message, Theme, Commands, Troubleshooting and About.

-- Settings re-read their values when anything outside them changes.
function ns.refreshOptions()
	local settings = HC.Settings
	if settings:IsShown() then settings:Select(settings.selected) end
end

-- ── Speed ──────────────────────────────────────────────────────────────────

-- Section icons.  Spell icons come from the client, so they show even
-- before the spell is learned.
local MACRO_ICON = "Interface\\Icons\\INV_Misc_Note_01"
local CLASS_ICONS = { DRUID = 783, SHAMAN = 2645 } -- Travel Form, Ghost Wolf
-- Racial movement abilities, in the order the Racial heading prefers them:
-- the first one the player knows sets its icon, else the first listed.  Add
-- a race's speed racial here when Speedster learns to use it.
local RACIAL_SPELLS = { 1259416 } -- Walk on Air (Skyborne)

local function spellIcon(spellID)
	if C_Spell and C_Spell.GetSpellTexture then
		local ok, texture = pcall(C_Spell.GetSpellTexture, spellID)
		if ok and texture then return texture end
	end
	if GetSpellTexture then
		local ok, texture = pcall(GetSpellTexture, spellID)
		if ok and texture then return texture end
	end
end

local function racialIcon()
	for _, spellID in ipairs(RACIAL_SPELLS) do
		if ns.isSpellKnownSafe(spellID) then return spellIcon(spellID) end
	end
	return spellIcon(RACIAL_SPELLS[1])
end

HC.Settings:NewPage({ name = "Speed", description = "One key for the fastest way to move." }, function(panel, y)
	local db = function() return ns.db end
	_, y = UI.Header(panel, "Speed macro", y, MACRO_ICON)
	_, y = UI.Check(panel, "Enable speed macro", "Build and bind the speed macro.", y,
		function() return db().enabled end,
		function(value) db().enabled = value; ns.refreshSpeedButton() end)

	local _, classFile = UnitClass("player")
	if classFile == "DRUID" or classFile == "SHAMAN" then
		_, y = UI.Header(panel, "Class", y, spellIcon(CLASS_ICONS[classFile]))
		local row
		if classFile == "DRUID" then
			local function travelKnown()
				return ns.isSpellKnownSafe(783) or ns.isSpellKnownSafe(33943) or ns.isSpellKnownSafe(40120)
			end
			row, y = UI.Check(panel, "Use Travel Form outdoors", "Shift into Travel Form outdoors for the speed key.", y,
				function() return db().druid_use_travel end,
				function(value) db().druid_use_travel = value; ns.refreshSpeedButton() end)
			UI.OnRefresh(panel, function()
				UI.SetEnabled(row.hcCheckbox, travelKnown())
			end)
			-- Said out loud under the switch, not tucked in a tooltip.
			if not travelKnown() then
				local note
				note, y = UI.Text(panel, "Not learned yet. Cat Form is quick, but it's no stag. Your trainer has the antlers when you're ready.", y)
				UI.OnRefresh(panel, function() note:SetShown(not travelKnown()) end)
			end
		else
			row, y = UI.Check(panel, "Use Ghost Wolf", "Unlocks after learning Ghost Wolf.", y,
				function() return db().shaman_use_ghost_wolf end,
				function(value) db().shaman_use_ghost_wolf = value; ns.refreshSpeedButton() end)
			UI.OnRefresh(panel, function() UI.SetEnabled(row.hcCheckbox, ns.isSpellKnownSafe(2645)) end)
		end
	end

	-- Only for races with a movement racial Speedster uses; anyone else
	-- would just see a switch they can never turn on.  An existing opt-in
	-- keeps the section so it can always be switched off.
	local function knowsRacial()
		for _, spellID in ipairs(RACIAL_SPELLS) do
			if ns.isSpellKnownSafe(spellID) then return true end
		end
		return false
	end
	if knowsRacial() or db().walk_on_air_while_falling then
		_, y = UI.Header(panel, "Racial", y, racialIcon)
		local racial
		racial, y = UI.Check(panel, "Walk on Air while falling", "Requires Walk on Air. Use the normal speed key for it while falling outside combat. Your separate Walk on Air key still works.", y,
			function() return db().walk_on_air_while_falling end,
			function(value) db().walk_on_air_while_falling = value; ns.refreshSpeedButton() end)
		UI.OnRefresh(panel, function()
			-- Recheck after spellbook load; an existing opt-in can always be disabled.
			UI.SetEnabled(racial.hcCheckbox, ns.isSpellKnownSafe(1259416) or db().walk_on_air_while_falling)
		end)
	end

	y = UI.Flush(panel, y)
	local divider = T.Fill(panel:CreateTexture(nil, "ARTWORK"), "edge")
	divider:SetHeight(1)
	divider:SetPoint("TOPLEFT", UI.PAD, y - 2)
	divider:SetPoint("TOPRIGHT", -20, y - 2)
	y = y - 20
	_, y = UI.Header(panel, "Current macro", y)
	_, y = UI.Text(panel, "Speedster applies this macro to your speed key. No action needed.", y)
	local macro = CreateFrame("EditBox", nil, panel, "BackdropTemplate")
	macro:SetSize(UI.CONTENT_WIDTH - 24, 26)
	macro:SetPoint("TOPLEFT", UI.PAD + 12, y)
	macro:SetAutoFocus(false)
	macro:SetFontObject(ChatFontNormal)
	macro:SetTextInsets(8, 8, 0, 0)
	T.Surface(macro, "rail", "edge")
	local function macroText()
		local text = ns.getMacro()
		return text ~= "" and text or "No speed macro yet for this class and level."
	end
	macro:SetScript("OnEscapePressed", function(self) self:SetText(macroText()); self:ClearFocus() end)
	UI.AttachHint(macro, "Current macro", "Select and copy this generated macro if useful.")
	UI.OnRefresh(panel, function()
		if not (macro.HasFocus and macro:HasFocus()) then macro:SetText(macroText()) end
	end)
	macro:SetText(macroText())
	y = y - 34
	return y
end)

-- ── Visibility: the floating button ────────────────────────────────────────

HC.Settings:AddVisibility()
HC.spec.visibility = function(panel, y)
	_, y = UI.Header(panel, "Floating button", y, HC.spec.icon)
	_, y = UI.Check(panel, "Show floating button", "A clickable speed button on screen. Shift-drag to move it.", y,
		function() return ns.db.show_floating_button end,
		function(value) ns.db.show_floating_button = value; ns.refreshSpeedButton() end)
	_, y = UI.Check(panel, "Hide on flights", "Hide the floating button from takeoff to landing.", y,
		function() return ns.db.hide_on_flights end,
		function(value) ns.db.hide_on_flights = value; ns.refreshSpeedButton() end)
	_, y = UI.ActionButton(panel, y, "Reset button position",
		function() HC.Commands:Dispatch("reset position") end,
		"Move the floating button back to the centre of the screen.", nil, 200)
	return y
end

-- ── Key Bindings ───────────────────────────────────────────────────────────
-- HammerCore's shared page: pick an action on the right, press a key, and it
-- joins the bound list on the left.

local ADDON_ICON = "Interface\\AddOns\\Speedster\\textures\\Speedster"

local function spellIcon(name)
	if C_Spell and C_Spell.GetSpellTexture then
		local icon = C_Spell.GetSpellTexture(name)
		if icon then return icon end
	end
	if GetSpellTexture then return GetSpellTexture(name) end
end

local function actionItems()
	local items = {}
	for _, action in ipairs(ns.getUtilityActions()) do
		items[#items + 1] = {
			id = action.bindingCommand,
			name = action.label,
			icon = spellIcon(action.spellName),
			detail = action.warning,
		}
	end
	return items
end

local function speedItem()
	return {
		id = ns.getPrimaryBindingCommand(),
		name = "Speed macro",
		icon = ADDON_ICON,
		detail = "Casts the fastest way to move for where you are.",
	}
end

HC.Settings:NewPage({ name = "Key Bindings", columns = 1, description = "Keys for the speed macro and extra movement actions." }, function(panel, y)
	local bottom = HC.Bindings.Page(panel, y, {
		inputs = { keys = true, mouse = true, wheel = true },
		empty = "Nothing bound yet. Pick an action on the right.",
		poolHint = "Click one, then press a key, mouse button or wheel.",
		pool = function()
			return {
				{ title = "Speed", items = { speedItem() } },
				{ title = "Movement actions", items = actionItems(),
					empty = "Actions appear here once this character learns them." },
			}
		end,
		bound = function()
			local bound = {}
			local all = actionItems()
			table.insert(all, 1, speedItem())
			for _, item in ipairs(all) do
				local key = GetBindingKey(item.id)
				if key then
					bound[#bound + 1] = { id = item.id, name = item.name, icon = item.icon, key = key }
				end
			end
			return bound
		end,
		bind = function(item, key)
			local ok, result = ns.bindActionKey(item.id, key)
			if not ok then return false, result end
			HC.Print(("bound %s to %s"):format(item.name, GetBindingText(result, "KEY_") or result))
			return true
		end,
		unbind = function(id)
			local ok, problem = ns.unbindAction(id)
			if not ok and problem then HC.Print(problem) end
		end,
		clearAll = function()
			ns.unbindAction(ns.getPrimaryBindingCommand())
			for _, item in ipairs(actionItems()) do ns.unbindAction(item.id) end
		end,
	})
	return bottom
end)
