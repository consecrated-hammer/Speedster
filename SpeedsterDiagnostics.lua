local addonName, ns = ...

local function yesNo(value) return value and "yes" or "no" end

local function framePoint(frame)
    if not frame or not frame.GetPoint then return "not created" end
    local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
    return table.concat({ tostring(point or "?"), tostring(relativeTo and relativeTo:GetName() or "?"),
        tostring(relativePoint or "?"), string.format("%.1f", x or 0), string.format("%.1f", y or 0) }, " ")
end

function ns.BuildDiagnosticReport()
    local interface
    if GetBuildInfo then
        local ok, _, _, _, value = pcall(GetBuildInfo)
        if ok then interface = value end
    end
    local db = ns.db or SpeedsterDB or {}
    local minimap = ns.HammerCore.Minimap.button
    local state = ns.HammerCore.State() or {}
    local floating = _G[addonName .. "FloatingButton"]
    local lines = {
        "Interface: " .. tostring(interface or "unknown"),
        "Target: " .. tostring(ns.addonMetadata and ns.addonMetadata("X-Speedster-Target") or "Retail"),
        "Database: " .. (ns.dbWasFresh and "created this load" or type(ns.db) == "table" and "loaded" or "unavailable"),
        "Enabled: " .. yesNo(db.enabled),
        "Class: " .. tostring(select(2, UnitClass("player")) or "unknown"),
        "Primary binding: " .. tostring(ns.getBindingText and ns.getBindingText() or "unknown"),
        "Utility actions exposed: " .. tostring(#(ns.getUtilityActionIDs and ns.getUtilityActionIDs() or {})),
        "Minimap shown: " .. yesNo(state.minimap),
        "Minimap stored angle: " .. tostring(state.minimapAngle or "none"),
        "Minimap visible: " .. yesNo(minimap and minimap:IsShown()),
        "Minimap point: " .. framePoint(minimap),
        "Floating button shown: " .. yesNo(db.show_floating_button),
        "Floating button point: " .. framePoint(floating),
        "Combat lockdown: " .. yesNo(InCombatLockdown and InCombatLockdown()),
        "Report privacy: no character name or macro text included; configured keybindings are included.",
    }
    return table.concat(lines, "\n")
end
