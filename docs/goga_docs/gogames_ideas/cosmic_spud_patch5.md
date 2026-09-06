# COSMIC SPUD — PATCH 5 (v0.3.4-5, the owner's full-playtest round)

> "ok tested it and now it really feels like a real rogue-like game" — and
> then the report. This patch fixes every line of it. Likely the last CS
> patch for a while: the owner is planning the NEXT game's GDD while this
> ships. The plan lives in `docs/goga_docs/plans/PLAN_v034p5.md`.

## THE FLOW LAWS (the three stuck reports)

1. **THE RIGHT-SHEET LAW** — the patch-4 rename had left every WAVE MARKET
   buy rebuilding THE SHOP (the universal GOGACoins list): buying anything
   in the market hijacked the sheet, and closing it stranded the break
   ("the game was half running but stats and skills not came"). Every
   market buy now rebuilds THE WAVE MARKET; the merge rebuilds THE MERGE
   BENCH; a SELL rebuilds its host.
2. **THE ARMORY TABS LAW** — the armory's tab buttons rebuilt THE SHOP
   (copy-paste casualty of the same rename). Tabs stay in THE ARMORY.
3. **THE RESUME LAW** — `_cs_close_top` resumes a stranded break when the
   stack empties (the X/CLOSE buttons carry the safety only the Android
   back had), and self-heals an already-empty stack. The chain steps pop
   through `_cs_pop_top` (raw, no resume) so they can never double-open.
4. **THE FRESH DOOR LAW** — CS sheets wear ids; when a close reveals THE
   DOOR it rebuilds from live state. Buying the place in THE SHOP and
   closing can never show a stale "BUY 400" card again (the owner's
   "there is conflict, it should get updated"). The armory BACK no longer
   PUSHES a second door on top of the first (the door leak).
5. **THE TOP BUTTONS LAW** — the box's HUD top bar (the "<" back + SHOP +
   the new INFO) wears PROCESS_MODE_ALWAYS in Cosmic Spud: the top buttons
   answer over every paused sheet, every time (the owner's "first time it
   worked, now it doesn't" is dead).

## THE COMBAT TRUTH (what the owner saw, and what it really was)

6. **THE SPECIAL-KEY LAW (the root cause)** — `_spawn_enemy` never copied
   `aura / aura_dps / ward / heal` from the data table into the enemy
   dict. The wraith's aura DAMAGE worked (kind-checked defaults) but its
   aura VISUAL never drew (`e.get("aura", 0.0)` was always 0) — the owner
   only ever saw the pale ring BAKED INTO the art. Every special now
   carries its own numbers.
7. **THE WRAITH TRUTH LAW** — the "violet wave-5 enemy shooting invisible
   stuff" WAS the wraith's aura damage tick (hurt SFX, no projectile). Its
   ring now READS: a fat breathing violet field + a pulse that rides the
   ring on every damage tick. The baked pale ring is gone from the
   regenerated art.
8. **THE HEALER IN THE OPEN LAW** — the mender's 500px heal field draws
   (green care) — the medic crest nobody could read now explains itself.
9. **THE WARDEN LAW** — new enemy (wave 9+): THE WARDEN projects a gold
   ring; friends inside take HALF damage (probe-proven math, the warden
   never wards itself). New art in the family style.
10. **THE FIRST-GLANCE LAW** — the first time a spitter / wraith /
    tri-shield / mender / warden appears, a one-line hint banner speaks
    its truth ONCE per save (meta-remembered). The tri-shield's sky-blue
    rings say "shield: shoot through the gaps" without the owner having
    to ask what the 3 circles are.
11. **THE AIM SIGHT LAW** — the aim aid is back, PROPER: a calm straight
    line from the muzzle to the first gun's real reach — steady alpha, a
    soft brighter core, a small end dot. Never wobbles, never flickers
    (the ugly old laser stays dead).

## THE WEAPONS

12. **THE TIER RANGE LAW** — tiers climb RANGE too (T2 x1.1, T3 x1.25)
    beside the dmg/cad growth, and every weapon card (market offers,
    loadout, armory, merge result) speaks the EFFECTIVE tier numbers
    through one helper (`_weapon_stat_line`).
13. **THE VARIED HOLSTER LAW** — the six starts no longer all drop in with
    the same first gun: each wears its signature starter in slot 1
    (brawler=SCATTER SPUD, ranger=RUSTY RIFLE, ...) on DROP IN.
14. **THE MELEE LAW** — weapon #13: THE PEEL CLEAVER, the game's first
    melee arm: a fast 120-degree arc chop that bites everything in the
    swing (a sweeping slash-arc VFX + its own chop SFX). Cards read
    `rng 130 (melee)`. It merges and tiers like every gun.

## THE UI

15. **THE BIG TEXT LAW** — every CSUI font size wears `_fs()` = x1.75 (the
    owner: "like 75% bigger"). Applied inside the four CSUI helpers so
    every sheet, card, chip and meter grows at once, and the TEXT-FIT
    measurements stay truthful. The meters/HUD boxes grew real heights
    (HP 34, wave 42, the right stack 250 wide); the door's start grid went
    two-across (three big cards overflowed the portrait door); the box's
    own top bar is the owner's one exception.
16. **THE INFO LAW** — the new top-left INFO button opens the run's truth:
    the header (wave / kills / score / collected CC / collected XP / LV)
    and one five-line block per stat in the owner's exact shape:
    `NAME:` / `base: nn` / `up: +nn (+nn%)` / `down: -nn (-nn%)` /
    `result: nn`. The deltas file into up/down ledgers inside
    `_apply_stat` (drafts, level packs, items, supplies all funnel there);
    the model is probe-readable (`_info_stat_rows`).
17. **THE CLEAN TITLES LAW** — the "NAME - extra details" em-dash disease
    is dead: "THE PLACES", "THE GUNS", "THE LAB", "THE CREW", "ITEMS",
    "WEAPON OFFERS", "LEVEL UP", "WAVE 3 CLEARED". Titles say their name
    and stop.
18. **THE SCROLL LAW (verified)** — every CS sheet's shelf scrolls (the
    door, shop, armory, market, merge, stats, skills, tree) and the new
    INFO sheet scrolls too.

## VERDICT

- cs_probe: 186 checks 0 fails (38 new patch-5 laws).
- flow_test ALL PASS; matcher 211/0; invaders/slasher/dario/merge/pong
  ALL PASS.
- qa_v034p5 Xvfb shots eyeballed: the door (big text, WORN card, no
  overflow), RUN INFO (the five-line blocks), the armory (effective stat
  lines), the arena (the wraith's violet field, the warden's gold ring,
  the mender's green care, the aim sight).

## VERSION

0.3.4-5 / version_code_base 30520. NO release (the law).
