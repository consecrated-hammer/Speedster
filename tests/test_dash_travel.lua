local S = dofile('tests/support.lua')
local eq = S.equal
local wrappers, driver, secure, world, header
local form, swimming, outdoors, shift, keyDown = 3, false, true, false, false
local mounted = false
local formList = { 5487, 1066, 768, 783 }
local function evaluate(body, self, extra)
    local env = { self = self, control = header, button = extra and extra.button,
        down = extra and extra.down, newstate = extra and extra.newstate,
        IsShiftKeyDown = function() return shift end,
        SecureCmdOptionParse = function(condition)
            if condition:find('noswimming,nomounted', 1, true) then
                return not world.combat and not swimming and not mounted and 'yes' or 'no'
            end
            if condition:find('nocombat', 1, true) then return not world.combat and 'yes' or 'no' end
            return condition:find('form:'..form, 1, true) and not swimming and outdoors and 'yes' or 'no'
        end }
    -- This whitelist deliberately excludes cooldown APIs and GetCVarBool.
    local fn = assert(loadstring(body)); setfenv(fn, env)
    local previous = secure; secure = true
    local a, b = fn(); secure = previous
    return a, b
end
SecureHandlerWrapScript = function(button, script, owner, pre, post)
    eq(script, 'PreClick', 'wraps preparation, not protected action')
    local original = assert(button:GetScript(script), 'preparation is installed before secure wrapping')
    wrappers[button] = { owner = owner, pre = pre, post = post }
    button:SetScript(script, function(self, inputButton, down)
        local _, message = evaluate(pre, self, { down = down, button = inputButton })
        original(self, inputButton, down)
        assert(message ~= nil, 'native wrapper must receive message to run post-body')
        evaluate(post, self, { down = down, button = inputButton })
    end)
end
RegisterStateDriver = function(owner, state, condition)
    header = owner; driver = condition
    evaluate(owner:GetAttribute('_onstate-cat'), owner, { newstate = form == tonumber(condition:match('form:(%d+)')) and 'cat' or 'other' })
end
UnregisterStateDriver = function() driver = nil end
GetCVarBool = function(name) eq(name, 'ActionButtonUseKeyDown', 'only required input CVar'); return keyDown end
GetNumShapeshiftForms = function() return #formList end
GetShapeshiftFormInfo = function(index) return 1, false, true, formList[index] end
wrappers = {}
local ns, HC
local known = { [768] = true, [1850] = true, [783] = true, [1066] = true, [1259416] = true }
ns, HC, world = S.load({ known = known,
    saved = { enabled = true, druid_use_travel = true, druid_dash_in_cat = true } })
header = assert(ns.movementBank, 'secure action bank created')
local primary, floating = S.primary(), _G.SpeedsterFloatingButton
for _, frame in ipairs({ primary, floating, header }) do
    local original = frame.SetAttribute
    frame.SetAttribute = function(self, key, value)
        assert(not world.combat or secure, 'insecure protected write in combat: '..key)
        return original(self, key, value)
    end
end
local cd = 0
C_Spell.GetSpellCooldown = function() return { startTime = cd > 0 and world.clock or 0, duration = cd, isEnabled = true } end
local function setForm(value)
    form = value
    evaluate(header:GetAttribute('_onstate-cat'), header, { newstate = value == tonumber(driver:match('form:(%d+)')) and 'cat' or 'other' })
end
local function press(button)
    local result, actions = nil, 0
    for _, down in ipairs({ true, false }) do
        assert(wrappers[button])
        button:GetScript('PreClick')(button, 'LeftButton', down)
        if down == button:GetAttribute('useOnKeyDown') then result = button:GetAttribute('macrotext'); actions = actions + 1 end
    end
    eq(actions, 1, "native attribute permits one action per complete press")
    return result
end
for _, inputDown in ipairs({ false, true }) do
    keyDown = inputDown; setForm(3); cd = 0; ns.refreshSpeedButton()
    local dash = header:GetAttribute('dash-macro')
    local forms = header:GetAttribute('forms-macro')
    eq(press(primary), dash, 'first accepted press attempts Dash')
    eq(header:GetAttribute('dash-spent'), true, 'exactly one advancement for full down/up press')
    eq(press(floating), forms, 'next press shares phase across floating/key')
    eq(press(primary), forms, 'failed form cast retries forms without returning to Dash')
    ns.refreshSpeedButton()
    eq(press(primary), forms, 'ordinary refresh preserves phase')
    setForm(4); setForm(3)
    eq(press(floating), dash, 'leaving Cat starts a fresh sequence')
    setForm(4); setForm(3); cd = 1.5
    eq(press(primary), dash, 'global cooldown does not spend the Dash step as a long cooldown')
    setForm(4); setForm(3); cd = 120
    eq(press(primary), forms, 'outside combat unavailable Dash goes straight to forms')
    cd = 0; setForm(4); setForm(3)
    swimming = true
    eq(press(primary), dash, 'swimming retains Aquatic-first payload')
    eq(header:GetAttribute('dash-spent'), false, 'swimming does not consume Dash step')
    swimming = false; shift = true
    press(floating)
    eq(header:GetAttribute('dash-spent'), false, 'Shift drag consumes no step')
    shift = false
    ns.db.walk_on_air_while_falling = true; world.falling = true
    press(primary)
    eq(header:GetAttribute('dash-spent'), false, 'falling racial consumes no Dash step')
    world.combat = true
    eq(press(primary), header:GetAttribute('dash-macro'), 'frozen racial falls through to Dash in combat')
    eq(press(floating), header:GetAttribute('forms-macro'), 'combat next press advances even if Dash failed')
    eq(press(primary), header:GetAttribute('forms-macro'), 'combat continues retrying forms')
    world.combat = false; world.falling = false
    ns.db.walk_on_air_while_falling = false
    setForm(4); setForm(3); outdoors = false; ns.refreshSpeedButton()
    press(primary)
    eq(header:GetAttribute('dash-spent'), false, 'indoors keeps established Cat/Dash behavior')
    outdoors = true
    ns.db.druid_use_travel = false; ns.refreshSpeedButton()
    eq(header:GetAttribute('dash-enabled'), false, 'form-only preference disables sequencing')
    ns.db.druid_use_travel = true; ns.refreshSpeedButton()
end
local trinket, itemDuration = 2820, 0
local speed = 0
local originalMounted, originalTicker = IsMounted, C_Timer.NewTicker
GetUnitSpeed = function() return speed end
GetShapeshiftForm = function() return form end
IsMounted = function() return mounted end
IsSwimming = function() return swimming end
local tick, cancelled
C_Timer.NewTicker = function(_, callback)
    tick = callback
    return { Cancel = function() cancelled = true end }
end
GetInventoryItemID = function(_, slot) return slot == 14 and trinket or nil end
C_Item = { GetItemCooldown = function(itemID)
    eq(itemID, 2820, 'checks the equipped Stopwatch cooldown')
    return itemDuration > 0 and world.clock or 0, itemDuration, 1
end }
setForm(4); setForm(3); cd = 0
assert(not ns.db.use_nifty_stopwatch, 'existing characters opt in to Stopwatch')
ns.db.use_nifty_stopwatch = true
ns.db.show_movement_reminders = true
ns.refreshSpeedButton()
speed = 7; tick()
local reminder = assert(S.wow.FindText('Nifty Stopwatch ready')):GetParent()
local dashReminder = assert(S.wow.FindText('Dash ready')):GetParent()
assert(reminder:IsShown(), 'ready Stopwatch shows while moving')
assert(dashReminder:IsShown(), 'ready Cat Dash shows beside the Stopwatch')
setForm(4); tick()
assert(not dashReminder:IsShown(), 'Dash reminder requires Cat Form')
setForm(3); cd = 120; tick()
assert(not dashReminder:IsShown(), 'Dash cooldown hides its reminder')
cd = 0; tick()
assert(dashReminder:IsShown(), 'Dash cooldown expiry while moving restores the reminder')
speed = 0; tick()
assert(not reminder:IsShown(), 'standing hides Stopwatch reminder')
speed = 7
itemDuration = 360; tick()
assert(not reminder:IsShown(), 'item cooldown hides the ready reminder')
itemDuration = 0; tick()
assert(reminder:IsShown(), 'cooldown expiration shows the reminder without restarting movement')
local itemMacro = press(primary)
assert(itemMacro:find('/use [nocombat,noswimming,nomounted] item:2820', 1, true))
eq(header:GetAttribute('dash-spent'), false, 'Stopwatch preserves the next Dash press')
assert(press(floating):find('item:2820', 1, true), 'floating button uses the same item')
for _, state in ipairs({ 'swimming', 'mounted', 'falling' }) do
    setForm(4); setForm(3)
    swimming, mounted, world.falling = state == 'swimming', state == 'mounted', state == 'falling'
    ns.db.walk_on_air_while_falling = world.falling
    local macro = press(primary)
    if world.falling then assert(macro:find('/cast [nocombat]', 1, true) == 1, 'falling racial comes before item') end
    if not mounted then eq(header:GetAttribute('dash-spent'), false, state .. ' preserves Dash') end
end
swimming, mounted, world.falling = false, false, false
setForm(4); setForm(3); press(primary)
world.combat = true
press(primary)
eq(header:GetAttribute('dash-spent'), true, 'frozen item macro falls through to Dash in combat')
world.combat = false
itemDuration = 360
assert(not press(primary):find('item:2820', 1, true), 'cooldown skips the item')
itemDuration, trinket = 0, 999
assert(not press(primary):find('item:2820', 1, true), 'replacement trinket is never selected')
trinket = 2820
C_Item.IsUsableItem = function() return false end
assert(not press(primary):find('item:2820', 1, true), 'unusable Stopwatch does not replace movement')
ns.db.use_nifty_stopwatch = false
ns.db.show_movement_reminders = false
ns.refreshSpeedButton()
assert(cancelled and not reminder:IsShown() and not dashReminder:IsShown(), 'turning reminders off hides the row and cancels polling')
C_Item, GetInventoryItemID, GetUnitSpeed, GetShapeshiftForm, IsSwimming = nil, nil, nil, nil, nil
IsMounted, C_Timer.NewTicker = originalMounted, originalTicker
-- Changing the CVar in combat cannot create mismatched edge selection.
world.combat = true; keyDown = not keyDown
ns.core.scripts.OnEvent(ns.core, 'CVAR_UPDATE', 'ACTION_BUTTON_USE_KEY_DOWN')
local beforeEdge = primary:GetAttribute("useOnKeyDown")
press(primary)
eq(primary:GetAttribute("useOnKeyDown"), beforeEdge, "combat preserves the native explicit action edge")
world.combat = false
ns.core.scripts.OnEvent(ns.core, 'PLAYER_REGEN_ENABLED')
eq(primary:GetAttribute('useOnKeyDown'), keyDown, 'deferred input preference applies after combat')
formList = { 768, 783 }; form = 1
ns.core.scripts.OnEvent(ns.core, 'UPDATE_SHAPESHIFT_FORMS')
eq(driver, '[form:1] cat; other', 'new Cat slot updates secure reset driver')
assert(header:GetAttribute('cat-condition'):find('form:1', 1, true), 'new Cat slot updates click condition')
eq(header:GetAttribute('dash-spent'), false, 'driver change starts a fresh sequence')
known[783], known[33943] = nil, true
ns.refreshSpeedButton()
eq(header:GetAttribute('dash-enabled'), false, 'unknown Travel cannot sequence to an unavailable form payload')
known[783] = true; ns.refreshSpeedButton()
C_Spell.GetSpellCooldown = nil
GetSpellCooldown = function() return world.clock, 120, 1 end
setForm(4); setForm(1)
eq(press(primary), header:GetAttribute('forms-macro'), 'legacy cooldown API skips unavailable Dash')
GetSpellCooldown = function() return world.clock, 120, 0 end
setForm(4); setForm(1)
eq(press(primary), header:GetAttribute('forms-macro'), 'paused or active legacy cooldown skips another Dash attempt')
GetSpellCooldown = nil
local rogue = S.load({ class = 'ROGUE', known = { [2983] = true }, saved = { enabled = true } })
eq(rogue.movementBank, nil, 'non-druid does not create or depend on movement bank')
eq(wrappers[S.primary()], nil, 'non-druid keeps original click handler')
eq(S.primary():GetAttribute('macrotext'), '/cast Spell 2983', 'non-druid movement action preserved')
rogue.db.use_nifty_stopwatch = true
GetInventoryItemID = function(_, slot) return slot == 13 and 2820 or nil end
GetItemCooldown = function() return 0, 0, 1 end
rogue.refreshSpeedButton()
local rogueMacro = S.primary():GetAttribute('macrotext')
assert(rogueMacro:find('item:2820', 1, true) and rogueMacro:find('/cast Spell 2983', 1, true),
    'non-druid keeps Sprint as fallback when using legacy item cooldown API')
GetInventoryItemID, GetItemCooldown = nil, nil
SecureHandlerWrapScript, RegisterStateDriver, UnregisterStateDriver, GetCVarBool = nil, nil, nil, nil
io.write('test_dash_travel: ok\n')
