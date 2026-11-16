# Development workflow

Develop only from this Git clone. Speedster is a WoW Forever addon: it ships
one TOC, `Speedster_Camelot.toc`.

Settings, commands, chat and the minimap button come from HammerCore,
vendored under `Libs/HammerCore`. Never edit that copy; change HammerCore,
commit, then run `python3 ../HammerCore/tools/sync.py .`.

Run the tests (Lua 5.1), then stage a `-devN` build into the Forever client
folder:

```sh
docker run --rm -v "$PWD:/r:ro" -w /r nickblah/lua:5.1-alpine sh -c \
  'for t in tests/test_*.lua; do lua "$t" || exit 1; done'
python3 ../HammerCore/tools/check.py .
python3 ../HammerCore/tools/toc_check.py .
python3 ../HammerCore/tools/whatsnew_check.py .
python3 ../HammerCore/tools/stage.py . --client forever
```

`stage.py` stages Forever builds to the live client's folder
(`wow-forever-interface`).

Confirm the loaded version in game with `/speedster version`. Releases are
tagged from `main` only.

The settings inventory and audit are in [SETTINGS-UX.md](SETTINGS-UX.md).
The test glob includes search ownership, dynamic spell availability, binding
conflicts, keyboard/mouse/wheel capture and saved-setting compatibility.
Archive the installed runtime folder locally before staging for rollback;
never touch WTF or SavedVariables. Staging and Syncthing delivery do not prove
which build is loaded in game.


## Dash / form action bank

The main key and floating button share one SecureHandlerStateTemplate bank.
Out-of-combat Lua prepares Dash-first and ordinary-form payloads, a dynamic Cat
condition and cooldown availability. A secure PreClick wrapper selects the
payload in its post-body, after the ordinary falling refresh and before the
protected action. Its pre-body returns a non-nil message so the post-body runs.
The restricted snippet uses macro-condition APIs and prepared attributes only;
GetCVarBool and cooldown inspection stay outside it. A useOnKeyDown attribute
keeps native action execution and sequence advancement on the same edge, even
when a CVar change is deferred until combat ends. Utility bindings stay separate.

With travel enabled/learned, the first eligible outdoor Cat press attempts Dash,
then later presses retry ordinary forms until Cat is exited. Failed casts still
advance. Outside combat a known unavailable Dash goes directly to forms.
Combat never performs an arbitrary cooldown-dependent rewrite: its first Dash
attempt may report cooldown, but the following press progresses. Swimming,
falling-racial and Shift-drag actions do not spend the step. Ordinary refreshes
never reset phase or re-register an unchanged state driver. Indoors or without
travel the existing Cat/Dash action remains. API absence retains the legacy
single action and is reported in diagnostics.

Native contracts checked against Blizzard's Classic UI implementation:
[secure wrapper dispatch](https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/SecureHandlers.lua),
[restricted API whitelist](https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/RestrictedEnvironment.lua),
[action click edges](https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua).
These establish the implementation contract, not Forever runtime proof.
Tests execute the actual snippet with a restricted whitelist, full down/up
click lifecycle, failed-cast model, shared buttons and combat write guards.
Forever acceptance still needs both input paths/CVar settings, combat, rapid
Cat exit/re-entry and confirmation that no blocked-action/taint report appears.
