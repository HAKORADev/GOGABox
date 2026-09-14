# HEAVY WAR — journal (03)

> Append-only. Newest at the bottom. Every pass adds its block:
> DONE / LEARNED / WRONG / NEXT. This file is how a fresh context resumes
> in one read.

---

## Pass 0 — 2026-09-14 — the setup

DONE:
- Repo resumed, laws re-read (AGENTS.md 1-31, ADDING_A_GAME, BOX_CORE_DESIGN).
- The mission folder + the GDD (`../heavywar.md`) + this journal born.
- THE PACK BLOCKER FOUND: the owner's Drive file is ToS-flagged at
  Google's side — `/view` = 403 with the ToS wall text, `uc?export=download`
  = 404. Nobody can download it, not just this sandbox. The owner was
  asked to re-upload (GitHub into the repo = the sure path).
- Architecture set: data-driven from day one (`heavywar_data.gd`), so the
  pack lands as swap + tune (see 02_PLAN.md).

LEARNED:
- Google's ToS wall text (translated from the zh page): "sorry, this item
  violates our Terms of Service, so you cannot access it".

WRONG (avoid repeating):
- First download attempts hit `drive.usercontent.google.com` directly with
  a guessed `confirm=t` — 404 wasted a call; probe `/view` FIRST to see
  the real wall before crafting endpoints.

NEXT:
- Build pass 1: the road + the tank + the gun + the sky skeleton.
- Then passes 2-8 per 02_PLAN.md, each with its qa phase.
- When the pack lands: 01_STUDY.md fills with the art/XML findings and the
  swap + tune pass runs.

---

## Pass 0.5 — 2026-09-14 — THE PACK LANDED + full study

DONE:
- The owner's new link worked (7z, password "heavy"). `drive.usercontent.
  google.com/download?id=...&export=download&confirm=t` = clean 20.5 MB pull
  (gdown was ToS-blocked on this file too, but plain usercontent was not).
- py7zr FAILED on this archive (`LZMAError: Invalid or unsupported options`).
  Standalone 7zz 25.01 binary (7-zip.org, no sudo) extracted it fine:
  999 files, 30 MB -> `heavywar_src/extracted/HeavyWeapon/` (outside repo).
- Full pack study done, digest script at `scripts/hw_study.py` ->
  `heavywar_src/DIGEST.json`. Findings -> `01_STUDY.md`:
  21 enemies (armor/points/weapon + strip dims), 19 mission levels +
  10 survival sets x 80 waves, 10 bosses with L1/L2 comeback params,
  10 places with 4-layer parallax + prop anims, 465 images, 184 sounds.
- THE USAGE LAW applied to the plan: art = 100% ours (PIL redraw at the
  pack's frame sizes), audio = synthesized, XML = rewritten into our tables.

LEARNED:
- The original's drive.usercontent endpoint still honors `confirm=t` for
  files that gdown refuses — same as the Quaternius folder trick.
- py7zr's LZMA decoder is narrower than real 7zz; always keep the 7zz
  binary at tools/7zip/ in the sandbox for password archives.
- The original XMLs are MALFORMED (multiple roots, stray `"/ attr>` in
  Anims.xml) — a tolerant regex-sanitizing parser is required.
- The pack carries NO drop/RNG tables — pickup logic was compiled. Our
  friend-helicopter cadence is our own design (the GDD's), free of legacy.
- Boss comeback model straight from the data: L2 = armor x2.5-4, fire x0.6.
- 100 fps frame units everywhere (`fire="175"` = 1.75 s); wave `length` is
  scroll px, not seconds.

WRONG (avoid repeating):
- None this pass; the tolerant-parser regex ate a space once (`"\1/>` ->
  `" \1/>`) — caught on the third run.

NEXT (pass 1):
- Scaffold `game/games/heavywar/` (heavywar.gd / heavywar_data.gd /
  heavywar_meta.gd) + registry entry + the GogaGame contract fit.
- THE ROAD + THE TANK + THE GUN + THE SKY skeleton with stand-in shapes,
  then the art tool paints the real slots (pass 1.5).

---

## Pass 1 — 2026-09-15 — THE ROAD + THE TANK + THE GUN + THE SKY

DONE:
- `heavywar_data.gd` born: 21 enemies (ours-named, the 11-fry/10-specials
  point law 1 / 10..100), 10 places (palette + exclusive + 180-360s), 5
  wave tiers x 4-7 recipes, 10 boss faces + the comeback formula
  (armor x2.2^cb, fire x0.85^cb, speed x1.06^cb), the six stats with their
  per-level reads, the drop table + caps, the shop prices (provisional).
- `heavywar_meta.gd` born: banked points, raise/lower with the LOCK + CAP
  laws, run records into counters (hw_kills/hw_score/hw_places/
  hw_bosses_run), the lore-once flag.
- `heavywar.gd` pass-1 playable: three-zone multi-touch (left swipe / right
  hold / middle nuke + the emulation-twin debounce), the spawn director
  (tier = places/2 + exclusives ride in), 12 enemy brains, the weapon set
  (dumb/guided/frag/armored/atom bombs, guns, missiles, rpg arcs, orbital
  laser), shells vs enemies vs boss parts (MIRROR front-shield + PLOWMAN
  plow armor laws), shields-eat-first with per-layer hp, the iframe gate
  INSIDE _hurt_tank, nukes (aegis blast width), the friend helicopter +
  crate chain (caps 3/3/3, the every-3-places coin crate), the laser
  megabeam, tunnels (clear hostiles + THE WAVE QUEUE + drops; calm both
  sides), shuffle-per-lap place queue, the boss cadence (every 5 places,
  1 permanent point, the armory sheet opens), the BACK-LAW sheet sync
  (_goga_sheet_popped), death -> record_run -> finish_run.
- Registry entry: heavywar (landscape/shop/banner, coin_div 500 = the
  owner's /500 law, price 600 fee 20 charge 300 reveal 8/11 - all
  provisional until ship), 12 achievements.
- hw_probe: **85 checks, 0 fails** headless (tests/hw_probe.tscn).

THE BATTERY CAUGHT (the brutal + critical part working):
1. the iframe gate was only in _hits_tank - direct callers bypassed it.
   Now it lives in _hurt_tank (defense in depth).
2. the director ROLLED WAVES during the tunnel (state guard missing).
3. the armory sheet desynced from the state when closed by the back path
   - the _goga_sheet_popped hook now closes the state loop.
4. a leftover wave volley survived the tunnel and popped into the calm -
   _enter_tunnel now kills the queue too.

LEARNED:
- Godot 4.7.2 headless: `--check-only` does not register autoloads or the
  global class cache - always `--import` first, then judge only parse
  errors, then prove with a live probe run.
- The sandbox needs: addons staged as `addons/<name> = plugins/<name>/addon`
  (NOT the plugin root - the autoload path is res://addons/<name>/<name>.gd).
- Godot 4.7.2 editor zip from GitHub releases + standalone 7zz both live in
  the sandbox cache now (godot at /home/z/.cache/godot/bin/godot).

WRONG (avoid repeating):
- Probe cheat order: `all_owned` was set in _boot BEFORE the meta lock law
  - the cheat owns every shelf, so the lock refused to refuse. The meta
  laws now run BEFORE the cheat, and _boot no longer sets it.
- boss_stats(11) is the DREADNOUGHT's comeback 1, not the gunship - the
  comeback count is boss_i / 10, the face is boss_i % 10. The probe now
  pins both faces.

NEXT (pass 2):
- THE ART TOOL (pass 1.5): tools/v040_hw_art.py paints every sprite slot
  the sim already reads (spr_enemy_*, spr_tank, spr_boom, spr_crate,
  spr_heli, spr_boss_*...) into assets/games/heavywar/ - original toy-
  military art at the pack's frame sizes, zero traced bytes.
- Then the place art layers (bg silhouettes per place) + the war room
  pass over the widgets.
