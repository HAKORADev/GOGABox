# SETUP — verified build environment

This is the exact procedure that was used to validate this repo (Aug 2026,
Ubuntu 24.04-class system, 4GB RAM OK). A future session can follow it blindly.

## 0. Prerequisites

```bash
sudo apt-get update && sudo apt-get install -y curl unzip zip jq python3 git
```

No `sudo` after this point — everything installs into the repo's `.cache/` and
`~/.android`. Disk budget: ~3 GB (toolchain) + ~2 GB (gradle caches).
RAM: 4 GB works (gradle is tuned to 2 GB heap in the project overlay);
8 GB+ is comfortable.

> **On this sandbox**: `sudo` is not available; if you run on a machine where
> it is, the same commands work — the bootstrap never needs root.

## 1. Bootstrap the toolchain

```bash
git clone https://github.com/HAKORADev/godot-android-arsenal.git
cd godot-android-arsenal
./tools/bootstrap.sh
```

`bootstrap.sh` is idempotent — it installs exactly what
`config/environment.lock` pins, and skips what is already valid:

| component | source | installed to |
|---|---|---|
| JDK 17 (Temurin) | pinned tarball from the lock file | `.cache/jdk/` |
| Android SDK (cmdline-tools 13114758, platform-tools, android-36, build-tools 36.1.0) | Google's official repo | `.cache/android-sdk/` |
| Godot 4.7.2-stable editor | GitHub release | `.cache/godot/bin/godot` |
| Android export templates | release tpz (Android subset only, ~450 MB of the 1.3 GB archive) | `.cache/godot/templates/` (symlinked into `~/.local/share/godot/export_templates`) |
| debug keystore | `keytool` (generated once per machine) | `~/.android/debug.keystore` |

The resolved toolchain is written to `.cache/env.sh`; all other scripts source
it. Override anything with a `.ci/local.env` file (gitignored), e.g.:

```bash
GDA_CACHE_DIR=/mnt/bigdisk/arsenal-cache   # relocate the whole cache
```

**Reuse an existing Android SDK**: if `ANDROID_SDK_ROOT` already points at a
valid SDK (has the locked platform + build-tools), bootstrap symlinks it into
the cache instead of downloading.

## 2. Verify

```bash
source .cache/env.sh
"$GODOT_BIN" --version            # 4.7.2.stable.official....
"$JAVA_HOME/bin/java" -version    # 17.x
ls "$ANDROID_HOME/platforms"      # android-36
```

Or run the same check on CI: Actions → **env-check** → Run workflow.

## 3. Test & build

```bash
./tools/test.sh jellyjump         # headless integration tests (exit code = verdict)
./build.sh jellyjump              # both ABIs
ls dist/jellyjump/                # JellyJump-v1.0.0-arm64-v8a.apk + -armeabi-v7a.apk
```

`build.sh <project>` does, in order:
1. **materialize** (`.ci/materialize-project.sh`): wipes and re-extracts the
   pinned `android_source.zip` into `projects/<g>/android/build`, applies the
   project's `android-overlay/`, stages shared plugins, injects gradle deps,
   writes `local.properties` and the template stamp file.
2. **patch presets**: version code (base+1 arm32, base+2 arm64), version name,
   keystore paths, aab format — from `config/projects.json`.
3. **import**: `godot --headless --import`.
4. **export**: `godot --headless --export-release "<preset>"` per ABI (each
   export runs the full gradle build).
5. **verify**: `.ci/verify-apk.sh` checks signature, badging, ABI content,
   prints a size summary (`dist/<g>/BUILD_SUMMARY.md`).

## Signing for release

```bash
GDA_RELEASE_KEYSTORE=/path/release.keystore \
GDA_RELEASE_KEYSTORE_USER=youralias \
GDA_RELEASE_KEYSTORE_PASS='***' \
./build.sh jellyjump
```

Without them, APKs are signed with the debug keystore (fine for sideloading
and testing; Play Store requires a real key).

## Bumping versions (the "freeze" procedure)

1. Edit `config/environment.lock` (e.g. new Godot version + templates URL).
2. Delete the affected cache (`rm -rf .cache/godot`) and run `./tools/bootstrap.sh`.
3. Re-run `./tools/test.sh jellyjump && ./build.sh jellyjump`.
4. If the Godot android template changed its gradle files, re-diff the
   project `android-overlay/` files against the new template and update them.
5. Commit. CI cache keys hash the lock file, so runners re-fetch exactly once.

## Known pitfalls (all pre-solved in the scripts, listed for archaeology)

- The templates tpz root is `templates/` — Godot's versioned dir name is added
  by us (`4.7.2.stable`).
- Godot's ConfigFile rejects unquoted paths with `/`; preset values are always
  quoted by the patcher.
- `sdkmanager` needs `cmdline-tools/latest` layout (Google zips it as
  `cmdline-tools/cmdline-tools`).
- Export presets must exist **before** `godot --headless --import` runs;
  otherwise the editor's fs-scan reports "Invalid export preset name".
- On 4 GB machines keep `org.gradle.jvmargs=-Xmx2048m` (set in the project
  overlay's `gradle.properties`).
