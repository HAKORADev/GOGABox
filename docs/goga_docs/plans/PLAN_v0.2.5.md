# PLAN_v0.2.5 — SNOWY TOWER + THE ALWAYS-PLAYABLE CHEAT

Status: DONE. Version 0.2.5 (code base 30340: arm32 30341, arm64 30342).

## 1. The box: all_owned grows teeth (owner request)

- `Roadmap.can_play_now`: the ownership cheat returns PLAYABLE for every
  owned game — windows, daily caps, fee, batteries all skipped (soon
  tiles still refuse: nothing to launch)
- `GameHost.launch`: under the cheat the launch is FREE and UNLIMITED
  (fee 0 configured into the host, so the game-over sheet's PLAY AGAIN is
  free too)
- `Box.daily_ok`: answers true under the cheat (the retry tap-time check)
- the pre-play page: PLAY FREE, no blocker lines, no thumbnail fade; the
  window/daily/battery rows stay visible as info
- flow_test: the cheat laws (always-playable + daily-never-blocks + the
  window returns when the cheat is off)

## 2. Snowy Tower (hopper) — the redesign (owner GDD)

Registry: coin_div 60 → 10, shop true, price 300 / fee 12 / the 16-22
window KEPT (the cheat now bypasses it), new desc + controls + achievements
(tower_30 / tower_80 / tower_150 + hops_50; the counter is max_tower).

Game (see tower.md for the full contract): the PGB v1.3.8 generator with
the reliability law, two walls, the x1.1-per-10 slide, swept landings,
score = new-max landings only, coins every 5-25 platforms from the last
coin SPAWNED, the physical snowfall, 4 characters with their own physics
+ spin + snow reaction, 4 platform skins as materials, day/night places
(shader + world modulate + aurora + stars), the 4 powerups with the life
ring inside the jump button, parallax background, 8 SFX + theme.

## 3. The store shelves (hopper)

| shelf | items |
|---|---|
| CHARACTERS (skins) | ball 0 · Ice Cube 400 · Shard 600 · Eggy 800 |
| PLATFORM SKINS (plat) | sand 0 · rock 300 · grass 300 · steel 450 |
| PLACES (place) | day 0 · night 400 |
| POWERUPS (pw) | x2 250 · big 250 · speed 300 · slow 350 |

Price floor law: nothing priced costs less than 250 (flow_test).

## 4. Tests + QA

- NEW tests/tower_probe.gd (+tscn): 50+ laws — generation (walls, gaps,
  reachability, reliability), the walls bounce, the scoring law (first
  landing +1, lower pays nothing, skips pay exactly 1), the slide law
  (sleep/wake/x1.1/slow-halves), coin spacing, the powerup set (live,
  drain, big x1.28, x2 exactly once, slow halves), the snow (count, cap
  growth, stick, heavy = slower, shed), the characters (floaty/sluggish/
  slippery + roll/tumble/wobble), platform behaviors (patrol-in-walls,
  blink, vanish+respawn), the run ends below the screen, the cheat laws
- flow_test: hopper /10 + shop + shop shape + price floor + cheat laws
- Xvfb qa_tower: 14 shots → download/qa_v025/ (the owner's
  "test the visuals before shipping" rule)
- probe stability: 12/12 ALL PASS (the seat-solid + tour-lock lessons)

## 5. Ship

- version 0.2.5, code base 30340 (arm32 30341, arm64 30342)
- build.sh gogabox → both ABIs → cert 6db87aca... (family, overwrite-safe)
- backups → /home/z/my-project/download/GOGABox-v0.2.5-*.apk
- push → CI green → worklog → the owner plays
