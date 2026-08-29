# unity_ads — shared Unity Ads bridge plugin

Godot 4.x **Android plugin (system v1)** that wraps the Unity Ads SDK
(`com.unity3d.ads:unity-ads:4.20.0`, pinned in `config/environment.lock`).

It is **not committed inside projects** — `.ci/materialize-project.sh` stages it
into any project listed in `config/projects.json` → `"use_plugins": ["unity_ads"]`:

| source                                   | staged into                                          |
|------------------------------------------|------------------------------------------------------|
| `addon/` (this dir)                      | `<project>/addons/unity_ads/`                        |
| `android/org/.../UnityAdsPlugin.java`    | `<project>/android/build/src/org/...` (gradle compiles it) |
| `<project>/config/ads_config.json`       | `<project>/addons/unity_ads/ads_config.json`         |

## How it works

- `UnityAdsPlugin.java` extends `org.godotengine.godot.GodotPlugin` and registers
  itself via the manifest meta-data `org.godotengine.plugin.v1.UnityAds`
  (added by each project's `android-overlay/AndroidManifest.xml`).
- GDScript accesses it as `Engine.get_singleton("UnityAds")`.
- `addons/unity_ads/ads.gd` (autoload `Ads`) wraps the singleton behind a stable
  API and **simulates the whole flow on desktop**, so gameplay code and headless
  tests work without a device.

## GDScript API (autoload `Ads`)

```gdscript
Ads.register_run()                     # count a finished run (interstitial pacing)
Ads.maybe_interstitial(cb)             # cb(shown: bool) - fires when pacing threshold hit
Ads.show_rewarded(cb)                  # cb(watched_to_end: bool)
Ads.banner_show() / Ads.banner_hide()  # anchored bottom banner (menu only)
Ads.cfg["test_mode"]                   # true while testing - flip to false for release
Ads.cfg["test_device"]                 # {name, gaid}: test ads serve ONLY on this
                                       # advertising id (matched natively at startup,
                                       # v0.0.7). Empty gaid -> everyone gets real ads.
```

Signals: `init_complete`, `banner_shown_changed(visible)`.

## Updating the SDK / changing integration

1. Bump `unity_ads_sdk` in `config/environment.lock`.
2. Bump the `implementation "com.unity3d.ads:unity-ads:..."` line in every
   project's `android-overlay/build.gradle`.
3. If the SDK changed APIs (like the 4.9 banner rewrite), edit
   `UnityAdsPlugin.java` here — every project picks it up on next build.
4. Placement IDs, game id, test mode and pacing live in each project's
   `config/ads_config.json` — see `docs/ADS.md`.

## Verification tips

- `javap` the SDK classes to confirm APIs after an upgrade:
  find the AAR in `~/.gradle/caches/modules-2/files-2.1/com.unity3d.ads/`,
  unzip it, `javap -cp classes.jar com.unity3d.ads.banners.BannerAd`.
- Always test on device with `test_mode: true` first.
