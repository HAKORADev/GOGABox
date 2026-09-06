# PLAN v0.3.4-4 — ONE BUILD, ONE SHOP, HONEST METERS
(the owner's played-again report: the GitHub round + the Cosmic Spud round)

## THE ORDER (the owner: "first start by fixing the github stuff and build a
real exe, then work on the new patch and the new version that will be built
for both platforms")

---

## FRONT A — GITHUB: ONE ACTION, ONE EXE, NO FORGE

**What happened (the autopsy):**
- run 34001288142: both `forge-*` jobs green after ~25-31 MINUTES each
  (compiling Godot templates from source with lto=full), and the
  `export-windows` job was **SKIPPED** — `if: ${{ inputs.run_export }}`
  evaluated false, so the run "finished but gave nothing". Zero exes ever
  shipped from three forge attempts.
- The export path had never actually run once — it also would have died in
  `materialize-project.sh` (requires `GDA_ENV_FILE` from bootstrap, which the
  export job never ran).

**THE ONE-BUILD LAW (the owner):**
1. **Kill the forge.** No template compiling, ever. Use THE SAME GODOT AS
   ANDROID (official `4.7.2-stable` editor + the official
   `Godot_v4.7.2-stable_export_templates.tpz`) — "with windows required
   stuff" = just the two Windows template files out of that same tpz.
2. **ONE exe, 32-bit** — `GOGABox.exe` (x86_32). A 32-bit exe runs on every
   Windows (32-bit natively, 64-bit through WOW64). No 64-bit build.
   The `Windows x86_64` preset dies; the `Windows x86_32` preset is THE one.
3. **ONE workflow** — `build.yml` (build-android.yml + the windows job
   merged, build-windows.yml deleted). One push = one action = APKs + EXE.
4. **FAST** — the windows job caches the editor + the two template files
   (keyed on `environment.lock`). No cache hit costs one tpz download; a hit
   costs seconds. The whole exe job must stay minutes, never hours.
5. **Docs say ONE windows build** (README, CI.md, SETUP.md, AGENTS.md,
   RESOLUTION_RULE if touched).

**CI shape (build.yml):**
- `plan` (unchanged matrix gen) → `build` (the APK matrix, unchanged) +
  `windows` (new, parallel) → `release` (manual only, now attaches the zip).
- windows job: restore caches → seat editor + `windows_release_x86_32.*`
  into `~/.local/share/godot/export_templates/4.7.2.stable/` → import →
  `--export-release "Windows x86_32" ../build/GOGABox.exe` → zip with
  README → artifact `GOGABox-windows`.
- NO materialize-project.sh (that is the android tree builder; the exe does
  not need it — the repo project dir is already complete).

**Local proof before CI:** download the tpz locally, seat the same two
files, run the exact same import+export here, hand the owner a REAL
`GOGABox.exe` from this session.

---

## FRONT B — COSMIC SPUD (the owner's list, one law each)

1. **THE NO-SHOOT-VFX LAW** — every shooting flash/light dies: the muzzle
   particle (the rotated "muzzle" kiss), and the wobbly aim laser line.
   Hit feedback (iframe flicker, hurt flash, sfx) is not shooting VFX — it
   stays. Sounds stay.
2. **THE UNIVERSAL WIDGET LAW** — the HUD GOGACoins widget becomes THE
   universal chip every GOGABox game wears (`Arc.chip` + `coin.png`), and
   it shows the coins **COLLECTED THIS RUN** (starts 0, ticks on pickup) —
   NOT the total wallet. The total lives in sheets (the shop header).
3. **THE SHOP LIST LAW** — the HUD SHOP button opens THE SHOP: a plain
   scrollable LIST of things that cost REAL GOGACoins (the invaders/matcher
   shape: `Arc.coin_chip()` header + `Arc.coin_button` rows + CLOSE):
   - THE PLACES — desert (free default), park (400)
   - THE GUNS — premium guns; owning one puts it in EVERY wave market
     (they join the wave loot, the invaders law)
   - THE LAB — WEAPON LAB (the merging) + FOUNDRY, learned forever
   - THE CREW — allies; owning one lists it in the deploy rows forever
   The old four-tab cosmic-coin store is THE ARMORY again (tree button);
   the wave market stays the break's own flow.
4. **THE COIN-ICON PRICE LAW** — a GOGACoins price is NEVER spelled out in
   full words: the optionals theme card and the armory themes tab say
   "BUY 400" + the coin icon (the universal design), not "BUY 400 GOGACOINS".
   (The patch-2 "full words" law is dead — the owner overrode it.)
5. **THE HONEST METERS LAW** — root cause found and proven: the meters are
   `ColorRect`s inside `PanelContainer`s, and a Container resets a child's
   manual size whenever a sibling's minimum size changes (probe-proven:
   298 → 100 → 298). The HP bar (label churn every frame) snapped back to
   FULL constantly; the whole meter family is fragile. ALL meters rebuild
   as custom-drawn plain Controls no container can touch:
   - HP: animated fill (approaches per tick — it MOVES for each HP),
     continuous green→yellow→red color by the real ratio, number label.
   - XP: real `run_xp / xp_for_run_level(run_level)` fill, animated.
   - WAVE: the wave clock, animated.
   - BOSS: the boss HP, animated (same bug, same fix).
6. Version 0.3.4-4 / version_code_base 30510; preset stamps 0.3.4.4;
   presets: only `Windows x86_32`, export_path `../build/GOGABox.exe`.
7. Probes: cs_probe extended (the collected law, the shop list laws, the
   meter geometry, the no-muzzle law, the premium-guns guarantee, the lab
   buys); flow_test + every game probe green; qa shots.

## STATUS
- [x] Front A: build.yml merged + build-windows.yml deleted (one action, both platforms)
- [x] Front A: presets one-exe (Windows x86_32 -> GOGABox.exe, arch x86_32) + version stamps 0.3.4.4
- [x] Front A: docs one-build pass (README, CI.md, SETUP.md, AGENTS.md, RESOLUTION_RULE.md)
- [x] Front A: local exe proof - PE32 Intel i386, GDPC embedded, 150.9MB, exported in ~5s
- [x] Front B: laws 1-5 implemented (no-shoot-vfx, universal widget collected, shop list,
      coin-icon prices, honest meters)
- [x] probes green (cs 148/0, matcher 211/0, flow_test + every game probe PASS),
      qa_v034p4 shots (shop/door/arena), commit, push, CI watch (build.yml: APKs + exe)
