# Speedster

**One key for the fastest way to get around.**<br>_Go zoom-zoom!_

[![WoW Forever](https://img.shields.io/badge/wow%20forever-supported-4c9a7a?style=flat-square)](https://www.curseforge.com/wow/addons/speedster) [![Release](https://img.shields.io/github/v/release/consecrated-hammer/Speedster?style=flat-square&color=4c9a7a&label=release)](https://github.com/consecrated-hammer/Speedster/releases) [![License](https://img.shields.io/badge/license-GPL--3.0-4c9a7a?style=flat-square)](https://github.com/consecrated-hammer/Speedster/blob/main/LICENSE.txt)

[![Discord](https://img.shields.io/badge/discord-join-5865F2?style=flat-square&logo=discord&logoColor=white)](https://discord.gg/z3xKxRygDc) [![GitHub](https://img.shields.io/badge/github-source-6e7681?style=flat-square&logo=github&logoColor=white)](https://github.com/consecrated-hammer/Speedster) [![Buy Me a Coffee](https://img.shields.io/badge/buy%20me%20a%20coffee-support-FFDD00?style=flat-square&logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/consecratedhammer)

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
2. On **Key Bindings**, choose **Speed macro** under **Primary speed key**, then press a keyboard key, mouse button or wheel. Shift, Ctrl and Alt combinations work too. Nothing is bound until you choose it.
3. On **Speed**, choose any class or racial preferences. The read-only **Current macro** shows what Speedster generates; there's nothing to copy. **Visibility** controls the floating button and minimap.

## Commands

| Command | What it does |
| --- | --- |
| `/speedster` | Open settings |
| `/speedster bind [KEY]` | Bind the speed macro (leave the key blank for `NUMPADMINUS`) |
| `/speedster macro` | Print the current speed macro |
| `/speedster toggle` | Show or hide the floating button |
| `/speedster reset position` | Move the floating button back |
| `/speedster whatsnew` | Show what's new in recent releases |
| `/speedster whatsnew reset` | Bring back the What's new popup and "!" (for testing) |

Every Consecrated Hammer addon also has `help`, `version`, `about`, `debug`, `startup`, `minimap`, `reset settings` and `quiz`.

Shift-drag the floating button to move it.

Right-click the minimap button for a quick menu: settings, the speed macro on or off, the floating button and **Reset button position**. **Minimap right-click** on Visibility makes it open settings instead.

## Settings worth knowing

Settings stay on three pages: **Speed**, **Key Bindings**, then **Visibility**.
The **Choose your speed key** link on Speed opens Key Bindings. Class and
racial preferences belong to the primary speed key; **Optional utility keys**
cast their named spell independently, even with the primary macro disabled.
Only learned utility spells appear in the available pool. Existing bindings
remain listed if a spell becomes unavailable, so you can remove them.

Click an active binding to replace it, or its **x** to remove every key for
that action. **Clear all** removes only Speedster bindings after confirmation.
If a chosen key is already used, settings offer **Replace** before taking it.
Bare left/right clicks need a modifier. The `/speedster bind` shortcut keeps
its existing immediate replacement behaviour and reports the old action.
Binding changes are unavailable in combat; movement and floating-button
changes wait until combat ends.

Class and racial controls hide with the primary macro disabled; search still
finds available preferences and highlights **Enable speed macro**. A saved
preference remains available to switch off if spell data is temporarily missing.


- **Use Travel Form outdoors** (druids) is on the Speed page. Turn it off and the macro sticks to Aquatic Form in water and Cat Form everywhere else.
- **Use Ghost Wolf** (shamans) is on the Speed page too, if you'd rather not have it on your key.
- **Walk on Air while falling** is available on the Speed page once you know the
  Skyborne racial. It starts off. Enable it to use Walk on Air from your normal
  speed key or floating button while falling outside combat. Otherwise the key
  keeps its normal class movement action. Your separate Walk on Air key remains
  available, including in combat. Falling alone never casts the spell.
  While falling outside combat, a failed Walk on Air cast (including cooldown)
  does not fall back to a class spell on that same press.

- **Hide on flights** is on the Visibility page and starts on. The floating button hides from takeoff to landing on a flight path, then comes back.
- Lost a setting? Type in the search box at the top of the settings window.

## Limits

- **Nothing to press until you learn something.** If your class has no supported speed spell yet, the macro stays empty until you learn one.
- **WoW Forever only.** Speedster doesn't have a Retail version.

## Licence

GPL v3, see [LICENSE.txt](https://github.com/consecrated-hammer/Speedster/blob/main/LICENSE.txt).
