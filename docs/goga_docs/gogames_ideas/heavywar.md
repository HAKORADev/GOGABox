# HEAVY WAR — the GDD (v040)

> The owner's own spec, the v040 mission. The heavy-weapon-like graduates
> from `FUTURE_GAMES.md` (the SOON shelf's first name). The working brain
> lives in `heavywar/` (mission / study / plan / journal).
> THE NAME LAW (owner): the game is **HEAVY WAR** — "calling it tank war
> takes a different name that we may do somehow a game called tank wars
> later and this game is not tank wars, you only play as a tank in a war".

## The shape

- **Horizontal only.** No levelling screen, no separate survival mode —
  ONE rogue-like survival run that ALWAYS goes up. Endless.
- **The original's structure is replaced whole.** Story levels, per-level
  bosses and the survival split are gone; what stays is the FEEL: the tank,
  the sky full of planes, the drops, the armory, the nukes.

## Places in one run

- The original's many places all live inside ONE run. Each place wears its
  own EXCLUSIVE enemies next to the SHARED ones.
- **THE TUNNEL LAW**: when the run changes place, the tank moves through a
  TUNNEL — the transition point. No enemy waves or spawns appear for a while
  BEFORE the tunnel and a while AFTER it. The tunnel is the breath between
  places.
- A place may take 3–10+ minutes.
- **Places are SHUFFLED every run** — a new game never walks the same order.

## The friend helicopter

- Drops **shields — up to 3 layers**.
- Drops **nukes**.
- Drops **laser weapon components**.
- Drops a **life** (max 3 lives).
- Drops **GOGACoin after each 3 places survived**.

## Bosses

- **After each 5 places, a boss comes.** Maybe +10 bosses.
- For endlessness the bosses make COMEBACKS: they shoot more, act faster,
  wear more — the same faces, meaner every visit.
- **Each boss killed pays 1 upgrade point**, and right after the boss dies
  the **upgrade menu** opens: spend points, increase/decrease purchased
  levels — transfer points where they should go.

## The armory (6 upgrades x 5 levels)

- 6 upgrades like the original's six, but each takes up to **5 levels** —
  **30 points** total (the original only ever let you reach 10 of 18).
- **30 points = 150 places survived — a very very long-term target.**
- **Upgrades are permanent here** (the allocations and the banked points
  survive across runs — the grind is real, nothing is wiped by a death).
- **The first 2 upgrades are open from the start; the other 4 need buying
  from the shop first, with high prices. The laser weapon needs buying for a
  too-high price.**

## Life, score, coins

- The tank wears **life points — each hit destroys one life**. 3 max, no
  extra lives beyond 3.
- **Score is based on kills**: every destroyed thing pays 1 point, except
  the 10/11 special enemies — each of those pays more, 10/20/30/40 and up.
- **Score bonus /500** (the GOGABox end-of-run conversion).
- **A life point returns after each 1000 score — max 3.**
- **Nukes are max 3.**

## Controls (the whole law)

- **Swipe left-right on the LEFT screen side** — moves the tank.
- **Tap or hold on the RIGHT side** — shoots.
- **Tap the MIDDLE area** (a proper dead area, an accurate place) — uses a
  nuke.
- That is all.

## Flow + shop

- First thing on boot: **"TAP ANYWHERE TO START"**. No optionals, no options
  menu — nothing before the gate.
- **The shop**: tank skins ONLY as cosmetics (no game themes — the scale of
  this game makes themes almost impossible) — plus the upgrade-unlock
  purchases (the 4 locked upgrades) and the laser unlock, per the armory law.
- Top bar widgets: built accurately, with proper designing (lives, nukes,
  shields, score, coins — the war room strip).

## The pack (the study source)

- The owner's pack of the ORIGINAL game: art, SFX, music, and the game
  logic as bare XML (naked assets — no decompiling needed).
- Take the art, SFX and music and **modify them accurately** — colors,
  sizes, view each thing to learn how it integrates. **Do NOT take the
  original's character art** (the tank body / mascot faces) — we do not
  need them.
- The XML carries the real logic: the dropping logic, the RNG, the enemy
  tables — study it and remake it with code-designing.
- Pack status: **the Drive link is ToS-blocked at Google's side** (see
  `heavywar/00_MISSION.md`); re-upload pending. The build is data-driven so
  the pack lands as a swap + tune pass.

## Tests

- The brutal and critical house tests: the headless qa rig (laws, economy,
  waves, boss menu, drops), flow_test's registry + boot laws, the Xvfb film
  rig for the visual truth. "do not forget the brutal and critical tests".
