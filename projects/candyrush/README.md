# Candy Rush

Endless challenging match-3 (candy-crush-like): swap pieces, chain cascades,
charge score targets before moves run out, and spend earned coins on whole
themes — **Candy Shop** (glossy sweets), **Gem Vault**, **Retro Fruits**
(pixel art) and **Neon Arcade** (dark + hue-shifted).

- 720×1280 portrait, `expand` stretch — full-screen edge-to-edge on modern phones
- 8×8 board, 5 piece types, seeded/deterministic board model (`game/board.gd`)
- Specials: striped (4-match), wrapped (L/T), color bomb (5-match) + combos
  (bomb+special, striped+striped, wrap+wrap…)
- Endless curve: targets grow ~12%/level, moves shrink 22→15 (`game/levels.gd`)
- Auto reshuffle on deadlock, hint button, cascade praise banners
- Ads: interstitial every 2 finished levels, rewarded (+5 moves save /
  double coins), menu banner — same shared `Ads` API as jellyjump

## Dashboard setup (before release)

1. Unity Dashboard → Monetization → Projects → **Add project**, package
   `com.zai.candyrush`.
2. Copy the **Android Game ID** into `config/ads_config.json` (`game_id`).
3. Create the three placements (`Interstitial_Android`, `Rewarded_Android`,
   `Banner_Android`) — names already match the config.
4. Keep `test_mode: true` until one real ad has been seen on device.

Empty `game_id` is safe in dev: the plugin skips init (no ads on device,
desktop simulation keeps working).

## Tests / build

```bash
./tools/test.sh candyrush          # headless: board math, specials, fuzz, scenes
./build.sh candyrush               # both ABIs -> dist/candyrush/*.apk
python3 scripts/derive_candyrush_assets.py   # re-derive all art from CC0 sources
python3 projects/candyrush/tools/gen_sfx.py  # re-generate synth SFX
```

Asset provenance: [docs/ASSETS.md](docs/ASSETS.md) + `../assets.manifest.json`
(sibling: `assets.manifest.json` at the project root).
