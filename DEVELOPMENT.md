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
