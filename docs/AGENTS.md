# AGENTS.md — operating manual for AI agents (and future humans)

> **You are resuming work on this repo. Start here, do not archaeologize.**
> This file is the "AI skill": it compresses everything a fresh session needs
> — environment, workflow, the ads integration with the real IDs, and the
> commit / push / build discipline — so the path from "hello" to "working"
> is one obvious step.

Human guides live next door: SETUP · ASSETS · ADS · CI · RESOLUTION_RULE.
Planning lives in `docs/goga_docs/`. This file is about *operating* the
repo: resuming, changing, shipping.

## 0. The one obvious step (resume checklist)

```bash
cd GOGABox                      # fresh sandbox? see §7 first
git pull                        # fast-forward to latest main
./tools/bootstrap.sh            # idempotent: ~1 min warm, ~10 min cold
./tools/test.sh gogabox         # must end ALL PASS
```

Then, in order:

1. Skim `git log --oneline -15` — commit subjects (`<area>: summary`) tell
   you what landed last. The repo has no in-repo journal by design (see §8).
2. Check CI is green: `./tools/ci.sh` (or the Actions tab).
3. Do the task — §4 for ads, §5 for build, §6 for shipping.
4. **Log your session in the sandbox-level journal** (outside the repo,
   §8). An undocumented change is half-done work.

## 1. What this repo is (and is not)

**This repo is GOGABox** — the Godot all-in-one Game box. One product: the
`projects/gogabox/` Godot project (menu + games + economy + plugins). The
machinery around it (`build.sh`, `.ci/`, `tools/`, `config/`, `plugins/`,
CI) exists to build and ship that one product — it stays generic in
mechanics (registry-driven, no hardcoded IDs) but serves nothing else.

| layer | rule |
|---|---|
| **The machinery** — `build.sh`, `.ci/`, `tools/`, `config/`, `plugins/`, CI | stays project-agnostic in mechanics; no game name or ad IDs hardcoded |
| **The product** — `projects/gogabox/` | the whole point of the repo |

`docs/` = **guides** (SETUP · CI · ADS · ASSETS · RESOLUTION_RULE · AGENTS)
plus `docs/goga_docs/` — the GOGABox planning home (GDDs in `gogames_ideas/`,
product thoughts in `ideas/`, release lists in `plans/`, raw dumps in
`brainstorms/`). If a doc answer starts with "for gogabox …", that content
belongs in `docs/goga_docs/`.

## 2. Ground rules (non-negotiable)

1. **Never edit generated paths**: `projects/*/android/build/`,
   `projects/*/addons/`, `dist/`, `.cache/`, `.godot/`. They are wiped and
   re-materialized on every build. Fix the *source* instead: the
   `android-overlay/`, the plugin, or the config.
2. **Toolchain changes go through `config/environment.lock`** — never curl a
   random SDK version into a script. Bump lock → delete the affected cache →
   `./tools/bootstrap.sh` (docs/SETUP.md has the exact freeze procedure).
3. **If you did it twice by hand, script it** and put it in `tools/`.
4. **Assets: CC0 only**, vendored (committed), recorded in the project's
   `assets.manifest.json`. Never hot-link at runtime.
5. **Secrets discipline**: keystores, passwords and GitHub tokens never
   enter the repo (`.gitignore` guards `*.keystore` and `.ci/local.env`).
   **Exception (owner-approved, v0.0.7):** `config/keystore/arsenal-release.jks`
   IS committed. An ephemeral per-run debug keystore made every update
   "conflict with the installed package" — a stable signature is what makes
   sideloaded updates installable. This is a hobby sideload project: rotate
   the keystore (and bump `keystore.pass` in `config/projects.json`) BEFORE
   any store publishing, and treat the current signature as public.
6. **Tests are the contract**: `tools/test.sh <game>` passes before and
   after every change. CI green = shippable; red = stop and fix first.
7. **Talk to the user in English**, short messages, conclusions first.

## 3. Map (30 seconds)

| path | what |
|---|---|
| `config/environment.lock` | pinned toolchain: Godot 4.7.2, JDK 17, Android SDK 36 / build-tools 36.1.0, AGP 8.6.1, Gradle 8.11.1 |
| `config/projects.json` | registry: package, version, ABIs, presets, `use_plugins`, `ci_auto` |
| `.ci/materialize-project.sh` | builds a clean `android/build`: pinned template + `android-overlay/` + plugins + config injection |
| `build.sh <g> [--abi ...] [--type ...] [--aab]` | materialize → patch presets → import → export → verify |
| `tools/test.sh <g>` | headless integration test (`tests/flow_test.tscn`, exit 0 = pass) |
| `tools/bootstrap.sh` | installs exactly the locked toolchain into `.cache/` (same on CI and local) |
| `tools/ci.sh [watch]` | list / watch GitHub Actions runs from the terminal |
| `tools/sync-assets.py` | re-vendor assets from `assets.manifest.json` |
| `tools/study/` | the game-study pipeline: web-portal scrapers, APKPure downloader, APK decompiler line, Godot .pck extractor, Quaternius/ambientCG fetcher — see docs/DECOMPILATION.md (study copies stay OUT of the repo) |
| `plugins/<name>/` | GOGABox android plugins (`notify`) |
| `docs/` | guides + `docs/goga_docs/` planning home (GDDs · ideas · plans · brainstorms) |

## 4. The platforms + THE 0-ADS LAW (the open-source round, 2026-09-19)

**THE 0-ADS LAW (owner):** GOGABox is MIT-licensed open source with ZERO
ads. The whole monetization stack was removed whole: the Unity Ads plugin
(`plugins/unity_ads/`), the `Ads` autoload, the death-menu DOUBLE (watch
ad) theatre, the per-3-runs interstitial pacing, the banner strip (the
registry `banner` keys and the 52dp reservation), `ads_config.json`,
`docs/ADS.md`, and the ad gradle deps + manifest entries. The box holds NO
INTERNET permission - it is fully offline. GOGACoins are the only currency.
Do not resurrect any of it. (The old spec lives only as history:
`docs/goga_docs/brainstorms/THE_APP_STORE_QUESTION.md`.)

**THE TWO-PLATFORM LAW:** ONE build action (`.github/workflows/build.yml`)
ships BOTH platforms on every push to main:

- Android APKs: arm32 + arm64 (the matrix via `.ci/ci-matrix.sh`).
- THE Windows exe: `GOGABox.exe`, x86_32, official Godot 4.7.2 templates
  (SSE2 baseline - runs on pre-2014 CPUs with no SSE4.2; 32-bit natively,
  64-bit through WOW64), embedded pck, verified by THE REAL-EXE LAW
  (`file` must print a genuine `PE32 executable ... Intel (i386|80386)`,
  size > 50MB so the pck is inside). No 64-bit exe, no template forging.

**The PC laws (do not break them when touching games):**

- THE VERTICAL SLICE LAW: on desktop, portrait designs render a KEEP-aspect
  slice down the window's middle; the letterbox wears the box brown
  (`ScaleRule.is_pc` + `apply_vertical_slice`; landscape keeps EXPAND).
  v0.4.0-17: the slice is the FALLBACK - in windowed mode THE RE-WINDOW LAW
  reshapes the window to the content first (portrait -> 9:16, landscape ->
  16:9, `ScaleRule.re_window`), so no empty sides show at all.
- THE FULLSCREEN LAW: F11 / Alt+Enter anywhere (main._input) + the SETTINGS
  toggle (PC builds only). The choice persists in Box settings
  (`pc_fullscreen`) and re-applies at boot (`ScaleRule.boot_window`).
- THE CONTROLS: every game wears `controls_pc` in its registry entry
  (keyboard/mouse lines rendered as HOW TO PLAY - PC in the guide); games
  with analog/zone touch controls carry a keyboard twin (the arrows /
  SPACE patterns - see dario/hopper/invaders/lanes/merge/pong/pacman/maze/
  brickbreaker/geometry/goldminer/deathworm/rockbreaker/heavywar).
- THE PLATFORM LAW: every registry entry wears `"os": ["android", "pc"]`;
  the search sheet filters by PHONE/PC chips.
- NOTIFICATIONS: the notify bridge stays a desktop no-op (its GDScript
  guards `OS.has_feature("android")`).
- `emulate_touch_from_mouse=true` in project.godot makes every tap game
  mouse-playable with zero code - only zone/analog games need the keyboard
  twin.

**THE SLIM PACK LAWS (v0.4.0-17 - the owner's size round: "213 MBs ... x2.2
the size of one apk ... there is something like compressing"):**

- THE SLIM AUDIO LAW: `assets/audio` holds OGG sources only (libvorbis q6,
  `tools/v0417_slim_audio.py` - 417 wav sources converted, duration-checked
  to 150 ms, refs patched). A forge that emits wav must convert before
  commit. The Jukebox already prefers .ogg and force-loops music at runtime.
- THE 2D TEXTURE LAW: every 2D texture imports LOSSLESS
  (`compress/mode=0`, no mipmaps - `tools/v0417_slim_textures.py`). The 38
  VRAM-compressed stragglers (bgs, thumbs, chess woods, splash) weighed 3x
  their source pixels and went blocky on gradients. VRAM compress is for
  real 3D only - this box has none.
- THE SMALL DELIVERY LAW: the Windows artifact ships THE ZIP ONLY (the exe
  + README inside it); CI fails if the delivery passes 175 MB. The exe's
  floor is the OFFICIAL 32-bit template (~116 MB, all renderers compiled
  in) - no forging, no UPX, no 64-bit preset; the game data is the only
  part that answers for its weight.


## 5. Developing & building

```bash
./tools/test.sh gogabox                # desktop integration test (ads simulated, no device)
./build.sh gogabox                     # both ABIs → dist/gogabox/*.apk
./build.sh gogabox --abi arm64-v8a     # fast single-ABI loop
./build.sh gogabox --aab               # Play Store bundle
```

- Godot binary: `.cache/godot/bin/godot` (or `source .cache/env.sh`).
- A build = materialize → patch presets → headless import → headless export
  per ABI → APK verify. Identical steps on CI and local.
- Generated assets (SFX, launcher icons): per-project tools under
  `projects/<g>/tools/`.
- Environment details and troubleshooting: docs/SETUP.md.

## 6. Commit, push, CI, release

**Commit style** — `<area>: <imperative summary>`, matching history:
`ads:` · `build:` · `ci:` · `config:` · `docs:` · `game:`. Plain `git revert`
for undos (keeps the original subject). One logical change per commit;
include the WORKLOG.md entry with it.

**Push** — `git push origin main`. Repo is public: clone/pull need no auth;
push needs the PAT (§7).

**CI** — pushes matching `projects/** plugins/** config/** .ci/** tools/**
build.sh` trigger `build-android` (every `ci_auto` project × every ABI).
**Docs-only pushes do not trigger CI — that is fine.** Terminal watching:
`./tools/ci.sh` (list last runs) · `./tools/ci.sh watch` (tail one to
completion). Cached runs ≈ 8–12 min per ABI, cold ≈ 20–25.

**Version bump (GOGABox design rule, owner-locked v0.1.8; THE PATCH NAMING
LAW, owner-locked v0.3.3-6)** — every new build gets `version_name`
**+0.0.1** (0.1.7 → 0.1.8 → 0.1.9 → 0.2.0 …) and `version_code_base`
**+10**; effective codes: arm32 = base+1, arm64 = base+2 (Play Store needs
distinct codes, higher on the modern ABI). Patches are REAL version
numbers now: a patch of `0.3.3` is **`0.3.3-1`, `0.3.3-2`, …** (`0.3.3-6`
= the sixth patch of 0.3.3), and a build with no patch is plain `0.3.3`.
NEVER write "PATCH N" words anywhere - `version_name` is printed verbatim
in the APK filename (`GOGABox-v<version_name>-<abi>.apk`) and the release
tag (`v<version_name>`), so the suffix number IS the patch identity. A
patch still bumps `version_code_base` +10 (every installable build needs
a fresh, higher code). Any other jump (+0.1.2, skipping, vibes) is
refused on sight — the answer is literally "fuck you" (owner's own rule,
his words, he will laugh).

**Price display (GOGABox design rule, owner-locked v0.1.9)** — ANYTHING that
costs GOGACoins shows the GOGACoin icon next to its price, everywhere
(shop rows, unlock buttons, tiles, hints). Never print a naked number —
"120" means nothing; games may carry their own currencies someday, so the
coin icon is what says "this price is GOGACoins". Companion rule:
unaffordable items are GRAYED OUT (disabled, dead to taps) — a dry wallet
must never "buy" something it cannot pay for (error-sfx-only buying is a
bug, not a design).

**Release** — bump version → push → CI green → Actions → **build →
Run workflow** → pick project + `create_release: true` → tag `v<version_name>`
gets the APKs + the Windows zip. Re-running the same version clobbers the
previous assets.

**Before any store submission** — `keystore` credentials verified ·
package name matches the installed one · docs updated. (THE 0-ADS LAW:
there is nothing ad-related to test or disclose anymore.)

## 7. Sandbox survival (this machine)

The workspace has been wiped **twice**; both times full recovery took
~10 minutes because everything lives in git:

1. `git clone https://github.com/HAKORADev/GOGABox.git`
   (public — no auth needed).
2. `./tools/bootstrap.sh`.
3. `./tools/test.sh gogabox` — if this passes, you are fully back.

Notes:

- GitHub PAT (push + CI API): kept **outside** the repo; if missing, ask the
  user. `tools/ci.sh` accepts `GITHUB_TOKEN` or `$HOME/.arsenal-gh-token`;
  read-only public access works without one (rate limits apply).
- Session journal lives **outside the repo** (user preference):
  `/home/z/my-project/worklog.md`. Write entries there, never commit a
  journal file into the repo. Since it can be lost with a sandbox wipe,
  the durable memory is this manual + clean commit messages.
- Builds are validated on 4 GB RAM; keep `org.gradle.jvmargs=-Xmx2048m`
  (already set in the overlay).

## 8. Session journal (outside the repo)

The task journal is **not part of the repo** (user preference — the repo
ships products, not diary entries). It lives in the sandbox at
`/home/z/my-project/worklog.md`: append-only, newest at the bottom, one
entry per session — what was asked → what was done (commits, runs,
versions) → what is pending → decisions taken.

Because that file can vanish with a sandbox wipe, keep the durable record
in the repo itself: accurate AGENTS.md sections and descriptive commit
subjects (`git log` is the real history).

## 9. Doc index

| need | read |
|---|---|
| env setup, toolchain freeze, pitfalls | docs/SETUP.md |
| add a new game | inside the box: one registry entry + one GogaGame script + one thumbnail — read `docs/goga_docs/plans/BOX_CORE_DESIGN.md` and docs/ADDING_A_GAME.md |
| the platforms + the 0-ads law | docs/RELEASE_LAW.md + this file §4 |
| assets policy, manifest, source catalogs, store trials | docs/ASSETS.md |
| studying other games: portals, APKs, engines, the usage law | docs/DECOMPILATION.md |
| CI, caching, releases, signing | docs/CI.md |
| what happened so far | `git log` + the sandbox session journal (§8) |

## 10. THE METHODS THAT CLICKED (v0.3.8-5/-6 field-tested)

The owner asked, after v0.3.8-6 landed: "if there is a thing you did that
helped you to fix the things, write it in the agents md itself if it is
that helpful for real." These are the methods that actually broke the
failure loops - written here so every future session starts with them.

**1. EVIDENCE BEFORE EDITS - boot the real thing and LOOK at it.**
The single biggest unlock across v0.3.8-5/-6. Headless probes verify LAWS,
but the bugs that shipped ("it is still the old thing", the transposed
dominoes, the misplaced frame) were all things a headless check can never
see. The working loop:

```bash
GODOT_BIN --path projects/gogabox res://tests/rec_domino.tscn   # or qa_*.tscn
# on the Xvfb rig: xvfb-run -a ... , film with ffmpeg -f x11grab,
# then MEASURE the frames with PIL (pixel census: where are the tiles,
# what color is the band, how big is the rect) - not eyeballs, numbers.
```

Never claim a visual fix without a still from the rig. A pixel census
(count the felt pixels, find the brown band, measure the chain tile's
aspect) catches in one command what nine thousand headless asserts miss.

**2. THE INDEX LAW - Controls are not their parents.**
The W-D-L widget "flip" (top-left over the back/shop buttons) happened
because `_score_label.get_parent()` is the chip's INNER panel, and its
`get_index()` is its seat INSIDE the chip (0) - so `move_child(widget,
that_index)` made the widget the FIRST child of the HUD row. When seating
a sibling relative to a composite control, seat by the OUTER container:
`_score_label.get_parent().get_parent().get_index()`. Verify with one
print of the row's child order after build.

**3. THE SEAM LAW - cover-fit math must clip.**
`draw_texture_rect(tex, Rect2(off, dst))` with a cover-fit dst SPILLS the
overflow outside the destination rect (no clipping in canvas draws). Any
texture fitted into a frame must use `draw_texture_rect_region` with the
visible source window (`src = (tex_size - dst_size / k) * 0.5`), or a
CanvasGroup/clip. The felt used to bleed past the rails on two sides -
that was the "mis-placed frame" the owner saw.

**4. THE SHORE LAW - interface separation is a painted overlay, not luck.**
"Map things overlap the interface" (tall trees into the HUD strip, wide
props into the side panel) is fixed by a field-owned overlay that is the
LAST child of the field: solid room tone across the interface's own
strips, fading over the field like a soft shelf shadow. Tree order then
does the z-work: every map layer under it, the panel + HUD CanvasLayer
above it. Things "sink" under the interface smoothly - no hard clip, no
sprite surgery.

**5. STATIC PIXELS FOR LOCKED ORIENTATIONS.**
For a portrait-locked game on a fixed design canvas (1080x1920), every
seat is an ABSOLUTE constant - no `vp.y * 0.4` proportional math. The
same numbers land the same pixels on every device, and the rig can
assert exact rects. Proportional math is only for designs that truly
scale.

**6. THE CHAIN-HONESTY CHECK FOR COMPOSED ART.**
When code composes dominoes/snake/cards art (thumbnails, posters), adjacent
halves must MATCH - build the pose from the game's own placement law (the
serpentine pack), and read the composed image back at face value. A poster
with a lying tile whose ends don't touch their neighbours reads fake
instantly. PIL note: `rotate(+90)` is CCW (top half ends up LEFT);
face files stored lo-hi need a vertical flip when the bigger value must
face an end.

**7. THE ONE-TRUTH RULE FOR POSITIONS.**
Every screen position gets exactly ONE computation point (a constant, or
one layout function). The dominoes end-slot bugs of v0.3.8-4/-5 round 1
came from two places computing the same slot (relayout + a leftover
block). When retiring a law, grep the call sites of its helpers and kill
them in the same commit - the compiler (GDScript) will NOT warn about a
dead duplicate painting on top.

**8. THE FEED TRUTH (v0.3.8-7) - "unclear sorting" means a TIE hitting an
UNSTABLE sort.**
The owner's "the feed sorting follow unclear something?" (failed fix
attempts across sessions) was never a sort-expression bug: feed_rows
ranked OWNED tiles by the save's owned[] ACQUISITION order, which only
LOOKED like release order while the reveal ladder was one straight chain.
Two quiet breaks: (a) v0.3.7-1's parallel paths (inbox rung, charge
meters, cross-game orders) let games unlock out of catalog order; (b) the
all_owned cheat answers owns_game() = true WITHOUT appending to owned[],
so every cheat-owned tile tied at the fallback ord - and Godot's
sort_custom is NOT stable, so ties land in an arbitrary but repeatable
scramble that reads as "some unclear thing". THE METHOD: when a user
reports an order that "follows unclear something", print the SORT KEYS
first and look for ties; an unstable sort turns ties into a mystery.
Ranking by the CATALOG index (release order) kills the tie class whole -
the feed reads snake -> pong -> ... -> chess on every save, under any
cheat, forever.

**9. THE WALL LAW (v0.3.8-8) - "really behind the interface" means SOLID
occlusion, never a fade.**
The owner rejected the v0.3.8-6 "shore" (a field-owned overlay fading the
room tone over the field's edge rows) as "that blur-like thing": it washed
the field's own pixels AND sank flying bloons under a gradient. What the
owner wants for "map stuff goes under the interface" is the NORMAL thing:
opaque interface surfaces seated BETWEEN the world and the widgets in the
tree (pop_siege's two #241407 ColorRects - the top strip ends exactly at
FIELD.y, the dock starts exactly at the field's right edge - so no field
pixel is ever covered and the occlusion edge is seamless against the host
backdrop). Props walk under a real surface and are GONE. No blur, no fade,
no wash, no clip masks.

**10. THE SPARE-CANVAS LAW (v0.3.8-8) - aspect EXPAND grows the canvas
past 1080x1920, so a static table must seat its BOTTOM off the real
viewport.**
The "brown band at the bottom" was never a color choice: the stretch rule
grows the design canvas in the spare axis (a 20:9 phone boots a 1080x2400
canvas), and a game that paints only its certified 1080x1920 constants
leaves the host's backdrop (#241407) visible below. The fix is not a
full-screen patch - it is to seat the bottom-anchored furniture (the hand
fan, the frame's bottom rail) off the REAL viewport height
(`maxf(1920, vp.y)`) and let the frame EAT the spare (domino's vertical
table grows the felt; the hand rides the true bottom). Keep the 16:9
pixels bit-exact (`1548.0 if SCREEN_H <= 1920.0 else ...`), grow only the
spare. Census the result with PIL (count the host-brown pixels; want 0).

**11. THE TWO TABLES (v0.3.8-8) - adding a position to a pinned game is a
CONSTRAINT SEAT, not a rewrite.**
Domino went portrait->both, chess landscape->both (the owner's position
ask, the slasher law). The pattern that worked: (1) turn the layout
CONSTANTS into vars seated by one `_apply_orientation(o)` at setup; (2)
keep every downstream seat FRAME/FIELD-relative so it follows for free;
(3) the ask = slasher's raw overlay (dim STOP eats taps) shown only when
`start_orientation == ""`, and `orientation_settled()` = drop the ask;
(4) bare rigs (rec_*/qa_*) must set `start_orientation` AND call
`ScaleRule.apply(get_window())` - a bare boot skips the menu governor, so
a 1920x1080 window otherwise keeps a portrait canvas and the film draws
the game in a column; (5) flow_test's orientation asserts update with the
registry (they are the contract, not an obstacle).

**12. THE FRESH SHEET LAW (v0.3.8-8) - a confirm that mutates state under
a still-open menu must re-seat that menu.**
The owner: "the menu still shows the previous one ... i have to re-open
it to update the menu". Sheet rows read their state at BUILD time (the
"(ON)" label, the SWITCH buttons), so a YES that equips underneath leaves
a live, lying sheet. The fix: in the YES handler, after applying, pop the
stale sheet and call its own open function again (merge2048's size
confirm). The NO path stays as-is - nothing changed underneath it.

**13. THE STATE LAW (v0.3.9-1) - a round-entry function must seat the
WHOLE state machine, and a rig that sets state by hand MASKS a dead one.**
The owner tested v0.3.9 and reported both new games' controls as "like
they are not existing". Root cause: `_new_round()` never assigned
`state` - the gate tap left it "ready" and the round-over advance left
it "round_over", and every aim/tap/release handler early-returns on
those states. Every rig (qa + rec) called `_new_round()` and then set
`state = "play"` BY HAND - the mask that hid the dead machine from
~60 passing checks. Two rules fall out: (1) the function that opens a
round is the ONLY door, so it seats state, turn, and the armed CPU in
one place; (2) a probe may never set the machine's state after calling
the entry function - if it must, the entry function is broken. Pin it:
a qa check that calls `_new_round()` and asserts the state BEFORE any
hand-set would have caught this in v0.3.9.

**14. THE REAL-FINGER RIG (v0.3.9-1) - drive the TRUE input pipeline, not
the handler.**
Calling `g._goga_input(ev)` directly proves the handler's logic; it can
NOT prove the finger's journey (engine queue -> `_unhandled_input` ->
`tk.feed` -> handler), and it feeds coordinates the real events would
never shape. `tests/qa_v039rig.gd` injects REAL events:

```gdscript
var ev := InputEventScreenTouch.new()
ev.position = pos; ev.pressed = true; ev.index = 0
Input.parse_input_event(ev)     # the engine delivers it for real
```

That rig caught what every direct-call probe missed: fourline's `_aim`
read the X ONLY, so a tap BELOW the board (the gate-tap's own release!)
dropped a disc into that column - THE AIM BAND fix (aim only over the
board + rail; outside it the ghost fades and a release plays nothing).
Run it on the Xvfb rig (it photographs every step) with
`QA_RIG_PHASES=fl,bv,chess` on a 1080x1920 screen and
`QA_RIG_PHASES=domino` on a 2400x1080 one - the window must fit the
Xvfb screen or the grab clips it.

**15. THE ALPHA LAW (v0.3.9-1) - a translucent fill on a shared draw
layer PUNCHES THROUGH everything drawn before it.**
The bovo poster's "extra lines that does not exist in the in-game" were
the plank bands: `ImageDraw` writes RGBA raw, so a band at alpha 70
REPLACED the slab pixels in the same working layer - at composite time
the band region showed the BACKDROP through the hole (a phantom dark
stripe). Same disease anywhere: the fourline poster's ghost disc punched
a hole through the frame. Two cures in `thumb_composer.py`: pre-blend
the tone opaque (`band = 0.28*dark + 0.72*base`), or bake the layer
first (`Scene.layer()` opens a fresh transparent pass so translucent art
composites for real). Rule of thumb: every pass that wears alpha fills
gets a `layer()` before it. Certify a rebuilt poster with the same
pixel scan that caught the bug (count the grid lines at a clean
x-column; want exactly the in-game count).

**16. THE BUY LAW (v0.3.9-1) - the shop SELLS, the options APPLY.**
The owner's refinement of the 2048 mechanic: "it should be bought only
from shop, never applied from it, the options menu is where this
happens". The shop's row for an owned size reads
"OWNED - APPLY IT FROM THE OPTIONS" (a label, no button); a locked
size's BUY takes the coins and stops - no confirm, no apply, board
untouched. The are-you-sure lives in the OPTIONS alone. Applied to
bovo AND merge2048 (one shared mechanic, one law). Probe it without
UI: buy, then assert the live board is untouched + the owned shop row
contains NO Button subtree.

**17. THE TWO-FORMULA RULE (v0.3.9-1) - a draw law and its landing-slot
law are one law; duplicate them word for word or not at all.**
Chess's graveyard draws each dead piece at `ic` (the tray icon size),
and the capture flight lands on `_tray_slot()` - a SECOND copy of the
same arithmetic. The portrait graveyard icons were 8px because the
formula divided the tray depth by 8 rows in BOTH orientations (portrait
stacks TWO rows of eight). The fix had to land in BOTH copies in the
same commit (the flight must land where the tray draws). Grep for the
second copy before fixing any layout formula - the compiler will not
warn that two functions share a constant by convention.

**18. THE FLOW LAW (v0.3.9-2) - a SORTED-asset lookup eats order info; the
ROTATION is the half order.**
The owner tested the dominoes board "+3 logical bugs ... connects in the
wrong direction using wrong position using wrong calculations". Root
cause: every domino face ships as a SORTED `lo-hi.png` texture
(`_set_tex` min/max's the pair), so the (a, b) ARGUMENTS can never pick
which half faces where - a lying tile ALWAYS painted lo left / hi right,
and half the chain's connections showed swapped pips (the serpentine's
-x rows and left-placed +x rows all need hi facing the flow's other
way). The fix is not in the lookup - it is in the DRAW: each chain entry
wears tv (the half that met the chain) + ov (the half it offers), and
the renderer picks the ROTATION per tile: lying = -PI/2 when lo leads,
+PI/2 when hi leads; standing corners = upright when tv == lo, PI when
tv == hi (every pip pattern is centrally symmetric, so the half turn
reads clean). The flight's r0/r1 must END in the body's exact rotation
or the face snaps at touchdown. Rule of thumb: the moment an asset
lookup SORTS its key, the caller's order is decoration - the transform
carries the meaning.

**19. THE IDENTITY LAW (v0.3.9-2) - a deferred landing marks by IDENTITY,
never by index, when the collection can grow at the front.**
Dominoes placed tiles into the chain array (left = push_front) and the
landing flight marked `chain[idx]["landed"]` with the index captured at
launch. A left placement inside the flight's 0.42s window shifts every
index by one - the mark blesses the WRONG entry and one tile silently
never paints (the rig's fast plies hit it every round; a real
insta-drop-left after the CPU's move could too). Fix: every entry wears
a monotonically increasing `pid` stamped at placement; the flight
carries the pid and the landing searches for it. Rule of thumb: an
index is a promise about a collection's future shape - if anything can
push/pop before the deferred work runs, hand the work an identity.

**20. THE DRAIN BEFORE THE VERDICT (v0.3.9-2) - a rig asserts only when
the air is clean.**
The chain-honesty rig kept seeing a tile "never painted" that the game
had honestly placed: its flight was still in the air (0.42s), because
the rig's own fat steps (0.3-0.5s) jump the CPU's 0.8s think mid-drain
and the loop's final turn-wait steps launch ONE MORE CPU move right
before the while-condition exits. Every rig that asserts on landed /
painted / settled state must first DRAIN: `while flies.size() > 0:
probe_step(0.3)` after the last action AND after the last turn-wait.
The same law that built THE REAL-FINGER RIG: the game's timing keeps
running under the rig's feet - drain, then judge.

**21. THE VERDICT-FIRST LAW (v0.3.9-3) - a round's last move is always the
game's biggest event; the verdict outranks the turn hand-off.**
Squares shipped with a round that could NEVER end: `_place` handled the
keep-brush branches (the KSquares "close one, go again") BEFORE checking
the winner - and on a dots-and-boxes board the final edge ALWAYS falls as
a capture, so the keep-brush return swallowed the resolve and the round
hung in "CPU IS THINKING" forever over a full board. The qa rig's
scripted finish caught it in one run (W=0 L=0, no memory record). The
fix is an ORDER law: inside the move resolver, check the terminal
condition FIRST, then the special-turn branches, then the plain hand-off.
Rule of thumb: when a game has a "same player continues" rule, the end
check comes before it in the code - or the game's last breath never gets
called.

**22. THE CLOCK TRUTH (v0.3.9-3) - fades live on the game clock; a rig
that samples one must DRIVE the clock, and a layer whose data changed
repaints in the mutator.**
Two faces of one law, both caught on the rig's film. (a) The squares qa
sampled a claimed box's fade pixel and got pure paper: the game was
probed with `paused = true`, so `_time` was FROZEN at the claim moment -
the fade's age was 0, its alpha was 0, and an invisible fill is HONEST
rendering of a stopped clock. A rig that wants to see a fade at age X
must `probe_step()` the clock there (13 steps of 0.01 for the 0.16s
color fade). (b) The same film showed placed lines missing from the
board: `_place` mutated the edge data but only the per-frame tick
repainted the layer - under a paused tick the paint stayed stale until
something else redrew. The mutator now repaints what it mutates
(`line_l.queue_redraw()` in `_place`, `_press`, `_drag_to`). Rule of
thumb: headless asserts check LAWS, the film checks TRUTH - and the
film's truth is only as fresh as the last repaint and the clock the
rig actually drove. Bonus seat: moving a widget AFTER the widget it
follows means its own removal SHIFTS every later index - compute the
insert seat from live indices (the squares goals card landed behind the
coins chip twice before the shift correction landed).

**23. THE LIVING LAYER (v0.3.9-4) - a layer whose art reads the clock
repaints on the TICK, not on events.**
The owner tested v0.3.9-3 and reported the square-complete color
transition "broken - after each drawn line, the animations moves a
frame". Root cause: law 22's half-truth. The mutators DID repaint what
they mutate (`box_l.queue_redraw()` inside `_place` when a box falls) -
but the box wash's alpha is a function of the GAME CLOCK, and the tick
only repainted `line_l` + `fx_l`. So the wash rendered its age-0 frame
at the claim and then SAT THERE, frozen, until the next event (the next
line placement) repainted the layer one frame forward. One frame per
event, exactly what the owner saw. The fix: the tick repaints every
animated layer every frame (`box_l` joined `line_l`/`fx_l` in
`_goga_tick`). Event-driven repaints are for EVENT-driven art (the
mutator law survives); time-driven art needs the heartbeat. Rule of
thumb: if a draw function reads `_time` (or any clock), its layer
belongs to the tick's repaint list - or the animation only moves when
something else happens. (The same round pinned two more squares truths:
the guide lattice - a board of naked dots reads BLANK, give every
playable edge a visible gray placeholder, the ink covers it when drawn;
and the HBoxContainer seat - `move_child(x, chip.get_index())` seats x
BEFORE the chip, `get_index() + 1` seats it after. The old index
gymnastics had been masking the wrong insert seat.)

**24. THE OVERFLOW LAW (v0.3.9-5) - a line that cannot fit at the floor
size must WRAP, never stretch its column.**
The owner tested the squares shop: "too wide buttons while content is
smaller". Root cause: the shop's long section labels went through
`Arc.fit_label`, whose font steps down to the FLOOR (12) and stops - a
text still wider than max_w at font 12 stayed a single-line Label whose
min width was its full text (825px inside a 560px scroll). One child's
min width stretches the whole VBox, so every 560px button FILLED to 825
and clipped at the viewport - the coins cut, the words cut, the buttons
"too wide". The fix lives in the ONE helper (ui_kit.gd): when the fitted
line still overflows, fit_label enables autowrap inside max_w. Rule of
thumb: a Label is a LAYOUT ACTOR - its min width votes on the column's
width; a non-wrapping label votes with its full text length. Any long
text inside a fixed column wraps or the column dies.

**25. THE STORY SHEET LAW (v0.3.9-6) - a raw Arc.sheet NEVER joins the
pop stack; either track the pair or push it.**
The owner's "biggest L": the dot eater's lore START button "does not
close the dialogue so i can start" - the game was UNPLAYABLE from the
first boot. Root cause: `_story_show` built its card with a RAW
`Arc.sheet(root, 0.0)` (the invaders pattern's HALF) but closed it with
game_base's `sheet_pop()` - which only pops sheets that came through
`sheet_push`. The stack was empty, the pop was a silent no-op, the dim
lived forever, and the tree unpaused UNDER a stuck dim (untouchable).
Two honest shapes, pick ONE per sheet: (a) `sheet_push(0.0, "id")` +
`sheet_pop()` - the tracked stack, the back button understands it; or
(b) the raw `Arc.sheet` + YOUR OWN tracked pair array freed by your own
closer (invaders `_story_pair`/`_story_down`) - for sheets that must
never answer the back button. Mixing half of each is the bug class.
Probe it with a REAL finger event on the button (qa_v0396_round): assert
the pair is empty, the tree unpaused, and the next state appeared.

**26. THE HONEST TARGET LAW (v0.3.9-6 round 2) - a step helper returns a
STEP; add it ONCE. And a movement bug is found by DRIVING, not by
asserting dirs.**
The owner filmed the dot eater's movement "corrupted": the body swept
DIAGONALLY to a cell off the board, froze there with its face turned
(the OOB error storm read every further `is_open` as null/wall), and
every later swipe pushed another error. Root cause: ONE shape copied
ten times - `to = c + _wrap_to(c, dir)` - but `_wrap_to` RETURNS the
next cell (`c + dir`, x-wrapped), so the flight targeted `2c + dir`.
The qa suite never caught it because it asserted `player["dir"]` and
`buf` - never `player["to"]` - and its seat helpers set `from`/`to` by
hand, bypassing every real takeoff. Two cures landed together: (a) every
flight site reads `to = _wrap_to(c, dir)` (the helper's return IS the
target), plus the BOUNDS LAW inside `is_open` (an out-of-grid cell is
never open - no error storms, ever); (b) THE FLIGHT RECORDER
(tests/de_flight_rec.gd): REAL finger gestures through the engine queue
while a sampler classifies every swipe's disposition and flags OOB
seats, dishonest flights (from/to not adjacent/wrap/rest), and pixel
teleports - exit 1 on any. Rule of thumb: a movement law is proven by
POSITIONS over time, not by the direction enum after the fact; and when
a helper returns "the next X", the call site adds NOTHING.

**27. THE SHELF TRUTH LAWS (v0.3.9-11) - the shop says what it is, or it
says nothing.**
The owner audited the shops after v0.3.9-10 and found the whole shelf
family lying in three ways: an equipped item collapsed into "small text
in green saying a description for something no one cares about", rows
wore "word + em-dash then shitty talk after the em dash", and every
button wore its own color for no reason. THREE laws, one sweep (the
sweep already landed in that version - keep them for every future
shelf):
   (a) **THE ON ROW LAW**: an equipped item keeps its FULL-SIZE row and
       plainly reads `NAME  (ON)` - built with `Arc.on_row(...)` in
       ui_kit.gd (a solid green card, same width/height as the action
       buttons). It NEVER collapses into a small colored fit_label. If
       the row is owned-not-equipped it reads just `NAME` (tapping
       equips); unowned reads `NAME <coin icon> PRICE`.
   (b) **THE NO-DASH LAW**: shop rows and section labels carry NO
       description, no flavor, no "word - talk" after an em-dash.
       Descriptions live in the game guide, never on the shelf. Section
       labels are one short name: "SKINS", "THEMES", "POWER-UPS". The
       ONE sanctioned exception is the functional pointer the owner
       pinned in law 16: an owned row of a shop-only item may read
       "(OWNED - APPLY IT FROM THE OPTIONALS)" - that is instructions,
       not talk. Real examples of the banned shape (do not regrow
       them): `"IVORY  (ON) - the carved classic - yours on any theme"`,
       `"JADE - the lucky stone"`, `"%s - FIELD THEM"`, `"SKINS - the
       pawns only you field, on any theme"`, `"PLACES - the garden you
       play in"`.
   (c) **THE ONE-COLOR LAW**: inside one shop, buy/equip buttons share
       ONE color (`Arc.ACCENT`) unless the color IS the item's own
       preview (snake's lava skin wearing lava orange - a direct
       reason). The ON row is green because "live" is its meaning. No
       third color, no per-row rainbow.
Sweep test: `grep -rn '(ON) - ' game/games/` must return nothing (the
powerup pointer's "OWNED - APPLY" inside the parens is the only legal
dash left).

**28. THE HOUSE CONTROLS LAW (v0.3.9-11) - optionals and mode asks wear
the house layout, never a bespoke one.**
The owner: a game's options menu "looks completely unrelated" when an
agent invents a new layout per game. Every mode/optional ask follows
the same bones: a dim + centered panel (Arc.sheet or the slasher
overlay), ONE short TITLE that states the ask, the choices as EQUAL
side-by-side cards/buttons in one HBoxContainer row (snake's mode row,
fruit slasher's produce row, the ludo X1/X2/X4 row), ONE shared action
color, NO hint line, NO explanation of what each mode is - "this is the
guide work". (THE v0.3.9-13 CORRECTION: the owner caught the title-less
optionals sheet - "i have even gave you an example what a title to
write" - and pinned the rule: not-too-helpful NEVER meant write-
nothing. A mode ask carries its question in one short line, the
owner's own examples: "HOW MANY PLAYERS" (snl), "CHOOSE MODE" (ludo,
snake). No second line, no explanations, no talk under the title.)
Per-game differences are allowed only in the labels/icons themselves,
not in the layout's bones. And the state stays visible: a selected
choice reads ON (law 27a's spirit, in options too).

**29. THE GUIDE CARRIES THE WORDS (v0.3.9-11) - "too helpful" text has
exactly one home.**
The owner has now killed the same disease three times: helpful
sentence-stacks on the tap-anywhere gate (v0.3.9-6 round 2), helpful
talk in optionals (law 28), and helpful dash-talk in shops (law 27).
The rule that ends the family: ANY sentence that explains how
something works belongs to the registry's guide text (desc/controls)
and NOWHERE else. In-game surfaces (gates, trays, HUD, sheets) carry
at most ONE short state line the moment needs ("THINKING", "(ON)",
"TAP ANYWHERE TO START"). If you find yourself writing a second
comma, you are writing guide text in the wrong place.

**30. THE PAUSE NEVER OUTLIVES ITS SESSION (v0.3.9-13) - a quit must
leave the tree breathing.**
The flow rig caught the cascade: the character lore cards pause the
tree (`get_tree().paused = true`), and a game quit from UNDER an open
card (the once-ever lore opens at first boot; the player quits instead
of tapping through) carried the pause into EVERY later launch - the
loader's outro tween is pause-bound, so the next game never finished
loading and the whole shelf looked dead. The fix lives in the HOST
(host_node._quit_to_menu): dismiss any open story card
(`game.box_story_dismiss()` - the shared card AND the legacy
invaders/pacman pair, duck-typed) and set `get_tree().paused = false`
before the session ends. Rule of thumb: ANYTHING a game pauses, the
host's quit path must unpause; a modal that outlives its scene is a
dead box.

**31. THE BOX STORY LAWS (v0.3.9-13) - the cast's dialogue has one
shape and one seat.**
The characters speak (docs/goga_docs/CHARACTERS.md is the bible):
(a) **THE ONCE-EVER LAW**: a story beat fires once ever per game -
`Box.counter` + `Box.bump_counter` with "lore_start"/"lore_end".
Replays never re-tell. (b) **THE SHARED CARD LAW**: new dialogue rides
`box_story_show` in game_base.gd (the name in the character's own
color, the name bar, the typewriter beat at ~55 glyphs/s, first tap
completes the line, next tap continues - TWEEN_PAUSE_PROCESS so it
types under the pause). NEVER build a raw Arc.sheet for a new story
(law 25). (c) **THE SEAT LAW**: first-start lore opens at the END of
`_goga_setup` and chains the game's own first screen through its
`after` callable; a first-end lore opens where the run ends and chains
`finish_run`. (d) **THE EASTER-EGG LAW**: ambient dialogue (the table's
secret, jumpcube's 60s idle) NEVER pauses - it draws over live play,
auto-advances, and a tap skips ahead.

**32. THE VISION LAW (v040-2) - the rig has EYES, so use them before the
owner has to.**
The owner's order after the v040-1 report: "you have full vision
capabilities meaning that you can watch videos and see images, which
means you can run simulated tests that use real finger touches and run
real gameplay and record and make screenshots and see the videos and the
images... you have the ability to keep telling yourself 'just one more
test, just one more fix' the whole night." THIS IS A LAW NOW, not a
suggestion, because the bugs that shipped (an opaque rectangle eating
the sky, an OS hand cursor standing in for the aim reticle, a white
mask drawn as the explosion, animals that never animated) were ALL
visible in one screenshot and NONE of them were visible to headless
asserts. The working loop, end to end:
   (1) **STUDY THE SOURCE WITH YOUR EYES**: extracting the archive and
       grepping the XMLs is HALF the study. OPEN the actual image files
       (PIL montages on a dark backing sheet, viewed with the Read
       tool), measure strips by their alpha seams, and count frames
       BEFORE writing any sprite map. File names lie; pixels don't.
       The masks are white-on-black LUMINANCE-alpha (never their own
       alpha channel); strips are static horizontal cells; rotation
       strips mean the engine NEVER rotated projectiles - it picked
       frames.
   (2) **FILM THE GAME**: xvfb-run + `--rendering-driver opengl3`
       (the box is gl_compatibility, llvmpipe renders it), a film probe
       that injects REAL InputEventScreenTouch/Drag through
       `_goga_input`, and `get_viewport().get_texture().get_image()
       .save_png()` at every beat (intro, combat, impacts, boss,
       menus). Then READ THE FRAMES with the Read tool and fix what the
       eye catches: voids, black squares (an additive material set on a
       holder does nothing - it must ride the SPRITE), mis-scales,
       floating pivots, dead widgets. One screenshot is worth a
       hundred asserts.
   (3) **HUNT REAL GAMEPLAY**: the browser exists; BiliBili hosts
       gameplay (yt-dlp `bilisearch:`); web-search finds walkthroughs.
       When the source game's FEEL is in question (pacing, entry
       animation, menu flow), watch a human play it before trusting a
       guess.
   (4) **THE LOOP**: "just one more test, just one more fix" - after
       every fix, re-film, re-look, re-fix. The owner will test when
       they wake up; the rig should have watched MORE gameplay than
       they will. Speedrunning the eye pass is how a patch becomes a
       report.

**33. THE BOX TOUCH LAWS (v040-3) - the feed never eats a button's tap,
and a game never steals the feed's place.**
Two rig-verified laws born from the owner's v040-2 box report:
(a) **THE CLIP LAW**: a BoxScroll owns a touch point ONLY if the point
    survives every `clip_contents` ancestor (`_clipped_out`). The
    carousel strip rides INSIDE the feed scroll; scrolled up, its global
    rect (and its cards' rects) slides under the top bar while the feed
    clips it invisible - a raw `has_point()` then hands the battery
    chip's tap to a hidden card (reproduced: tap chip -> a game page
    opened). Checked at capture AND at tap dispatch.
(b) **THE RETURN LAW**: `_save_feed_state()` snapshots the feed's scroll,
    the strip's scroll, the carousel list index and ALL FOUR filters at
    the launch tap; `on_game_closed` -> `_restore_feed_state()` rebuilds
    with the filters restored and lands the scroll on the SAME grid row
    (rig: deep 1475 -> restored 1475 exact). "Not just same position -
    exact same state."
**34. THE TOLERANCE-HIDING LAW (v040-5) - a probe's pass margin can BE the
bug.**
The owner's "closing a game returns you a little up" survived two shipped
fixes because the rig probe asserted `abs(restored - saved) <= 340` - a
340px forgiveness wide enough to sleep through the very bug it existed
for. The real defect was a 40px anchor fudge in _save_feed_state (the
first tile "at least 40px inside" the screen got pinned TO the edge,
losing the sub-row offset). THE METHOD: when the owner can see a drift
the rig cannot, shrink the tolerance to the owner's eye (+-2px), then let
the FAILING probe write the fix - the v040-5 exact-tile anchor (remember
the straddler tile by index + its EXACT screen offset, rebuild, put it
back) passes where the 340px probe passed and the owner still failed.

**35. THE CHROMA-CUTOUT LAW (v040-5) - thumbnails are composed from the
game's OWN renders, never re-drawn.**
A thumbnail that "looks like the game" is a photograph of the game: the
film rig stages one composed frame (full-loadout tank, staged enemies and
drops, HUD hidden) and the thumb tool crops it. When cutouts are needed,
render over pure magenta (`RenderingServer.set_default_clear_color`) and
key it in PIL - never paste rectangular crops over a scene (the sky
seam ships). And when a still must be cleaned, patch with a strip sampled
from the SAME rows (the vertical gradient survives), never a flat fill.

**36. THE SIM TELLS THE DESIGN (v040-7) - let the headless bot play
BEFORE the owner does; it finds the spec's silent contradictions.**
Rock Breaker's owner spec said "both golden and mystery rocks will not
leave screen" - which quietly means REGULAR rocks CAN. The first build
sealed the arena (everything bounced forever); the pacing sim then
showed rocks raining onto the cannon faster than early DPS could kill
them - the shield vaporized everything, rp crawled at 1-2, the economy
was dead. The open floor (regular rocks shatter on the ground, only
the specials persist) fell straight out of re-reading the spec with the
sim's evidence in hand. THE METHOD: give every new game a fast-forward
bot that plays 8 minutes in seconds (drive `_goga_tick(dt)` manually,
`set_process(false)` first), instrument rp/income/rocks-alive every few
sim-seconds, and let the CURVE - not your taste - pick the physics laws.
Subsidiary laws it taught: bullets need SUBSTEPPED sweeps (a 1350px/s
bullet steps 45px at 30Hz - a 43px hit circle tunnels straight through);
straight-vertical shots need THE LEAD LAW (fire only when the target is
low - a short flight beats the drift); a live bank (coins spendable
mid-run) must flush to the save on a debounce, not per event; and a
number-format law ("1.00K") belongs in ONE static function the probe
reads without booting the scene.

## THE v0.4.1 LAWS (the owner's mixed-report round - the PC seat + the games)

33. THE DESIGN FOLLOWS THE CONTENT: on a desktop the design (portrait /
    landscape) is picked by what is showing (the menu's position choice,
    the game's orientation) - NEVER by the window's aspect. The fullscreen
    corruption family dies here (RESOLUTION_RULE rules 9-13).
34. THE PC STRETCH = KEEP: a desktop canvas never outgrows its content;
    windowed re_window matches the design, off-aspect wears the box brown
    + the edge veil. Bar clicks land outside the canvas (dead).
35. THE SHARPNESS LAW: the design downscales on small monitors - the 2D
    raster art ships mips (tools/v041_mipmaps.py) and canvas samples
    trilinear (project.godot). New art keeps mipmaps/generate=true.
36. DYNAMIC SCALE: the FidelityFX spatial sharpen pass over the final
    frame (rcas.gdshader) - the honest FSR for a 2D GL app, all GPUs,
    off by default, no restart. Never fake an FSR brand on it.
37. THE PC SEAT: ESC = the back law (1:1), F10 = the menu position (main
    menu only), arrows scroll the feed / the picks row, Tab+LR switches
    the list, buttons NEVER take focus, WASD falls back to arrows (no
    game may define its own WASD use), the gamepad speaks dpad=arrows /
    ABXY=1-4 / START=back, and the GOGACursor is the box's pointer (games
    with their own cursor own the pointer; box sheets always bring one
    back).
38. THE UNFOCUS PAUSE LAW: losing focus opens the back-button pause sheet
    + mutes the master bus; returning keeps the pause up (prepare to
    return). The Android freeze law (v0.3.8-5) stays underneath.
39. THE TAP-ANYWHERE LAW: one universal full-screen overlay in game_base
    (tap_anywhere_start) - every intro covers EVERY pixel and any key.
    No game builds its own tap patch again.
40. THE SPLASH VEIL LAW: the veil is opaque from frame zero (a direct
    child of the splash layer); only the logo fades. The feed can never
    flick through the splash again.
41. THE DOOMSCROLL LAW: the feed runs to the last pixel (the banner
    reserve is gone) and the bottom wears the dark-brown shade + side
    wings (menu.gd _build_bottom_shade).
42. THE SETTINGS SEAT: AAA-shaped (AUDIO / SCREEN & GRAPHICS / CONTROLS /
    RESET over CLOSE). Every toggle persists, rebuilds in place, and the
    platform-only rows never leak (phones never see Screen & Graphics or
    Controls).
43. THE TAGS: the pre-play header wears the platform chips AND the
    control-scheme chips (touch / mouse+keys / gamepad, Meta.CTRL_TAGS +
    Meta.ctrl_list). The guide reads HOW TO PLAY (universal) first, then
    CONTROLS split by DEVICE - never platform-branded.
44. THE THUMBNAIL CAPTURE LAW: a game's thumb may be a code-programmed
    in-game capture (tests/v041_thumbs*.gd) - the owner prefers the real
    render over painted art when the two disagree.
45. THE ROTATION OVERRIDE PARITY (v041-1 r7): a game CAN override the
    play position on EVERY platform (the host's rotation reload), the
    USER still cannot during play (F10 stays menu-only, the sensor is
    locked on phones). The reload's mid-flight guard (host_node
    _orient_now = "") is claimed BEFORE the design moves on EVERY path -
    the design governor never fights an in-flight rotation. A refused
    ask re-windows the window back to the settled kind: a rotated window
    around un-rotated content can never outlive the refuse.
46. THE GAME CURSOR SEAT (v041-1 r7): a game arms its OWN hardware
    cursor (GogaCursorLib.game_arm: normal + CLICK image, the box's held
    state, game-side) - the OS composites it above every Control, so HUD
    buttons and sheets can never paint over it (the Heavy War lesson:
    a drawn reticle under the top bar vanishes over SHOP/back). Touch
    seats keep the drawn aim; the box cursor returns on game close.
47. THE POPUP COLLISION LAW (v041-1 r7): the achievement/battery popups
    MEASURE against the live viewport - a line that fits stays ONE line
    (the panel hugs its content), a line that cannot fit wraps at the
    FULL available width (the text column MUST carry EXPAND_FILL - an
    autowrapping Label's min width is its longest word, the HBox will
    starve it blind), and the parked panel's REAL height collides against
    55% of the viewport with a bounded font ladder (30/19 -> 26/17 ->
    22/15). Measured, never estimated, never letter-counted.
48. THE CODE FRAME LAW (v041-1 r7): the loader's golden frame is drawn
    in CODE (draw_rect, straight edges) and the thumbnail sits FLUSH
    against it (inset = the stroke width). A StyleBoxFlat radius next to
    a straight child lets the art float over the curved corners.
49. THE DOOMSCROLL ENGINE (v041-1 r7): arrow scrolling is a real engine
    - echoes are DEAD (an OS key-repeat is not a fresh nudge), the held
    keys drive ONE continuous accelerating glide, release glides out
    honestly, every target clamps to the REAL scrollable max
    (bar.max_value - bar.page; the 1,000,000 phantom made the bottom of
    the feed stick), a refresh kills pending targets, and a finger grab
    (BoxScroll.grabbed) always wins over a pending arrow glide. The feed
    AND the picks line ride it, 1:1.
50. THE WINDOWS TOAST SEAT (v041-1 r7): Notify.schedule on Windows is a
    REAL toast - a per-user AppUserModelId registration (HKCU, identity
    + icon + ShowInSettings) and a Scheduled Task per notification that
    fires WinRT toast XML (title, body, appLogoOverride icon, per-kind
    ms-winsoundevent sound). Same entries as Android (schedule/cancel/
    cancel_all), same controllables, survives app close AND reboot.
    Windows scripts live under user://notify; custom wav audio is a
    packaged-app feature - kinds map to distinct system toast sounds.
51. THE 3D SEAT (v041-2): the box hosts 3D games natively. A game wears
    "dim": "3d" in the registry and extends GogaGame3D
    (game/core/game_base3d.gd, a Node3D); the host stays Node2D and the
    game joins as a Node3D child - 2D canvas layers render ABOVE the 3D
    world, so the loader, the HUD, every sheet/popup/toast and the
    cursor seat work over 3D for free, and the host skips its brown bg
    for 3d (the world brings its own environment). THE TWIN LAW:
    game_base3d.gd mirrors game_base.gd contract-for-contract - an infra
    change to one twin MUST be mirrored to the other (GDScript has no
    multiple inheritance; a shared base would re-seat 25 shipped games).
    The 3D GOGACoin default is Coin3D (game/core/game_coin3d.gd) with
    the scale law Coin3D.world_diameter(design_px, cam, distance) - the
    coin reads the same size the 2D coin.png reads. Input arrives
    through the same TouchKit + key translation as 2D (the box never
    learns 3D); MSAA 2x arms while a 3D game lives and restores on
    exit.
52. THE REAL-WINDOW GATE + THE SEAT DEATH + THE BIRTH GRACE (v041-2 r2,
    the owner's three dead roots):
    a) THE REAL-WINDOW GATE: a rotation is ASYNC on real desktops (the
    WM_SIZE echo pumps late); get_viewport_rect() is the DESIGN on a PC
    (aspect KEEP pins it) and can never verify a rotation. The host's
    boot AND the orientation reload now hold until the PHYSICAL window
    px (DisplayServer.window_get_size) agree with the content kind
    (headless + PC-fullscreen exempt), and the design governor's window
    half re-windows ONCE after 45 frames of physical drift (the lost
    WM-echo heal). No game ever boots wearing a stale-shape layout.
    b) THE SEAT DEATH: the game cursor seat (goga_cursor.gd's game_arm)
    is STATIC - it outlived the game that armed it, so the menu's own
    LMB mirror re-swapped the dead game's images back on every click.
    Law: the seat dies WITH the game node (both twins' _exit_tree call
    game_disarm); no click anywhere can resurrect a dead game's cursor.
    c) THE BIRTH GRACE + THE TAP LAW: with emulate_touch_from_mouse one
    physical click is a mouse event AND an emulated touch; a sheet born
    inside a press handler received the emulated press + the physical
    release and its buttons self-pressed (Tower Ball skipped its own
    optionals). Law: tap_anywhere fires on the RELEASE (a tap is press +
    release), and every new sheet wears a one-frame full-rect input
    shield that dies right after birth.
53. THE SOURCE LAW (v041-2 r2, the owner: "my mistake was not giving you
    the actual sources"): when a port/clone's FEEL is questioned, study
    the owner-named originals FIRST (decompile/configs), quote the exact
    constants in the game data file, and log them in the manifest
    provenance (mechanics study only - assets stay derived in-repo).
