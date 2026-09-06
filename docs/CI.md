# CI — GitHub Actions

## Workflows

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
