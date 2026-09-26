local addon, ns = ...

local core = CreateFrame("Frame", addon.."Core")

local function addonMetadata(key)
	local getter = C_AddOns and C_AddOns.GetAddOnMetadata
	local value = getter and getter(addon, key)
	if value ~= nil then return value end
	return GetAddOnMetadata and GetAddOnMetadata(addon, key)
end
ns.addonMetadata = addonMetadata

-- Speedster supports WoW Forever only (the Camelot TOC).
ns.core = core

local buttonName = addon.."_SpeedButton"
local bindingCommand = "CLICK "..buttonName..":LeftButton"
local utilityActions = {
	{ id = "druidDash", label = "Druid: Dash", spellIDs = { 1850 } },
	{ id = "hunterPack", label = "Hunter: Aspect of the Pack", spellIDs = { 13159 }, warning = "Group travel only: taking damage dazes affected party members." },
	{ id = "mageSlowFall", label = "Mage: Slow Fall", spellIDs = { 130 }, warning = "Consumes a Light Feather." },
	{ id = "priestLevitate", label = "Priest: Levitate", spellIDs = { 1706 }, warning = "Consumes a Light Feather." },
	{ id = "shamanWaterWalking", label = "Shaman: Water Walking", spellIDs = { 546 }, selfCast = true, warning = "Consumes Fish Oil; damage cancels the effect." },
	{ id = "paladinFreedom", label = "Paladin: Blessing of Freedom", spellIDs = { 1044 }, selfCast = true },
	{ id = "gnomeEscapeArtist", label = "Gnome: Escape Artist", spellIDs = { 20589 } },
	{ id = "skyborneWalkOnAir", label = "Skyborne: Walk on Air", spellIDs = { 1259416 } },
	{ id = "skyborneSkysight", label = "Skyborne: Skysight", spellIDs = { 1259686 } },
}
local db
local speedButton
local floatingButton
local utilityButtons = {}
local pendingRefresh
local pendingFloatingReset
local FLOATING_BUTTON_SIZE = 36
local ICON_PATH = "Interface\\AddOns\\Speedster\\textures\\Speedster.tga"
local FALLBACK_ICON_PATH = "Interface\\Icons\\INV_Misc_QuestionMark"

local function trim(text)
	if type(text) ~= "string" then return "" end
	return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function isSpellKnownSafe(spellID)
	-- Forever can expose the modern API without reporting every learned
	-- form, so the legacy checks are merged in.
	if C_SpellBook and C_SpellBook.IsSpellKnown then
		local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
		local ok, known = pcall(C_SpellBook.IsSpellKnown, spellID, bank)
		if ok and known then return true end
	end
	if IsSpellKnown then
		local ok, known = pcall(IsSpellKnown, spellID)
		if ok and known then return true end
	end
	if IsPlayerSpell then
		local ok, known = pcall(IsPlayerSpell, spellID)
		if ok and known then return true end
	end
	return false
end
ns.isSpellKnownSafe = isSpellKnownSafe

local function getSpellNameIfKnown(spellID)
	if not isSpellKnownSafe(spellID) then return end
	local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)
	if not name then
		name = GetSpellInfo(spellID)
	end
	return name
end

local function utilityActionFor(spec)
	for _, spellID in ipairs(spec.spellIDs) do
		local spellName = getSpellNameIfKnown(spellID)
		if spellName then
			local macro = "/cast "
			if spec.selfCast then macro = macro.."[@player] " end
			return spellName, macro..spellName
		end
	end
end

function ns.getUtilityActions()
	local actions = {}
	for _, spec in ipairs(utilityActions) do
		local spellName, macro = utilityActionFor(spec)
		if spellName then
			actions[#actions + 1] = {
				id = spec.id,
				label = spec.label,
				spellName = spellName,
				macro = macro,
				warning = spec.warning,
				bindingCommand = "CLICK "..buttonName.."_"..spec.id..":LeftButton",
			}
		end
	end
	return actions
end

function ns.getUtilityActionIDs()
	local ids = {}
	for _, spec in ipairs(utilityActions) do
		ids[#ids + 1] = spec.id
	end
	return ids
end

function ns.getPrimaryBindingCommand()
	return bindingCommand
end

local function buildMacro()
	if not db or not db.enabled then return "" end

	local _, classFile = UnitClass("player")
	if classFile == "DRUID" then
		local cat = getSpellNameIfKnown(768)
		local aquatic = getSpellNameIfKnown(1066)
		local travel = db.druid_use_travel and getSpellNameIfKnown(783) or nil
		local flight = db.druid_use_travel and (getSpellNameIfKnown(40120) or getSpellNameIfKnown(33943)) or nil

		if travel then
			local air = flight or travel
			local clauses = {}
			if aquatic then clauses[#clauses + 1] = "[swimming]!"..aquatic end
			if cat then clauses[#clauses + 1] = "[indoors]!"..cat end
			clauses[#clauses + 1] = "[flyable,nocombat]!"..air
			clauses[#clauses + 1] = "!"..travel
			return "/cast "..table.concat(clauses, ";")
		end

		if aquatic then
			if cat then return ("/cast [swimming]!%s;!%s"):format(aquatic, cat) end
			return "/cast [swimming]!"..aquatic
		end
		if cat then return "/cast !"..cat end
	end

	if classFile == "SHAMAN" then
		local ghostWolf = db.shaman_use_ghost_wolf and getSpellNameIfKnown(2645) or nil
		if ghostWolf then return "/cast !"..ghostWolf end
	elseif classFile == "HUNTER" then
		local cheetah = getSpellNameIfKnown(5118)
		if cheetah then return "/cast !"..cheetah end
	elseif classFile == "ROGUE" then
		local sprint = getSpellNameIfKnown(2983)
		if sprint then return "/cast "..sprint end
	elseif classFile == "MAGE" then
		local blink = getSpellNameIfKnown(1953)
		if blink then return "/cast "..blink end
	end

	return ""
end

ns.getMacro = buildMacro

local function applyFloatingButtonPosition()
	if not floatingButton or not db then return end

	floatingButton:ClearAllPoints()
	if type(db.floating_button_point) == "table" and db.floating_button_point.point and db.floating_button_point.relativePoint then
		floatingButton:SetPoint(
			db.floating_button_point.point,
			UIParent,
			db.floating_button_point.relativePoint,
			db.floating_button_point.x or 0,
			db.floating_button_point.y or 0
		)
	else
		floatingButton:SetPoint("CENTER", UIParent, "CENTER", 0, -120)
	end
end

local function saveFloatingButtonPosition()
	if not floatingButton or not db then return end
	local point, _, relativePoint, x, y = floatingButton:GetPoint(1)
	if not point or not relativePoint then return end
	db.floating_button_point = {
		point = point,
		relativePoint = relativePoint,
		x = x or 0,
		y = y or 0,
	}
end

function ns.resetFloatingButtonPosition()
	if not db then
		return false, "settings are not ready yet"
	end

	db.floating_button_point = nil
	if not floatingButton then
		return true
	end
	if InCombatLockdown() then
		pendingFloatingReset = true
		return false, SPELL_FAILED_AFFECTING_COMBAT
	end

	applyFloatingButtonPosition()
	return true
end

local function createFloatingButton()
	floatingButton = CreateFrame("Button", addon.."FloatingButton", UIParent, "ActionButtonTemplate, SecureActionButtonTemplate, SecureHandlerBaseTemplate")
	floatingButton:SetSize(FLOATING_BUTTON_SIZE, FLOATING_BUTTON_SIZE)
	floatingButton:SetMovable(true)
	floatingButton:SetClampedToScreen(true)
	floatingButton:EnableMouse(true)
	floatingButton:RegisterForClicks("AnyUp", "AnyDown")
	floatingButton:SetAttribute("type", "macro")
	floatingButton:SetAttribute("macrotext", "")
	floatingButton:SetAttribute("shift-type1", "")
	local frameName = floatingButton:GetName()
	local icon = _G[frameName.."Icon"]
	if not icon then
		icon = floatingButton:CreateTexture(nil, "ARTWORK")
		icon:SetPoint("TOPLEFT", floatingButton, "TOPLEFT", 6, -6)
		icon:SetPoint("BOTTOMRIGHT", floatingButton, "BOTTOMRIGHT", -6, 6)
	end
	icon:SetTexture(ICON_PATH)
	if not icon:GetTexture() then
		icon:SetTexture(FALLBACK_ICON_PATH)
	end
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	icon:SetVertexColor(0.95, 0.95, 0.95)
	floatingButton.icon = icon

	local hotKey = _G[frameName.."HotKey"]
	if hotKey then
		hotKey:Hide()
	end
	local nameText = _G[frameName.."Name"]
	if nameText then
		nameText:Hide()
	end
	local countText = _G[frameName.."Count"]
	if countText then
		countText:Hide()
	end

	floatingButton:SetScript("OnMouseDown", function(self, button)
		if button ~= "LeftButton" then return end
		if InCombatLockdown() or not IsShiftKeyDown() then return end
		self._isDragging = true
		self:StartMoving()
	end)
	floatingButton:SetScript("OnMouseUp", function(self)
		if not self._isDragging then return end
		self._isDragging = nil
		self:StopMovingOrSizing()
		saveFloatingButtonPosition()
	end)
	floatingButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Speedster")
		GameTooltip:AddLine("Left-click: use speed macro", 0.85, 0.85, 0.85)
		GameTooltip:AddLine("Shift + left-drag: move button", 0.85, 0.85, 0.85)
		GameTooltip:Show()
	end)
	floatingButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	applyFloatingButtonPosition()
end

function ns.refreshSpeedButton()
	if not speedButton then return end
	if InCombatLockdown() then
		pendingRefresh = true
		return
	end
	pendingRefresh = nil
	local macroText = buildMacro()
	speedButton:SetAttribute("macrotext", macroText)
	for _, spec in ipairs(utilityActions) do
		local utilityButton = utilityButtons[spec.id]
		if utilityButton then
			local _, utilityMacro = utilityActionFor(spec)
			utilityButton:SetAttribute("macrotext", utilityMacro or "")
		end
	end
	if floatingButton then
		floatingButton:SetAttribute("macrotext", macroText)
		floatingButton:SetShown(not not db.show_floating_button)
	end
	if ns.refreshOptions then
		ns.refreshOptions()
	end
end

function ns.getBindingText()
	return ns.getActionBindingText(bindingCommand)
end

function ns.getActionBindingText(command)
	local key1, key2 = GetBindingKey(command)
	if key1 and key2 then
		return ("%s, %s"):format(GetBindingText(key1, "KEY_") or key1, GetBindingText(key2, "KEY_") or key2)
	elseif key1 then
		return GetBindingText(key1, "KEY_") or key1
	end
	return NOT_BOUND
end

function ns.bindActionKey(command, keyText)
	if InCombatLockdown() then
		return false, SPELL_FAILED_AFFECTING_COMBAT
	end

	local key = trim(keyText)
	if key == "" then
		key = "NUMPADMINUS"
	end
	key = key:upper()

	local oldAction = GetBindingAction(key)
	local oldKey = GetBindingKey(command)
	if oldAction ~= "" and oldAction ~= command then
		ns.HammerCore.Print(("'%s' replaced previous binding '%s'."):format(key, GetBindingName(oldAction) or oldAction))
	end

	if not SetBinding(key, command) then
		return false, "failed to set binding"
	end

	if oldKey and oldKey ~= key then
		SetBinding(oldKey, nil)
	end

	SaveBindings(GetCurrentBindingSet())
	if ns.refreshOptions then
		ns.refreshOptions()
	end
	return true, key
end

function ns.bindKey(keyText)
	return ns.bindActionKey(bindingCommand, keyText)
end

-- Settings, commands, chat, the minimap button and the startup message come
-- from HammerCore (Libs/HammerCore); see Setup.lua.

core:SetScript("OnEvent", function(_, event, ...)
	if event == "ADDON_LOADED" then
		local addonName = ...
		if addonName ~= addon then return end

		ns.dbWasFresh = type(SpeedsterDB) ~= "table"
		if type(SpeedsterDB) ~= "table" then
			SpeedsterDB = nil
		end

		SpeedsterDB = SpeedsterDB or {
			enabled = true,
			druid_use_travel = true,
			shaman_use_ghost_wolf = true,
			show_floating_button = true,
		}
		db = SpeedsterDB
		ns.db = db
		if db.show_floating_button == nil then
			db.show_floating_button = true
		end
		-- Flight-master form cancelling was Retail-only and is gone.
		db.cancel_form_on_taxi = nil
		if db.shaman_use_ghost_wolf == nil then
			db.shaman_use_ghost_wolf = true
		end

		speedButton = CreateFrame("Button", buttonName, UIParent, "SecureActionButtonTemplate")
		speedButton:RegisterForClicks("AnyUp", "AnyDown")
		speedButton:SetAttribute("type", "macro")
		speedButton:SetAttribute("macrotext", "")
		speedButton:Hide()
		for _, spec in ipairs(utilityActions) do
			local utilityButton = CreateFrame("Button", buttonName.."_"..spec.id, UIParent, "SecureActionButtonTemplate")
			utilityButton:RegisterForClicks("AnyUp", "AnyDown")
			utilityButton:SetAttribute("type", "macro")
			utilityButton:SetAttribute("macrotext", "")
			utilityButton:Hide()
			utilityButtons[spec.id] = utilityButton
			_G["BINDING_NAME_CLICK "..buttonName.."_"..spec.id..":LeftButton"] = spec.label
		end
		createFloatingButton()
		ns.HammerCore:Start()

		_G["BINDING_HEADER_SPEEDSTER"] = "Speedster"
		_G["BINDING_NAME_"..bindingCommand] = "Use speed macro"

		ns.refreshSpeedButton()
	elseif event == "PLAYER_REGEN_ENABLED" then
		if pendingFloatingReset then
			pendingFloatingReset = nil
			applyFloatingButtonPosition()
		end
		if pendingRefresh then
			ns.refreshSpeedButton()
		end
	elseif event == "SPELLS_CHANGED"
	or event == "LEARNED_SPELL_IN_TAB"
	or event == "LEARNED_SPELL_IN_SPELLBOOK" then
		ns.refreshSpeedButton()
	end
end)

core:RegisterEvent("ADDON_LOADED")
core:RegisterEvent("PLAYER_REGEN_ENABLED")
core:RegisterEvent("SPELLS_CHANGED")
for _, eventName in ipairs({
	"LEARNED_SPELL_IN_TAB",
	"LEARNED_SPELL_IN_SPELLBOOK",
}) do
	pcall(core.RegisterEvent, core, eventName)
end
