## Speedster

Speedster is a lightweight World of Warcraft Retail and WoW Forever addon that generates a class-aware movement speed macro and binds it to a key through a simple options panel.

## What It Does

- Builds a dynamic movement macro based on your class and known spells.
- Updates automatically when you learn new relevant spells/forms.
- Lets you bind your preferred key or mouse button from the options panel ("press next key/button" capture).
- Exposes separately bindable learned movement, descent, terrain-travel and escape actions.
- Shows your currently generated macro in the options panel.
- Optional flight master support can auto-cancel form/dismount so you can select a taxi destination without manual unshifting.

## Supported Class Speed Abilities

- Druid: Cat Form, Aquatic Form, Travel/Flight Form logic (when known)
- Shaman: Ghost Wolf
- Hunter: Aspect of the Cheetah
- Rogue: Sprint
- Mage: Blink

## Additional Bindable Actions

When the character knows one of these abilities, it appears in **Additional
movement actions** in Speedster's options with its own **Bind Key** control.
No action is bound automatically.

- Druid: Dash
- Hunter: Aspect of the Pack (shown with its daze warning)
- Mage: Slow Fall
- Priest: Levitate
- Shaman: Water Walking
- Paladin: Blessing of Freedom (self-cast)
- Gnome: Escape Artist
- Skyborne: Walk on Air and, for Windshapers, Skysight

Slow Fall and Levitate consume Light Feathers; Water Walking consumes Fish Oil.
The normal Speedster key remains independent, so a player can use any desired
key or mouse button for each available action.

If your class has no supported speed spell available yet, the generated macro will be empty until one is learned.

## Usage

1. Open settings with `/speedster`.
2. Bind a key on the **Key Bindings** page: click **Bind key**, then press the
   key or button you want. Learned additional actions have their own
   **Bind key**. Or type `/speedster bind [KEY]` (blank means `NUMPADMINUS`).
3. Copy the generated macro from **Speed**, below **Behaviour**, or print it
   with `/speedster macro`.

## Commands

| Command | Effect |
| --- | --- |
| `/speedster` | Open settings |
| `/speedster help` | List every command |
| `/speedster version` | Print the loaded version and client |
| `/speedster about` | Open the About page |
| `/speedster debug` | Open a copyable diagnostic report |
| `/speedster startup [on\|off]` | Show the startup message |
| `/speedster minimap [on\|off]` | Show the minimap button |
| `/speedster reset position` | Move the floating button back |
| `/speedster reset settings` | Reset every setting after a confirmation |
| `/speedster toggle` | Show or hide the floating button |
| `/speedster bind [KEY]` | Bind the speed macro |
| `/speedster macro` | Print the current speed macro |
| `/speedster quiz` | Take a five-question lore quiz |

Settings, commands, the minimap button and the reference pages come from
[HammerCore](https://github.com/consecrated-hammer/HammerCore), shared by
every Consecrated Hammer addon and vendored under `Libs/HammerCore`.
