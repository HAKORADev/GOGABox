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
ads. (v042 amendment: the box carries the Android INTERNET permission —
LAN peer-to-peer sockets need it even on a wifi — but gains NO servers, NO
telemetry, NO online services; the offline BEHAVIOR law stands. v042-1
amendment: RECORD_AUDIO rides the voice chat — requested AT RUNTIME from
the voice-toggle press, never at boot; READ_MEDIA_IMAGES +
READ_EXTERNAL_STORAGE ride the PFP upload picker, requested from the
upload press. Every permission is user-visible in the patch notes and
each one answers a feature the owner ordered.)
The whole monetization stack was removed whole: the Unity Ads plugin
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
54. THE SHIELD DEATH + THE SEAT TOKEN + THE ONE-DESIGN-WRITER (v041-2 r3,
    the owner: "the game itself even the shop in it and everything, does
    not listen to any inputs at all" + "the cursor-leak fix is corrupted"
    + "the app only switches accurately to F10 switches"):
    a) THE SHIELD DEATH LAWS: the r2 birth shield connected `ready` AFTER
    `add_child` - ready had already fired inside add_child, so the
    kill-tween was NEVER created and the shield (full-rect, MOUSE_FILTER_
    STOP) sat over EVERY sheet_push sheet forever, eating every click
    (Tower Ball's whole UI, the heavy war XP cards; sheets opened under a
    paused tree could never run the tween anyway). Law: connect ready
    BEFORE the add, the shield is PROCESS_MODE_ALWAYS, the tween is
    TWEEN_PAUSE_PROCESS - the shield dies 0.05s after birth in every
    pause state. GUI input is delivered to PROCESS_MODE_ALWAYS nodes
    under a paused tree, and a paused STOP control ABOVE them still eats
    the pick (both proven on a real Xvfb window by
    tests/pause_input_probe.gd - headless window px are 0x0 and verify
    NOTHING).
    b) THE SEAT TOKEN: the cursor game seat's disarm is TOKENED - the
    dying game's _exit_tree fires DEFERRED (queue_free), AFTER the next
    seat (the replayed game's cursor, or the box arrow on the quit road)
    armed; an unconditional disarm killed the fresh seat and the OS arrow
    showed everywhere while the setting stayed ON. Law: game_arm mints a
    seat token, only the LIVE token may disarm, a stale corpse is a
    no-op, and the live seat hands the pointer back to the box cursor
    the same frame it dies (never a dead-cursor frame).
    c) THE ONE-DESIGN-WRITER: while a game lives the HOST owns the canvas
    mapping (content_scale_size/aspect). The menu's size_changed hook
    fired _apply_base UNGUARDED on every window resize - including the
    host's re_window at every launch/reload/quit - and the WM echo
    STOMPED the game's design back to the menu's: a landscape game
    rebooting inside a portrait canvas ("a vertical image in the
    horizontal view"), on every automatic path, while F10 (menu-only)
    always worked. Law: menu design writes return early while
    GameHost.active_host != null; the boot restores pc_position BEFORE
    shaping the window (boot parity with F10); the host's gate verifies
    BOTH truths (the real window px AND the canvas design) and every
    re-assert carries its kind explicitly (an implicit mid-flight read
    once asserted the portrait default - the probe caught it).
    THE OWNER-EXPERIENCE RIG: tests/click_probe.gd - real synthetic
    clicks through the real GUI against the real games under Xvfb. A
    sheet fix is not shipped until a CLICK lands on it.
55. THE MENU WIDTH LAW (v041-3, the owner: "why the fuck we even have
    left-right scrolling to normal menus like a shop or in settings ...
    make the base width itself be enough so user do not have to scroll
    it ... in both positions vertical/horizontal in phone/PC the menus
    will not have areas out-of-resolution"):
    a) THE BASE WIDTH IS MEASURED: Arc.sheet_width_for(live canvas) -
       82% of the design width, clamped 620..940 (portrait 1080 -> 885,
       landscape 1920 -> 940; a phone's EXPAND canvas grows the spare
       axis only, so the clamp holds everywhere - nothing out of
       resolution). Arc.sheet opens EVERY sheet at it (the width min is
       set even when the height rides free - an auto sheet used to be
       as wide as its widest row, which is how 560 became the box's
       de-facto width), and fit_sheet re-clamps with the same formula.
    b) THE ROWS FOLLOW FOR FREE: PanelContainer stretches its child and
       the VBox stretches its FILL children - hardcoded 560-min rows
       open to the new inner width with zero call-site edits. Never
       "fix" a narrow sheet by editing row widths; widen the sheet.
    c) THE TEXT ANSWERS TO THE ROW: Arc.button / Arc.coin_button step
       the font down (floor 14) when a line cannot fit the row - a long
       row can never vote the panel wider than its base again (law 24's
       OVERFLOW LAW extended to buttons; labels already wrap).
    d) THE MECHANIC STAYS: BoxScroll's horizontal drag is not removed -
       a pathological row can still scroll sideways; it is just never
       the base width's fault anymore.
    e) THE BUTTON OUT-OF-RESOLUTION LAW (v041-3 r2, the owner: "internal
       buttons and the width will let like at least 10% free width 5
       from each side on both positions on both platforms ... if a
       button had more text, make it use same logic of dynamic smart
       detection like the GOGABox pop-ups ... so a button can never go
       out-of-resolution"): Arc.button / Arc.coin_button clamp their
       declared min width to SHEET_INNER_MIN = 825 design px - DERIVED,
       never guessed: portrait 1080 -> 0.82*1080 - 60 margins = 825.6 is
       the TIGHTEST legal sheet inner width (landscape/PC clamp at 940
       -> 880; a phone's EXPAND canvas grows the spare axis only; a PC's
       content scale never changes design px) - so the >=5%-per-side
       free width holds BY CONSTRUCTION on every seat, both axes, both
       platforms. An explicit Arc.sheet(sheet_width) can NARROW, never
       widen past the measured base. And the text answers to the POPUP
       LAW (law 47): measure the rendered line against the row's real
       fit width, step the font down to the floor, and a line that
       cannot fit even AT THE FLOOR wraps at the full fit width (the
       button grows the measured height it needs, never the width) -
       the same measure/ladder/wrap ladder the achievement + battery
       popups run, so no widget can ever paint itself out of
       resolution.
56. THE THUMB SHAPE + GRAY LAWS (v041-3, r2 CORRECTED by the owner: "i
    do not want the thumbnails to get curved at the top, i want them to
    be the same look ... the gray-out effect was making a curve to the
    thumbnails while the gray-out itself was a layer on top of the
    thumbnail without curves ... the fix was supposed to be make the
    gray-out just to be on top of the thumbnail accurately, no need to
    touch the thumbnail itself"):
    a) THE SHAPE, CORRECTED: a thumbnail NEVER gets curved. The r1
       rounded-holder clip (stylebox radius 24 + clip_children =
       CLIP_CHILDREN_ONLY) curved the art to chase the card's rounded
       silhouette - the owner rejected the whole approach: fix the
       GRAY's alignment, never the thumb's geometry. _add_thumb rides a
       plain holder Panel again (CARD paint, radius 0, no clip) that
       only positions the square thumb above the label strip - the
       thumbnails wear the exact same look they always wore. (The
       MYSTERY tile's rounded stylebox stays - it is the card's own
       dark cover matching the card's silhouette, not a thumbnail.)
    b) THE GRAY (r1, stands - this was the accurate part): a grayed
       thumbnail is GRAY, not a wash-out - modulate alpha washes the
       image through to the card behind it. The gray rides
       assets/ui/thumb_gray.gdshader (grayscale + darken, fully
       opaque, per-instance ShaderMaterial so states do not leak into
       neighbours): strength 1.0, darken 0.42..0.62 by state (GATED the
       darkest, LOCKED/daily 0.58-0.62, strip 0.55). The material IS
       the layer that sits EXACTLY on the thumbnail - per-pixel, on the
       art's own silhouette, aligned by construction, zero geometry
       touched.

57. THE LAN LAWS (v042, the owner: "work on the LAN thing completely as
    v042 ... implement all of it accurately" — the whole spec lives in
    docs/goga_docs/ideas/LAN_MULTIPLAYER.md, the build plan in
    docs/brainstorm/v042/MASTER.md):
    a) THE CORE: game/core/lan.gd (autoload LAN) — plain TCP
       (TCPServer/StreamPeerTCP, JSON lines), port 31440, the host owns
       the truth, the session dies with the app. THE TEN SECONDS LAW and
       the match births run on the HOST's one clock. The probe
       (tests/qa_v042_lan) lives the whole session over REAL loopback
       sockets: 4 cores, the hold, the countdown, the birth, the relay,
       the left-out, THE LONE LAW, the prune, the cap.
    b) THE GAME CONTRACT (duck-typed, both twins): lan_match_start(seed,
       seats) / lan_act(who, a) / lan_snap(data) / lan_prog(from_dev,
       data) / lan_end(results) / lan_hold_end_solo(); the moves ride the
       game's OWN move door (apply locally, then LAN.send_act). The CPU
       never wakes in a LAN match (THE REAL-ONLY LAW). The relay models:
       TURN_RELAY (snl/jumpcube/domino/chess/squares/fourline/bovo),
       HOST_AUTH (rally's ball), SELF_AUTH (snake's shared world), RACE
       (towerball's identical seeded towers).
    c) THE SEAT PERSPECTIVE LAW: on EVERY device the local player wears
       id 1 and the rivals 2..N — the display laws (YOU / the verdict
       lines) keep working; turn order is the session's arrival order.
    d) THE NAME LAW: EN letters + space + ' . - only, NO emoji, NO digits,
       max 20 (LanProfile.sanitize_name) — sanitized at input AND at
       protocol intake (never trust a peer's name).
    e) THE GOGAPROFILE (game/core/lan_profile.gd): the local GitHub-shaped
       profile (name / drawn one-guy PFP variants / desc / links / age /
       role gamer-developer-OWNER-unique / gender with other). THE ANCHOR:
       hash(OS.get_unique_id()+salt) rides the profile and a short hash
       rides the session (a cloned profile shows as a GHOST). THE
       SURVIVAL LAW: the profile mirrors to Android/media/<package>/ and
       Windows %USERPROFILE%/GOGABox/profile/ — newest copy wins, a wiped
       app re-adopts its mirror.
    f) THE MULTI-LEVEL TAGS: registry "lan": {players, platforms, cross}
       -> Meta.lan_list chips (lan / lan_phone / lan_pc / lan_cross /
       lan_2p..4p); the PLAYERS badge is its own area (cards + pre-play);
       the search sheet wears the LAN row; the pre-play page wears the
       live LAN line under the tags ("IN THE ROOM x/y - WAITING z").
    g) THE PERMISSION: Android INTERNET=true is REQUIRED for the sockets
       (both presets) — the owner-visible trade is documented in §4.
    h) THE TWIN LAW holds: the LAN hold overlay (game/core/lan_hold.gd)
       is ONE shared widget; the routing blocks (lan_hold_begin /
       _lan_route / _lan_unroute) are mirrored verbatim in game_base.gd
       and game_base3d.gd.
58. THE SETTER-NAME TRAP (v042, cost the round an hour of ghost-hunting):
    a STATIC GDScript function named like a property setter (`set_name`,
    `name`, `set_...` of any native property) is SILENTLY rerouted by the
    engine's property convention - the call returns nothing, no error, no
    warning, the body never runs. `LanProfile.set_name()` no-op'd for a
    full session while `save()` beside it worked. THE LAW: name statics
    with unambiguous verbs (`set_player_name`, `player_name`) - never
    `set_<property>`/`<property>` shapes on RefCounted helpers. The rig
    that caught it: push_error inside the suspect function prints the
    GDScript backtrace - when a call "does nothing", trap it, don't
    theorize.



59. THE INPUT LAWS (v042-1, the owner's report: "it writes the thing
    double or triple and the head of the writing area is mis-placed...
    the fields of join a session are un-write-able"):
    a) A LineEdit NEVER mutates its own text (text/caret_column) while the
       user types - a mid-composition write desyncs the Android IME (the
       composing text re-lands: doubles/triples, the caret jumps to the
       head). Validation rides the COMMIT DOORS: text_submitted,
       focus_exited, and THE FLUSH (Arc.flush_fields on the sheet close).
       Arc.line is the ONE factory; it never rewrites mid-typing.
    b) text_changed runs CHEAP work only - a save-per-keystroke is three
       disk writes behind the IME and reads as "lagging and weird". No
       SceneTreeTimer may touch a focused field either (a timer-driven
       rebuild under the keyboard is the same desync).
    c) The OS keyboard does the filtering: virtual_keyboard_type NUMBER
       for digits, URL for links - never a live strip-and-rewrite.
    d) A sheet holding a focused field never rebuilds itself (the LAN
       ticker asks Arc.focused_field first).
    e) An interactive control inside a NON-BoxScroll sheet keeps its
       native mouse_filter - the v042 picker buttons wore IGNORE (the
       BoxScroll pattern) on plain sheets and were DEAD to taps (the
       gender row the owner could not click). IGNORE is for controls
       UNDER a tap router only.
    f) Arc.link_ok is the lite link validator (pure string shape, zero
       network): an invalid link never renders, a valid one opens the OS
       browser via Arc.link_open.
60. THE FACE LAWS (v042-1, the owner: "place holders to be only one
    which is yellow guy-icon in brown background... support local media
    uploading as PFPs... videos and GIFs to be PFPs up to 1 minute
    cached with a hash... 30 days and caches not used get deleted"):
    a) ONE placeholder: the YELLOW one-guy on the BROWN plate (GogaPfp
       paints it; never reintroduce a placeholder fleet).
    b) GogaPfp is the ONE renderer for every PFP seat (profile sheet,
       hold rows, member rows, roster, chat labels) - media faces paint
       everywhere or nowhere; keep-aspect-covered, no stretching.
    c) The media budget: 60 seconds, 720 long side on import (GIFs ride
       the PFP budget: 480/150 frames - GDScript LZW), 16MB import cap,
       2MB wire cap. mp4/webm are REFUSED honestly (no engine decoder) -
       a fake would be a dummy build.
    d) The cache is hash-addressed (SHA-256 of the source bytes) under
       user://pfp_cache/: a changed face busts every cache for free;
       30-day LRU sweep at boot; the LIVE face is pinned.
    e) THE FOCUS LAW: a GogaPfp paints ONE frame unless focused (the big
       profile face / the visitor view) - rows never animate in the
       corner of the eye.
    f) The profile sheet has NO roles row (the owner: "remove the roles
       thing, it is useless") - the role FIELD survives the protocol for
       the future dev identities.
    g) THE AGE SELECT LAW: a select menu of specific numbers, 1..21 plus
       the 21+ bucket (stored 99); age_display renders anything over 21
       as "21+"; the store keeps 3 chars max.
61. THE TURN-RELAY WHO GATE (v042-1, caught while wiring combo): the
    v042 TURN_RELAY games applied ANY arriving act while in the waiting
    state - on a rotated seat table that lets a stranger's roll steal a
    local turn (the sequences only align if every device maps the
    sender's seat to its own local index). Law: an act lands ONLY when
    who maps to the state machine's current turn (snl's _lan_local_turn,
    ludo's seat-of-army compare); a relayed act from a COMBO seat rides
    send_act_as(its own seat number), never the primary's.
62. THE 3D SEAT CORRECTION (v042-1, the owner: "the 3D game that
    supposed to get LAN was tower destroyer and not tower ball"): the
    LAN registry seat lives on towerdestroyer (the RACE law: identical
    seeded towers, one shooter per device, scores ride lan_prog, THE
    LAST CANNON verdict); towerball is solo-only. An owner correction
    overrides a freeze for the named feature only - nothing else in the
    frozen game may drift.

## THE v042-1 r2 LAWS (the owner's second LAN report - "i was still not
## able to test the actual thing at all, not even for a moment")

63. THE TEXT GUARD (v042-1 r2, the owner: "it needs to be fixed from
    it's roots ... sometimes it double the letter when writing letters,
    sometimes it jumps me off-place, some times it literally when i
    delete something, it deletes the wrong thing ... if i changed the
    head of the place of writing, it returns me to the end after one
    char"): the box's WASD->arrow and gamepad d-pad translations INJECT
    real arrow key events (Input.parse_input_event) - inside a focused
    LineEdit/TextEdit those arrows ARE caret moves: W drove the caret to
    the START, S to the END, A/D walked it; every word containing w/a/s/d
    teleported the caret mid-word, deletes hit the wrong characters, and
    typing read as doubled/reordered. THE LAW: main._push_key (the ONE
    injection door) refuses to fire while a LineEdit/TextEdit/CodeEdit
    holds the keyboard focus. Number fields were "clean" only because
    digits/dots are never translated - that asymmetry was the tell.
64. THE COMMIT-ON-CHANGE LAW (v042-1 r2, the owner: "profile showcase
    not update in real-time, it requires me to close and re-open menu"):
    Arc.line commits on EVERY text_changed (the commit writes the STORE
    only - never the field, never a rebuild - the IME is untouched), so
    the showcase, the seats and every action button read the store's
    live truth without focus tricks. Belt: action handlers flush_fields
    (or read the field's text directly - the combo ADD) before reading.
    LanProfile.save() mirrors the face file only when the live hash
    actually changed (a 16MB copy per keystroke is theft).
65. THE SMART EXTRA-LINE LAW (v042-1 r2, the owner: "make all of writing
    fields and the buttons. viewing of the profile have the same logic
    of the smart extra line move from the pop-up of GOGABox in-app
    messages ... make it to make new lines for writing as soon as the
    current line is going to be full, it is better than letting the
    users scroll a horizontal one-line of text"):
    a) LONG fields (about, links, chat-sized text) write in Arc.area -
       a TextEdit with WORD_SMART wrap, the box fonts, no horizontal
       scroll; the cap rides the COMMIT door (TextEdit has no
       max_length in Godot 4 - a mid-typing rewrite is banned by 59a).
    b) The visitor view's LINK ROW wraps to 3 lines max (the extra rides
       the built-in ellipsis) and wears the DOMAIN HINT at the bottom
       (Arc.link_domain: host + subdomains, no scheme/port/path) so the
       reader knows where a link goes before it opens. Buttons keep the
       v041-3 wrap seat.
66. THE SCAN LAWS r2 (v042-1 r2, the owner: "scan the network do
    nothing, it only lists players that in the session, it is supposed
    to list players that in GOGABox in same network ... when i press
    add, it says invite refused ... add local player never adds
    anything"):
    a) EVERY GOGABox answers discovery pings (LANFIND.set_answering
       publishes the identity; in_session is a FLAG, not a gate). The
       ping rides the subnet-directed broadcasts (/24, /16, /8 of every
       private local IPv4) PLUS 255.255.255.255 - Android drops the
       global one on many networks; the /24 is what crosses the wifi.
    b) An invite is legal whenever the target is not already one of MY
       seats - hosting or riding a session is NOT a refusal (the r1
       invite_peer refused whenever session_active() was true, and the
       host menu is always inside a session). ADD on a seated peer says
       ALREADY IN YOUR SESSION; on a stranger's session, THEY ARE IN
       ANOTHER SESSION; invite_peer auto-hosts for a free caller.
    c) An action button that follows a field reads the FIELD's text
       directly (the commit may never have fired - focus does not
       always move on touch).
67. THE JOIN HONESTY LAW (v042-1 r2, the owner: "we both are on the
    'lan live' thing, i was not even able to play lan, every time i
    play, i jump into solo"): a join wears REAL states - connecting
    (LAN.joined_ok() is false: no badge, no hold, no pre_open) -> joined
    (the welcome landed) -> or an HONEST death within 12 seconds
    ("cannot reach the host - check the address, the wifi and the
    firewall"), toasted through session_died. The LAN LIVE badge lives
    only on a REAL partner: session_active() AND joined_ok() AND
    session_size() >= 2 AND the game is LAN-capable - a 1-seat session
    never wears it, and the badge repaints LIVE on every session_changed
    (menu._lan_tiles + _paint_lan_badge) - never again only at tile
    build.
68. THE NAME LAW r2 (v042-1 r2, the owner: "make hosting or joining can
    not even happen without having a name, even 1 char is enough (must
    be not space only ... there is a bug when the name is numbers only
    it get wiped"): EN letters + DIGITS + space + ' . - ; ONE character
    is a name; the sanitizer collapses spaces so a space-only entry
    dies at name_ok. HOST/JOIN gates flush the name field first and
    refuse an empty name with "NAME YOURSELF FIRST".
69. THE FACE META LAW (v042-1 r2, the owner's Windows report: "after
    putting/selecting a PFP image on windows, the app behaves like the
    image is set for real, but the thing visualized is still the
    placeholder one"): in the face meta dict, "h" is THE HASH - never a
    dimension. The r1 image import wrote the fitted HEIGHT over "h"
    (the gif path's "hh" was right); cache_has(height-number) could
    never be true, so every imported image face fell back to the drawn
    guy on every seat while the profile acted set. Dimensions live
    under "w"/"hh". The Android face picker is the SYSTEM explorer
    (use_native_dialog on both platforms) with a NORMAL format list -
    the popular video shapes included; an undecodable one dies with its
    named honest reason (PfpMedia.VIDEO_REFUSE - "no weird .oga").
70. THE PLACEHOLDER SHAPE LAW (v042-1 r2, the owner: "the guy PFP is
    weird, make it like the button icon but without plus sign and be
    yellow and bigger, current thing tries to be full body buy it is
    bad and wrong"): the drawn face IS the button icon's shape - a
    round head + ONE arch body (a half-disc, dome UP - y grows downward,
    the arc's sin rides NEGATIVE; the eye pass caught the r2 draft
    bending the dome under the plate), nothing else. No legs, no arms,
    no full body. Yellow on the brown plate, filling the seat
    (paint_pfp's height parameter spans the whole bust). The icon
    itself (assets/ui/icon_lan.svg/.png) is the same shape PLUS the
    plus badge top-left (the owner: "normal circle and an arch-like
    curve as the body and plus sign at top left").

## THE v042-1 r3 LAWS (the owner's third LAN report - "the LAN infra
## really needs real work on it" - the ROOM round)

71. THE ROOM LAW (the owner: "in games there is whether server-side world
    or the host-side world, currently we do not have the host-side world
    ... make a host be able handle up to 12 different players ... make it
    possible to each different group of players to play at the same
    time, like if group one 2 players joined ludo, then other 3 players
    can play ludo in another dimension"): a session is a LOBBY of up to
    12 seats; any member CREATES a room ("dimension") for a game; the
    room's members are its players in JOIN ORDER; the room's OWNER
    carries the config (lan_params, set live via the room settings hook
    lan_room_settings(vb)) and STARTS the match - the game is NEVER
    loaded or initialized before that moment. Many rooms live at once
    and every relay (act/snap/in/prog/end) is scoped to its own room.
    THE LONE LAW and THE TEN SECONDS LAW are DEAD - a lone room waits
    forever, nobody is ever thrown to solo by a timer.
72. THE ABSOLUTE SEAT LAW (the owner: "make the color of the player be
    different and not same ... both players see themself as shazam and
    both see the other player as marble ... in ping pong both players
    are controlling red"): match seats ride in JOIN ORDER with an
    absolute rseat on every device - seat 1's color, name and turn slot
    are the SAME everywhere. The local player is highlighted with YOU,
    never re-colored. A game's turn index IS the absolute seat (the
    games' my_slot()/lan_my_index()); the WHO GATE drops any act whose
    sender is not the turn's seat. The owned skins (a LOCAL thing) never
    re-ink a LAN token - the seat's army color rules.
73. THE CONFLICTION LAW (the owner: "i managed to join on other device
    by clicking same button at exact same moment, this thing should not
    even happen ... make it trust the network data flow so the first
    always get executed, others just get a message 'confliction happened
    with another player'"): every room mutation is serialized on the
    host's ONE pump - the first message in wins, a racing loser reads
    "CONFLICTION HAPPENED WITH ANOTHER PLAYER" (the last-seat race is
    the proof case; the room cap refuses with the line).
74. THE DISCONNECT LAW (the owner: "when someone get disconnected or
    close game whether he is host or joiner, it corrupts the game, just
    end the game when one disconnected ... with notifications"): a
    member leaving/dropping/kicked mid-match folds the room's match for
    everyone left - match_ended carries results with a dq row and the
    WHY ("X LEFT THE MATCH - GAME OVER"); the games show the honest
    verdict, never a corrupted limbo. A folded room stays folded.
75. THE PAUSE-PROOF PUMP (the joiner-drop root): the games pause the
    tree - a paused LAN/LANFIND/Voice pump stops the heartbeats and both
    sides prune each other mid-match (the "random disconnect when i
    quitted a game"). All three autoloads ride PROCESS_MODE_ALWAYS now,
    and PRUNE_AFTER is 15s.
76. THE TOP-LEVEL NOTES (the owner: "the invitation message appears only
    in menu ... make all of them be top-level to appear anywhere any
    time in any position even in-games because they are very
    important"): LanNotes (game/core/lan_notes.gd, layer 95, built by
    main.gd, PROCESS_MODE_ALWAYS) owns the invites (JOIN / LEAVE AND
    JOIN when I ride a session - the switch law - / DECLINE) and the
    critical lines (kicked, session died, room refused). The menu never
    duplicates them.
77. THE SCAN LAWS r3 (the owner: "make it more smart, like once it
    detect that player is in, it changes word from 'add' to something
    else ... make it smart and low-level detection"): the pong carries
    the LIVE state (in_session, is_host, size, playing - the game a
    live match runs) and the scan sheet RE-PINGS every 2.2s while open -
    a box that joins a session or starts a match while I watch flips
    its own row. The row's word IS the truth: ADD / IN YOURS (disabled)
    / INVITE (+ "PLAYING <game>").
78. THE ONLINE HONESTY LAW (the owner: "i bet you are just trolling me
    and have not truly integrated the tech for real here"): the UPnP
    mapping is attempted HARDER (2s discover, 3 mapping tries) and the
    session sheet SAYS the truth - "ONLINE ON - the code reaches the
    internet" when the router opened the port (the code then carries the
    PUBLIC address), "ONLINE OFF - LAN + VPN only" when it refused.
    Without the mapping there is no serverless online play - the sheet
    says so instead of lying.
79. THE ADD-LOCAL-PLAYER RETIREMENT (the owner: "the button add local
    player is useless ... even if it is fake"): the host menu's button
    and its sheet are GONE - sessions fill with REAL devices through the
    scan only. The engine API (add_local_slot) survives for the game
    hooks.
80. THE CHAT r3 LAWS (the owner: "in android, sending a message makes it
    appear as two ... the cooldown is not dynamic ... the button chat
    itself, get top right and top left yellow dots ... make the chat
    opens from where is the last read message was"): a) THE DEDUPE - the
    host never echoes a sender's line back (the sender lands it
    locally; the echo was the double); b) THE LIVE COOLDOWN - the send
    door shows WAIT n S always while it runs (a 0.25s Timer on the
    sheet), flipping to SEND the second it ends; c) THE DOTS - the HUD
    CHAT button wears the yellow unread dot (top-right) and the mention
    dot (top-left; a line naming me counts); d) THE LAST-READ SEAT -
    LAN.chat_read_id tracks the newest seen line and the sheet opens
    scrolled there; e) THE ID LAW - replies carry stable message ids,
    never array indexes (the sliding window retargeted index replies).
81. THE VOICE r3 LAWS (the owner's semantics, verbatim: "other players
    mic's mean you do not hear them, and their speakers mean they do not
    hear you and your mic means none of them hear you and your speaker
    means you hear none of them"): a) THE FOUR GATES are all real and
    all VISIBLE - the roster shows THEIR MIC / THEIR HEAR (the live
    remote truth off the VST wire) and MY MIC TO THEM / MY HEAR OF THEM
    (my toggles); b) THE VST WIRE - every toggle broadcasts the sender's
    state to the session; c) THE DEV-KEY LAW - every voice map keys by
    device id, never the seat number (the seats renumbered on leave and
    silently re-pointed frames to the wrong humans); d) THE BEACON LAW -
    every device re-announces its UDP address every 2s (the r2 hello
    fired once; a lost packet meant the host relayed to nobody - "my
    voice from phone mic did not reached PC"); e) THE UNHANG LAW - the
    toggle chips ride ACTION_MODE_BUTTON_RELEASE and repaint from the
    live getter (the Android chip held its pressed paint).
82. THE FACE r3 LAWS (the owner: "PFP is set, accurately, BUT! only for
    me, on other devices, i see the placeholder forever" + "when the
    media is wide it overlaps with the name text" + "android app
    deleting deletes profile data"): a) THE ROW LAW - every seat that
    shows a face asks for its media once (LAN.pfp_touch; the profile
    viewer was the only asker), and the arrival repaints every waiting
    renderer (LAN.face_arrived); b) THE WIRE CAP rides to 8MB - a legal
    60s video face dwarfed 2MB and never arrived; c) THE WIDE-MEDIA LAW
    - the GogaPfp plate CLIPS its children and the video fits
    keep-aspect INSIDE the plate (a wide face letterboxes; the name row
    is never touched); d) THE RE-ADOPT LAW - the mirror's
    face_<hash>.<ext> rides BACK into the cache on load (the mirror had
    the face while the wiped cache answered cache_has=false - the drawn
    guy came back); e) THE VERIFIED MIRROR - every non-user write is
    read back (a silent mirror failure is HOW the hard-wipe ate the
    profile), the WRITE_EXTERNAL_STORAGE grant rides the picker press
    for the older Androids, and the picker itself stays the SYSTEM
    explorer.
83. THE CPU WORD LAW (the owner: "change label CPU anywhere to the
    perspective player name, whether the message is 'CPU is thinking'
    or anything else"): a turn banner, a tray mark or a coin toast in a
    LAN match reads the CURRENT PLAYER's name - "CPU" survives only in
    solo. The banner shows only on the WAITING device ("<RIVAL> IS
    THINKING"); the actor's device says YOUR MOVE.
84. THE SLASHER LAN (the owner: "make the game fruit ninja be LAN 2
    players ... make the players be blue as the first player and red is
    the second, red and blue i mean the color of the slash line"): a 2P
    RACE (the towerdestroyer pattern) - identical seeded harvests, each
    device scores its own slices, scores ride lan_prog, a 90-second
    round, the verdict is the higher score when both are done (0 hearts
    ends a run early into the honest wait card). The blades wear the
    ABSOLUTE colors: seat 1 BLUE, seat 2 RED - on both devices - and a
    slice flashes the rival's blade ghost in their color. The registry
    wears the lan block (12 games now).
