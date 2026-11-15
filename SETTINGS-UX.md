# Speedster settings UX audit

## Matching binding columns, 2026-11-16

The native Key Bindings page frames both Active bindings and Available, with
matching heading insets, top anchors and heights. Wrapped help text reserves
shared space above the rows and tiles, which stay inside their padded columns.

## Native section dividers, 2026-11-16

The Speed page uses subtle 1px bronze dividers between visible sections.
Hidden class/racial groups leave no orphan lines; no leading or trailing line
is drawn. The Modern presentation keeps its existing layout.

## Compact speed-key row, 2026-11-16

The native Speed page places the assigned key in a dark, bronze-edged inset,
with larger gold text and Change directly beside it. The inset also opens Key
Bindings on click; its tooltip shows the full binding when a long label is
clipped. Unbound uses muted Not set and Set key. Existing binding labels,
multiple-key updates, search registration and the Modern layout are preserved.

## Party-panel artwork follow-up, 2026-11-15

The owner supplied the compact Party/raid-panel as the visual reference.
Settings now use horizontal gold-edged page tabs, an opaque stone interior,
bronze raid-panel surround and a compact title bar in an 860x660 window. The
existing pages and search remain; a redundant single-page subtab is hidden.
Help text wraps, and the macro uses a minimum 64px dark inset and small game
font. Shared dialogs and quiz inherit the same opaque stone/frame family.
Gameplay and saved preferences remain unchanged; native visual acceptance is
still required after staging.

## Blizzard presentation preview, 2026-11-15

The complete addon now opts into HammerCore’s Blizzard presentation in its
Init spec. This covers shared settings, menus, binding capture, dialogs,
reports, quiz and private update notes. Native action/minimap templates and
gameplay behaviour are preserved. The preview is fixed for the session and
preserves saved legacy theme values; there is no new theme page or per-window
switch. Native update notes serialize with existing Modern notices instead of
contributing a section or renderer to the shared aggregate. In-client visual
acceptance remains after staging. HammerCore’s docs/BLIZZARD-PRESENTATION.md
owns the skin and notification contract.

## Previous settings audit

Reviewed 2026-11-13 from `eb89d9f` (v1.3.0), with a clean source checkout.
HammerCore was 0.5.0 at `64e78b9`; the existing pushed settings branch at
`3c1eeeb` provides the current 0.5.2 shell. This implementation adds only
per-action dynamic binding search and shared scale/report registrations to that source, on an isolated
`feat/speedster-settings-search` worktree. No other addon is changed.

## Target hierarchy and mapping

Before: Speed, Visibility, Key Bindings; shared reference pages.
After: **Speed, Key Bindings, Visibility**; shared reference pages unchanged.
There are no tabs, new pages or global advanced switch. Position remains
with its three floating-button controls on Visibility.

E = essential, S = standard, A = advanced. All addon keys remain per character.
Game bindings remain in the game's selected binding set, outside SavedVariables.

| Previous control | Final location/control | Tier | Persistence and decision |
| --- | --- | --- | --- |
| Speed: Enable speed macro | Speed: Your speed key | E | `enabled`, unchanged; explains scope and combat deferral |
| No setup shortcut | Speed: Speed key status with Set key or Change | E | Current game binding shown; searchable navigation to Key Bindings; no saved key |
| Speed: Travel Form outdoors | Speed: Class movement | S | `druid_use_travel`, unchanged; explains aquatic/indoor/outdoor/flying choices |
| Speed: Ghost Wolf | Speed: Class movement | S | `shaman_use_ghost_wolf`, unchanged; Water Walking is separate |
| Implicit Hunter/Rogue/Mage choices | Speed: class explanation | E | Cheetah/Sprint/Blink once learned; no invented switches or priority changes |
| Speed: Walk on Air while falling | Speed: Racial movement | S | `walk_on_air_while_falling`, unchanged and off by default |
| Editable Current macro box | Speed: Current macro | A | Read-only, multiline, indexed; no new key or macro editor |
| Key Bindings: Speed macro | Second page: Primary speed key | E | Existing secure CLICK action; no automatic binding |
| Key Bindings: Movement actions | Optional utility keys | S/A | Dash, Pack, Slow Fall, Levitate, Water Walking, Freedom, Escape Artist, Walk on Air, Skysight; learned pool only |
| Active binding rows | Same page: all assigned keys shown | E | Existing unavailable actions remain manageable; click to change, x removes all keys for that action |
| Capture keyboard/mouse/wheel | Same shared capture prompt | E | Modifiers supported; explicit Replace on conflict; bare left/right click requires modifier |
| Clear all | Same page, confirmed | A | Every Speedster action, including unavailable spells; unrelated bindings preserved |
| Visibility: Show floating button | Visibility: Floating button | S | `show_floating_button`, unchanged; Shift-left-drag explained |
| Visibility: Hide on flights | Same section | S | `hide_on_flights`, unchanged; disabled when button hidden |
| Re-centre button | Same section | S | Clears only `floating_button_point`; retains settings, bindings and shared preferences |
| Show minimap button | Visibility: Minimap button | S | `hammerCore.minimap` plus angle; existing legacy migration preserved |
| Minimap right-click | Same section | S | `hammerCore.minimapRightClick`, menu/settings |
| Show startup message | Visibility: Updates | S | `hammerCore.startupMessage`; existing legacy migration preserved |
| Show What's new after updates | Same section | S | `hammerCore.whatsNew`, unchanged |
| Show unread marker / What's new sound | Same section | A | `hammerCore.whatsNewDot`, `whatsNewSound`, unchanged |
| Settings search / Show support links | Visibility: Settings window | S | `hammerCore.settingsSearch`, `supportLinks`, unchanged |
| Header scale / window dragging | Shared header, 0.7 to 1.3 | S | `hammerCore.settingsScale`, `settingsPoint`, unchanged |
| Theme | Existing hidden shared facility | A | The build opts into complete Blizzard presentation; legacy saved values remain intact |
| What's new cards and settings links | Shared reference page | S | Existing seen/unread tracking; added development highlights link current pages |
| Commands, Troubleshooting report, About/quiz/support links | Shared reference pages/footer | A | Existing commands and diagnostics retained; no gameplay settings moved there |
| Reset all settings | Existing confirmed command | A | Existing full-reset/reload behaviour; no new page reset or schema |

## Findings and implementation priorities

**P1: search and lifecycle.** Current macro was not indexed; shared binding
search indexed only the generic panels, not action tiles, active rows or remove
buttons. Conditional racial construction could not recover after spellbook
loading. Binding lists and Clear all ignored already-bound unavailable spells.
Implement dynamic registration and stale-entry removal in shared HammerCore;
refresh every constructed Speedster page after normal spellbook refresh.
Keep unknown/off options out of results, but retain a saved opt-in for disabling.
Hide available preferences with the primary feature off and route search to its
visible enabling switch. Guard dependent setters as well as dimming controls.

**P2: setup and inspection.** Key Bindings was behind Visibility; README
instructions named an obsolete Bind key button. Move the page second, add a
setup link, name the primary and optional action groups, explain automatic class
choices, and protect the generated macro from edits. Show all current keys,
keep failed operations visible and offer explicit conflict replacement through
HammerCore's existing command binding helper. Keep `/speedster bind` unchanged.

**P3: low-risk clarity.** Explain reset scope, use spell icons matching the
class, disable irrelevant flight hiding, and distinguish disabled from unlearned
macro states. Keep generated macros visible without adding another click.

## Player journeys and decisions kept

A new player uses Set key on the Speed key status row, selects Speed key and presses an
input. A regular player sees class preferences on Speed and separately named
utility spells on Key Bindings; floating-button settings stay together. An
advanced player can inspect/copy the read-only macro and manage multiple keys,
modifier mouse clicks or wheel inputs with conflict feedback.

No additional class options, altered movement priorities, automatic casts,
macro editor, Retail TOC or new schema. Walk on Air remains an opt-in keypress
choice while falling outside combat, with no class fallback on the same failed
press and the existing secure class fallback in combat. Utility actions remain
independent. No secure click, falling-selection, attribute-write, Shift-drag or
flight implementation was changed.

Existing SavedVariables, defaults and legacy migration stay intact, including
position and minimap choices. Additional unavailable-action enumeration is
opt-in for settings; the gameplay learned-action path keeps its old contract.
Shared full reset keeps its existing confirmation and reload. Position reset
is intentionally available even when the floating button is hidden.

The CurseForge description needs no change: these are settings improvements
within the existing advertised features. No live description was modified.

## Validation boundary

The complete Lua 5.1 suite includes class macros, falling opt-in/combat fallback,
click edges, deferred updates, Shift-drag and flight transitions. The UX suite
constructs all pages for eight classes at scales 0.7 and 1.3; checks search/focus,
duplicate registrations, hidden-parent routing, learned/removed spells, macro
protection, persistence, reset isolation and binding assignment/replacement/
removal through keyboard, modified mouse and wheel capture. Failed binding and
combat operations, unrelated keys and unavailable actions are covered.

Headless construction does not prove actual font clipping, wrapping, frame
strata or WoW secure-action execution. Inspect all pages at both scales in
Forever and check real input edges, combat entry/exit, failed racial casts,
Shift-drag and flight takeoff/landing. Confirm the staged version in game.
The wiki handoff records final review, commit, staging and delivery evidence.
