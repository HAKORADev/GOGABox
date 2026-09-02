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
