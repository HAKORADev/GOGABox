# PLAN v0.3.4 — COSMIC SPUD (the Brotato-competitor)

The GDD lives at `docs/goga_docs/gogames_ideas/cosmic_spud.md` (the law).
This file is the build tracker. The owner's sequence: GDD -> plans/docs ->
asset hunt -> docs update -> audio analysis -> verify assets -> BUILD -> he
tests v033-patch + v034 TOGETHER at the end. NO auto-release (the law).

## Phase A — paper (this round)
- [x] A1 GDD written (identity, camera law, 6 starts, 12 enemies, 12
      weapons x3 tiers, 6 allies, drafts with teeth, 18-node tree, the
      3-currency ledger, the GogaShop + wave shop, themes day/night,
      VFX/SFX/music plan, achievements)
- [x] A2 matcher v0.3.3-8 (the deadlock law) shipped first — done,
      CI green (6ccaa7a)
- [ ] A3 PLAN_v034 tracker (this file)

## Phase B — the asset hunt (DONE)
- [x] B1 web hunt: 2204 CC0 sprites on disk (kenney topdown-shooter /
      desert-shooter / tanks / particle pack / rts-scifi / tower-defense /
      tiny-town + OGA wasteland/seasons/potatoes) - raw cache outside the
      repo, provenance in assets.manifest.json + the MANIFEST.md
- [x] B2 web hunt: 439 audio files (kenney sci-fi/impact/ui/digital/rpg +
      OGA gun impacts + 8 music candidates), all CC0, ffprobe-verified
- [x] B3 the pipelines: tools/v034_cs_art.py (75 repo assets: SPUDNIK, the
      12 enemies, 3 bosses, 12 weapon icons + world guns, 11 projectiles,
      pickups, 8 props, the ferris silhouette, 4 SEAMLESS theme grounds,
      the kenney fx subset) + tools/v034_cs_audio.py (38 files: 28 curated
      SFX + 5 music loops + the wave horn trim + 5 numpy synth gaps -
      hurt/boss roar/frost/rail/aura tick), 38/38 ffprobe-verified

## Phase C — the build (DONE)
- [x] C1 cs_meta.gd — the ledger (cosmic coins, char XP/level, the armory
      with tiers, allies, themes, the tree, the loadout, run records)
- [x] C2 cosmic_spud.gd CORE — arena 2400x1350 + the camera law (follow +
      clamp + the ZOOM LAW for huge logical viewports) + the stick ghost +
      the aim/auto-fire target law (boss > elite > closest)
- [x] C3 enemies — 12 types + flocking + the python complex trio (the aura
      wraith 250px/15 per s-tick, the mender 500px +10/0.5s, the TRI-SHIELD
      3 rings with local-frame crack intervals + the push-out) + elites x4
      affixes + the death-splits (brood/splitter) + boomling fuse + charger
      wind-dash + orbiter orbit-dive + spitter keep-and-shoot
- [x] C4 bosses — THE HEAP (slam + summons + charge) / THE PRISM MATRIARCH
      (4 rings + radial bursts + self-mend) / SPUD REAPER (triple charge +
      teleport-behind + the 160px aura) + the cycle scaling
- [x] C5 weapons x12 + projectiles + crit/burn/chill/lifesteal/pierce-all +
      the orbital strike + the gravity well + the boomerang return trip
- [x] C6 waves + endless difficulty + the spawn stream/burst + XP/coin/
      heart drops + the wave-clear heal + the leftover-to-gems sweep
- [x] C7 drafts — the wave draft (11 cards, gives AND takes, weighted,
      skip) + the XP-level draft (11 pure picks, queues)
- [x] C8 wave shop (weapons/supplies/allies/merges + the discount node) +
      the GOGASHOP meta UI (weapons/allies/themes/loadout tabs, cosmic
      coins, the tier gates, the sell law note)
- [x] C9 the skill tree (18 nodes, chains + level gates, one-by-one) +
      merging everywhere (the 50% law, the WEAPON LAB gate, FOUNDRY -25%)
- [x] C10 themes x2 day+night (4 baked grounds + props + tints + music)
- [x] C11 music/SFX wiring (theme day/night music, the boss layer, 24+
      cs_ sfx through Jukebox)
- [x] C12 death bank (coins -> wallet, kills*2+wave*8 -> char XP, the
      record) + achievements (5) + the registry entry (graduated from the
      spud teaser, /200 + fee 50 + landscape) + the composed thumb
- [x] C13 cs_probe.gd 45 checks 0 fails (data laws, the camera law + zoom,
      aim, contact, aura, mender, the ring carve/pass law, the score law,
      the break, the draft law, the XP law, the shelf/merge law, the 3
      bosses, the bank, the wallet, the tree gates) - flow_test ALL PASS
      (the registry counts, the roadmap graduation, the mystery queue, the
      feed order, the all-games boot incl. cosmic spud) - invaders probe
      re-pointed (11/4) ALL PASS - Xvfb rigs (arena/shield/boss/option/
      night) eyeballed - version 0.3.4 / 30470
