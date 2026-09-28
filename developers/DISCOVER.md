# DISCOVER.md — the store, its sources, its tiers

The discover feed is a SEARCH ENGINE over SOURCES. A source is either a
github repo (served over RAW http — never the API) or a local folder.
The engine owns the tiers; a source can never claim one.

## The catalog (the known-file convention, schema 2)

A github source serves, at its repo root, a real MULTI-FILE catalog:

```
GOGAs/discover/
  index/
    source.json        # the identity + the tier file map
    official.json      # the official tier's game rows
    community.json     # the community source directory (CI-synced)
    hobbyist.json      # the hobbyist rows (usually empty in a repo)
  REPOS.txt            # the one-line community register (the PR target)
```

`source.json`:

```jsonc
{
  "schema": 2,
  "name": "GOGABox Official",
  "repo": "HAKORADev/GOGABox",
  "branch": "main",
  "engine_version": "0.4.3",          // the APP self-update channel
  "update_assets": {"android": "<url>", "pc": "<url>"},
  "tiers": {                           // paths are CATALOG-relative
    "official": "official.json",
    "community": "community.json",
    "hobbyist": "hobbyist.json"
  }
}
```

A tier file's game rows point at packages with GOGAs-folder-relative
index paths (the raw fetch walks them exactly as written):

```jsonc
{
  "schema": 2, "tier": "official", "updated": "2026-09-28",
  "games": [
    {"index": "games/<pkg id>/index/index.json", "id": "gogabox_github-<user>_...",
     "game_id": "...", "title": "...", "version": "1.0.0",
     "size_bytes": 0, "updated": "2026-09-28", "versions_count": 1}
  ]
}
```

`community.json` is the REGISTER's catalog view — the same repos as
`REPOS.txt`, with room for per-source metadata (branch, note). The two
files are one register: goga-packages CI fails when a PR touches one but
not the other. Everything is fetched over
`raw.githubusercontent.com` — the REST API is never touched, the rate
limits are bypassed by construction (a well-known path IS the API).

**The tier trust law.** Rows from the OFFICIAL source wear the tier
FILE's name (the owner curates his own catalog). Rows from every other
source wear the ENGINE's tier — a community repo listing games in its
own `official.json` reads community, never official.

**The local simulation.** A LOCAL source walks the SAME catalog when the
folder is repo-shaped: a repo root (`GOGAs/discover/index/source.json`
under it) or the GOGAs folder itself (`discover/index/` one level down).
The local flow IS the contract; schema-1 sources (the old inline
`games` array in source.json) still parse untouched.

Each game's `index/index.json` carries the full manifest
(PACKAGING.md) plus the `files` array — the downloader fetches every
listed file over raw http, assembles the package in `GOGAs/.cache/`,
runs THE STRICT VALIDATOR, then installs through the same import door a
local folder uses. **The local flow IS the remote flow** — a developer
who tests locally has tested the real thing.

## The tiers (engine-decided, never source-claimed)

| tier | who is in it |
|---|---|
| `official` | the hardcoded repo list (engine-side, `GogaDiscover.OFFICIAL_REPOS`) — today: HAKORADev/GOGABox |
| `community` | repos listed in the official repo's `GOGAs/discover/REPOS.txt` (CI-validated — PUBLISHING.md) |
| `hobbyist` | everything else (manually added sources, local imports) |

Modifying local data only worsens YOUR OWN box's experience — nothing
upstream is affected (the tiers ride the engine and the official file).

## The user's source registry

`GOGAs/discover/sources.json` — added through the box
(DISCOVER feed > ADD SOURCE): a github repo (`user/repo`) or a local
path. A local path may be:

1. a package root (one game),
2. a parent of roots (many games),
3. **a virtual repo** — a folder with `gogabox.repo.json`
   (`{"repo": "user/repo"}`) + the same shape a real repo would serve.
   THE LOCAL SIMULATION LAW: the full github-side flow (discovery →
   install → update) simulated with zero network. The local flow IS the
   contract; when the real side arrives it is the same system pointed
   at a real URL.

## The search (the owner's sorts)

The discover search filters (keyword, genres, sub genres, age, content,
tier) and SORTS with the arrows: `SIZE ↑/↓` (smaller→bigger / bigger→
smaller), `DATE ↑/↓`, `VERSIONS ↑/↓` (by how many versions released for
the same game). Case never matters — the lowercase law holds.

## The data-processing map (what lives where)

| data | where it lives | lifetime |
|---|---|---|
| feed metadata (source.json + game indexes) | re-fetched per feed pull | re-fetchable, tiny |
| downloads in flight | `GOGAs/.cache/discover/dl/<pkg id>/` | until installed |
| installed games | `GOGAs/games/<pkg id>/` | until uninstalled |
| app update staging | `GOGAs/.cache/update/` | until applied |
| saves | the package's `save/` or `libs/clients/<id>/` | forever (portable) |
