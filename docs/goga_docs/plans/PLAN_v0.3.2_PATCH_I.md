# PLAN_v0.3.2_PATCH_I.md - the owner playtest round

Owner law honored: ONE push at the very end.

1. Snapshots: unzipped upload/space_invaders_v032_snapshots.zip (11 shots),
   every complaint confirmed pixel by pixel before touching code.
2. THE SLASHER (owner priority): TouchKit dragged() now emits TRUE polyline
   segments (prev->cur); first segment covers the silent pre-threshold walk.
   slasher seg floor 14px -> 2px. Probe regression feeds the REAL kit.
3. Art pass (tools/v032b_patch_art.py + v032b_boss_fix.py): atmosphere-only
   BGs (11), dash-derived enemies (11), big layered bosses (10); the
   divergent invaders ship_*.png copies deleted (the engine loads Lanes).
4. Engine pass: optionals-first flow (snake-standard image boxes), hearts
   "x nn" + shape, 6-level ladder, boss % chip under the body, story sheets
   (scroll + pause) + speaker-anchored alpha bubbles, tower-law analog
   controls, defender aim + weapon flavor + boss targeting, titan contact
   fuse + full-field, defend menu grays, shop 2-in-1 crew rows, dash shop
   sections, facts deleted, safe % formatting for lore lines.
5. THE HIDDEN BUG the playtest exposed: blast damage loops iterated the live
   `enemies` array while kills erased from it - every kill SKIPPED the
   enemies behind it (titan "not following the description"). Fixed with the
   copy law + a dense-field probe regression.
6. Tests: invaders_probe rewritten for the new laws (ALL PASS); the FULL
   battery green (flow_test, dash/slasher/xo/merge/dario/snake/tower/pong/
   geometry probes). Xvfb QA: 9 shots eyeballed against every complaint.
7. Thumbnail recomposed. version 0.3.2 PATCH I (base 30420).
8. Build both ABIs, ONE push, release with the APKs attached.
