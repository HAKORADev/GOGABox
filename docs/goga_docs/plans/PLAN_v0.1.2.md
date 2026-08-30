# PLAN v0.1.2 — landscape fix + FHD designs + code background + round-ready ping + notification sound

Owner feedback after testing v0.1.1 on the FHD+ phone. Every item is a
checkbox; the commit message references this file.

## 1. LANDSCAPE RENDERING CORRUPTED (the "easy screen thing")

- [x] Symptom: rotating to landscape kept the VERTICAL design - content
      rendered as a portrait strip dead-center, black bars on the sides.
- [x] Root cause: `menu._apply_base()` read `_root.size` (DESIGN space -
      1080x2400-shaped forever once portrait was applied) so the orientation
      check could never flip. See RESOLUTION_RULE.md section 7.
- [x] Fix: decide from `DisplayServer.window_get_size()` (real pixels).
- [x] Hook `get_window().size_changed` (the only signal that fires on a
      plain rotation under aspect KEEP).
- [x] `set_active(true)` re-applies the design after a game closes (the
      host `_restore()` pin is portrait-blind).

## 2. UNIVERSAL SCALE -> 1080x1920 / 1920x1080 (owner: "my phone is FHD+")

- [x] Designs are 9:16 / 16:9. FHD+ renders 1:1 native; other aspects
      letterbox with box-brown bars (aspect KEEP). Nothing off-screen, same
      look on every phone (geometry_probe verifies both designs).
- [x] project.godot, host_node, menu, tests all moved to the new constants.
- [x] geometry_probe is END-TO-END now: sets the override, lets the real
      `_apply_base` decide, fails if the visible rect != the design.

## 3. MOVING BACKGROUND REBUILT IN CODE (owner: "the duplicated image with
   lower opacity" illusion is gone)

- [x] Detected the two main colors of bg_main.png
      (scripts/v012_bg_colors.py): base #261508, stripe #35200d, dots
      #422a16. Stripe period measured 90 px @720-wide (45deg) -> 95.5 px
      along the normal at 1080 design width.
- [x] NEW assets/ui/bg_stripe.gdshader: 45-degree stripe field + staggered
      dot grid (parallax 0.5x) + vertical shade + a soft sheen band sweeping
      down every 26s. fract() math = mathematically seamless forever, full
      opacity, no ghost copy. Pattern in design px = same look both
      orientations, every phone.
- [x] menu.gd: Sprite2D/region-scroll removed; ColorRect + ShaderMaterial;
      dust particles keep their layer (above bg, below feed).

## 4. BATTERY SFX = "BATTERIES FOR A ROUND RECHARGED" (owner: "instead" of
   the full-pool ping)

- [x] store.gd: `_battery_full_sfx` -> `_battery_round_sfx`. A pool pings
      exactly when regen CROSSES one round's worth (below per_round before,
      at/above it now). The old full-cap ping is GONE.
- [x] Box bank: same crossing rule on resume credit, using `_round_need()`
      (fattest per_round among owned charged games, fallback 2).
- [x] menu 2s tick calls `Box.poll_game_batteries()` so the ping happens
      LIVE while sitting in the box (lazy regen used to need a sheet open).
- [x] New signal `battery_round_ready` mirrors the ping; flow_test covers
      ping-once / no-ping-when-already-ready / no-ping-at-full / bank rules.

## 5. SILENT GOGABATTERIES NOTIFICATION (owner heard nothing)

- [x] App-side chain verified end-to-end: wavs are valid PCM16 44.1kHz,
      raw resources ARE in the APK, channels created with sound + proper
      AudioAttributes at IMPORTANCE_DEFAULT since v0.0.5.
- [x] Channels are IMMUTABLE on Android - any silent legacy state on the
      device can only be cured with new ids: bumped to *_v3.
- [x] Java: legacy v2 ids deleted on upgrade, pending schedules migrated
      v2->v3 at fire time (a deleted channel would post into a silent
      system bucket), vibration on, logcat diagnostics at channel creation
      AND notification post (sound= / importance=) for future debugging.
- [x] Owner-side checklist if it is STILL silent after v0.1.2: the
      notification slider is separate from media on most phones; check
      Settings > Apps > GOGABox > Notifications > GOGABatteries > Sound;
      check Do Not Disturb. logcat tag GOGANotify shows exactly what the
      channel carries.

## 6. SHIPPING

- [x] flow_test: ALL PASS (17 suites), geometry_probe: FIT both designs.
- [x] config/projects.json -> 0.1.2 / code base 30210 (arm32 30211,
      arm64 30212), same arsenal keystore (overwrite-install safe).
- [x] Build + push + CI green + artifacts verified.
