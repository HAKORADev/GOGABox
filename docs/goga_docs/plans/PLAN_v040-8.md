# PLAN v040-8 — the owner's v040-6 + v040-7 report, worked to the bone

Two reports, one version. Heavy War carries the v040-6 fixes, Rock Breaker
carries the v040-7 fixes, and the TOP-UP system graduates from the doc into
the box (the owner: "if you made the top-up idea real now, it will help me").

## A. THE TOP-UP SYSTEM (built, per TOPUP_SYSTEM.md)

- THE FRAMEWORK: the registry entry grows an optional `currency` block
  (`{name, rate, tint}`) + a `coin_api` script path. A game joins the
  top-up by declaring — no game ids anywhere in the menu code.
- `core/game_coin.gd` (GameCoin): `games()` (every currency-carrying game,
  registry order), `balance(id)`, `add(id, n)`, `rate(id)`, `convert()`.
- Adapters: HWMeta (`scrap` wallet) + rockbreaker (`rockcoins` wallet) —
  each exposes the two static calls the registry points at.
- THE MENU: the main-menu wallet chip is TAPPABLE → the top-up sheet:
  BALANCE = nn (coin icon) → TOP-UP → the game picker as VERTICAL CARDS
  (the guide-view law: thumb, title, wallet, rate line) → a game's
  top-up screen: the game's coins first, the GOGACoins under, the rate
  line, the amount field (hard-capped at the wallet, live "= nn" preview)
  → TOP-UP → confirmation → settle (coins down, game coins up).
- THE RATES: 1 GOGACoin = 5 scrap (Heavy War), 1 GOGACoin = 5 rockCoins
  (Rock Breaker) — the owner's "1 gogacoin is just 5 game coins".

## B. HEAVY WAR (the v040-6 report)

1. THE SHOP SEAT: the GOGABox SHOP leaves the main menu (menu = DEPLOY +
   SCRAP SHOP) and rides the in-game top bar as a HUD button (top left).
2. THE UPGRADES BACK IN THE BOX SHOP: the box shop sells the same 8 shelf
   items for GOGACoins (ceil(scrap price / 5)) — GOGACoins unlock levels
   without grinding scrap.
3. THE KILLS WIDGET IS DEAD: the custom top-right canvas panel is gone;
   the score lives in the BOX score chip wearing the plane icon (the pop
   siege icon law); the wave counter rides the top-left widget.
4. THE SCRAP WIDGET: a top-bar chip next to the score/coins (pop siege
   law) — the bottom-left canvas widget is dead.
5. THE WAVE LAW: waves roll their own type — KILLS (a quota to kill) /
   TIME (survive the clock) / BOTH — random per wave, the clocks grow as
   the waves climb (wave 1 is NOT 3:00).
6. THE HONEST COUNTER: a leaver (an enemy that exits alive) never counts
   as killed — the quota stays, a replacement spawns; the REMAINING
   widget shows exactly what the wave is limited by (clock / jets / both).
7. THE TWO-STATE LAW: hover/shadow machines APPROACH their station,
   loiter shooting, then LEAVE for good — no more ping-pong flips.
8. THE DIVE ANGLE: the kamikaze lerps its body angle into the dive.
9. THE TANK SCALE: everything ÷3.

## C. ROCK BREAKER (the v040-7 report)

1. THE TAP LAW FIXED: every button inside the shop/upgrade scrolls
   registers as a tappable (the BoxScroll law) — the freeze-on-press is
   dead; buttons activate.
2. THE TEXT PURGE: no em-dash essays, no meta lines ("no third shelf...")
   — the shelf speaks in names, levels and prices only.
3. THE REAL ASSETS: the Crazy Caves study sprites (cc/ outside the repo)
   are code-modified into OUR assets (the usage law: zero original bytes
   ship): desaturated + re-lit rock bases (3 sizes × 5 materials) tinted
   at runtime by the heat ramp, 3 baked crack overlays, the carriage
   rebuilt from the carts + our cannon barrel (5 skins), the cave
   backgrounds recolored into the 5 places, rail ground strips.
4. THE SHADER LAW: the sky is a real canvas_item shader (gradient,
   drifting fbm clouds, twinkling stars, sun/moon glow per place), the
   neon rocks wear a fill-glow shader — Godot does the pretty.
5. THE BOUNCE LAW: every rock BOUNCES off the ground (the original's
   law) — nothing shatters on the floor; the side walls are OPEN (a
   regular rock exits and frees its side seat), only the golden and the
   mystery rocks never leave (they bounce off walls + floor forever).
6. THE SPAWN LAW: both sides at wide random heights/angles/speeds, arcs
   that are THROWN UP then fall, bursts of 1..4 rocks per wave of the
   spawner, the 15/side + 50 cap + hold-at-45 laws untouched.
7. THE SHOT LAW: bigger balls with comet trails at a visible speed.

## D. THE GATE

- qa_v0407_rock extended: the bounce law, the open walls, the leaver
  honest counter (heavywar), the wave-type roll, the GameCoin converts.
- hw5_probe re-run green; flow_test ALL PASS.
- config 0.4.0-8 / code base 31180.
