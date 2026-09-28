# Speedster

**One key, go zoom-zoom!**

_Water, indoors or out, your druid picks the right form._

[![Discord](https://img.shields.io/badge/discord-join-5865F2?style=flat-square&logo=discord&logoColor=white)](https://discord.gg/z3xKxRygDc) [![WoW Forever](https://img.shields.io/badge/wow%20forever-supported-4c9a7a?style=flat-square)](https://www.curseforge.com/wow/addons/speedster) [![Release](https://img.shields.io/github/v/release/consecrated-hammer/Speedster?style=flat-square&color=4c9a7a&label=release)](https://github.com/consecrated-hammer/Speedster/releases) [![License](https://img.shields.io/badge/license-GPL--3.0-4c9a7a?style=flat-square)](https://github.com/consecrated-hammer/Speedster/blob/main/LICENSE.txt)

Questions, bugs or ideas? Come say hi on the [Consecrated Hammer Discord](https://discord.gg/z3xKxRygDc). Bug reports go in `#bug-reports`, or you can open a [GitHub issue](https://github.com/consecrated-hammer/Speedster/issues).

---

Speedster builds a movement macro for your class from the spells you know, and puts it on one key. Press it and you get the fastest way to move for where you are. It's for WoW Forever, and was originally inspired by MountsJournal's keybindable movement macro.

## What it does

- **Builds the macro for you**, from your class and known spells, and rebuilds it when you learn something new.
- **Picks the right form for druids.** Aquatic Form while swimming, Cat Form indoors, and Travel Form outdoors (or Flight Form where you can fly, once you have it).
- **Covers the other speed classes too:** Shaman Ghost Wolf, Hunter Aspect of the Cheetah, Rogue Sprint and Mage Blink.
- **Extra movement keys.** Spells you know from the list below each get their own key, so they don't fight with the main one:
  - Druid Dash
  - Hunter Aspect of the Pack (with a daze warning)
  - Mage Slow Fall and Priest Levitate (these use Light Feathers)
  - Shaman Water Walking (uses Fish Oil)
  - Paladin Blessing of Freedom, cast on yourself
  - Gnome Escape Artist
  - Skyborne Walk on Air and, for Windshapers, Skysight
- **A floating button** you can click instead of using a key.

## Getting started

1. Install, then type `/speedster` for settings.
2. On the **Key Bindings** page, click **Bind key** and press the key or mouse button you want. Each extra movement spell you know has its own **Bind key** there too. Nothing is bound until you choose it.
3. The **Speed** page shows the macro Speedster made for you. There's nothing to copy; it's already on your key.

## Commands

| Command | What it does |
| --- | --- |
| `/speedster` | Open settings |
| `/speedster bind [KEY]` | Bind the speed macro (leave the key blank for `NUMPADMINUS`) |
| `/speedster macro` | Print the current speed macro |
| `/speedster toggle` | Show or hide the floating button |
| `/speedster reset position` | Move the floating button back |

Every Consecrated Hammer addon also has `help`, `version`, `about`, `debug`, `startup`, `minimap`, `reset settings` and `quiz`.

Shift-drag the floating button to move it.

## Settings worth knowing

- **Use Travel Form outdoors** (druids) is on the Speed page. Turn it off and the macro sticks to Aquatic Form in water and Cat Form everywhere else.
- **Use Ghost Wolf** (shamans) is on the Speed page too, if you'd rather not have it on your key.

## Limits

- **Nothing to press until you learn something.** If your class has no supported speed spell yet, the macro stays empty until you learn one.
- **WoW Forever only.** Speedster doesn't have a Retail version.

## Licence

GPL v3, see [LICENSE.txt](https://github.com/consecrated-hammer/Speedster/blob/main/LICENSE.txt).
