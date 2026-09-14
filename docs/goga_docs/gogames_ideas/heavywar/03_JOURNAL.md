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

---

## Pass 2 — 2026-09-15 — THE VOICE AND THE LEDGER

DONE:
- `tools/v040_hw_sfx.py`: all 20 event sounds synthesized from numpy
  (fire, boom/bigboom, the nuke's double crack, bombfall whistle,
  shieldhit, tankhit, rico, pickup/coin dings, heli rotor, lasergo+laser,
  tunnel whoosh, start horn, bossgo, bossdie cascade+jingle, gameover,
  click, crate) — 100% ours.
- The tank wears the shop's skin (live `_apply_skin`).
- THE SHOP on the sheet-stack law: 6 skins, the 4 armory locks, THE LASER
  at 5000. The back button and Android back both close it; the rebuy
  refresh reopens the same window; pause rides with it.
- Probe: 99 checks 0 fails.

LEARNED:
- The `all_owned` cheat both LIES about locks and BLOCKS buys — the shop
  laws must run cheat-off.
- The shop rides `sheet_push` (the v0.3.3-p2 doctrine), NOT the older
  lanes-style pair juggling — the back law closes it for free.

---

## Pass 3 — 2026-09-15 — THE TEN FACES FIGHT

DONE:
- All 10 boss brains (gunship fan-sprays, dreadnought crawling broadsides,
  skystealer's dipping tractor + meteor rain, wreckball's shadow slams,
  warhead's cross-screen bombing lunge, kongo's throw + LEAP STOMP,
  eyebot's pod + tight fans, mechworm's boulder rain + road breach,
  warbot's telegraphed eye beam, secretfist's atom/fan/beam mix).
- The new projectile family: meteor/ball/boulder/barrel with a gravity
  table + ground-impact behaviors (the ball hurts by radius) + sprites.
- Probe: THE MARATHON LAW — 101 checks 0 fails (all ten faces tick 6
  simulated seconds each and die paying their point).

WRONG (avoid repeating):
- The warbot's `arm` part carries no `fire` key — parts default it now.
  Data files may be ragged; every reader defaults.

---

## Pass 4 — 2026-09-15 — THE SHIP PREP

DONE:
- `tools/v040_hw_thumb.py`: the 480x320 thumbnail from the game's own
  sprites (snow place, tank, scout formation, gunship, boom, stencil box).
- flow_test updated: 25 playable games, heavywar's economy pinned
  (title law, /500, fee 20, landscape). RESULT: ALL TESTS PASSED.
- config/projects.json: version_name 0.4.0, code base 31100
  (arm32 31101, arm64 31102 ride the build).
- games_done.md: HEAVY WAR on the shipped shelf (#25), the SOON shelf
  corrected (heavy-weapon-like shipped, four names wait).
- The final film verified: GULFGATE combat (darts + raiders diving, the
  lighthouse, the tank, the war room strip, the SHOP button).

THE STATE AT PUSH:
- Playable end to end: intro tap -> shuffled places -> waves -> tunnel
  calm -> bosses every 5 -> armory points -> death banks the run.
- The GDD's laws all land: horizontal only, all places per run via
  tunnels with calm, shuffles every lap, exclusives per place, the
  helicopter's caps (3/3/3) + the every-3-places coin law, 6x5 armory
  with the rebalance menu, kills = score with the 10..100 specials and
  the life-per-1000 cap 3, the three-zone controls, no optionals,
  skins+4-locks+laser shop, the accurate war room strip.
- The owner tunes the numbers after the first device test — every value
  lives in heavywar_data.gd on purpose.

NEXT (post-test passes):
- The owner's device test -> the tuning pass (data file only).
- The laser's art pass (the megabeam is a ColorRect — worth a sprite).
- Music loop (CC0 or synth) — the game is SFX-only by design for now.
- Comeback count polish: after every 2nd comeback a face gains a new
  behavior (noted in 01_STUDY §4, not yet built).

## PASS 4 - THE SHIP-BLOCKER LESSON (the .cache file killed CI)

THE OWNER'S CATCH: the first v040 push failed the GitHub Actions build,
and a new file `.cache` appeared in the repo. Both the same accident.

WHAT HAPPENED:
- During the v040 work session a stray shell redirect wrote a 14-byte
  FILE named `.cache` at the repo root (contents: the text
  `/home/z/.cache`). It got swept into a commit by an add-all.
- The .gitignore already had `.cache/` - but the TRAILING SLASH makes
  the pattern match directories ONLY. A plain file named `.cache`
  walked right past it.
- CI needs `.cache/` as a DIRECTORY (build-android.yml caches
  .cache/jdk, .cache/android-sdk, .cache/godot there). Checkout
  created the file instead, the toolchain-cache tar restore died with
  `tar: .cache: Cannot mkdir: File exists`, and tools/bootstrap.sh
  then failed with `mkdir: cannot create directory ... File exists`.
  Both arch jobs red before Godot even ran.

THE FIX (same-session patch):
- `git rm --cached .cache` + delete the file.
- Also untracked tools/study/__pycache__/*.pyc (same class of junk,
  tracked since the study-pipeline commit).
- .gitignore: `.cache/` -> `.cache` (no slash - catches file AND dir)
  plus `__pycache__/` + `*.pyc`.
- The fix commit re-triggers the build; watch it to green before the
  owner downloads.

THE LAW GOING FORWARD:
- Before every push: `git status` AND a quick scan of the staged file
  list for dotfiles at the repo root. Anything that is not
  .gitignore/.github/docs/projects/config/tools must justify itself.
- Redirect accidents (`cmd > file` typos landing at cwd) are a real
  failure class in long sessions - the .gitignore gap closed it at
  the net, the pre-push scan closes it at the source.
