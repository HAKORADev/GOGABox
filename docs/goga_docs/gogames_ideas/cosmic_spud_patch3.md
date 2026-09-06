# COSMIC SPUD - PATCH 3 GDD (v0.3.4-3)
The owner finally played past the optionals and reported a full round. Every
item is a law with a name; the probe (cs_probe 132 checks) enforces them.

## 1. THE HUD LAW
The box chrome chips died WHOLE (v0.3.4-2 hid only their labels - an empty
score panel floated next to the icon-only coin chip: the owner's "empty
widget"). The game builds its own top-right stack: COSMIC COINS (big),
SCORE (yellow), KILLS (red), GOGACoins (green, live wallet + this run's
riders). ARM/LV stay on the left. KILLS left the small sub-row.

## 2. THE SILENCE LAW
The gogacoin never announces itself: no "hides in the swarm" banner, no
"carrier dropped the coin" banner, no "+1 wallet" banner, no fanfare sfx,
no CARRIER! chip. The glint arc on the carrier + the counter tick are the
only tells. Silent is cool.

## 3. THE COIN SIZE LAW
The world gogacoin pickup draws at 0.16 scale of the box's big ui coin art
(it rendered "very very weirdly HUGE" before).

## 4. THE FLASH LAW
The muzzle flash was drawn UPRIGHT at the gun tip (a standing candle).
Tex particles now carry a rotation; the flash rides the barrel, bigger.

## 5. THE SHARED CONTACT LAW
The old splatter law (the enemy's remaining HP is the damage, then it dies
on your skin; the 0.6s iframe silences everything after) is DEAD.
- Per-enemy contact cooldown 0.55s; every tick of an ongoing collision:
  - the player takes the enemy's scaled damage (armor, dodge, contact_cut
    apply) with sfx + red number + flash EVERY time - a contact tick uses a
    SHORT 0.28s guard, never the long iframe (the owner's "still get hit
    with no feedback" bug);
  - the enemy takes THE RAM back: 8% of its max HP + 3 + armor (halved for
    bosses) with its own number + a dust burst at the contact point;
- a full-HP mender touch no longer deals 1000 damage - its real attack does.

## 6. THE BREAK CHAIN
clear -> WAVE DRAFT (pick 1 of 3, NO reroll - SKIP only)
      -> THE WAVE MARKET (tabs ITEMS / WEAPONS / ALLIES; supplies live in
         items; YOUR LOADOUT with SELL lives in weapons; the REROLL lives
         here with u3's free shuffle first; THE HOLD DECK = up to 5 offers
         pinned, they survive rerolls, freeable, THIS market visit only,
         never saved)
      -> THE MERGE BENCH (its own menu, all pairs, the LAB lock reason)
      -> THE STATS MENU (one point per XP level, packs cost 1-3, PIERCE ALL
         once, closable=false - no X; mid-wave level-ups QUEUE for the
         break, they never interrupt)
      -> THE SKILLS MENU (when unspent points wait)
      -> next wave.
A break that loses its sheet (back button, a shop visit) falls back to the
market - the chain can never strand the player.

## 7. THE SKILLS LAW (the second point currency)
SKILL POINTS: one per 100 kills, LIFETIME (banked + live run), they never
reset with a round. THE TEN:
| skill | cost | effect |
|---|---|---|
| SHATTERED SHIELD | 2 | blocks one hit whole, reforms 12s later (blue halo + shatter burst) |
| LEECH AURA | 2 | enemies within 140px bleed 2 HP/s each to you (3 max) |
| FROST AURA | 2 | enemies within 170px crawl 30% slower, always |
| GHOST ROUND | 2 | a shot that hits you FLIES THROUGH and strikes enemies behind for half damage (the owner's own idea) |
| STARCH RAGE | 1 | below 35% HP: +40% damage |
| STATIC BURST | 1 | every 6s lightning zaps the 3 nearest enemies |
| TWIN TAIL | 2 | a ghost gun answers every volley backwards at 40% |
| ADRENALINE ROOT | 1 | a dodge revs +80% attack speed for 2s |
| GOLDEN GUT | 1 | +25% cosmic coins from every source |
| MAGNETIC SKIN | 1 | magnet +60%, hearts heal +50% |
The SKILLS button joins the boot door; the chain enters the menu whenever
points wait.

## 8. THE UNIVERSAL SHOP LAW
THE SHOP = the GOGACoins store and the HUD button opens it at ANY phase
(pauses the run). Header wears BOTH wallets always; tabs WEAPONS / ALLIES /
PLACES / LOADOUT; places say the price in full GOGACOINS words (the border
law). "GOGASHOP" and "THE ARMORY" are dead names. The wave market remains
the in-run cosmic-coin store (the owner: everything in-run is game coins).

## 9. THE BIG-UI LAW
The door's start cards grew (64px art, 12px stats, 16px names), the theme
cards grew, the wallet line grew. Every CS sheet scrolls BOTH axes (wide
grids read left-right). THE HUG LAW's second pass: autowrap labels only
know their real wrapped height one frame after layout - the scroll re-hugs
then, so no measured ghost voids.

## 10. THE WOW PASS
Camera shake (hurt 5, contact 3, explosions 4, boss death 10, decay 24/s).
The low-HP red vignette pulse below 30% HP. Pickup sparkles (coins/hearts),
the level-up golden-blue burst. The ram dust + the shield shatter + the
static zap rings.

## 11. THE PROBE
cs_probe 89 -> 132 checks, 0 fails: the shared contact laws (both sides,
cooldown, never-silent), the hold deck (cap, survives reroll, shelf size),
the skills (points math incl. the 100th live kill, buy-once, ghost round
pass-through, shield block + reform, frost field), the stats pack
(multi-cost), the full chain walk (draft no-reroll -> market tabs+reroll ->
bench -> stats no-X -> skills -> wave 2), the break law (back reopens the
market), the universal shop (button at any phase, no X, GOGACoins chip,
PLACES tab, BACK resumes), the HUD widget law, the coin size, the silence.
