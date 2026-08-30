# PLAN v0.1.6 — THE THUMBNAIL PIPELINE

Owner directive: build the universal 960x640 real-gameplay thumbnail system,
prove it on snake + pong rally, ship as v0.1.6. Owner will NOT test this
build directly (v0.1.5 and v0.1.6 get tested together later).

## 1. LOCKED DECISIONS (this release)

- Universal canvas 960x640 for every thumbnail (games, SOON, mystery rule).
- Real-game thumbs have NO baked text; optional text = game font first.
- Games run at NATIVE design resolution, chosen frame downscaled to 960x640.
- NO video previews - shelved forever ("let the player just play the game").
- Thumbnail tooling lives in dev/ and is EXCLUDED from exports.
- Pipeline doc for the dev: docs/THUMBNAILS.md; rules history:
  docs/goga_docs/ideas/THUMBNAILS.md.

## 2. BUILT

- dev/thumb_capture/capture.{gd,tscn} - the harness: instantiates the REAL
  game (same loader path as the host), native viewport, CLI args
  (--game/--time/--every/--seed/--out/--hud/--w/--h), segment tagging for
  future multi-scene games, per-game drive hooks, auto-advance over "all".
- drives/snake_drive.gd - board centering + 1.35x poster zoom + honest
  greedy play (coin detours) + death->restart attract loop (over-flag +
  ghost-sprite cleanup).
- drives/rally_drive.gd - staged 3:2 court (paddles in-band), tracking with
  human-ish error, speed cap + ghost-ball rescue (llvmpipe tunneling),
  miss->restart attract loop.
- dev/thumb_capture/post.py - focus band crop (portrait/landscape aware),
  960x640 LANCZOS downscale, focus sweeps, contact sheets, single-frame
  final pick, before/after proof sheets.
- derive_assets.py - snake/rally hand-drawn thumbs RETIRED (commented, so a
  re-run cannot clobber captures); SOON template moved to _thumbs_soon()
  and regenerated at 960x640 (same design, 2x).
- export_presets.cfg - exclude_filter="dev/*" on BOTH presets.
- New thumbs: assets/thumbs/snake.png + rally.png = captured real gameplay
  (snake: 40s seed-3 run, long snake about to eat; rally: staged court,
  ball-on-paddle contact). Before/after proof saved for the owner.

## 3. VERIFICATION

- Spike first: Xvfb + opengl3 renders the real game (llvmpipe; headless
  cannot render).
- Ball-visibility probe: 72/72 rally frames contain the ball after the
  guards (was ~8/38 pre-fix).
- flow_test suite + geometry probe re-run before the build.
- Menu side needs NO change: _add_thumb already cover-fits (3:2 preserved).

## 4. SHIP

- version_name 0.1.5 -> 0.1.6, version_code_base 30240 -> 30250
  (arm32 30251, arm64 30252), same signing chain (overwrite-install safe).
- Build both ABIs, verify APKs, push, CI green, APKs backed up to download/.
- Owner test path: v0.1.5 + v0.1.6 together, next test round.
