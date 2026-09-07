# PLAN v0.3.6 — GEOMETRY FLASH (the first decompile-tools production)

Owner GDD: docs/goga_docs/gogames_ideas/geometry.md
Study: Geometry Dash Lite 2.2.147 via tools/study (THE USAGE LAW).

## checkboxes

- [x] PGB v1.3.8 geometry_flash.py studied (pygame sketch: pushers, coins,
      speed-up — the grandfather; nothing worth carrying but the intent)
- [x] GD Lite fetched (198MB XAPK, AEGON edge, ~15s), assets extracted (1038 files)
- [x] Atlas study: GJ_GameSheet-hd (blocks/spikes/rings), GameSheet03
      (playerSquare = white mask + colors at runtime; starAnim twinkle),
      Glow sheet (white glow overlays = GD's glow trick), gradientBG.
      Anatomy captured: dark beveled body + bright structure lines + glow
      overlay; orb = filled core + white ring; star = 4-point twinkle.
- [x] GDD written (geometry.md)
- [x] ART tools/v036_gf_art.py — 100% original neon-filled redesigns
      (5 skins, block/line/strip tiles, pusher, spikes, saw, orbit +
      twinkles, particles, 3 mechanic chips, deco, tap ring)
- [x] SFX tools/v036_gf_sfx.py — 10 synth SFX + the 31s theme (ogg 0.6MB)
- [x] Shaders: gf_bg (gradient + drifting grid + breath band, dimmed per
      QA) + gf_swap flash (gentle radial)
- [x] game/games/geometry/geometry.gd (~1550 lines):
      - layout law (roof 300 / lines 460-620-780 / ground 940; apex 204.7)
      - standpoint x=0.32w + drift-back law + pusher carry law + edge death
      - chunk generator (9 patterns) + fairness laws + calm runway + swap calm
      - 3 mechanics + hidden scheduler (10/20/30/40s, never same twice)
      - THE SPIN LAW: 90° over the PREDICTED flight (72 samples vs scroll)
      - orbits +1 (pitch-ladder blip), speed x1.1/10pts, chips (score/
        speed/mechanic) + the swap banner
      - GOGACoin 30/35/40/45/50s from last APPEAR, halo + bob
      - pits both strips (the roof pits only in flip modes), spikes/saws,
        pushers both strips (up + hanging), THE SUPPORT TRUTH (walk-offs)
      - shop: 5 skins / 3 themes (THE BUY-ONLY LAW via _buy_theme) /
        6 tails (buy→ON, toggle forever)
      - ready gate "TAP ANYWHERE TO START" + death burst + shake + finish
- [x] registry: geometry graduates (landscape, fee 10, div 4, price 350,
      needs_games 2 reveal kept, banner, 7 control lines, 5 achievements)
      + game_base ach cases (orbit_500/flips_250/gf_triple)
- [x] tests/gf_probe.gd: 54 checks ALL PASS — layout/apex, standpoint,
      tap laws (3 mechanics), spin law, surface/support/bonk/space truths,
      pit/edge/hazard, pusher (ride + top-safe), generator fairness (40
      seeds), roof-play gating, scheduler (never-same + durs + swap calm),
      orbit/speed, coin law, shop economy + buy-only, tables
      (+ the probes CAUGHT: the phantom cell hole in _chunk_push, the
      off-screen landing bug in _vertical, the us-scaling floatiness)
- [x] flow_test updated (13 playable, 2 teasers, geometry asserts) — ALL PASS
- [x] qa_v036 Xvfb rigs (8): ready/run/flip/sticky/coin/shop/theme/death —
      eyeballed; fixes landed: dimmer bg grid, tail under the square +
      beefier, fresh-save midnight look
- [x] thumb via thumb_composer (scene_geometry: the square mid-spin over
      the orbit arc, spike, pusher, coin, real strip tiles) — 960x640
- [x] manifest provenance (gf-study-gd-lite / gf-original-art / gf-synth-audio)
      + DECOMPILATION.md production-mission record
- [ ] version 0.3.6 / 30670, build arm32+arm64, cert unchanged
- [ ] push, CI green, NO release (the law), worklog

## risks / notes

- 1920x1080 fixed design + EXPAND: all layout math from get_viewport_rect()
  like pop_siege (never assume exactly 1920).
- Banner strip reserved (banner_bottom()) — the ground strip sits above it.
- Tween-await law: never await tw.finished bare (matcher lesson).
- The tree-pause laws: shop sheet uses the sheet stack; pause resumes.
- GD audio is RobTop-licensed: NOTHING from the APK ships. 100% synth.
