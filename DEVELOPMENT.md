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
python3 ../HammerCore/tools/stage.py .
```

`stage.py` still targets the old Forever beta folder
(`wow-forever-beta-interface`). The release client hasn't been confirmed to
load from there, so pass `--output <AddOns folder>` until HammerCore's Forever
staging path is updated.

Confirm the loaded version in game with `/speedster version`. Releases are
tagged from `main` only.
