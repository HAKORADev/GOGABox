# PLAN v0.1.0 — repo rework + owner feedback round (after v0.0.9)

Status: IN PROGRESS. Owner feedback on v0.0.9 (2026-08-30, 5:30 AM — "take
your time doing the repo stuff first, then after that do the v0.1.0").

## A. Repo rework (GOGABox-only product, done FIRST)

- [x] Rename GitHub repo `HAKORADev/godot-android-arsenal` → `HAKORADev/GOGABox` (API, 200 OK)
- [x] Set repo description: "Godot all-in-one Game box"
- [x] Update git remote URL to the new repo name (push verified)
- [x] LICENSE → AS-IS notice (HAKORADev all rights reserved, personal non-commercial use)
- [x] README.md rewritten: GOGABox product branding, repo map, release checklist
- [x] Docs restructure: `docs/goga_docs/{gogames_ideas,ideas,plans,brainstorms}`;
      moved `projects/gogabox/docs/*` + `projects/gogabox/Docs/*` in there
      (RESOLUTION_RULE.md → docs/ root as a build rule)
- [x] Seed `gogames_ideas/` + `ideas/` with README conventions
- [x] AGENTS.md / SETUP / CI / ADDING_A_GAME / workflows → GOGABox-only language
      (also fixed: workflow_dispatch default project was "jellyjump" — deleted project;
       tools/ci.sh default repo slug pointed at the old name)
- [x] Asset stores one-by-one trial: GameArt2D.com, Poly Haven, ambientCG,
      Shadertoy, Godot Shaders, Google Fonts, Quaternius — download 1 asset
      from each, log the ones that worked in `docs/ASSETS.md`
      (VERDICT: ambientCG ✅ scriptable · GameArt2D ✅ scriptable · Google Fonts ✅ scriptable ·
       Poly Haven ⚠️ API-gated, browser fine · Quaternius ❌ itch modal · Shadertoy ❌ needs free API key ·
       Godot Shaders ❌ WAF-blocks bots)
- [x] Commit + push the repo rework before touching game code

## B. Game fixes (v0.1.0 build)

- [ ] **Resolution/scale**: raise internal resolution toward the phone's
      native (owner: 1080x2400) so things render smaller — owner: "fixing
      the resolution and scale thing will fix this and the buttons issue".
      Update docs/RESOLUTION_RULE.md decision (owner relitigated it).
- [ ] **Top-picks right arrow out of resolution** — must sit fully on screen
- [ ] **UNLOCKED! badge clipping** — the "k" literally out of the green
      widget and out of the thumbnail; size the ribbon from the real text width
- [ ] **NEW! on mystery black boxes** — owner never asked for that; black
      boxes stay a mystery (no badge rendering on mystery tiles at all)
- [ ] **Score-bonus ratio dead-menu ONLY** — remove the per-game in-game HUD
      line added in v0.0.9 (owner: "not for each game in-game scene, i said
      dead menu only"); keep the dead-menu line
- [ ] **Allow reminders STILL dead** — owner: study the notify plugin + the
      Godot version + real examples; make it SIMPLE (just ask for the
      notifications permission); no weird slop fallbacks (ladders/watchdogs out)

## C. Ship

- [ ] `config/projects.json` → 0.1.0 / 30190
- [ ] flow_test.gd updated + ALL PASS
- [ ] Build both ABIs, verify signature == arsenal cert, backup to download/
- [ ] Push, CI green, worklog entry
