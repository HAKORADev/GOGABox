# PLAN - Cosmic Spud v0.3.4-3 (patch 3) + GOGABox for WINDOWS (64+32)

The owner's two-front round: he played past the optionals at last and reported
the next round of Cosmic Spud defects + a full new platform wish. Both fronts
ship in ONE version (0.3.4-3) because the repo is one product. No release
without the owner's explicit ask (RELEASE_LAW).

---

## FRONT A - COSMIC SPUD PATCH 3 (the owner's report, item by item)

### A1. THE HUD LAW (score + kills widgets, the empty chip killed)
- The owner: "there is an empty widget next to gogacoins widget, the game
  supposed to have two, one for score and other for kills".
- ROOT CAUSE: v0.3.4-2 hid only the box chrome chips' LABELS - the empty
  score chip panel still rendered next to the icon-only coin chip.
- FIX: hide the whole chrome chips (new game_base helpers); build the CS
  top-right stack: COSMIC COINS (bigger), SCORE (yellow), KILLS (red),
  GOGACoins (green, live wallet + this run's pickups). KILLS leaves the
  left sub-row (ARM/LV stay). All black boxes, CS face law.

### A2. THE SILENCE LAW (the gogacoin never announces itself again)
- The owner: "the way you made the game literally notifies the user gogacoin
  will arrive and gogacoin and collected and and, bad, silent is cool".
- FIX: the three banners (HIDES IN THE SWARM / DROPPED THE COIN / +1 wallet)
  are GONE; the collection sfx is GONE; the CARRIER! HUD chip is GONE. The
  glint arc on the carrier + the GOGACoins counter tick are the only tells.

### A3. THE COIN SIZE LAW (the huge gogacoin pickup)
- The owner: "the gogacoins appear in the game are very very weirdly HUGE".
- FIX: the world pickup sprite scales to ~0.22 of the ui coin art.

### A4. THE FLASH LAW (the candle flicker when shooting)
- The owner: "when the character shoots, i see a flicker that looks like a
  candle". ROOT CAUSE: the muzzle particle drew its flame texture UPRIGHT
  (no rotation, fixed 32px box) at the gun tip - a standing candle.
- FIX: tex particles gain an optional rotation; the muzzle flash is drawn
  rotated along the aim angle, bigger, at the true gun tip.

### A5. THE SHARED CONTACT LAW (collision damage + continuous feedback)
- The owner: "colliding with enemies... shared damage from me and to me with
  an SFX... when the colliding is still on, i still get hit but with no
  visual or hearable feedback".
- OLD (splatter law): the enemy's REMAINING HP hit the player ONCE and the
  enemy died; during the 0.6s iframe every further contact was SILENTLY
  ignored - the "still colliding, no feedback" bug.
- NEW: per-enemy contact cooldown 0.55s. Every tick of an ongoing contact:
  - the player takes the enemy's (scaled) damage - armor, dodge and
    contact_cut apply - with SFX + red number + flash EVERY time;
  - the enemy takes THE RAM back (8% of its max HP + 3 + armor), with its
    own number + dust burst; bosses take half ram;
  - the global iframe shortens to 0.28s for contact only (chain protection,
    but never silence).
- The old one-shot splatter is dead (a full-HP mender touch no longer
  deals its 1000 HP as damage - its real attack does).

### A6. THE BREAK CHAIN (draft -> WAVE MARKET -> MERGE -> STATS -> SKILLS)
- The owner: "we will have shop menu, stats menu, skills menu... splitting
  merge menu to be as another menu instead of in shop, put it after shop,
  make shop has items, weapons, allies".
- WAVE DRAFT keeps the per-wave pick-1-of-3 law, but its REROLL is REMOVED
  (the owner: "a re-roll should be for shop items"). u3 FATE REROLL now
  grants one free MARKET reroll per break.
- THE WAVE MARKET (in-run, cosmic coins): tabs ITEMS / WEAPONS / ALLIES.
  - ITEMS holds the stat items + supplies. WEAPONS holds offers + YOUR
    LOADOUT with SELL. ALLIES deploys/raises.
  - THE HOLD DECK (Brotato's lock): up to 5 offers held; held offers
    survive rerolls; hold/unhold free; lasts THIS market visit only, never
    saved as game data; a held item can still be bought or unheld.
  - REROLL OFFERS climbs in price, consumes u3's free shuffle first.
- THE MERGE BENCH: its own menu after the market (all pairs listed, the
  LAB lock reason when unlearned), CONTINUE advances.
- THE STATS MENU (the level-up, the owner: "a menu that appears after the
  game shop when the level-up happens"): one point per XP level; the stat
  packages cost 1-3 points ("some stuff requires more than one point");
  big text, up-down AND left-right scrollable, NO X (closable=false, the
  DONE button advances). Mid-wave level-ups no longer interrupt - they
  queue for the break (the old mid-wave draft opened and trapped).
- THE SKILLS MENU (new, below).

### A7. THE SKILLS LAW (skill points: 1 per 100 kills, lifetime)
- The owner: "make sure to make there is two things, skill points and stats
  points. stats is the thing in the example game, i want the skills to be
  earned from each 100 kill as a point, skills should be unique... a real
  high cool-factor".
- Points: lifetime kills (banked + this run) / 100 - spent. Persist across
  rounds (the owner: "why are coins and skills currently saved per different
  game rounds" - skills are META now, never reset).
- THE TEN (each a real run modifier, wired in code):
  1. SHATTERED SHIELD (2) - blocks one hit, reforms 12s later (blue ring,
     shatter burst).
  2. LEECH AURA (2) - enemies within 140px bleed 2 HP/s to you.
  3. FROST AURA (2) - enemies within 170px crawl 30% slower.
  4. GHOST ROUND (2) - an enemy shot that hits you FLIES THROUGH and deals
     half its damage to any enemy it meets behind you (the owner's own idea).
  5. STARCH RAGE (1) - below 35% HP: +40% damage.
  6. STATIC BURST (1) - every 6s lightning zaps the 3 nearest enemies.
  7. TWIN TAIL (2) - a ghost gun guards your back at 40% damage.
  8. ADRENALINE ROOT (1) - a dodge revs +80% attack speed for 2s.
  9. GOLDEN GUT (1) - +25% cosmic coins from every source.
  10. MAGNETIC SKIN (1) - magnet +60%, hearts heal +50%.
- The SKILLS button joins the boot menu; the break chain enters it whenever
  unspent points exist.

### A8. THE UNIVERSAL SHOP BUTTON (the owner's repeated law)
- The owner: "the shop button in the game is not the supposed thing?? where
  is the shop that uses gogacoins, this button should open a normal
  universal style shop as i described many times".
- FIX: the HUD SHOP button ALWAYS opens THE SHOP - the universal GOGACoins
  store (the old armory, re-branded): green GOGACoins chip in the header on
  EVERY tab, tabs PLACES / WEAPONS / ALLIES / LOADOUT, places in full-words
  GOGACOINS prices (the v0.3.4-2 border law stands), works at any phase
  (pauses the run). The wave market remains the in-run cosmic-coin store.

### A9. THE BIG-UI LAW (the optionals + the widgets grew)
- The owner: "the optionals start menu needs to get that scrollable fix too
  because it is currently feels and looks too small... even the cosmic coins
  widget is small too".
- FIX: optionals cards/fonts up (art 64, stats 12, names 16, perks 12),
  themes cards bigger, the shop/tree/market/stats/skills scrolls move BOTH
  axes (left-right for wide grids), the money widget 168x38 @ font 18.

### A10. THE WOW PASS (the owner: "the game feels too poor... see why the
wow-factor here is bad")
- Camera SHAKE on player hurt / explosions / boss slam / boss death.
- Low-HP red vignette pulse (the fx layer, the CS face respected).
- Coin + XP pickup sparkles, the level-up golden burst.
- The contact ram dust + the shield shatter + static zap lines (A5/A7 art).

### A11. PROBES + QA
- cs_probe 89 -> ~120 checks: the shared contact law (both sides take
  damage, feedback fires every tick), the silence law (no gogacoin banner),
  the coin size, the hold deck (5 cap, survives reroll, frees on buy), the
  stats packs (multi-cost, points ledger), the skills (points math, buy
  once, shield blocks, ghost round passes through, frost slows, rage
  multiplies), the market tab shape, the merge menu standalone, the chain
  order, the universal shop button at every phase.
- qa_v034p3 rigs re-shot: boot door (bigger), market + hold deck, merge
  bench, stats menu, skills menu, HUD with the four widgets, contact fight.

## FRONT B - GOGABOX FOR WINDOWS (64-bit AND 32-bit)

### B1. THE SSE2 BASELINE LAW (the owner's whole point)
- Modern Godot x86_64 builds need SSE4.2 (Haswell+). The owner wants older
  CPUs to run the box: custom export templates built with
  `scons platform=windows target=template_release arch=x86_64 lto=full
  use_static_cpp=yes custom_cflags="-march=x86-64"
  custom_cxxflags="-march=x86-64"`.
- TWO builds: x86_64 (the line above) AND arch=x86 (32-bit) - the owner's
  follow-up: "make two windows builds too, 64 and 32".

### B2. THE TEMPLATE FORGE (.github/workflows/build-windows.yml)
- Job templates-x64 / templates-x86 (parallel, ubuntu-latest, mingw-w64
  cross-compile): fetch the pinned 4.7.2 source, build template_release,
  upload windows_release_x86_64.exe(.pck) / windows_release_x86.exe(.pck)
  artifacts.
- Job export (needs both): the pinned Linux editor + the forged templates in
  export_templates/4.7.2.stable, then TWO --export-release runs.
- Single .exe law: binary_format/embed_pck=true (no side .pck).
- Compression law: the export compresses the embedded pck; the delivery
  artifacts are zipped.
- iterate until mature (the owner: "test the updated github actions until
  it's mature"); if lto=full trips the 6h runner wall, drop to a lighter
  LTO and SAY SO in the docs.

### B3. THE PC LAWS (the only game-code differences the owner listed)
- THE DEATH MENU: the DOUBLE (watch ad) block hides on non-Android builds
  (Ads.desktop_sim) - no ads on PC, nothing fake.
- THE CONTROLS (per game, keyboard/mouse):
  - snake + cosmic spud: hold LMB and move (the stick they already are);
  - PONG: LEFT/RIGHT arrows; 2048: arrows;
  - Space Dash / Snowy Tower / Cursed Dario / Space Invaders:
    LEFT/RIGHT arrows (+ SPACE for fire/jump);
  - matcher / xo / fruit slasher: the mouse they already need.
- THE TOUCH SPEED FIX (Android, the owner: "moving the finger faster meant
  make moving faster... make the arrow button make the move in fixed proper
  speed"): Space Dash + Snowy Tower (invaders too) axis becomes FIXED SPEED
  - past the dead zone the move runs at full proper speed, drag distance no
  longer scales it.
- THE VERTICAL SLICE LAW (the owner: "vertical games should not run in full
  screen, only horizontal ones run in full window, vertical will take a
  vertical slice and the sides be the gogabox background"): on desktop the
  portrait games (and the box menu) render a KEEP-aspect vertical slice;
  the letterbox is painted the box brown (the default clear color), never
  black. Landscape games keep EXPAND (full window).
- NOTIFICATIONS: the notify bridge stays a desktop no-op (the owner allows
  killing them on Windows); in-app toasts still work everywhere. Windows
  10+ native toasts are documented as future work, not slop-hacked now.

### B4. THE SEARCH + TAGS LAW
- Every registry entry gains "os": ["android","pc"] (the badge/tag for all
  games, platform exclusives become possible later).
- THE SEARCH BAR: a real text field - the query is normalized (lowercase,
  spaces stripped) and matched as a SUBSTRING of the game's title+id:
  "slash" finds FRUIT SLASHER, case-insensitive, reading between spaces.
- The search sheet gains PLATFORM chips (PHONE / PC) that filter by the os
  tag; the game guide wears a PLATFORMS section.
- THE GUIDE: every game's registry entry gains "controls_pc"; the guide
  renders CONTROLS - PHONE and CONTROLS - PC as separate sections.

### B5. THE DOCS LAW
- README (Windows section), docs/CI.md (the forge), SETUP.md (the scons
  line), ADDING_A_GAME.md (os + controls_pc), AGENTS.md, RESOLUTION_RULE.md
  (the vertical slice), the repo description via the API.
- GDD: cosmic_spud_patch3.md with every law above.

## THE ORDER
1. Front A code + probes + qa (the owner's test target).
2. Front B workflows pushed EARLY so the forge runs while Front A is
   finished; then the export presets + PC code paths.
3. One commit `gogabox v0.3.4-3`, push, CI green, worklog, report.
