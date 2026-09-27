# PLAYBOOK: mod a game (THE AGGRESSIVE ONE)

The owner's own framing: this chapter is deliberately brutal. Modding
here means REACH IN AND CHANGE THE THING. The platform is MIT, the data
is plain, the pck is unencrypted by choice, the saves are plain files.
You are expected to reverse, extract, decompile, edit and reassemble —
on the user's own box, with games the user legally holds. No platform
gate exists to stop you and none will be added; what stops you is the
law of the land and your own judgment (the prime laws).

1. **The easy 90%: data/.** The package's `data/logic/*.json` tables
   drive the game live (the ports read them at setup with a packed
   fallback). Edit speed tables, prices, drops, wave numbers — no
   repack, no tools, save + relaunch. `data/visuals/assets/` overrides
   the art by name (the game loads it FIRST). `data/visuals/shaders/`
   swaps the shine. `data/audio/*` swaps the voice.
2. **The next 9%: the pck.** Godot's own pack format, no encryption.
   The box's study line (`tools/study/`) extracts pcks; any Godot pack
   extractor works. Read the scripts, learn the game's real tables,
   edit, repack (a repackaged pck replaces the one inside the installed
   package folder — the box loads what sits in `game/<plat>/goga.pck`).
   The scripts are plain GDScript bytecode — readable, renameable,
   editable.
3. **The last 1%: native/web.** A web game is plain files — read the
   JS, edit the JS. A native game is the native world's rules (the C
   ABI in, the game's own format inside) — the platform puts nothing
   in your way and takes nothing from your work.
4. **Localization:** translate `data/logic/strings.json` (or the game's
   own table) — keys untouched, values translated, the whole table, no
   invented keys. A localization pack = that file + optional
   audio/visual overrides.
5. **Flavors:** "make this horror, add gamble, make it porn, make it
   for girls, make it calm" — a flavor is a data-layer diff (palette +
   sfx set + mood numbers + overrides). Ship it as a folder diff against
   the package's data/ tree. The engine does not gate flavors; the
   AGE + CONTENT tags describe, the age door gates the play button,
   and the human decides what runs on their box.
6. **The line:** you mod what you legally hold, on your own box, for
   your own play (or with the owner's blessing for a republication).
   The platform will not crack DRM for you and will not stop you from
   studying what sits unencrypted in its own format — both of those are
   your responsibilities, not its features.
