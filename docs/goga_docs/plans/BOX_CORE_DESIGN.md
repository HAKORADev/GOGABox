# GOGABox — Core Design (v0.0.4)

> GOGABox = **GO**dot **GA**me **Box**. One Android app that hosts many mini-games,
> Cartoon-Network-GameBox style but our own: arcade-warm, for everyone (not
> kids-only, not too mature). Ported from HAKORADev/Python_Game_Box_PGB v1.3.8
> and grown from there. This is the ONE doc that defines the machine. Read it
> fully before adding a game.

## 1. Pillars

1. **Arcade endless**: every game is a score-chasing loop. No long tutorials,
   no level maps. Tap a tile → insert coins (entry fee) → play → earn GOGACoins.
2. **One engine, many worlds**: shared infra (save, wallet, scores, audio, ads,
   touch helpers, UI kit) is written ONCE in `game/core/`. Each game is a folder
   in `game/games/` with its own art, physics and feel. Games do NOT have to
   match each other visually — the Box chrome (menu, buttons, currency) does.
3. **Adding a game = blinking**: create the game's OWN ROOM -
   `game/games/<id>/<id>.gd` (one folder per game, extending `GogaGame`),
   add ONE entry to `game/core/registry.gd`, drop a thumbnail in
   `assets/thumbs/<id>.png`, add a test case. No core edits.
4. **Games are their own world**: launching a game HIDES + freezes the menu
   (main.gd on_game_entered) - no windows-on-top, no taps leaking into the
   feed. Returning restores it (on_game_closed).
4. **Fair economy**: playing always *nets positive* for a decent run. The box
   can never soft-lock (FREE PLAY kicks in below the cheapest fee).

## 2. The loop (why a player returns)

    MENU (amber arcade grid)
      └─ tap game tile → GAME PAGE (stats, achievements, reset, PLAY)
            └─ PLAY (entry fee deducted) → RUN
                  ├─ collect GOGACoins in-world + score→coin conversion at the end
                  ├─ optional REWARDED AD: double the run's earnings
                  └─ every 3rd run-end → interstitial
                        └─ back to MENU with fuller wallet → unlock the next game

- **GOGACoin** = the shared meta-currency. Every game ALSO has its own flavor
  (Snake's apples, Slasher's combos...) but coins collected in-world ARE
  GOGACoins. High score and GOGACoins are independent systems.
- **Entry fee** per run (see registry). Keeps the coin economy meaningful.
- **Unlock prices** gate games: Snake is free; the rest cost 150→400 coins.
- **Anti-softlock**: if wallet < cheapest fee of an owned game → that game's
  PLAY shows FREE (no fee).

## 3. Architecture

    projects/gogabox/
    ├── Docs/                     # our brain dump: plans/ + ideas/ (NOT shipped)
    │   ├── plans/                # design docs (this file), port notes, roadmaps
    │   └── ideas/                # brainstorms, new game sketches
    ├── game/
    │   ├── main.tscn/gd          # bootstrap: builds menu, owns scene routing
    │   ├── core/                 # <- THE ENGINE (shared, stable)
    │   │   ├── store.gd          # autoload `Box`: save, wallet, unlocks,
    │   │   │                     #   hiscores, achievements counters, settings
    │   │   ├── audio.gd          # autoload `Jukebox`: music/sfx buses + volume
    │   │   ├── registry.gd       # `GameReg`: the game list (id, price, fee, ...)
    │   │   ├── ui_kit.gd         # `Arc`: buttons/panels/toasts/icons, palette
    │   │   ├── touch_kit.gd      # `TouchKit`: tap/swipe/drag detectors
    │   │   ├── game_base.gd      # `GogaGame`: base class every game extends
    │   │   └── game_host.gd      # `GameHost`: launches a game, orientation
    │   │                         #   switching, banner policy, run reporting
    │   ├── menu/                 # menu grid + game page + settings + unlock sheet
    │   └── games/                # <- THE WORLDS (one file each for v0.0.1)
    │       ├── snake.gd          # grid snake, swipe, in-grid coins, skin shop
    │       ├── merge2048.gd      # swipe merge puzzle
    │       ├── lanes.gd          # 3-lane dodge, tap left/right, speed ramps
    │       ├── rally.gd          # endless pong rally vs AI, drag paddle
    │       ├── hopper.gd         # vertical platform hop (Snowy Tower)
    │       └── slasher.gd        # landscape fruit slasher, swipe trails
    ├── assets/
    │   ├── fonts/                # Kenney Rocket (display) + Kenney Mini (UI) [CC0]
    │   ├── ui/                   # box chrome: bg, logo, coin, icons  (PIL-made)
    │   ├── thumbs/               # 480x320 tile art per game        (PIL-made)
    │   ├── audio/                # CC0 packs + per-game synth sfx
    │   └── games/<id>/           # per-game sprites
    ├── tests/flow_test           # infra + every game boots & round-trips
    └── tools/                    # derive_assets.py, gen_sfx.py (deterministic)

### The contract every game signs (`GogaGame`)

A game is a **Node2D** that:
- does its setup in `_goga_setup()` (called after the entry fee is taken),
- reports the run via `finish_run(score, coins_earned, extras)` — the host
  converts, saves best/last/plays, awards coins, offers the rewarded double,
  paces interstitials, returns to menu,
- may use `shop_open()` to sell skins/power-ups for GOGACoins,
- may use `achievement_count(key, n)` / `achievement_max(key, n)` to feed
  achievement counters,
- must survive pause + instant quit (host owns the back gesture),
- must NOT touch save files, Ads pacing or wallet directly.

Orientation: registry says `portrait` or `landscape`; GameHost rotates the
window (`screen_set_orientation` + `content_scale_size`) around the run and
restores SCREEN_SENSOR after. The BOX itself rotates freely (manifest
fullSensor + project orientation=6); the menu re-lays out on resize. Games
must size from the viewport, not hardcoded 720.

Per-game stats the Box tracks for every game (feeds the trophies screen):
best, last, plays, **time** (seconds played), **spent** (entry fees + shop),
**earned** (run payouts + ad doubles), counters, achievements, skins, and the
"New!" seen flag. Games never write these directly - the host does.

## 4. Box chrome design (menu)

- **Palette** (arcade amber, everyone-friendly — not pink-cute, not black-mature):
  - bg gradient #3a2313 -> #241407 with soft diagonal arcade stripes
  - card #fff3dc, ink #35210f, accent #ffb020, accent hot #ff7a1a,
  - good #58c470, bad #e8574a, coin gold #ffc93c
- **Layout** (responsive: the menu is built from anchors + containers, so
  portrait AND landscape both work — rotating shows more grid columns):
  - top bar: GOGABox logo (left) - GOGACoin chip - trophies - settings (right)
  - **HOT** row: horizontal BoxScroll, featured cards 300x208 (scroll left)
  - **ALL GAMES**: vertical BoxScroll, 2..6 col grid tiles 334x312 (scroll down)
  - bottom 78px reserved for the 52dp ad banner — content never hides under it
  - tile states (see Docs/plans/REVEALS_AND_NOTIFICATIONS.md): owned / locked
    (price, "New!" until first tap) / gated (own N games) / mystery (?????,
    orders or countdown) / soon (workshop)
- **Scrolling** is handled by `BoxScroll` (game/core/scroll_box.gd): raw touch
  drag + inertia + tap dispatch. Buttons inside scroll areas are FORBIDDEN
  (they eat the emulated mouse and kill the scroll) — register tappables.
- **Game page** (sheet): big thumbnail, PLAY [fee], best/last/plays stats,
  scrollable achievements list, time/spent/earned, RESET progress (confirm).
- **Trophies & stats** (trophy button): one row per game - icon, name, trophy
  count, total time, plays, coins spent/earned, last + best score.
- **Settings**: Music + SFX sliders and RESET ALL PROGRESS (full wipe).
- **Loading screen** (`Loader`): universal pre-launch screen for every game -
  game thumb with animated scan bar, real resource loading, progress + %, tips.
- **Achievements** (`Achiever`): one shared top pop-up (slide-down banner,
  trophy icon, confetti + sound) for ALL games; games just call
  check_achievements(). Mid-run sweep every ~3s by GogaGame._process.
- **Splash chain**: Android 12 splash (adaptive G icon) -> boot_splash.png
  (assets/ui/splash.png, replaces the Godot logo) -> in-engine splash with
  slow zoom + tap-to-skip (game/main.gd).
- **App icon**: letter-G emblem (icons/, generated by tools/make_brand.py) -
  main 192 + adaptive fg/bg + white notification glyph.
- **Notifications** (`Notify` autoload + plugins/notify): local Android
  notifications via AlarmManager, persisted across reboot. Used for timed
  game reveals and (later) return reminders. POST_NOTIFICATIONS asked once.

## 5. Versioning (GOGABox scheme)

Build counter B starts at 1. version_name = B split into decimal digits
((B/100).(B/10%10).(B%10)): 0.0.1 -> ... -> 0.0.9 -> 0.1.0 -> ... -> 1.0.0.
version_code_base = 30000 + 10*B (arm64 = base+2, arm32 = base+1).
B lives in config/projects.json and moves with every released build.

## 6. Ads (unity_ads plugin, same contract as the other games)

- Game ID 5770940 (the arsenal's first ID, per docs/ADS.md), package
  com.zai.gogabox. test_mode: false -> REAL ads from day one.
- Banner: ONLY on the box menu (games are banner-free — full-screen play).
- Interstitial: every 3rd run end (pacing owned by host, not games).
- Rewarded: run-end "DOUBLE GOGACoins"; later per-game extras opt-in via the
  same plugin API. Per-game ads may also register extra runs.

## 7. Economy modularity (v0.0.4)

- **coin_div**: score -> coins is per game (`"coin_div": N` in the registry):
  bonus = score / N, and below N a run earns 0. snake /10, lanes /100 ...
  In-run collectables (pickups) stack on top. No key -> default /100.
- **Per-game banner**: registry `"banner": true` opts a game into showing the
  ad banner inside its own view. Default: banner-free play.
- **coin icon rule**: every coin-priced control uses `Arc.coin_button`.

## 8. 2D & 3D

Godot runs 2D and 3D **in the same project** (separate scenes, and 3D can be
embedded inside 2D via SubViewport). The registry carries a `dim` field so a
future 3D game (Pop TD 3D?) plugs in without core changes. v0.0.1 ships 2D.

## 9. Ported at v0.0.1 (from PGB v1.3.8) + roadmap

| game (PGB name) | id | price | fee | status |
|---|---|---|---|---|
| Snake | snake | free | 10 | shipped (skins shop) |
| Pong (vs AI -> endless rally) | rally | 150 | 8 | shipped |
| Space Dash (was Geometry Flash, then Space Dodge; v0.2.4 = the full enemies-and-weapons redesign) | lanes | 200 | 20 | shipped |
| Fruit Slasher | slasher | 250 | 15 | shipped (landscape) |
| Snowy Tower | hopper | 300 | 12 | shipped |
| 2048 (solo) | merge | 400 | 15 | shipped |
| Dario | dario | 350 | — | mystery teaser (orders) |
| Hen Invaders (1P) | hen | 350 | — | mystery teaser (20 min box time) |
| Cosmic Spud | spud | 350 | — | mystery teaser (24 h real time) |
| Escape The Maze | maze | 400 | — | mystery teaser (orders, needs 2 games) |
| Matcher | matcher | 400 | — | mystery teaser (45 min box time) |
| XO (vs AI ladder) | xo | 450 | — | mystery teaser (orders, needs 3 games) |
| Keyboard Singer (rhythm rework) | keys | 450 | — | mystery teaser (72 h real time) |
| Pop TD | poptd | 500 | — | mystery teaser (orders, needs 4 games) |

PvP modes were dropped by design. Each remaining port gets its own Docs/plans
note as it enters development. New original games go through Docs/ideas first.
