# WORKLOG — durable task journal

> **Append-only. Newest entry at the bottom. Never delete or rewrite
> older entries.** One entry per task session, in this format:
>
> ```
> ## <date> — <task title>
> - Asked: what the user wanted
> - Done: commits / versions / CI runs (be specific)
> - State now: what works, what is pending or broken
> - Decisions: choices made, so the next session does not re-argue them
> ```
>
> Protocol: docs/AGENTS.md §8 · Resume checklist: docs/AGENTS.md §0.

## 2026-08-27 — repo + CI build-out, JellyJump v1.0.0

- Asked: a reusable Godot→Android build environment as a monorepo, with CI,
  and the first game (JellyJump, 720×1280, CC0 assets, full monetization loop).
- Done: commit `2a63d93` — `tools/bootstrap.sh`, `.ci/` (materialize, preset
  patcher, APK verifier, SDK/Godot installers), `build.sh`, `tools/test.sh`,
  `config/environment.lock` + `projects.json`,
  `.github/workflows/build-android.yml` + `env-check.yml`, docs.
- State: JellyJump v1.0.0 released (interstitial every 3 runs, rewarded
  revive + double coins, menu banner; Unity Ads direct, SDK 4.20.0).
- Decisions: everything pinned in the lock file; local = CI (same scripts);
  materialize over committed build dirs; CC0-only vendored assets.

## 2026-08-28 — LevelPlay mediation backend (plugin layer)

- Asked: check whether the chosen ad SDK is the most profitable; switch if not.
- Done: commit `19d5369` — `plugins/levelplay/` (LevelPlay/ironSource
  mediation SDK 9.6.0), backend-switchable plugin system (`use_plugins`,
  `plugin.meta.json` contract, manifest meta injection, autoload repoint),
  docs/ADS.md rewrite.
- State: implemented and tested, not yet activated; default backend stayed
  `unity_ads`.
- Decisions: mediation > single network for revenue (2+ networks ⇒ eCPM
  +20–50%); LevelPlay chosen over MAX; keep both backends switchable in one line.

## 2026-08-28 — LevelPlay activation with real IDs, v1.0.1

- Asked: user supplied real LevelPlay IDs (App Key `27d84b1ed`, interstitial
  `6j6die13bsc4f0n3`, rewarded `s6iuno9k7m9nx0sz`, banner `l7t8jl7rzxpuq0im`,
  native `jsyz6rjnru2nd61x`) — "set it up and make sure it works".
- Done: commit `7257c24` — activated backend, v1.0.1, pushed, CI green,
  release published. Found + fixed two real bugs on the way: (1) desktop-sim
  branch must run before native `available()` checks in `ads.gd`; (2) `.gdignore`
  inside `android/build` so Godot's scanner doesn't poison gradle with
  `*.import` sidecars.
- State: superseded by the next entry (rolled back); v1.0.1 release deleted.
- Decisions: native ad unit captured but not wired (no native format in the
  plugin); IDs preserved in docs/AGENTS.md §4.1.

## 2026-08-28 — rollback to Unity Ads direct

- Asked: "UnityAds only is good for me" — roll the repo back before LevelPlay.
- Done: reverts `56f53d4` + `f74a0f1` (tree byte-identical to `2a63d93`);
  kept one unrelated fix as `1a669d8` (the `.gdignore` race fix); deleted the
  v1.0.1 GitHub release + tag; CI run `33210926341` green; v1.0.0 latest again.
- State: repo on Unity Ads direct, `use_plugins: ["unity_ads"]`, tests green.
- Decisions: LevelPlay work stays recoverable — re-enable path documented in
  docs/AGENTS.md §4.3 (two `git revert` of the reverts + IDs from §4.1).

## 2026-08-29 — agent manual + general/specific doc split

- Asked: user felt the repo docs blurred the line between "general arsenal"
  and "this game"; wanted an AGENTS.md that works as an AI skill (ads IDs,
  dev/commit/push/build workflow) so future sessions resume in one step.
- Done: added `docs/AGENTS.md` (resume checklist, ground rules, ads playbook
  with the real Unity Ads + LevelPlay IDs, commit/CI/release conventions,
  sandbox recovery, worklog protocol) + root `AGENTS.md` stub; created this
  durable `WORKLOG.md` (seeded with prior task history — the sandbox-local
  worklog was lost twice to wipes); split `docs/ASSETS.md` into general
  policy (stays in docs/) vs per-game sources (`projects/jellyjump/docs/ASSETS.md`);
  added `tools/ci.sh` (list/watch Actions runs from the terminal, live-tested).
- State: docs-only + `tools/ci.sh`; push triggers CI (tools/** path) as a
  bonus validation.
- Decisions: `docs/` = general guides only; game-specific notes live in
  `projects/<g>/docs/`; ad IDs are documented in-repo (not secrets — they
  ship in every APK), while keystores/PATs never enter git.
