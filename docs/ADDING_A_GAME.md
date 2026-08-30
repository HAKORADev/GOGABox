# ADDING A GAME — to the GOGABox shelf

> The repo ships ONE product: GOGABox. You do not add new project folders —
> you add games **inside** `projects/gogabox`. (The old multi-project
> workflow was retired when the repo became GOGABox-only.)

## The 6-step checklist (inside the box)

1. **Register the game** — `projects/gogabox/game/core/registry.gd`:
   id, display name, price (GOGACoins), meta tags (age/genre/subs), state
   (PLAYABLE / SOON / GATED), description ("tag" used by the pre-play ? menu).
2. **Write the game script** — one file under
   `projects/gogabox/game/games/<id>/<id>.gd` extending `GogaGame`
   (see `docs/goga_docs/plans/BOX_CORE_DESIGN.md` for the contract:
   `_build_hud`, `set_score`, payouts, death-menu hooks).
3. **Thumbnail** — `projects/gogabox/assets/thumbs/<id>.png`, 480x320,
   drawn from the real game sprites (see `projects/gogabox/tools/`).
4. **Wire it into the box** — the box feed/carousel, store page and search
   read the registry; a PLAYABLE game appears automatically.
5. **Tests** — extend `projects/gogabox/tests/flow_test.gd` (unlock, play,
   score paths for the new game); `./tools/test.sh gogabox` must end ALL PASS.
6. **Ship** — bump `version_name`/`version_code_base` in
   `config/projects.json`, build both ABIs, push, CI green.

## Design docs

Every game idea gets a GDD in `docs/goga_docs/gogames_ideas/<id>.md` before
it gets a script. Raw ideas go to `docs/goga_docs/brainstorms/`.
