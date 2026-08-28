# levelplay — Unity LevelPlay mediation plugin (multi-network)

Godot 4.x **Android plugin (system v1)** wrapping the **Unity LevelPlay**
mediation SDK (`com.unity3d.ads-mediation:mediation-sdk:9.6.0`, pinned in
`config/environment.lock`).

**What makes it different from `unity_ads` (direct):** LevelPlay is Unity's
mediation platform (ex-ironSource). Instead of one network, *many networks
compete for every impression* — Unity Ads, Meta Audience Network, AdMob,
AppLovin, Mintegral, Liftoff, DT Exchange, Pangle, InMobi, ... Mediation with
2+ networks typically lifts eCPM 20–50% vs any single network (industry data,
2025–2026; see `docs/ADS.md`).

## Staging (automatic)

`.ci/materialize-project.sh` stages this plugin into any project whose
`config/projects.json` entry lists `"use_plugins": ["levelplay"]`:

| source | staged into |
|---|---|
| `addon/` (this dir) | `<project>/addons/levelplay/` |
| `android/org/.../LevelPlayPlugin.java` | `<project>/android/build/src/main/java/...` (gradle compiles it) |
| `plugin.meta.json → gradle_deps` | injected into `build.gradle` |
| `plugin.meta.json → manifest_meta` | injected into `AndroidManifest.xml` |
| `plugin.meta.json → autoload` | rewrites the `Ads` autoload in `project.godot` |
| `<project>/config/ads_config.json` | `<project>/addons/levelplay/ads_config.json` |

The `Ads` autoload API is **identical** across backends (`register_run`,
`maybe_interstitial`, `show_rewarded`, `banner_show/hide`, `cfg`), so game
code and `tests/flow_test.gd` work unchanged on either backend.

## Gradle deps (kept in plugin.meta.json, single source of truth)

```gradle
implementation "com.unity3d.ads-mediation:mediation-sdk:9.6.0"   // LevelPlay core
implementation "com.unity3d.ads:unity-ads:4.20.0"                // Unity Ads network SDK
implementation "com.unity3d.ads-mediation:unityads-adapter:5.12.0" // Unity Ads <-> LevelPlay bridge
```

Adding another network later = append its adapter here + enable it on the
dashboard, e.g. Meta:
`implementation "com.unity3d.ads-mediation:metads-adapter:<matching-version>"`.

## One-time dashboard setup (the only manual step)

1. Sign in at https://app.unity.com → **Grow → LevelPlay**.
2. **Add app** → Android, package name = the project's `package`
   (`config/projects.json`).
3. Note the **App Key** (8 hex chars).
4. Under the app → **Ad Units**: create `Interstitial`, `Rewarded`, `Banner`
   and copy each **Ad Unit ID**.
5. **Setup → Unity Ads network**: connect it with the existing Game ID
   (`5770940`) so current demand stays in the waterfall.
6. Optional but recommended for revenue: add Meta / Mintegral / AppLovin in
   **Setup → Networks** (each needs its own account/app id).

Then fill `projects/<g>/config/ads_config.levelplay.template.json` (rename to
`ads_config.json`) and flip `use_plugins` to `["levelplay"]`.

## Native API (Engine.get_singleton("LevelPlayAds"))

```gdscript
ads.configure(app_key, test_mode, banner_enabled)   # test_mode -> setAdaptersDebug(true)
ads.set_ad_unit("interstitial", id)                 # AFTER init_complete
ads.set_ad_unit("rewarded", id)
ads.load("interstitial") / ads.load("rewarded")
ads.is_loaded(kind) / ads.show(kind)
ads.banner_show(banner_id) / ads.banner_hide()
```

Signals: `init_complete`, `init_failed(msg)`, `ad_loaded(kind)`,
`ad_failed(kind, msg)`, `ad_shown(kind)`, `ad_closed(kind)`,
`reward_received(name, amount)`, `banner_loaded`, `banner_failed(msg)`.

Rewarded completeness is **not** an ordinal guess like Unity Ads direct:
`onAdRewarded(LevelPlayReward)` fires exactly when the reward is earned, and
the GDScript layer resolves the callback from that.

## Upgrading the SDK / verifying APIs

1. Bump the version here + in `config/environment.lock`.
2. Download the AAR from Maven Central
   (`https://repo1.maven.org/maven2/com/unity3d/ads-mediation/mediation-sdk/<v>/`),
   unzip, then `javap -cp classes.jar com.unity3d.mediation.LevelPlay` etc.
   to re-verify every signature used by `LevelPlayPlugin.java`.
3. Keep the Unity Ads SDK + `unityads-adapter` versions aligned per the
   LevelPlay changelog (https://developers.is.com/resources/api/changelogs/).
