# ADDING A GAME — the 6-step checklist

The environment is project-agnostic: `build.sh`, CI, plugins and the toolchain
are shared. A new game = a folder + one registry entry.

## 1. Create the project folder

Easiest: copy the reference game and rename.

```bash
cp -r projects/jellyjump projects/mygame
rm -rf projects/mygame/.godot projects/mygame/icons
```

Then adjust `projects/mygame`:
- `project.godot` — `config/name`, `run/main_scene`, autoloads (keep
  `GameState`/`Sfx`; keep the `Ads` autoload path exactly as-is — it is staged).
- `icon.svg` + rerun `tools/rasterize_icons.gd` after the first import.
- `game/…` — your code. You may delete everything jelly-specific.
- `tests/flow_test.tscn` — keep the convention (exits 0 = pass).
- `assets.manifest.json` — record every asset's source + license.

## 2. Android overlay

`android-overlay/` layers your customizations over the pinned Godot android
template (re-applied on every build — never edit `android/build/` directly):

| file | purpose |
|---|---|
| `src/main/AndroidManifest.xml` | permissions, orientation, plugin meta-data |
| `gradle.properties` | memory tuning, gradle flags |
| `src/main/java/…` | (optional) project-specific java |

Start by copying jellyjump's two files and editing package-specific bits.

## 3. Export presets

`export_presets.cfg` with **one preset per ABI**, named whatever you like.
Register the mapping in the registry (step 4): preset names are referenced
per-ABI. Keep `version/code` values — they are overwritten at build time from
`version_code_base` (+1 arm32, +2 arm64).

## 4. Register the project

`config/projects.json`:

```json
"mygame": {
    "display_name": "My Game",
    "path": "projects/mygame",
    "enabled": true,
    "ci_auto": true,
    "apk_name": "MyGame",
    "package": "com.zai.mygame",
    "version_name": "0.1.0",
    "version_code_base": 20000,
    "aab": false,
    "abi_presets": {
        "arm64-v8a": "Android arm64",
        "armeabi-v7a": "Android arm32"
    },
    "use_plugins": ["unity_ads"],
    "ads_config": "config/ads_config.json"
}
```

- `ci_auto: true` → built on every push to main (both ABIs).
- `use_plugins` → which shared plugins get staged (and their gradle deps
  injected). Drop the key or empty it to skip ads.

## 5. Ads (optional)

Copy `config/ads_config.json`, set your Unity Game ID + placements, keep
`test_mode: true` until shipping (see docs/ADS.md).

## 6. Validate + push

```bash
python3 tools/sync-assets.py mygame   # re-fetch any missing assets
./tools/test.sh mygame                # headless tests
./build.sh mygame                     # both ABIs locally
git add -A && git commit -m "add mygame" && git push
```

CI builds it automatically; APKs appear under the run's artifacts. Done.

## Notes & guardrails

- `projects/<g>/android/build/`, `projects/<g>/addons/`, `.godot/`, `dist/`
  are generated — never commit them (gitignore already handles it).
- The monorepo is the storage of record: push before the session ends.
- Keep per-game tools under `projects/<g>/tools/` (e.g. `gen_sfx.py`).
