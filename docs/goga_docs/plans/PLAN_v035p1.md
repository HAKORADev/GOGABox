# PLAN v0.3.5-1 - POP SIEGE: THE REAL GAME PATCH

The owner played v0.3.5 and rated it 0.5/10: real bugs, broken map paths, and a
soul-less look built from zero real art. This patch rebuilds the game around
REAL assets (the owner's directive: the uploaded GameMaker TD template, the
Gamesnacks Endless Siege art pulled from its CDN atlases, heavy modifications
into our own identity) and fixes every reported item.

## COSMIC SPUD (1 item)
- C1  INFO sheet: kill the scrollbar-sidebar; the sheet body becomes a
      BoxScroll (game_safe) - direct raw-touch up/down scroll anywhere.

## POP SIEGE - FLOW LAWS
- P1  No more boot-straight-into-siege: the run opens in a READY moment (map
      name + START). Nothing moves until the owner taps START.
- P2  OPTIONALS is dead. The HUD wears MAPS (opens the map wall directly) +
      SHOP + a real PAUSE button (the host pause sheet, real freeze).
      HOW TO PLAY in-game is dead (that lives in the box guide).
- P3  Every game-owned sheet (SHOP, MAPS) PAUSES the tree for real (the CS
      sheet-life pattern) and resumes on close. Game over force-closes every
      sheet first so the death menu ALWAYS surfaces.
- P4  Speed cycles x1 -> x2 -> x3 -> x1.
- P5  A/M wave law: AUTO (countdown marches) / MANUAL (countdown frozen, you
      send every wave). The big panel wave button is a PLAIN LABEL now - not
      tappable (the owner's accidental-tap report).
- P6  THE NEXT WAVE button (the ES pink one, bottom-right of the field):
      idle -> calls the wave now (early-call bonus); wave rolling -> stacks
      the NEXT wave immediately (the owner's launch-while-rolling law).
- P7  The pop pay law: PopCoins come from POPS only (bumped coin table) +
      Kaching income + the early-call bonus. The flat end-of-wave pay is DEAD.

## POP SIEGE - PLACEMENT + CARD LAWS
- P8  Placement rebuilt on TouchKit: tap a card (gold highlight, the ghost
      waits), then a TAP on the field places (drag still previews). Tap an
      occupied/blocked cell = bad tick, placement cancels. Second tap on the
      card cancels.
- P9  Cards rebuilt as flat panels (no bare Button-with-overlay-text): the
      "two texts over each other" highlight bug class is dead. Selected card
      wears a gold border; unaffordable cards dim.

## POP SIEGE - SHEETS
- P10 SHOP: BoxScroll with registered tappables (the matcher law - scrolling
      works while the finger lands on a row), and the sheet is WIDER.
- P11 MAPS (renamed): directly, internally scrollable (BoxScroll), 2-column
      wall, wider sheet, painted thumbs, D/N chips, buy/play.

## POP SIEGE - THE MAPS
- P12 The hard-turn disease is dead: every path is a smooth spline (dense
      Catmull-Rom samples, gentle curves, no 90-degree cells). 30 maps
      rebuilt with distinct shapes and feels (arcs, S-curves, loops, REAL
      spirals, twins, crossings that converge on one heart), multi-path
      maps kept. Ids/names/prices kept (saves survive).
- P13 The look: every map bakes a PAINTED background (theme ground with the
      ES checker, soft road with borders and wear, pooled water with shores,
      decor scatter, framed board) at build time. Night stays the in-game
      tint + lamp + fireflies law.

## POP SIEGE - THE REAL ART (the owner's directive)
- P14 Source A: the uploaded GameMaker TD template (Towers vs Monsters kit):
      trees, graves, house, land smoke/ring, sounds of placement.
- P15 Source B: the Endless Siege web atlases (game CDN, 900 unique frames):
      tower tier lines (archer / cannon / fire / crystal with REAL 3-tier
      tops), cells, explosion/flame/snow/teleport frames, upgrade-menu
      icons, the NEXT WAVE + AUTO WAVES candy buttons. All RECOLORED +
      RECOMPOSED into the GOGA identity (never a 1:1 clone).
- P16 The folk are GADGETS: stone base + rotating head that tracks the
      target. 10 families x 3 gears, each gear visibly stronger.
- P17 The bloons are a full glossy drawn set: red..pink, black, white,
      zebra, lead, rainbow, ceramic (+2 crack stages), MOAB + BRUTUS
      airships. The honest rbe chain stays.
- P18 The pop juice: ES splash/explosion frames + the shockwave shader,
      floating +N PopCoin text on pops, HP bars on tanks, head-recoil
      tracking, placement smoke.

## POLISH LAWS
- P19 THE CLEAN TITLES LAW everywhere: no em-dash helper subtitles in any
      sheet, chip, toast or label.
- P20 CI: the restored "branches: ain]" push-trigger typo (the un-windowing
      restore resurrected it) is fixed to [main] (committed via the API -
      the sandbox write-guards workflow files).
- P21 Version 0.3.5-1 (code base 30610 -> arm32 30611 / arm64 30612).
      The 0.3.6 name stays reserved for the NEXT version.

## ACCEPTANCE
- pd_probe updated + green headless, flow_test green, all other probes green.
- qa rig screenshots eyeballed: ready gate, field (painted board + gadgets),
  placement, shop, maps, night, next-wave button.
- Pushed; CI green on both ABIs. No release (the law).
