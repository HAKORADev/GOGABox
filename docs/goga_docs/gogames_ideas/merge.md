# 2048 (merge) — the journal

## Origins

The PGB (Python_Game_Box_PGB) v1.3.8 2048 — pygame + pymunk, arrow buttons,
a hue-cycling background, merge-value-sum scoring. It joined GOGABox at the
box's birth as a 212-line stub: a hardcoded top-left board (27,250), tiles
that TELEPORTED (the bookkeeping freed the source node and respawned a
fresh one at the destination, so the slide tween almost never fired),
merge-value-sum scoring, auto-granted coins, no shop. The owner played it
in the v0.2.7 round and called it "somehow totally broken for real".

## v0.2.7 — THE REBUILD

The owner's contract: the same grid but centered and BIGGER, a cool
backdrop matched to the grid, swipe-anywhere controls, each fusion worth
exactly +1 with the run bonus /20, a GOGACoin growing in an empty cell
after every 15 fusions, banner ads, collisions + animations + effects
better than the python one, and a shop with THEMES (his own sketches:
Minecraft with lava, a Sea with real water inside the tiles). "Take your
time doing everything very good, no simplifying!"

- THE LAYOUT: the biggest 4x4 square that fits between the HUD bar and the
  banner strip, centered both ways (`_layout_board`); the board grew from
  the old fixed 660px orphan to a viewport-filling ~1.5x.
- THE BACKDROP: the classic theme lives on a DEEP COOL SLATE (#27304a)
  with a soft halo behind the board and drifting dust — cool against the
  warm beige grid, exactly the owner's "background cool color matches the
  grid one".
- THE SLIDE ENGINE: the classic compress + merge with move lists (the PGB
  shape) — tiles KEEP their nodes and tween (TRANS_QUAD, 0.11s); merges
  free both victims at pop time and the doubled tile is BORN with a
  TRANS_BACK pop, a +1 float, chunk particles and a tier-pitched pop.
- THE SCORING: one fusion = EXACTLY +1 (the old stub paid the tile value
  sum). coin_div 150 -> 20.
- THE GOGACoin CELL: every 15 fusions one EMPTY cell grows the REAL coin
  (coin.png, fade-in, bob, a sweeping glint — the owner's "appear like the
  other games, but with fade effect"). THE SWEEP LAW: a tile sliding
  THROUGH the cell takes it (the coin rides the slide like a real coin on
  a table); a tile landing dead on it counts too. The coin claims its cell
  BEFORE the 90/10 spawn; a full board holds it until a cell frees.
- THE COLLISIONS: merge chunks are squares with gravity + spin that BOUNCE
  off the board frame (vx/vy reflected at the frame, damped) — the pymunk
  spirit without the engine.
- THE END: no empty cell and no equal pair = the gray cascade (rows fade
  one after another) then the dead menu. 2048 fires a golden burst and the
  run continues (endless).
- THE SHOP (registry shop: true) — THEMES:
  - Classic (free default): the warm board on the cool slate; m_slide /
    m_pop.
  - Minecraft (800): a generated stone-block wall, dirt holes, block-face
    tiles with deterministic pixel noise (grass/dirt/wood/stone/iron/
    copper/gold/redstone/diamond/emerald/lava tiers), lava-glow numbers
    breathing on 128+ with rising embers, m_thud / m_stone / m_lava.
  - Deep Sea (650): glass cells holding REAL water — a per-tile shader
    (water_tile.gdshader): the fill IS the tier (0.22 for a 2 up to 0.95
    for a 2048), the surface tilts with the slide (slosh), waves energize
    on motion and settle calm, a meniscus line + foam, splashes droplets
    on merge. m_slosh / m_splash.
- SFX: tools/v027_sfx.py (deterministic, re-runnable) — tower_break +
    the seven 2048 voices.
- THE THUMB: recomposed to the new look (cool slate, big centered board,
    the coin cell, the +1 pop, the hero glow).
- tests: merge_probe (the NEW probe) — centering, banner/HUD clearance,
    the slide laws (rides, two-pairs-in-one-move, no double merges), the
    +1 law, the coin cell spawn/sweep/pending, the stuck + cascade end,
    the themes (equip, water fill = tier, block textures), the particle
    bounce, the real tk.swiped path, the shop pair. flow_test grew the
    /20 + shop laws and reversed the banner law. ALL PASS.
- Xvfb QA (qa_v027, 11 shots eyeballed BEFORE shipping) caught: the
    numberless board (the rebuilt TileNode never set lab.text!), the
    blurry stone (linear filter — the layers now demand NEAREST), the too
    subtle lava glow, and the clipped shop labels (fit_label's floor; the
    theme rows are wrapped label + short button now). All fixed + re-shot.

## Ideas shelf (owner musing: "what else in shop? i am not sure... it is a
puzzle and relaxing game maybe?")

- more themes (candy? retro CRT? wood?), a board-frame shelf, an undo
  power-up, a daily-seed challenge mode — WAIT for the owner.

## v0.2.8 — THE VERDICT ROUND II

The owner played the rebuild and ruled on five things:

- THE CLASSIC BACKGROUND WAS BLUE ("i guess you misunderstood me when i
    said deep blue i just meant for the sea theme") — Classic now wears
    the WARM PAPER of the real 2048 palette: the cream page, a whisper of
    warm dust, soft warm vignette edges; the frame went warmer (b9a99a).
    The deep blue belongs to Deep Sea alone.
- THE COLLECTED COINS NEVER DISAPPEARED ("when collected it never
    disappear until another coin appear") — root cause: the coin canvas
    item kept its stale painting because `coin_layer.queue_redraw()` was
    only called while a coin was ALIVE; after `_take_coin_cell()` nobody
    repainted the layer, so the ghost coin hung around. The take now
    repaints explicitly AND the tick repaints the layer every frame
    (spawn, bob, glint, ERASE). The probe grew the law; the QA shot
    03 proves the erase.
- THE SEA WATER WAS FAKE ("just animations based on movement even if
    there is no movement... a weird wave and not real physical-based
    water... if a square is at the left edge and i swiped to left, i will
    still see the water moves which is unreal") — the old code fed the
    water from the SWIPE DIRECTION (every tile in the move list got
    energized, stationary tiles included, and the shader kept a
    time-driven sine). REBUILT as real physics: a per-tile damped SPRING
    (W_K 49 / W_C 1.9 / W_ACC_K 0.00034) whose only force is the tile's
    ACTUAL acceleration, measured from its real position deltas each
    frame. A still tile sits still — forever; only acceleration is a
    force (a steady coast does not re-excite the water); the surface
    settles through a few natural swings. The shader lost the time-wave
    and gained tilt + energy: the resting shape is a flat fill with a
    static meniscus; ripples and foam exist ONLY while energy lives.
    merge_probe pins four laws: stillness, motion, settle, coast.
- THE OPTIONS MENU (owner: "add an optionals menu shows 4x4 normal and
    6x6 and 8x8, make the others be bought first for high prices, make
    6x6 score bonus be /80 and 8x8 /160") — the HUD grew an OPTIONS
    button: 4x4 free (bonus /20, the registry default), 6x6 at 1800
    (/80), 8x8 at 3600 (/160). The bonus follows the board through a
    MODULAR `bonus_div_override` var on the game base — host_node reads
    it in ONE place (`_live_div`) so the payout theatre, the honest-math
    line and the dead menu all agree; no game names in the economy.
    Switching the size starts a FRESH board (honest earnings: no mixing
    a 6x6 run into a 4x4 score). GRID the const became `grid_n` the var;
    every loop (slide, spawn, stuck, cascade, layout) is size-aware.
- THE THUMB'S "41" ("if you give it a closer look, you will see an empty
    square has number 41 which is weird") — it was the "+1" fusion pop:
    the Kenney Rocket "1" glyph carries a bottom serif bar and read as
    "41" over an empty hole. The pop is GONE from the scene and the
    thumbnail is recomposed on the warm paper.
- BONUS CATCH (the probe): the 90/10 fresh spawn could land ON the coin
    cell — the reward got swallowed and auto-collected at the next slide.
    `_spawn_random` now skips the coin cell; the coin owns its cell until
    a slide really sweeps it.
- tests: merge_probe grew the v0.2.8 chapters (sizes + divs + fresh-board
    switch, the 6x6 slide, the options pair, the water still/motion/
    settle/coast laws, the coin vanish); flow_test grew the size/div
    registry laws. ALL PASS.
- Xvfb QA (qa_v028, 12 shots eyeballed BEFORE shipping): the warm paper,
    the coin erase, the sea still-vs-tilt pair, the options sheet, the
    centered 6x6 — plus the whole XO remake chapter below.
