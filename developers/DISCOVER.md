# DISCOVER.md — the store, its sources, its tiers

The discover feed is a SEARCH ENGINE over SOURCES. A source is either a
github repo (served over RAW http — never the API) or a local folder.
The engine owns the tiers; a source can never claim one.

## The source file (the known-file convention)

A github source must serve, at its repo root, this exact path:

```
GOGAs/discover/index/source.json
```

fetched as `https://raw.githubusercontent.com/<user>/<repo>/<branch>/GOGAs/discover/index/source.json`.
That path IS the API (the no-api-limit law) — github's REST is never
touched, the rate limits are bypassed by construction.

```jsonc
{
  "schema": 1,
  "name": "GOGABox Official",
  "repo": "HAKORADev/GOGABox",
  "engine_version": "0.4.3",          // the APP self-update channel
  "update_assets": {"android": "<url>", "pc": "<url>"},
  "games": [
    {"index": "games/<pkg id>/index/index.json",   // raw-fetched next
     "id": "gogabox_github-<user>_...", "version": "1.0.0"}
  ]
}
```

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
