# CI — GitHub Actions

## Workflows

### `build.yml` — THE one build action (push + manual)

ONE run builds BOTH platforms: the `build` job (the APK matrix) and the
`windows` job (the exe) run in parallel; `release` (manual only) attaches
the APKs + the Windows zip.

| trigger | behavior |
|---|---|
| **push → main** (paths: `projects/**`, `plugins/**`, `config/**`, `.ci/**`, `tools/**`, `build.sh`) | builds every project with `ci_auto: true` × every ABI (release) + the Windows exe |
| **manual dispatch** | pick `project` + `abi` (`all`/`arm64-v8a`/`armeabi-v7a`) + `build_type` (`release`/`debug`), optional `create_release` |

### The Windows law (v0.3.4-4) — ONE exe, official templates, minutes not hours

The forge era is dead. Three forge attempts burned ~30 minutes each
compiling templates from source and the export stage never once produced an
exe. The owner's law now:

- **THE SAME official Godot** the Android build uses (pinned
  `4.7.2-stable` editor) + **THE SAME official export templates tpz** — the
  workflow extracts just `windows_release_x86_32.exe` (+ the console
  wrapper) and seats them in `~/.local/share/godot/export_templates/4.7.2.stable/`.
- **ONE exe ships**: `GOGABox.exe` (`binary_format/architecture="x86_32"`,
  `embed_pck=true`) — a 32-bit binary that runs on EVERY Windows: 32-bit
  natively, 64-bit through WOW64. The `Windows x86_64` preset was deleted.
- **THE REAL-EXE LAW** (machine-checked): `file` must read
  `PE32 executable for MS Windows ... Intel i386`, and the size must exceed
  50 MB (the embedded pck guard).
- Cached under `win-toolchain-<lock hash>` (editor + the two template
  files). A cold run costs one tpz download (~1.3 GB); a warm run takes
  minutes: import → export → verify → `zip -9` as
  `GOGABox-windows-<version>.zip`.
- The export path `projects/build/` is created by the job; locally:
  `mkdir -p projects/build && godot --headless --path projects/gogabox
  --export-release "Windows x86_32" ../build/GOGABox.exe`.

Job flow: `plan` (generates the matrix with `.ci/ci-matrix.sh` — the same
script runs locally) → one `build` job per (project, abi) → optional `release`.

Each build job:
1. restores caches (toolchain + gradle),
2. `./tools/bootstrap.sh` (installs only what's missing),
3. `./build.sh <project> --abi <abi> --type <type>` (identical to local),
4. uploads `dist/<project>/*.apk` as an artifact
   named `<project>-<abi>-<build_type>`,
5. appends a build summary (sizes, versions, ABI) to the run page.

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
