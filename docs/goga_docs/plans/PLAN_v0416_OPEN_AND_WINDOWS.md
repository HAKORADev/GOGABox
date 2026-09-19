# PLAN - v0.4.0-16: THE OPEN-SOURCE ROUND (MIT + 0 ads + the windows return)

The owner's order (2026-09-19): "i want you to nuke all ads, remove
everything related to monetization, everything related to closed source,
i want the project to be open-source under MIT and also with 0 ads" +
"there is an old commits where we started earlier on making GOGABox to be
compiled for windows OS as 32bit exe that works on pre-2014 CPUs that does
not support sse4.2, re-do this, find that commit, then update the repo with
it's contents". Brainstorms docs stay. The pending todo list waits.

---

## FRONT A - THE 0-ADS + MIT NUKE

- **THE 0-ADS LAW**: the whole monetization stack removed whole:
  - `plugins/unity_ads/` (the Unity Ads v1 plugin + its README) DELETED.
  - the `Ads` autoload gone from project.godot (notify stays).
  - the death-menu DOUBLE (watch ad) theatre, the reward hint, the retry
    countdown, the tier payout - host_node lines gone whole; the honest
    math line (pickups + bonus ratio) SURVIVES.
  - the per-3-runs interstitial pacing gone (`Box.should_show_interstitial`
    deleted + the store counter field dead).
  - the banner strip retired: the registry's 28 `"banner": true` keys gone,
    `banner_bottom()` reads 0.0 forever (25+ layout call sites reclaim the
    52dp strip through the ONE helper), the menu's banner_show/hide gone.
  - `projects/gogabox/config/ads_config.json` + `docs/ADS.md` DELETED.
  - the ad gradle dep + the manifest's UnityAds registration gone.
  - the loader's "watch an ad" tip gone; doc headers reworded.
  - flow_test: the reward tier math + the plugin-file checks updated to the
    0-ads truth.
- **THE OFFLINE LAW (rides the 0-ads law)**: no INTERNET permission - the
  android presets' `permissions/internet` + `access_network_state` read
  false and the overlay manifest's network uses-permissions are gone.
  The box is fully offline.
- **MIT**: the AS-IS all-rights placeholder LICENSE replaced with the MIT
  license (Copyright HAKORADev 2026) + the third-party note (Godot MIT,
  Kenney CC0). README's license section rewritten.
- Brainstorms + plans KEPT untouched (the owner's order) - including
  `THE_APP_STORE_QUESTION.md` (the ads history) and the old plans.
- The active docs tell the truth now: README (0 ads + two platforms),
  AGENTS.md §4 (the platforms + the 0-ads law, the playbook deleted),
  CI.md (build.yml + the exe job), RELEASE_LAW.md (THE TWO-PLATFORM LAW),
  RESOLUTION_RULE.md (the reclaimed inset + the vertical slice),
  ADDING_A_GAME.md (os + controls_pc).

## FRONT B - THE WINDOWS RETURN (the commit archaeology)

Found the round: `81351ac` (THE FORGE) -> `e881cfc`/`edf7100` (forge fixes)
-> `0dbc128` (v0.3.4-3 THE WINDOWS BUILD + the PC laws) -> `ea066a7`
(addon staging) -> `7529688` (THE REAL-EXE LAW) -> `805b041` (v0.3.4-4 THE
GREAT UN-WINDOWING, the money reason). The mature state at `7529688` is the
resurrection source (the forge itself was already dead by then: official
templates won).

- **THE ONE BUILD LAW**: `build-android.yml` renamed to `build.yml` and
  wears the `windows` job again - push to main builds the APKs AND the exe;
  manual dispatch adds the optional release (APKs + zip).
- **THE REAL-EXE LAW**: the exe must be a genuine 32-bit Windows GUI binary
  (`PE32 executable ... Intel (i386|80386)`) over 50MB (the pck inside).
- **THE SSE2 BASELINE LAW**: the official x86_32 templates are SSE2-only -
  the exe runs on pre-2014 CPUs with no SSE4.2 (the owner's whole point).
  32-bit natively, 64-bit through WOW64. No 64-bit exe, no forging.
- The export preset `Windows x86_32` is back (embedded pck, the .ico, the
  HAKORA product stamp, version 0.4.0.16) + `icons/icon.ico` restored.
- The PC window: desktops open 1280x720 (`window_width/height_override`).
- **THE VERTICAL SLICE LAW**: `ScaleRule.is_pc()` + `apply_vertical_slice()`
  are back (the file never changed - the un-windowing diff reversed clean);
  host_node's orientation paths + the menu's `_apply_base` wear it; portrait
  games render the KEEP slice with the box brown sides, landscape EXPANDs.
- **THE PLATFORM LAW**: `Meta.OS_TAGS` + `os_label` + the "os" chip branch
  are back; all 29 registry entries wear `"os": ["android", "pc"]`; the
  search sheet wears the PLATFORM filter chips again; the guide renders
  PLATFORMS badges + HOW TO PLAY - PC.
- **THE CONTROLS**: the forge's keyboard twins restored for dario, hopper,
  invaders, lanes, merge, pong (pong re-aimed through the v0.3.7-1 GLIDE -
  the keys drive the follow target), and NEW twins for pacman (arrows),
  maze (arrows + SPACE start), brickbreaker (arrows + SPACE launch),
  geometry (SPACE/UP as the tap), goldminer (SPACE as the tap),
  deathworm (arrows bend + SPACE dash), rockbreaker (arrows roll + SPACE
  fire), heavywar (arrows steer, the mouse keeps aim + fire). The mouse
  games (xo, matcher, slasher, snake, cosmic_spud, pop_siege, chess,
  domino, fourline, bovo, squares, jumpcube, ludo, snl, marble) play
  through `emulate_touch_from_mouse` with zero code. Every entry carries
  its `controls_pc` lines.
- **NOTIFICATIONS**: the notify bridge stays a desktop no-op (its android
  feature guard was already the law).
- `tools/v0416_registry_os.py` (new one-shot) inserted the 29 os tags +
  29 controls_pc arrays; the 2026 tool pattern follows `v034p3_registry_os`.

## THE ORDER

1. Front A code nuke -> Front B infra -> registry tool -> keyboard twins.
2. Docs + LICENSE + version (0.4.0-16 / 31260, both spots - THE VERSION LAW).
3. flow_test + probes green -> ONE commit -> push -> CI green (both jobs).
