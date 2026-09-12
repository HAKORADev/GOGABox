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
   Ad IDs / App Keys are *not* secrets — they ship inside every APK and
   mediation platforms gate misuse by package name — so they live in
   `ads_config.json` and in §4 below.
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
| `config/environment.lock` | pinned toolchain: Godot 4.7.2, JDK 17, Android SDK 36 / build-tools 36.1.0, AGP 8.6.1, Gradle 8.11.1, Unity Ads 4.20.0 |
| `config/projects.json` | registry: package, version, ABIs, presets, `use_plugins`, `ci_auto` |
| `.ci/materialize-project.sh` | builds a clean `android/build`: pinned template + `android-overlay/` + plugins + config injection |
| `build.sh <g> [--abi ...] [--type ...] [--aab]` | materialize → patch presets → import → export → verify |
| `tools/test.sh <g>` | headless integration test (`tests/flow_test.tscn`, exit 0 = pass) |
| `tools/bootstrap.sh` | installs exactly the locked toolchain into `.cache/` (same on CI and local) |
| `tools/ci.sh [watch]` | list / watch GitHub Actions runs from the terminal |
| `tools/sync-assets.py` | re-vendor assets from `assets.manifest.json` |
| `tools/study/` | the game-study pipeline: web-portal scrapers, APKPure downloader, APK decompiler line, Godot .pck extractor, Quaternius/ambientCG fetcher — see docs/DECOMPILATION.md (study copies stay OUT of the repo) |
| `plugins/<name>/` | GOGABox android plugins (`unity_ads`, `notify`) |
| `docs/` | guides + `docs/goga_docs/` planning home (GDDs · ideas · plans · brainstorms) |

## 4. Ads integration playbook

### 4.0 Where ads live

Nothing ad-related sits inside game scenes. Game code calls only:

```gdscript
Ads.register_run()
Ads.maybe_interstitial(func(shown): ...)
Ads.show_rewarded(func(watched_to_end): ...)
Ads.banner_show() / Ads.banner_hide()
```

The `Ads` autoload (pacing + **desktop simulation**) and the native bridge
are staged in at build time from `plugins/<backend>/`, selected by
`use_plugins` in `config/projects.json`. Per-project knobs and IDs live in
`projects/<g>/config/ads_config.json`. Architecture details: docs/ADS.md.

### 4.1 The real IDs (as of Aug 2026)

**ACTIVE backend — Unity Ads direct** (`use_plugins: ["unity_ads"]`):

| thing | gogabox |
|---|---|
| Unity Game ID (Android) | `5770940` (owner decision: GOGABox reuses the first ID created for the repo) |
| test_mode | `false` (real ads; flip `projects/gogabox/config/ads_config.json` for local testing) |
| interstitial placement | `Interstitial_Android` |
| rewarded placement | `Rewarded_Android` |
| banner placement | `Banner_Android` |
| package name | `hakora.dev.gogabox` |
| dashboard | Unity Publishing dashboard → Monetization → Projects. NOTE: per-package dashboard entries may be needed later if Unity restricts serving for unregistered packages — create them, then paste the new Game ID into `projects/gogabox/config/ads_config.json`. Placements and the plugin contract stay identical. |
| config file | `projects/gogabox/config/ads_config.json` |

**LevelPlay mediation — built, verified, then rolled back (see §4.3):**

| thing | value |
|---|---|
| App Key | `27d84b1ed` |
| interstitial ad unit | `6j6die13bsc4f0n3` |
| rewarded ad unit | `s6iuno9k7m9nx0sz` |
| banner ad unit | `l7t8jl7rzxpuq0im` |
| native ad unit — **not wired** (no native format in any plugin yet) | `jsyz6rjnru2nd61x` |
| dashboard | app.unity.com → Grow → LevelPlay (same platform as ironsrc.com; either URL works) |
| recover from commits | `19d5369` (plugin) + `7257c24` (activation) |

### 4.2 Wiring a backend into a project (any backend)

1. Does the plugin exist? (`ls plugins/`) → set `use_plugins: ["<name>"]`
   in `config/projects.json`. If not, write one (§4.5).
2. Fill `projects/<g>/config/ads_config.json` with that backend's schema and
   IDs (`unity_ads`: `game_id` + `placements`; `levelplay`: `app_key` +
   `ad_units`). Keep `test_mode: true` while developing.
3. Desktop must never crash: every plugin's `ads.gd` simulates ads when not
   running on Android. Order matters — the desktop branch must come **before**
   any native `available()` check (a past bug; `tools/test.sh` catches it).
4. Verify: `./tools/test.sh <g>` → `./build.sh <g> --abi arm64-v8a` → confirm
   the plugin meta-data and dex classes landed in the APK (`.ci/verify-apk.sh`,
   or `aapt2 dump badging` + a dex grep).
5. One-line override without editing config:
   `GDA_FORCE_PLUGINS=<name> ./build.sh <g>`.

### 4.3 GOGAds - REMOVED (v0.3.7-2)
The in-house ad framework lived here; the owner nuked it whole
("nuke GOGAds, that's done"). The spec is archived in
`docs/goga_docs/brainstorms/THE_APP_STORE_QUESTION.md`. The Unity Ads
plugin + the house banner below are UNTOUCHED - they are the older,
shared system.

### 4.4 Re-enabling LevelPlay (if ever asked)

The full mediation backend (LevelPlay SDK 9.6.0 + Unity Ads adapter, plugin,
config, docs) was built, CI-verified green, then rolled back at the user's
request ("UnityAds only is good for me"). It is two revert commits deep in
history:

```bash
git revert --no-edit 56f53d4 f74a0f1   # undo the reverts: plugin first, then activation
```

After reverting: re-check the IDs against §4.1 (they come back with the
revert), keep `test_mode: true`, run tests + both-ABI build, push.
Reporting shows up in the **LevelPlay console** (app.unity.com → Grow), not
the classic Unity Ads monetization section. Future option, not a pending
task: AppLovin MAX could be added as just another `plugins/<name>`.

### 4.5 Writing a new ad backend plugin

Contract — `plugins/unity_ads/` is canonical:

```
plugins/<name>/
  plugin.meta.json     # addon_dir, gradle_deps[], manifest_meta{}, autoload{name,script}
  addon/ads.gd         # autoload `Ads`: DEFAULTS + config merge + desktop sim + the standard GDScript API
  android/...java      # GodotPlugin v1: configure / load / show / banner + signals
```

`.ci/materialize-project.sh` consumes `plugin.meta.json`: copies the addon,
injects the gradle deps, injects the manifest meta-data, repoints the
autoload. Before trusting any ad-SDK API from docs, download the AAR and
**`javap` it** — docs lie, bytecode doesn't (this caught real API drift
before). Details: `plugins/unity_ads/README.md`.

### 4.6 SDK upgrades

1. Bump the SDK version in `config/environment.lock` and the plugin's
   `plugin.meta.json`.
2. `rm -rf .cache/android-sdk && ./tools/bootstrap.sh`.
3. `javap` the new AAR; re-verify every signature the plugin uses.
4. `tools/test.sh` + full both-ABI build before pushing. CI cache keys hash
   the lock file, so runners re-fetch exactly once.

### 4.7 Studying other games (the decompilation pipeline)

When the owner asks to study a shipped game (web or android), do NOT
re-derive the scraping/decompiling from scratch — the pipeline exists and is
tested: `tools/study/fetch_webgame.py` (GameSnacks/CrazyGames/Poki/generic),
`tools/study/fetch_apkpure.py` (APK/XAPK via the AEGON app endpoint),
`tools/study/decompile_apk.py` (apktool + jadx + Il2CppDumper + ilspycmd +
UnityPy in one command), `tools/study/godot_pck.py`,
`tools/study/fetch_asset.py`. Full site matrix, per-engine playbook, install
commands and the proven-results table: **docs/DECOMPILATION.md**.

THE LAW (owner directive): study copies live in `study_out/` OUTSIDE the repo
and are never committed or shared. Assets crafted from studied games are
modified/redesigned before they enter GOGABox, and decompiled logic is
studied, then rewritten — provenance gets recorded in docs/ASSETS.md and the
manifest, like the Pop Siege art pipeline did.

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

**Release** — bump version → push → CI green → Actions → **build-android →
Run workflow** → pick project + `create_release: true` → tag `v<version_name>`
gets both APKs. Re-running the same version clobbers the previous assets.

**Before any store submission** — `test_mode: false` in the project's
`ads_config.json` · package name matches the ad dashboard entry · one real
interstitial + rewarded tested on device · consent/GDPR guidance reviewed ·
docs updated.

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
| ads architecture and config | docs/ADS.md + plugins/unity_ads/README.md |
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
