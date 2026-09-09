# PLAN v0.3.7-2 — THE GREAT UNWIND (patch 2)

The owner's verdict after testing patch 1 on device. The box-side experiments
(age system, GOGAds, the ladder re-sort, the snake endless, the flip law) are
REMOVED - surgically, docs included, with the full specs archived in
`docs/goga_docs/brainstorms/THE_APP_STORE_QUESTION.md` so a future round can
resurrect them. The game-side patch-1 work the owner liked STAYS (pong glide,
maze controls/shop/finder/thumbnail, cosmic spud arsenal + gore, tower tails +
fit/cube-first/coin-truth/x2 laws, geometry rich decks + lore-behind, the
achievements overhaul, the honest badge law, the 5 SOON teasers, Key Singer
retired).

Six numbered owner fixes ride on top (his list):

1. **SNAKE ROLLBACK** - the whole Endless mode is OUT. `snake.gd` reverts to
   the pre-patch-1 file (zero endless refs in the old file - a clean revert);
   the registry sheds its `gogads` key.
2. **GEOQUARE PHYSICS** - Snowy Tower's geo cube moves EXACTLY like the
   normal square in the normal theme. THE REAL FLIP LAW dies whole: the
   flip vars, `_cube_body()`, `_update_flip()`, `_flip_settle()`, the
   ball/square/shard/egg `_cube_body()` gates, the draw-lift offset, the
   style-swap flip re-anchor. The square branch returns to the v0.2.6
   continuous tumble (the owner confirmed UNTOUCHED in v0.2.7); the ball
   rolls, the egg wobbles, the shard tumbles - in BOTH themes, one physics.
3. **FEED SORT = THE OLD ONE** - the ladder re-sort (chain reveals re-skinned
   as staggered orders/inbox mysteries, appear_after 0..11, inflated charge
   meters) is REVERTED in the registry: lanes/slasher/merge/dario/xo/invaders
   return to plain chains, matcher/pop_siege/cosmic_spud return to direct
   reveals with the 100/100/200 meters, geometry/maze return to direct
   appear_after 0. The feed lists like v0.3.7 again.
4. **GEOMETRY FLASH FLAT WAIT** - the patch-1 fix did not work because
   `_goga_setup()` still called `_gen_ahead()` after `_seed_world()`: the
   ready gate opened on a PREFILLED world (real chunks on screen no matter
   what the wait law fed). The prefill is gone - setup seeds the flat
   runway only, the ready tick keeps feeding flat ground + roof forever,
   and `_ready_start()` re-stamps the 6s calm runway from wherever the wait
   ended (the OPENING LAW holds after any wait length).
5. **GEOMETRY FLASH WORLD AUDIT** - the owner saw an orbit literally
   overlapping a block. Every pattern is tested by a new probe
   (probe_v037p2): per-pattern trials across levels 0-5 with invariants
   (orbit never inside a block/pusher/hazard, structures never intersect,
   pits obey the max-pit math). The audit caught THE GATE: its welcome
   orbit sat INSIDE the ground pillar (center at pillar edge, y deep in the
   stone). Fixed into the doorway lane. The whole deck is rated PASS.
6. **SNOWY TOWER READY CARD** - the controls line ("touch LEFT + slide...")
   is GONE from the tap-anywhere card. The guide owns teaching.

Plus the removals (the owner's "remove it completely, nothing from these
things"):

- **THE AGE SYSTEM, ALL OF IT**: the +3..+21 ladder (registry comments +
  BOX_MAX_AGE + age_num/age_allowed + the playable/workshop filters), every
  registry `age` key, the Meta AGES table (the NEW ladder AND the old
  everyone/kids/teens tags), age_label/used_ages, the ui_kit age chip
  branch, the menu AGE filter row + `_filter_age`, the guide AGE section,
  the pre-play AGE chip row, and THE "!" DOOR (the settings button, the
  agreement sheet, the age rates sheet, the `agreement_ok` progress key).
- **GOGAds, THE WHOLE SYSTEM**: the autoload (gogads.gd + its project.godot
  line), the baked index + ad art (`assets/gogads/`), the snake registry
  break, the host start/end break hooks. The UNITY banner (v0.2.6 shared
  plugin, pre-dates this round, other HAKORA projects share it) STAYS -
  the owner nuked GOGAds, not the house banner.
- **DOCS**: ADS.md becomes a tombstone pointing at the archive; AGENTS.md
  4.3 + the core-file table row go; ADDING_A_GAME.md sheds the age/gogads
  words. The FULL specs (GOGAds + the age ladder + the legal tier text)
  are archived in THE_APP_STORE_QUESTION.md under a new section.

Tests: flow_test restored to the old ladder/mystery/charging semantics
(minus the retired keys tests, plus the honest-badge interactions that
stay), probe_v037p1 + qa snake_endless rig deleted, probe_v037p2 written
(world audit + same-physics + flat-wait + feed-restore laws), qa_v037p2
rigs (tower same-physics + gf flat wait + the keeper rigs). test.sh gogabox
must be ALL PASS. Version 0.3.7-2 / 30820 (arm32 30821 / arm64 30822).
NO release (the law).
