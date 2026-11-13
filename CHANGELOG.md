# Changelog

## [Unreleased]

### Changed

- Show the current speed key on Speed with Set key or Change. Fit the read-only macro field to its contents.
- Use Re-centre button for position actions and clearer shared update-sound labels.
- Use speed key consistently and shorten movement tooltips and spell names.
- Keep three settings pages, with Key Bindings second and a setup link on Speed. Explain automatic class movement and independent utility keys.
- Make the generated macro read-only and searchable, with clearer disabled and unlearned states.
- Refresh class, racial and utility controls after spellbook changes, including hidden pages used by search. Keep saved preferences and unavailable spell bindings accessible for removal.
- Offer explicit conflict replacement in the binding dialog, show every assigned key, and search individual bind, change and remove actions. The slash binding shortcut keeps its existing behaviour.
- Disable Hide on flights while the floating button is hidden; clarify that position reset preserves settings and bindings.
- Update HammerCore to the pinned 0.5.2 development revision with dynamic binding search. Existing preference keys, defaults and movement macro rules are unchanged.


## [1.3.0] - 2026-11-10

### Added

- **Hide on flights.** The floating button now ducks out of sight while
  you're on a flight path and pops back when you land. The gryphon knows
  the way; you don't need a speed button up there. It's on by default, and
  **Hide on flights** on Visibility turns it off.
- **Settings search.** A search box at the top of the settings window finds
  any setting and takes you straight to it.

### Changed

- **Minimap right-click opens a menu.** Settings, a speed macro switch, the
  floating button and Reset button position, all in one place. Rather it
  opened settings? Set **Minimap right-click** on Visibility. It used to
  show or hide the floating button, which is now in the menu.
- **Reload UI only when it's needed.** The standing button in the settings
  footer is gone. Nothing in Speedster needs a reload anyway.
- Updated the shared Consecrated Hammer library.

## [1.2.0] - 2026-11-09

### Added

- **A fresh coat of paint.** Settings have a new look, with a Window scale
  slider, Reload UI in the footer and links to the CurseForge page, Discord
  and Buy me a coffee (hide those on Visibility).
- **Key bindings, the easy way.** The Key Bindings page now matches the rest
  of the suite: click the speed macro or a movement action, press a key,
  mouse button or wheel, and it's listed on the left with an x to remove it.

- **What's new.** After an update with something worth knowing, a small
  window lists the highlights once, along with news from any other
  Consecrated Hammer addons you use. Reopen it with `/speedster whatsnew` or
  from About, or turn it off with **Show what's new after updates** on
  Visibility. It stays quiet on a fresh install and waits until you're out of
  combat.
- **What's new page.** Every release's highlights also live in settings,
  under REFERENCE, back to the first WoW Forever build, one card per release.
  A yellow "!" beside it means there's something you haven't read yet, and
  opening the page hands it in, quest turn-in sound and all. **Mark unread
  What's new** and **Turn-in sound** on Visibility turn those off.

### Changed

- **Little icons on the Speed page.** Each section now wears its own: a note
  for the speed macro, Travel Form or Ghost Wolf for your class, Walk on Air
  for Skyborne and Speedster's logo for the floating button.
- **Racial settings only for races that have one.** Everyone else no longer
  stares at a Walk on Air switch they can never turn on.
- **Druids without Travel Form** get a gentle note on the Speed page instead
  of a mystery greyed-out switch. Cat Form is quick, but it's no stag.
- Clicking a support link shows the whole address, with an icon for where
  it's going.
- Updated the shared Consecrated Hammer library. The lore quiz has a much
  bigger question bank, and the minimap button's first click after a drag
  works again.

## [1.1.0] - 2026-11-05

### Added

- Optional Walk on Air on the normal speed key and floating button while
  falling outside combat. Enable it on the Speed page; it starts off and
  keeps the separate racial binding and normal class movement in combat.

## [1.0.1] - 2026-10-28

### Changed

- CurseForge release notes now come from this changelog instead of a list of
  commit messages.

## [1.0.0] - 2026-10-28

### Added

- The GPL v3 licence text as `LICENSE.txt`, so the licence links in the README
  and on CurseForge resolve.

### Removed

- Retail support: Speedster is now a WoW Forever addon only.
- The flight-master shapeshift cancel, which only ever worked on Retail.
- Test files from the packaged download.

## [0.5.0] - 2026-09-26

### Added

- A lore quiz: the quest "!" on the About page, or `/speedster quiz`, asks five
  questions suited to your client, class and race. **Share result** posts
  the verdict to yourself, Say or Party in one click; it is unavailable in
  combat and during keys, PvP matches and encounters.
- New commands: `help`, `version`, `about`, `debug`, `startup`, `minimap`,
  `reset position`, `reset settings`, `toggle`, `bind` and `macro`.

### Changed

- Speedster now uses HammerCore, the settings, command and chat foundation shared
  by every Consecrated Hammer addon. The login message reads
  `Speedster v0.5.0 loaded - type /speedster for settings, /speedster help for commands`, chat uses
  a gold name prefix, and `/speedster help` lists every command.
- Settings move from the single Blizzard options page to the shared window:
  Speed (with the current macro), Visibility (floating button, then minimap
  button and startup message) and Key Bindings, then Commands,
  Troubleshooting and About.
- Right-click the minimap button to show or hide the floating button.
- Your startup-message and minimap choices carry over.

### Removed

- `/speedsterbind`, `/speedstermacro` and `/speedsterloadmsg`; use
  `/speedster bind`, `/speedster macro` and `/speedster startup`.

## [0.4.11] - 2026-09-26

### Changed

- Support Retail and WoW Forever only; remove older Classic interface numbers.

### Fixed

- Keep Retail spell checks limited to its active spellbook while letting WoW
  Forever confirm learned forms through its legacy APIs.
- Keep the options panel's spell availability in sync with the generated macro.
- Cast Aquatic Form only while swimming when it is the Druid's sole known form.

## [0.4.10] - 2026-09-19

### Fixed

- Declare Retail's current interface alongside the supported Classic and WoW
  Forever interfaces, so CurseForge correctly lists the unified package for
  Retail and Forever.

## [0.4.9] - 2026-09-19

### Fixed

- Let minimap-button collectors such as MinimapButtonBag retain Speedster's
  icon in their collapsed menu after routine macro refreshes.

### Added

- Add a copyable troubleshooting report and compatible early SavedVariables
  loading for Retail and WoW Forever.

## [0.4.8] - 2026-09-18

### Fixed

- Register the Speedster keybinding header once, so the additional action bindings load without a Lua error.

## [0.4.7] - 2026-09-18

### Added

- Individually bindable learned movement, emergency-descent, terrain-travel and
  movement-escape actions, including Skyborne abilities.

## [0.4.6] - 2026-09-18

### Changed

- Present the Camelot flavour as WoW Forever without beta or testing language.

## [0.4.5] - 2026-09-18

### Changed

- Identify the Camelot TOC as WoW Forever beta and declare the `camelot` load game type.

## [0.4.4] - 2026-09-18

### Fixed

- Build one Retail and WoW Forever package for CurseForge.

## [0.4.3] - 2026-09-18

### Fixed

- Correct the release-notes extraction guard used by the automated publisher.

## [0.4.2] - 2026-09-18

### Fixed

- Publish distinct Retail and WoW Forever packages.

## [0.4.1] - 2026-09-18

### Added

- Provisional WoW Forever package with a client-safe movement backend.
- Default-on configurable startup message.

### Fixed

- Ship the Speedster button and minimap icon in a WoW-safe TGA format.
