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

- [x] **Resolution/scale**: DENSITY RULE in main.gd — content_scale_factor =
      720/clamp(device_short_px, 840..1152): the owner's 1080x2400 phone now
      runs a ~1080x2400 logical viewport (things render smaller, +50% room,
      text still sharp). Small devices floored at 840, flagships capped at
      1152. Verified by the NEW tests/geometry_probe.gd (boots the real main
      scene, fails on any control outside the viewport — all 3 configs FIT;
      it also PROVED the two reported 720-width overflows). Banner reserve is
      now computed from real dpi. docs/RESOLUTION_RULE.md §5 written.
- [x] **Top-picks right arrow out of resolution** — probe-measured root
      cause: carousel row 764px wide vs 720 logical width; fits at every
      density the rule now produces
- [x] **UNLOCKED! badge clipping** — _ribbon sizes the panel from the real
      text width (Kenney_Rocket.get_string_size) + padding, grows inward
- [x] **NEW! on mystery black boxes** — never rendered anymore (owner:
      "black boxes just stay a mystery"); badge state still tracked in Box
- [x] **Score-bonus ratio dead-menu ONLY** — game_base.gd HUD line removed;
      Arc.bonus_ratio_text + the host_node dead-menu line stay
- [x] **Allow reminders STILL dead** — ROOT CAUSE FOUND + fixed: Godot
      android plugins do no snake_case→camelCase conversion (docs: "There is
      no coercing snake_case to camelCase"); the addon called
      native.request_permission() while Java had requestPermission() — every
      call silently errored since v0.0.6. Java methods renamed to snake_case,
      ladder/watchdog slop deleted (plain official ask), NEW flow_test
      name-parity test parses every native.* call against the Java class

## C. Ship

- [x] `config/projects.json` → 0.1.0 / 30190
- [ ] flow_test.gd updated + ALL PASS
- [ ] Build both ABIs, verify signature == arsenal cert, backup to download/
- [ ] Push, CI green, worklog entry
