# ADS — monetization backends

Monetization is a **shared plugin + per-project config**. Nothing ad-related
is hardcoded inside game scenes. Two interchangeable backends ship in
`plugins/`; the active one is a **one-line switch** per project.

## Backends

| | `unity_ads` (current default) | `levelplay` |
|---|---|---|
| what | Unity Ads **direct** — one network | Unity **LevelPlay mediation** (ex-ironSource) — many networks compete per impression |
| SDK | `com.unity3d.ads:unity-ads:4.20.0` | `com.unity3d.ads-mediation:mediation-sdk:9.6.0` + `unityads-adapter:5.12.0` (Maven Central) |
| revenue | baseline | **+20–50% eCPM typical** once 2+ networks are enabled (bidding + waterfall); with only Unity Ads enabled it is ≈ equal to direct |
| needs | Unity Ads Game ID (have it: `5770940`) | LevelPlay **App Key** + 3 **Ad Unit IDs** from the Unity dashboard (one-time, ~10 min, see below) |
| status | ✅ active, CI-verified end-to-end | ✅ code complete, compile-verified; **waiting on dashboard IDs** |

Market context (2025–2026): mediation controls >90% of top-grossing game
monetization via three players — AppLovin MAX (~half the market), LevelPlay,
AdMob mediation. "You'll always get bad eCPM without mediation" is the
standard indie finding; a single-network setup leaves money on the table.
Unity-Ads-first games conventionally pick **LevelPlay**: same Unity account,
Unity demand performs a few points better in LevelPlay than in MAX, and MAX
can later be added *as a network inside* LevelPlay (AppLovin bidding adapter)
— so no path is closed by choosing it.

## Architecture

```
config/projects.json → "use_plugins": ["unity_ads" | "levelplay"]   ← backend switch
plugins/unity_ads/    ← direct backend   (addon/ads.gd + UnityAdsPlugin.java)
plugins/levelplay/    ← mediation backend (addon/ads.gd + LevelPlayPlugin.java)
projects/<g>/config/ads_config.json ← per-project knobs (IDs, pacing, test mode)
```

`.ci/materialize-project.sh` stages the selected plugin: addon →
`addons/<dir>/`, Java → gradle source set, `gradle_deps` → `build.gradle`,
`manifest_meta` → `AndroidManifest.xml`, `autoload` → rewrites the `Ads`
autoload in `project.godot`, and copies `config/ads_config.json` into the
addon. The `Ads` autoload API is identical on both backends, so **game code,
tests and docs never change when you switch**.

A/B a backend without editing config:

```bash
GDA_FORCE_PLUGINS=levelplay ./build.sh jellyjump      # mediation build
GDA_FORCE_PLUGINS=unity_ads  ./build.sh jellyjump     # direct build
```

## Current config (jellyjump, unity_ads backend)

```json
{
    "enabled": true,
    "test_mode": true,                     // ⚠ flip to false before shipping
    "game_id": "5770940",                  // Unity Dashboard → project Game ID (Android)
    "placements": { "interstitial": "Interstitial_Android", "rewarded": "Rewarded_Android", "banner": "Banner_Android" },
    "interstitial_every_runs": 3,
    "banner_height": 90,
    "banner_enabled": true
}
```

## Switching jellyjump to LevelPlay (when dashboard IDs exist)

1. Dashboard (https://app.unity.com → **Grow → LevelPlay**):
   add the Android app with package `com.zai.jellyjump` → copy the
   **App Key**; create **Interstitial / Rewarded / Banner** ad units → copy
   their IDs; **Setup → Unity Ads** → connect Game ID `5770940` (existing
   demand keeps flowing); optionally enable Meta / Mintegral / AppLovin
   (each = its own network account, each adds demand = more money).
2. `cp projects/jellyjump/config/ads_config.levelplay.template.json
   projects/jellyjump/config/ads_config.json` and paste the 4 IDs.
3. `config/projects.json` → `"use_plugins": ["unity_ads"]` → `["levelplay"]`.
4. Build: `./build.sh jellyjump` (or push; CI does it) → test on device with
   `test_mode: true`, LevelPlay dashboard → **Testing → Test Suite** also
   validates the integration on-device.

Until step 2 is done, levelplay builds initialize-fail **gracefully**: the
game runs ad-free (no crash), exactly like a user with no fill.

## Monetization loop (jellyjump reference, backend-agnostic)

| moment | ad | logic |
|---|---|---|
| every 3 finished runs | interstitial | `Ads.register_run()` then `Ads.maybe_interstitial(cb)` on retry/home |
| death → "SAVE ME" | rewarded | revive once per run; callback `true` only if reward granted |
| game over → "DOUBLE COINS" | rewarded | doubles the run's coins |
| menu | banner | `Ads.banner_show()` / `banner_hide()`; desktop shows a simulated strip |

GDScript API (autoload `Ads`, identical on both backends):

```gdscript
Ads.register_run()
Ads.maybe_interstitial(func(shown): ...)
Ads.show_rewarded(func(watched_to_end): ...)
Ads.banner_show() / Ads.banner_hide()
```

On **desktop**, `Ads` simulates everything (rewarded always completes), so
`tools/test.sh` and editor playtesting need no device and no network.

## Before publishing a game

1. `test_mode: false` in its `ads_config.json`.
2. IDs exist in the dashboard for the **exact package name** you ship
   (`config/projects.json` → `package`).
3. Test one real interstitial + rewarded on device.
4. Privacy/consent: Unity LevelPlay requires a consent flow for EEA/UK
   (TCF v2). The plugin exposes the SDK path (`LevelPlay.setMetaData` /
   `setConsent`); wire your CMP of choice before shipping to those regions.
   Direct Unity Ads: review Unity's GDPR guidance in the Dashboard.

## Changing how ads integration works

- Pacing / toggles → edit the project's `ads_config.json` (no rebuild of logic).
- GDScript behavior → edit `plugins/<backend>/addon/ads.gd` once; all projects
  get it on next build.
- Add an ad network (levelplay) → append its adapter to
  `plugins/levelplay/plugin.meta.json` → `gradle_deps` + enable it on the
  dashboard. No game code changes.
- New backend (e.g. AppLovin MAX, AdMob) → copy a `plugins/<name>/` dir,
  write the GodotPlugin bridge + `ads.gd` with the same `Ads` API, declare
  `manifest_meta` + `autoload` in its `plugin.meta.json`, register it in
  `use_plugins`. The materialize pipeline needs zero new logic.
- Native side / SDK upgrade → edit the backend's Java + pin new versions in
  `plugin.meta.json` and `config/environment.lock`; verify APIs with `javap`
  against the downloaded AAR (see each plugin's README).
