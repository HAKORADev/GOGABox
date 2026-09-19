# CI — GitHub Actions

## Workflows

### `build.yml` — THE ONE BUILD (both platforms)

| trigger | behavior |
|---|---|
| **push → main** (paths: `projects/**`, `plugins/**`, `config/**`, `.ci/**`, `tools/**`, `build.sh`) | builds every project with `ci_auto: true` × every ABI in its `abi_presets` (release) + THE Windows exe |
| **manual dispatch** | pick `project` + `abi` (`all`/`arm64-v8a`/`armeabi-v7a`) + `build_type` (`release`/`debug`), optional `create_release` (APKs + the Windows zip) |

Job flow: `plan` (generates the matrix with `.ci/ci-matrix.sh` — the same
script runs locally) → one `build` job per (project, abi) → the `windows`
job → optional `release` (needs both).

Each APK job:
1. restores caches (toolchain + gradle),
2. `./tools/bootstrap.sh` (installs only what's missing),
3. `./build.sh <project> --abi <abi> --type <type>` (identical to local),
4. uploads `dist/<project>/*.apk` as an artifact
   named `<project>-<abi>-<build_type>`,
5. appends a build summary (sizes, versions, ABI) to the run page.

### The Windows exe job (THE REAL-EXE LAW)

Minutes, not hours: no template forging. The job seats the **official
Godot 4.7.2 Windows x86_32 export templates** (SSE2 baseline — the exe runs
on pre-2014 CPUs with no SSE4.2; 32-bit natively, 64-bit through WOW64),
stages the shared plugin addons (the gitignored GDScript autoloads), imports
the project and exports the ONE preset `Windows x86_32` (embedded pck,
single file, the .ico). Then it VERIFIES the binary:

- `file` must print a genuine `PE32 executable` for `Intel (i386|80386)`,
- size must exceed 50MB (the pck is inside),

and zips `GOGABox.exe` + a README.txt into `GOGABox-windows-<version>.zip`.
There is no 64-bit exe preset. The exe is exported with the project's
committed `export_presets.cfg` — no per-run patching.

**THE SMALL DELIVERY LAW (v0.4.0-17):** the artifact ships **THE ZIP ONLY** —
the old run uploaded the raw exe AND the zip, so one download carried the
game twice (~360 MB). The zip is what ships. The game data itself is kept
lean by THE SLIM PACK LAWS (tools/v0417_slim_audio.py: every wav source is
ogg; tools/v0417_slim_textures.py: every 2D texture imports lossless), and
the job fails CI if the delivery ever re-fattens past 175 MB. Read the exe's
weight honestly: ~116 MB of it is the OFFICIAL 32-bit template (the engine
floor: D3D12 + ANGLE + Vulkan + GL all compiled in) — the laws forbid
forging it, so the exe can never weigh less than the engine; the zip is as
small as the official build gets.

**THE 0-WARNINGS LAW (v0.4.0-17):** both workflows run the Node 24 action
majors (`checkout@v5`, `cache@v5`, `upload-artifact@v5`,
`download-artifact@v5`) and pin `ubuntu-24.04` on every job — the Node 20
deprecation and the ubuntu-latest→26 migration notes can no longer appear.

### `env-check.yml`

Fast toolchain-only sanity run (no build). Use it after touching
`config/environment.lock` or `.ci/` scripts.

## Caching ("freeze it, save time")

| cache | path | key |
|---|---|---|
| toolchain | `.cache/jdk`, `.cache/android-sdk`, `.cache/godot` | `hashFiles('config/environment.lock')` |
| gradle | `~/.gradle/caches`, `~/.gradle/wrapper` | hashes of all gradle files, prefix fallback |

Bumping the lock file invalidates the toolchain cache once, then freezes again.
First uncached run ≈ 20–25 min per ABI; cached runs ≈ 8–12 min.

## Releases

Manual dispatch with `create_release: true` attaches both ABIs + the Windows zip to a GitHub
release tagged `<project>-v<version_name>` — project-scoped, so two games
can both be at v1.0.0 without colliding (older global `v<version>` tags like
`v1.0.0` remain from before this scheme). Re-running with
the same version re-uploads (clobbers).

## Production signing on CI (optional, when ready)

1. Repo **Settings → Secrets and variables → Actions**, add:
   - `RELEASE_KEYSTORE_B64` — base64 of your release keystore:
     `base64 -w0 release.keystore`
   - `RELEASE_KEYSTORE_PASSWORD`, `RELEASE_KEYSTORE_ALIAS`
2. Add a decode step before the build step in `build.yml`:

```yaml
      - name: Decode release keystore
        if: ${{ secrets.RELEASE_KEYSTORE_B64 != '' }}
        run: |
          echo "${{ secrets.RELEASE_KEYSTORE_B64 }}" | base64 -d > "$RUNNER_TEMP/release.keystore"
          {
            echo "GDA_RELEASE_KEYSTORE=$RUNNER_TEMP/release.keystore"
            echo "GDA_RELEASE_KEYSTORE_USER=${{ secrets.RELEASE_KEYSTORE_ALIAS }}"
            echo "GDA_RELEASE_KEYSTORE_PASS=${{ secrets.RELEASE_KEYSTORE_PASSWORD }}"
          } >> "$GITHUB_ENV"
```

`build.sh` already consumes those env vars. Until then, CI APKs are
debug-signed (valid for testing/sideloading).

## Cost notes

Public repo → Actions minutes are free on `ubuntu-latest`. The cache stays
well under GitHub's 10 GB/repo limit (~4 GB total). Private repo → ~25
build-minutes per full run against the 2 000 min/month free tier.
