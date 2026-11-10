-- Hide on flights: the floating button hides at takeoff and comes back at
-- landing, using HammerCore's takeoff and landing without flight times.
local S = dofile("tests/support.lua")
local equal, contains, wow = S.equal, S.contains, S.wow

for _, toc in ipairs(S.TOCS) do
    -- The spec asks for takeoff and landing only.
    local ns, HC = S.load({ toc = toc, saved = { enabled = true, show_floating_button = true } })
    equal(type(HC.spec.flights), "table", toc .. ": flights are declared")
    equal(HC.spec.flights.estimates, false, toc .. ": without flight times")
    equal(HC.Flights.Estimates(), false, toc .. ": HammerCore skips estimates")
    equal(HC.Flights.enabled, true, toc .. ": HammerCore tracks flights")
    equal(ns.db.hide_on_flights, true, toc .. ": Hide on flights starts on for an existing profile")
    equal(ConsecratedHammerFlights, nil, toc .. ": no learned flight times are shared")

    local button = S.floating()
    equal(button:IsShown(), true, toc .. ": the button shows on the ground")
    S.takeOff(HC)
    equal(HC.Flights:Flying(), true, toc .. ": the flight boarded")
    equal(button:IsShown(), false, toc .. ": takeoff hides the button")
    equal(ns.db.show_floating_button, true, toc .. ": the saved choice is untouched")
    equal(ns.hiddenForFlight(), true, toc .. ": and Speedster knows why it's hidden")
    S.land(HC, 90)
    equal(HC.Flights:Flying(), false, toc .. ": the flight landed")
    equal(button:IsShown(), true, toc .. ": landing brings the button back")
    equal(ns.hiddenForFlight(), false, toc .. ": nothing hidden on the ground")
    equal(HC.State().flights, nil, toc .. ": the landing saved no route time")

    -- Turned off, flights change nothing.
    ns.db.hide_on_flights = false
    S.takeOff(HC)
    equal(button:IsShown(), true, toc .. ": with the setting off the button stays up")
    -- Switching it on mid-flight hides it straight away, and off brings it back.
    HC.Settings:Show("Visibility")
    local switch = S.switch("Hide on flights")
    assert(switch, toc .. ": Visibility has Hide on flights")
    wow.Click(switch)
    equal(ns.db.hide_on_flights, true, toc .. ": the switch turns it on")
    equal(button:IsShown(), false, toc .. ": turning it on mid-flight hides the button")
    wow.Click(switch)
    equal(ns.db.hide_on_flights, false, toc .. ": the switch turns it off")
    equal(button:IsShown(), true, toc .. ": turning it off mid-flight shows the button")
    wow.Click(switch)
    S.land(HC)
    equal(button:IsShown(), true, toc .. ": landing shows it again")

    -- A button the player hid stays hidden after landing.
    SlashCmdList.SPEEDSTER("toggle")
    equal(button:IsShown(), false, toc .. ": toggle hides the button")
    S.takeOff(HC)
    S.land(HC)
    equal(button:IsShown(), false, toc .. ": landing doesn't show a button the player hid")
    equal(ns.hiddenForFlight(), false, toc .. ": a hidden button isn't counted as hidden for the flight")

    -- Toggling on during a flight waits for landing, and says so.
    S.takeOff(HC)
    SlashCmdList.SPEEDSTER("toggle")
    equal(ns.db.show_floating_button, true, toc .. ": toggle turns the button on mid-flight")
    equal(button:IsShown(), false, toc .. ": but it stays out of the way")
    equal(wow.LastPrint(), "Speedster: floating button shown after you land", toc .. ": toggle explains the wait")
    contains(HC.spec.status(), "Floating button: hidden for the flight", toc .. ": status says it's hidden for the flight")
    SlashCmdList.SPEEDSTER("debug")
    local report = HC.Copy.frame.edit:GetText()
    contains(report, "Hide on flights: yes", toc .. ": debug reports the setting")
    contains(report, "Hidden for flight: yes", toc .. ": debug reports the flight hide")
    contains(report, "Flights: on (no estimates)", toc .. ": debug includes HammerCore's flights line")
    S.land(HC)
    equal(button:IsShown(), true, toc .. ": it shows at landing")
    SlashCmdList.SPEEDSTER("toggle")
    equal(wow.LastPrint(), "Speedster: floating button hidden", toc .. ": the ground toggle message is plain")
end

-- The button is secure: a flight change during combat waits for combat to
-- end, without touching the frame.
do
    local ns, HC, world = S.load({ saved = { enabled = true, show_floating_button = true } })
    local button = S.floating()
    S.takeOff(HC)
    equal(button:IsShown(), false, "hidden at takeoff")
    world.combat = true
    local show, hide = button.Show, button.Hide
    button.Show = function() error("protected Show in combat") end
    button.Hide = function() error("protected Hide in combat") end
    S.land(HC)
    equal(button.shown, false, "landing in combat leaves the button alone")
    button.Show, button.Hide = show, hide
    S.regen(ns)
    equal(button:IsShown(), true, "the button returns once combat ends")
end

-- A reload mid-flight comes back as a resumed flight and keeps it hidden.
do
    local ns, HC = S.load({ saved = { enabled = true, show_floating_button = true, hide_on_flights = true }, taxi = true })
    local button = S.floating()
    S.fire(HC, "PLAYER_ENTERING_WORLD")
    equal(HC.Flights:Current().resumed, true, "a reload on a taxi resumes the flight")
    equal(button:IsShown(), false, "the button stays hidden after a reload mid-flight")
    S.land(HC)
    equal(button:IsShown(), true, "and returns at landing")
end

-- A saved choice to keep the button on flights survives a reload.
do
    local ns = S.load({ saved = { enabled = true, show_floating_button = true, hide_on_flights = false } })
    equal(ns.db.hide_on_flights, false, "a saved off stays off")
    ns = S.load({ saved = { enabled = true, show_floating_button = true, hide_on_flights = "yes" } })
    equal(ns.db.hide_on_flights, true, "a broken saved value falls back to on")
end

-- A dialogue flight (no flight-map click) and a silent one caught by the
-- fallback both hide the button and bring it back on landing.
do
    local ns, HC = S.load({ saved = { enabled = true, show_floating_button = true } })
    local button = S.floating()
    S.world.taxi = true
    HC.Flights.frame.scripts.OnEvent(HC.Flights.frame, "PLAYER_CONTROL_LOST")
    equal(button:IsShown(), false, "a dialogue takeoff hides the button")
    S.land(HC, 60)
    equal(button:IsShown(), true, "landing brings it back")
    HC.Flights.frame.scripts.OnEvent(HC.Flights.frame, "PLAYER_ENTERING_WORLD")
    S.world.taxi = true
    HC.Flights.frame.scripts.OnUpdate(HC.Flights.frame, 2.1)
    equal(button:IsShown(), false, "the fallback check hides it too")
    S.land(HC, 60)
    equal(button:IsShown(), true, "and landing brings it back")
end

io.write("Speedster flight tests passed\n")
