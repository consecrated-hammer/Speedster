# Changelog

## [Unreleased]

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
