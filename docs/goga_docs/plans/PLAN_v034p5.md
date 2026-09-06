# PLAN v0.3.4-5 — COSMIC SPUD PATCH 5 (the owner's full playtest round)

**Round:** 2026-09-06. The owner finally felt the rogue-like loop ("now it
really feels like a real rogue-like game") and shipped a full report. This is
likely the last CS patch for a while — the owner is planning the next game's
GDD in parallel, so quality bar: bug-free, probed, QA-shot.
**Status:** DONE — one commit, CI green, no release (the law). All 18 laws shipped: cs_probe 186/0, flow_test + every game probe green, qa_v034p5 shots eyeballed.
**Version:** 0.3.4-5 / version_code_base 30520.

## THE LAWS

### A. THE FLOW BUGS (the owner's three stuck reports)
1. **THE RIGHT-SHEET LAW** — the patch-4 rename left the wave market's buys
   rebuilding THE SHOP (the universal list). Every market buy (weapons /
   items / supplies / allies) now rebuilds THE WAVE MARKET; the merge-bench
   MERGE rebuilds THE MERGE BENCH; a SELL rebuilds its own host sheet. No
   more "bought something and the universal shop opened".
2. **THE ARMORY TABS LAW** — the armory's tab buttons rebuilt THE SHOP
   (copy-paste casualty). They rebuild THE ARMORY.
3. **THE RESUME LAW** — `_cs_close_top` now calls `_resume_break()` when the
   stack empties during a break: the X / CLOSE buttons can NEVER strand the
   chain anymore (only the Android back had the safety before).
4. **THE FRESH DOOR LAW** — CS sheets wear ids now. When a close reveals THE
   DOOR, the door rebuilds from live state (buying the place in THE SHOP and
   returning to the door no longer shows a stale "BUY 400" card). The
   armory's BACK in boot reopens the door through `_cs_reopen` — the old
   path PUSHED a second door on top of the first (a growing door leak).
5. **THE TOP BUTTONS LAW** — the box's HUD layer wears PROCESS_MODE_ALWAYS
   in Cosmic Spud: the top-left "<" and the top SHOP button work over the
   paused sheets now (the owner's "first time it worked, now it doesn't" is
   dead — it works every time). The BACK LAW still guards the door.

### B. THE COMBAT TRUTH (what the owner saw and what it really was)
6. **THE WRAITH TRUTH LAW** — the "violet wave-5 enemy shooting invisible
   stuff" IS the AURA WRAITH: its aura damage tick played the hurt SFX with
   no projectile. The wraith's aura now READS: a big breathing violet field,
   a pulse ring on every damage tick, and the baked-in pale ring is GONE
   from the regenerated art.
7. **THE HEALER IN THE OPEN LAW** — the MENDER always healed friends in
   500px with a medic crest nobody could read. Its heal aura now DRAWS (a
   green field + rising cross motes on the healed).
8. **THE WARDEN LAW** — new enemy (from wave 9): THE WARDEN projects a
   golden aura; friends inside take HALF damage from every hit. The probe
   asserts the half-damage math; the art joins the family.
9. **THE FIRST-GLANCE LAW** — the first time each special enemy appears
   (spitter / wraith / tri-shield / mender / warden), a one-line hint banner
   speaks its truth once per save (meta-remembered). No more "what is this?".
10. **THE AIM SIGHT LAW** — the aim aid is back, PROPER this time: a calm
    straight line from the muzzle along the aim to the first weapon's real
    range — steady low alpha, a soft brighter core, a small end dot. It
    never wobbles and never flickers (the old ugly laser stays dead).

### C. THE UI
11. **THE BIG TEXT LAW** — every CSUI font size wears `_fs()` = x1.75
    (the owner: "like 75% bigger"). Applied inside the four CSUI helpers
    (`_cs_label/_cs_button/_cs_coin_button/_cs_text_w/_cs_text_h`), so every
    sheet, card, chip and meter label grows at once and the TEXT-FIT
    measurements stay truthful. The meters/HUD boxes that would clip got
    real heights/widths; the box's own top bar is NOT touched (owner's
    exception); floaters/banners/elite tags scale too.
12. **THE INFO LAW** — a new top-left INFO button opens the run's truth:
    the header (wave, kills, collected CC, collected XP, score, level) and
    then one 5-line block per stat in the owner's exact shape:
    `NAME:` / `base: nn` / `up: +nn (+nn%)` / `down: -nn (-nn%)` /
    `result: nn`. The up/down sums are tracked for real in `_apply_stat`
    (drafts, level packs, items, supplies, skills all funnel there).
13. **THE CLEAN TITLES LAW** — the "NAME - extra details" em-dash disease is
    dead: titles and section headers say their name and stop
    ("THE PLACES", "ITEMS", "LEVEL UP", "WAVE 3 CLEARED"...).
14. **THE SCROLL LAW (verified)** — every CS sheet's shelf scrolls; the new
    INFO sheet scrolls too; the stats/skills/tree sheets re-checked.

### D. THE WEAPONS
15. **THE TIER RANGE LAW** — tiers now grow RANGE too (T2 x1.1, T3 x1.25)
    next to the dmg/cad growth, and every weapon card shows the EFFECTIVE
    numbers of its tier: `dmg / cad / rng` (market offers, armory, loadout,
    merge result line).
16. **THE VARIED HOLSTER LAW** — the six starts no longer all drop in with
    the same first gun: each start wears a signature starter in slot 1
    (soldier=SMG, ranger=RUSTY RIFLE, brawler=SCATTER SPUD, engineer=SPUD
    SMG, pyro=SCATTER SPUD, frostbite=RUSTY RIFLE) when owned — the loadout
    reorders itself on DROP IN.
17. **THE MELEE LAW** — weapon #13: THE PEEL CLEAVER, the game's first
    melee arm: a fast 120-degree arc chop (short range, hits everything in
    the swing) with a clean fading slash-arc VFX and its own chop SFX. The
    cards read `rng 130 (melee)`. Merging climbs it like every gun.

## THE ORDER
1. A1-A5 (flow) → 2. B6-B10 (combat) → 3. D15-D17 (weapons) → 4. C11-C14
   (UI) → 5. art + sfx → 6. cs_probe patch-5 laws → 7. qa shots → 8. docs
   (GDD patch5 + the tracker) → 9. version + push + CI.
