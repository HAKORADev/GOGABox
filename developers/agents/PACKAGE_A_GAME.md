# PLAYBOOK: package an existing Godot project

The project exists (yours, licensed, or one you are porting 1:1 from
the archive). The pck law decides the shape:

1. **Stage a packaging project** (tools/v043_package.py does this —
   read `stage_project()`): the BOX CORE copied at the SAME
   `res://game/core/` paths. Why: the box loads your pck with
   `replace_files=false` — the box's own files can never be shadowed,
   and your compiled `extends GogaGame` resolves to the box's real
   class at runtime (one class, no skew).
2. **Your files under your paths.** The game script + assets keep
   their original res:// paths (the four pilots kept theirs verbatim —
   the 1:1 port law).
3. **Headless export:** `godot --headless --path <staged> --import`
   then `--export-pack <preset> game/<plat>/goga.pck` per platform.
   The pck carries everything; the box skips what it already owns.
4. **The data door.** Wire the game's tunables to `GOGA.data_json`
   (with the packed fallback — the 1:1 behavior holds without the
   file) and its art to `GOGA.visual_override` (the same deal). The
   data/ minimums must then be REAL files — the validator counts them,
   and the modder will edit them.
5. **Assemble + validate + import + play.** The whole contract is
   PACKAGING.md; the validator names every miss.
