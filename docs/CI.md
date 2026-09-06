# CI — GitHub Actions

## Workflows

### `build-windows.yml` — the template forge + the two exe builds (manual)

The owner's law: modern Godot x86_64 requires SSE4.2 (Haswell+); GOGABox
must run on older CPUs. So the Windows exports NEVER use the official
templates - the workflow FORGES them from the pinned source:

```
scons platform=windows target=template_release arch=x86_64 \
  lto=full use_static_cpp=yes debug_symbols=no d3d12=no angle=no \
  winrt=no accesskit=no \
  custom_cflags="-march=x86-64" custom_cxxflags="-march=x86-64" -j"$(nproc)"
```

- `arch=x86_64` → the 64-bit template; `arch=x86` → the 32-bit one.
- The forge then runs `objdump` over the template and FAILS if any
  SSE4.2/AES-only mnemonics (`pcmpgtq`, `pcmpestr*`, `crc32`, `aesenc`)
  appear - THE SSE2 LAW, machine-checked.
- The x86_64 job also switches mingw to its **posix-threads** flavor
  (`update-alternatives --set ...-posix`) - Godot refuses the win32 one.
- `d3d12/angle/winrt/accesskit=no`: GOGABox renders GL Compatibility; the
  optional driver SDKs are not part of this forge.
- The export job seats the forged templates in
  `~/.local/share/godot/export_templates/<version>.stable/`, materializes
  the project, and exports BOTH presets (`Windows x86_64`, `Windows x86_32`)
  with `binary_format/embed_pck=true` - each result is ONE exe. Artifacts
  ship zipped (`zip -9`) as `GOGABox-windows-<version>.zip`.

### `build-android.yml` — the dispatcher

### `build-android.yml` — the dispatcher

| trigger | behavior |
|---|---|
| **push → main** (paths: `projects/**`, `plugins/**`, `config/**`, `.ci/**`, `tools/**`, `build.sh`) | builds every project with `ci_auto: true` × every ABI in its `abi_presets` (release) |
| **manual dispatch** | pick `project` + `abi` (`all`/`arm64-v8a`/`armeabi-v7a`) + `build_type` (`release`/`debug`), optional `create_release` |

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

Manual dispatch with `create_release: true` attaches both ABIs to a GitHub
release tagged `<project>-v<version_name>` — project-scoped, so two games
can both be at v1.0.0 without colliding (older global `v<version>` tags like
`v1.0.0` remain from before this scheme). Re-running with
the same version re-uploads (clobbers).

## Production signing on CI (optional, when ready)

1. Repo **Settings → Secrets and variables → Actions**, add:
   - `RELEASE_KEYSTORE_B64` — base64 of your release keystore:
     `base64 -w0 release.keystore`
   - `RELEASE_KEYSTORE_PASSWORD`, `RELEASE_KEYSTORE_ALIAS`
2. Add a decode step before the build step in `build-android.yml`:

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
