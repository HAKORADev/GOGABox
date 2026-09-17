# DEADLY WORM — the survival cross-section (v040-9)

> The owner's GDD, verbatim-shaped into laws. The teacher: **Death Worm™**
> (PlayCreek, the Adobe-Flash-era classic, ported everywhere since) — studied
> under THE USAGE LAW from the official APK; every shipped asset is a
> code-modified derivative (forge: `projects/gogabox/tools/v0409_worm_art.py`),
> every readable number reshaped into our own tables.
> **THE OWNER'S RENAME LAW:** "first, rename it to deadly worm."

## THE ONE-LINE

You ARE the worm. A fixed 2D place — sky, surface, underground — wide but not
endless. The spawner never rests and always grows harder. The run ends only
when the worm dies. Eat everything, break the machines, bank the wormCoins,
grow through the ten worms.

## THE LAWS (the owner's words, owner-locked)

1. **SURVIVAL, NOT STAGES.** "the GOGABox game will be survival and not
   stage-based … a round ends when the worm dies, it can not last forever and
   the game will keep spawn things over and over without resting and always
   becomes much harder."
2. **THE WORLD.** "sooo, fixed 2D place, the place is wide but not endless,
   there is under ground, land/surface and a sky, that's it." One screen tall
   (1080), the world 2112 wide — the camera pans, the rock bounds hold.
3. **THE PLACES.** "you will design different places following the original
   one, like 5 different places and make one default (like egypt in the
   original) and other 4 be bought in the shop for real gogacoins … make sure
   places are not just different views, they likely have exclusive things
   that make them harder/easier to play in."
   - THE DUNES (free) — the classic, balanced.
   - THE ICE (600) — grip 0.78: the worm drifts; the cold slows the prey x0.88.
   - THE CITY (800) — machines over meat; bullets x1.25; the subway sparks
     bite the tail at the bottom.
   - THE JUNGLE (700) — roots drag the dive x0.85; every animal pays half more.
   - THE KINGDOM (900) — war spawn tilt, bullets x1.2, the wall torches burn.
4. **THE TEN WORMS.** "you will not make skins but will make like, 10
   different worms and it works like this, each one has different size,
   speed, power, health, each one can get x1.5 it's stats while it levels up,
   each one has different levelling up capacity for each level."
   - A maxed worm is EXACTLY x1.5 its base stats (per level:
     1.5^((lvl-1)/(maxlvl-1))); the capacities are strictly different
     (5, 6, 7, … 14 levels).
   - THE CHAIN: "the next worm can not be unlocked until the previous one is
     maxed it's levels, when it is able to be unlocked, it will require
     wormCoins." Prices 0 / 250 / 600 / 1.1K / 1.8K / 2.8K / 4.2K / 6.5K /
     9.5K / 14K.
   - Ten UNIQUE specials (the owner: "make sure to make each worm unique with
     this thing"): ROAR, SURGE, GEYSER, GHOST DIVE, BLOOD FRENZY, QUAKE,
     VENOM SPIT, DEVOUR, VOID PULL, FIRE BREATH.
5. **THE ECONOMY (points, not percentages).** "destroying vehicles gives no
   health, eating humans each 1 gives 1 point and land animals give 3 and
   ground animals under the ground will give 1 per 3 of them, points and not
   percentages." Vehicles are bitten apart (never eaten, never health) and pay
   their own bounty (car 2, truck 3, btr 4, heli 4, tank 5, launcher 5, plane
   5, ufo 6). **THE SCORE BONUS IS /500** at the box gate (the registry
   coin_div), "as same as pop siege or heavy war".
6. **THE HEALTH IS FIXED.** "the health will be fixed-limit, no rogue-like
   style … the whole health in the game will show up as nn% but in the worms
   menu it will show real numbers of them and the next number for each worm
   level up and like that." Eating never heals. The dirt below the line is
   armor — enemy shots only bite the surfaced worm.
7. **THE COIN LAW.** "each coin will drop from edible things after each 10
   eaten things it will give one coin, make sure to make the economy good for
   long-term." wormCoins bank LIVE during the run and spend on the worm chain
   and the power-ups. THE TOP-UP: 1 GOGACoin = 5 wormCoins (the framework,
   declared in the registry like scrap and rockCoins).
8. **THE CONTROLS.** "controls will be left side to move the worm the same way
   the original one did but using hidden analog, right side tap for the dash,
   each one has different cool down and length for it, make sure to make it's
   widget accurately, tapping on the middle will use the worm special
   ability." LEFT = the hidden analog (drag vector = the steering stick);
   RIGHT = tap to dash; MIDDLE = tap for the special. THE CHARGE LAW: "recharge
   for one use should be after each 100 points" (hold 2).
9. **THE FEEL.** "original game has amazing physics, copy it well, each size
   has weight and different impact on things, the original has a mechanic
   where moving directly at the surface line makes the worm slower." The
   chain swims, gravity owns the air, riding the line crawls at x0.62.
   No collectable weapons — the owner: "original game had many collectables
   like machine gun-like thing and other weird things, i do not want the game
   to be that stupid."
10. **THE POWER-UPS.** "original offered collectables like x2 size for
    specific time and also double speed and also double jump and like that,
    make each one of them called power-ups and be bought first from the shop"
    — six kinds (MEGAWORM, ADRENALINE, GHOST SKIN, HUNGER CALL, FRENZY, STONE
    SCALE); bought with wormCoins FIRST, then they drop in-run "one after
    every 1 to 2 minutes … selection be randomized" among the unlocked only.
    "powerups show up accurately as cool widget" — the chips live under the
    top bar with their countdowns (the Snowy Tower / Geometry Flash law).
11. **THE WORMS MENU.** "for worms shop, make it normally just call it
    'worms' button next to the shop button and it shows a cool menu showing
    an image of the worm with the details and shows the current level and
    next level and the remaining and like that." The WORMS button rides the
    top bar next to SHOP; the rows wear the portrait, the real stat numbers,
    the next level's numbers and the points remaining.
12. **THE ART.** "use the original assets for everything 1:1 but do
    code-modifications on the assets so they are from the original but they
    are actually not, like this." The forge cuts the study atlases and walks
    every sprite through the modification pass (hue identity per worm, grade,
    grain, the baked bone/stone decals in the dirt). The GOGABox widgets
    follow the universal in-game top bar.

## THE STUDY'S REAL NUMBERS (what we took)

- The auto-scenario spawn table (humans ~70%, soldiers 100% @3 max, rockets,
  jeeps/trucks ~8s delays, planes/helis ~8-10s, tanks 60%, underground
  animals 3-6, ug vehicles 2-3) → our weighted roll + the never-resting
  intensity ramp (interval 3.4s / intensity, floor 0.55s).
- The worm upgrade curve (size 0.8→2.0, speed 1→1.8) → our ten-worm stat
  bands and the x1.5 level law.
- The bonus_drop/bonus_prob weights → our power-up pool logic (bought-first).

## THE FORGE (our own stock)

`tools/v0409_worm_art.py` — deterministic, idempotent. Ten worms (the classic
worm2 + the 2017 seven + wraith + dragon), eight human skins, nine animals,
thirteen vehicles, nine shots, twelve explosion frames, five place bakes with
our buried decals, the shop previews, the coin/dot/pow icons, the composed
960x640 thumbnail. `tools/v0409_worm_sfx.py` — the 15 dw_* voices + two place
beds (numpy synth, the house law).
