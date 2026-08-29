# ADS — Unity Ads integration

Monetization is a **shared plugin + per-project config**. Nothing ad-related
is hardcoded inside game scenes.

> Agent-facing playbook — real IDs, backend switching, re-enabling the
> LevelPlay mediation backend, writing new plugins, SDK upgrade protocol:
> **[AGENTS.md §4](AGENTS.md#4-ads-integration-playbook)**. This file is the
> architecture reference.

## Architecture

```
projects/<g>/config/ads_config.json   ← per-project knobs (IDs, pacing, test mode)
plugins/unity_ads/                    ← canonical plugin (see its README.md)
  ├─ addon/ads.gd                     ← autoload `Ads`: pacing logic + desktop simulation
  └─ android/.../UnityAdsPlugin.java  ← native bridge (GodotPlugin v1, SDK 4.20.0)
```

At build time `.ci/materialize-project.sh` stages the plugin into the project
and injects `ads_config.json`, so projects stay clean and the plugin stays
single-source.

## Configuration (per project)

`projects/jellyjump/config/ads_config.json`:

```json
{
    "enabled": true,
    "test_mode": true,                     // ⚠ flip to false before shipping
    "game_id": "5770940",                  // Unity Dashboard → project Game ID (Android)
    "placements": {
        "interstitial": "Interstitial_Android",
        "rewarded": "Rewarded_Android",
        "banner": "Banner_Android"
    },
    "interstitial_every_runs": 3,          // pacing: one interstitial per N finished runs
    "banner_height": 52,                   // px reserved at the bottom (plugin holder = 52dp, transparent, standard 320x50 banner)
    "banner_enabled": true
}
```

Placement IDs / Game ID are configured in the Unity Dashboard:
https://dashboard.unity3d.com → Monetization → Projects.

## Monetization loop (jellyjump reference)

| moment | ad | logic |
|---|---|---|
| every 3 finished runs | interstitial | `Ads.register_run()` then `Ads.maybe_interstitial(cb)` on retry/home |
| death → "SAVE ME" | rewarded | revive once per run; callback `true` only if watched to the end |
| game over → "DOUBLE COINS" | rewarded | doubles the run's coins |
| menu | banner | `Ads.banner_show()` / `banner_hide()`; desktop shows a simulated strip |

GDScript API (autoload `Ads`):

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
2. Confirm the Game ID + placements exist in the Unity Dashboard for the
   **exact package name** you ship (`config/projects.json` → `package`).
3. Test one real interstitial + rewarded on device.
4. Privacy/consent: the plugin uses the plain SDK initialize path; review
   Unity's GDPR/consent guidance for your distribution regions (Unity's
   Android privacy options live in the Dashboard + `MetaData` API if you need
   explicit consent plumbing).

## Changing how ads integration works

- Pacing / toggles → edit the project's `ads_config.json` (no rebuild of logic).
- GDScript behavior → edit `plugins/unity_ads/addon/ads.gd` once; all projects
  get it on next build.
- Native side / SDK upgrade → edit `UnityAdsPlugin.java` + the SDK version in
  `config/environment.lock` and each project's `android-overlay` gets the dep
  injected from `plugins/unity_ads/plugin.meta.json` (`gradle_deps`).
  After an SDK bump: `javap` the new AAR (see plugin README) and re-verify the
  API signatures used by the plugin.
