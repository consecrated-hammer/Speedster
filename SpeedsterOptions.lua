local addon, ns = ...
local HC = ns.HammerCore
local UI, T = HC.UI, HC.Theme

-- Speedster's own settings pages on HammerCore's window: Speed, Key
-- Bindings, and the floating button on Visibility.  HammerCore adds the
-- minimap button, startup message, Theme, Commands, Troubleshooting and About.

-- ── Key capture ────────────────────────────────────────────────────────────
-- One capture frame over the settings window takes the next key, mouse
-- button or wheel turn and binds it to the waiting command.  Escape cancels.

local capture = { active = false }

local function normalizeBindingKey(key)
	if key == "LeftButton" then key = "BUTTON1" end
	if key == "RightButton" then key = "BUTTON2" end
	if key == "MiddleButton" then key = "BUTTON3" end
	if GetConvertedKeyOrButton then key = GetConvertedKeyOrButton(key) end
	if not key or key == "" then return end
	if IsKeyPressIgnoredForBinding and IsKeyPressIgnoredForBinding(key) then return end
	if CreateKeyChordStringUsingMetaKeyState then return CreateKeyChordStringUsingMetaKeyState(key) end
	local parts = {}
	if IsControlKeyDown and IsControlKeyDown() then parts[#parts + 1] = "CTRL" end
	if IsAltKeyDown and IsAltKeyDown() then parts[#parts + 1] = "ALT" end
	if IsShiftKeyDown and IsShiftKeyDown() then parts[#parts + 1] = "SHIFT" end
	parts[#parts + 1] = key
	return table.concat(parts, "-")
end

local function setPropagation(frame, propagate)
	if frame.SetPropagateKeyboardInput then frame:SetPropagateKeyboardInput(propagate) end
	if frame.SetPropagateMouseClicks then frame:SetPropagateMouseClicks(propagate) end
	if frame.SetPropagateMouseMotion then frame:SetPropagateMouseMotion(propagate) end
end

local function stopCapture()
	capture.active = false
	if capture.button then capture.button:SetText("Bind key") end
	capture.button, capture.command, capture.label = nil, nil, nil
	if capture.frame then
		capture.frame:Hide()
		capture.frame:EnableKeyboard(false)
		capture.frame:EnableMouse(false)
		setPropagation(capture.frame, true)
	end
end

local function captureKey(rawKey)
	if rawKey == "ESCAPE" then
		stopCapture()
		HC.Print("key binding cancelled")
		return
	end
	local key = normalizeBindingKey(rawKey)
	if not key then return end
	local ok, result = ns.bindActionKey(capture.command, key)
	if ok then
		HC.Print(("bound %s to %s"):format(capture.label or "action", GetBindingText(result, "KEY_") or result))
	else
		HC.Print(result)
	end
	stopCapture()
	if ns.refreshOptions then ns.refreshOptions() end
end

local function ensureCaptureFrame()
	if capture.frame then return capture.frame end
	local owner = HC.Settings.window or UIParent
	local frame = CreateFrame("Frame", nil, owner)
	frame:SetAllPoints(owner)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:EnableMouseWheel(true)
	frame:SetScript("OnKeyDown", function(_, key) captureKey(key) end)
	frame:SetScript("OnMouseDown", function(_, button) captureKey(button) end)
	frame:SetScript("OnMouseWheel", function(_, delta) captureKey(delta > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN") end)
	frame:SetScript("OnHide", function() if capture.active then stopCapture() end end)
	frame:Hide()
	capture.frame = frame
	return frame
end

local function startCapture(button, command, label)
	if capture.active then stopCapture() end
	local frame = ensureCaptureFrame()
	capture.active, capture.button, capture.command, capture.label = true, button, command, label
	button:SetText("Press a key (Esc cancels)")
	frame:Show()
	frame:EnableKeyboard(true)
	frame:EnableMouse(true)
	setPropagation(frame, false)
end
ns.StopBindCapture = stopCapture

-- Settings re-read their values when anything outside them changes.
function ns.refreshOptions()
	local settings = HC.Settings
	if settings:IsShown() then settings:Select(settings.selected) end
end

-- ── Speed ──────────────────────────────────────────────────────────────────

HC.Settings:NewPage({ name = "Speed", description = "One key for the fastest way to move." }, function(panel, y)
	local db = function() return ns.db end
	_, y = UI.Header(panel, "Speed macro", y)
	_, y = UI.Check(panel, "Enable speed macro", "Build and bind the speed macro.", y,
		function() return db().enabled end,
		function(value) db().enabled = value; ns.refreshSpeedButton() end)

	local _, classFile = UnitClass("player")
	if classFile == "DRUID" or classFile == "SHAMAN" then
		_, y = UI.Header(panel, "Class", y)
		local row
		if classFile == "DRUID" then
			row, y = UI.Check(panel, "Use Travel Form outdoors", "Unlocks after learning Travel Form.", y,
				function() return db().druid_use_travel end,
				function(value) db().druid_use_travel = value; ns.refreshSpeedButton() end)
			UI.OnRefresh(panel, function()
				UI.SetEnabled(row.hcCheckbox, ns.isSpellKnownSafe(783) or ns.isSpellKnownSafe(33943) or ns.isSpellKnownSafe(40120))
			end)
		else
			row, y = UI.Check(panel, "Use Ghost Wolf", "Unlocks after learning Ghost Wolf.", y,
				function() return db().shaman_use_ghost_wolf end,
				function(value) db().shaman_use_ghost_wolf = value; ns.refreshSpeedButton() end)
			UI.OnRefresh(panel, function() UI.SetEnabled(row.hcCheckbox, ns.isSpellKnownSafe(2645)) end)
		end
	end

	_, y = UI.Header(panel, "Behaviour", y)
	local taxi
	taxi, y = UI.Check(panel, ns.camelotPreview and "Cancel shapeshift at flight masters (unavailable in Forever)"
			or "Cancel shapeshift at flight masters",
		"Leave a travel form automatically when you open a flight map.", y,
		function() return not ns.camelotPreview and db().cancel_form_on_taxi end,
		function(value)
			if ns.camelotPreview then return end
			db().cancel_form_on_taxi = value
		end)
	if ns.camelotPreview then UI.SetEnabled(taxi.hcCheckbox, false) end

	local divider = T.Fill(panel:CreateTexture(nil, "ARTWORK"), "edge")
	divider:SetHeight(1)
	divider:SetPoint("TOPLEFT", UI.PAD, y - 2)
	divider:SetPoint("TOPRIGHT", -20, y - 2)
	y = y - 20
	_, y = UI.Header(panel, "Current macro", y)
	_, y = UI.Text(panel, "Speedster applies this macro to your speed key. No action needed.", y)
	_, y = UI.TextInput(panel, "", "Select this generated macro and copy it with Ctrl+C.", y,
		function()
			local macro = ns.getMacro()
			return macro ~= "" and macro or "No speed macro yet for this class and level."
		end,
		function() end,
		UI.CONTENT_WIDTH, 440)
	return y
end)

-- ── Visibility: the floating button ────────────────────────────────────────

HC.Settings:AddVisibility()
HC.spec.visibility = function(panel, y)
	_, y = UI.Header(panel, "Floating button", y)
	_, y = UI.Check(panel, "Show floating button", "A clickable speed button on screen. Shift-drag to move it.", y,
		function() return ns.db.show_floating_button end,
		function(value) ns.db.show_floating_button = value; ns.refreshSpeedButton() end)
	local reset = UI.Button(panel, 200, 22)
	reset:SetPoint("TOPLEFT", UI.PAD, y - 4)
	reset:SetText("Reset button position")
	reset:SetScript("OnClick", function() HC.Commands:Dispatch("reset position") end)
	return y - 38
end

-- ── Key Bindings ───────────────────────────────────────────────────────────

HC.Settings:NewPage({ name = "Key Bindings", description = "Keys for the speed macro and extra movement actions." }, function(panel, y)
	local card
	card, y = UI.Card(panel, y, 56)
	local name = UI.FontString(card)
	name:SetPoint("TOPLEFT", 16, -12)
	name:SetText("Speed macro")
	local current = UI.FontString(card, "GameFontHighlightSmall", "muted")
	current:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
	local bind = UI.Button(card, 190, 24)
	bind:SetPoint("RIGHT", -12, 0)
	bind:SetText("Bind key")
	UI.AttachHint(bind, "Bind key", "Click, then press a key, mouse button or wheel. Esc cancels.")
	bind:SetScript("OnClick", function() startCapture(bind, ns.getPrimaryBindingCommand(), "speed macro") end)
	UI.OnRefresh(panel, function() current:SetText("Key: " .. ns.getBindingText()) end)

	_, y = UI.Header(panel, "Additional movement actions", y)
	local listTop = y
	local none = UI.FontString(panel, "GameFontHighlightSmall", "muted")
	none:SetPoint("TOPLEFT", UI.PAD, listTop)
	none:SetText("Actions appear here once this character learns them.")
	local rows = {}
	for _, id in ipairs(ns.getUtilityActionIDs()) do
		local row = CreateFrame("Frame", nil, panel, "BackdropTemplate")
		row:SetSize(UI.CONTENT_WIDTH, 44)
		T.Surface(row, "raised", "edge")
		row.label = UI.FontString(row)
		row.label:SetPoint("TOPLEFT", 12, -8)
		row.warning = UI.FontString(row, "GameFontHighlightSmall", "muted")
		row.warning:SetPoint("TOPLEFT", row.label, "BOTTOMLEFT", 0, -3)
		row.warning:SetWidth(330)
		row.warning:SetJustifyH("LEFT")
		if row.warning.SetWordWrap then row.warning:SetWordWrap(false) end
		row.bind = UI.Button(row, 92, 22)
		row.bind:SetPoint("RIGHT", -10, 0)
		row.bind:SetText("Bind key")
		row.bind:SetScript("OnClick", function() startCapture(row.bind, row.command, row.name) end)
		row.key = UI.FontString(row, "GameFontHighlightSmall", "muted")
		row.key:SetPoint("RIGHT", row.bind, "LEFT", -10, 0)
		row:Hide()
		rows[id] = row
	end
	local function layout()
		local y = listTop
		for _, row in pairs(rows) do row:Hide() end
		local shown = 0
		for _, action in ipairs(ns.getUtilityActions()) do
			local row = rows[action.id]
			if row then
				shown = shown + 1
				row:ClearAllPoints()
				row:SetPoint("TOPLEFT", UI.PAD, y)
				row.label:SetText(action.label)
				row.warning:SetText(action.warning or "")
				row.key:SetText("Key: " .. ns.getActionBindingText(action.bindingCommand))
				row.command, row.name = action.bindingCommand, action.label
				row:Show()
				y = y - 50
			end
		end
		none:SetShown(shown == 0)
		if shown == 0 then y = y - 24 end
		panel.hcSetBottom(y)
		return y
	end
	UI.OnRefresh(panel, layout)
	return layout()
end)
