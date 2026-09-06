# PLAN v0.3.4-4 (android-only revision) — THE GREAT UN-WINDOWING

**Round:** 2026-09-06, the owner's call after seeing the Windows numbers.
**Owner quote (the law):** "we should not do windows builds because no way to
make money from them at all... sorry for working on windows things that was
obviously not worth it... we have to focus only on Android".
**Status:** DONE — everything below shipped in one commit, CI green, no
release (the release law).

## 1. The decision

The windows experiment (the v0.3.4-3 forge, the v0.3.4-4 one-build) is
RETIRED. The box returns to the pre-forge ANDROID-ONLY state, with exactly
two survivors the owner explicitly kept:

1. **THE COSMIC SPUD PATCH 4 LAWS** (the whole point of v0.3.4-4): the
   no-shoot-VFX law, the universal collected-coins widget, the real
   GOGACoins shop list, the coin-icon prices, the honest meters.
2. **THE SEARCH BAR** (the owner: "in the search bar, remove the example,
   just let it enter a name without that example") — kept, with its example
   placeholder REMOVED. It now just says "type a name".

## 2. The rollback inventory (what was un-windowed)

**Workflows:**
- `.github/workflows/build.yml` (the APK+exe one action) — DELETED.
- `.github/workflows/build-android.yml` — RESTORED verbatim (the pure
  android pipeline: push builds both ABIs, manual dispatch, optional
  release). `env-check.yml` untouched.

**Project/export:**
- `export_presets.cfg` — restored to the android-only file: the
  `Windows x86_32` preset block is gone, `icons/icon.ico` deleted.
- `project.godot` — the PC window override (1280x720) removed.
- `.gitignore` — the windows-era output ignores removed.

**Code (all restored to the pre-forge state, commit `ab9d740`):**
- `core/scale_rule.gd` — `is_pc()` + `apply_vertical_slice()` gone.
- `core/host_node.gd` — the vertical-slice windowing, the desktop restore
  branch, the death-menu "no ads on PC" guard: all gone (the rewarded
  DOUBLE theatre is back to the android flow everywhere).
- `core/meta.gd` + `core/ui_kit.gd` — OS_TAGS / "os" chips gone.
- `core/registry.gd` — the `"os"` + `"controls_pc"` keys on all 11 games gone.
- `menu/menu.gd` — SURGICAL (not wholesale): the PLATFORM filter row, the
  guide's PLATFORMS + "CONTROLS - PC (WINDOWS BUILD)" sections and the
  vertical-slice branch are gone; the text search (`_filter_text`,
  `_norm_txt`, the search row, the live Apply light-up) STAYS with the new
  bare placeholder.
- Keyboard controls (THE PC LAW code) removed from: dario, hopper, invaders
  (incl. the fixed-speed axis refactor back to the analog touch axis),
  lanes, merge2048, pong. Touch is the only input again.
- KEPT on purpose: `core/game_base.gd`'s `_score_chip_ref` /
  `_coins_chip_ref` (the CS patch-3 chip laws the HUD law needs) and the
  whole `cosmic_spud/` tree + `cs_probe.gd` (patch 3 + 4 laws).

**Docs:**
- README / CI / SETUP / AGENTS / RESOLUTION_RULE / ADDING_A_GAME — restored
  to the android-only wording (the Windows law, the exe pipeline, the PC
  window section, the platform-law registry docs: all gone).
- `PLAN_v034p3_AND_WINDOWS.md` + `PLAN_v034p4_ONE_BUILD.md` — DELETED (they
  document builds that no longer exist; recoverable from git history).
- `cosmic_spud_patch4.md` — VERSION section updated to the android-only
  revision.
- `RELEASE_LAW.md` — gained THE ANDROID-ONLY LAW so no future round
  re-introduces desktop builds by accident.
- `FUTURE_GAMES.md` — the Strategy lanes shelf grew the owner's two new
  names: **vertical-lanes-td** (PvZ stood upright) and
  **zombie-catchers-like** (stealth + tactical hunting).

## 3. Version

- `config/projects.json`: version_name stays **0.3.4-4** (the owner: "same
  patch 4, not 5"), version_code_base bumped 30510 → **30511** so the
  android-only APK installs cleanly over any earlier v0.3.4-4 build.

## 4. Verification

- repo-wide grep: zero hits for `is_pc / apply_vertical_slice / OS_TAGS /
  os_label / controls_pc / _filter_os / icon.ico / kb latches` in the game
  tree; zero windows/exe mentions in the living docs.
- probes: flow_test (all games boot + play), cs_probe (the patch-4 laws),
  and the touched games' probes (dario/hopper/invaders/lanes/merge/pong).
- CI: `build-android.yml` must come back GREEN producing the two APK
  artifacts — that is the whole delivery (the release law).
