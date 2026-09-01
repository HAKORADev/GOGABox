# PLAN v0.2.3 — the owner's pong + box verdict round

The owner played v0.2.2 late night (4:30 AM) and filed the full list. Everything
below shipped in this build; every numbered item maps 1:1 to his report (he
asked for the numbering so he can track without forgetting something).

## PONG (game/games/rally/pong.gd)

1. **AI too hard — shorter reading range.** `AI_VISION = 0.42`: an enemy pad
   only READS the ball inside 42% of the field depth from its own edge. Beyond
   that range it drifts back to center and can be wrong-footed by fast angled
   returns. Inside the range it still predicts (with the folded wall bounce),
   thinks every 0.13s, carries the human error, and the heat beats its speed
   cap. Probe: the pad chases an incoming ball parked INSIDE the range and
   ignores (drifts on) the SAME ball when it is FAR.
2. **GOGACoin design.** The in-court coin is the REAL `assets/ui/coin.png`
   (drawn with draw_texture_rect + a soft golden halo) - no more hand-drawn
   disc. And the spawn law is the owner's literal one: **ONE coin on the court
   at a time**; a new one spawns 5-20s after the LAST COLLECTED one (the timer
   restarts at spawn and again at collection; an uncollected coin just waits).
   Probe: timer firing with a coin present NEVER piles a second one.
3. **Ball logic + serve + speed limit.**
   - The near-platform weirdness root cause: the old code tested only the
     LANDED position against a band around the pad and then TELEPORTED the
     ball to a fixed offset inside that band - a fast ball could step over the
     whole band (tunneling into the goal behind the pad) or reappear somewhere
     it never touched. REBUILT as a swept test: the move segment
     ball_prev -> ball_pos is tested against the pad's face plane; the bounce
     happens AT the crossing point (the contact the player sees) and the ball
     simply sits there - the same clean reflection a wall gets. Probe: a
     900px-in-one-step ball BOUNCES (no tunnel, never behind the pad); a ball
     beside the pad is not bounced by it.
   - Serve: born at the MIDDLE of the field, flying TOWARD the platform that
     conceded (owner: "spawn it at the middle of the field toward the
     platform"), with a small tangent skew. Probe: center spawn + direction.
   - Burn ceiling 3.5 -> **x5** (owner: "x5 is more better").
4. **Position ask.** It is JUST the two phone cards now - no "HOW DO YOU
   PLAY?", no subtitle, no walls line; the word VERTICAL/HORIZONTAL under each
   phone is the whole sentence. And in horizontal the USER's platform swapped
   to the RIGHT edge, enemy LEFT (owner: "will be better!"). Probe: the
   horizontal court gives the user "right".
5. **Optionals naming.** "MORE WALLS" -> "MORE ENEMIES" on the strip.
6. **END button.** The pause sheet only offers END while the RUN is live
   (new `GogaGame._goga_pause_end_ok()` hook; pong overrides it with
   `_phase == "run"`). Pausing from the position ask or the optionals/options
   screen shows RESUME + QUIT TO BOX - no END row at all. Probe asserts both.
7. **The store round.** The pong shop is the snake shop's language now:
   Arc.sheet + PROCESS_MODE_ALWAYS + BoxScroll(game_safe) with every live
   button registered as a tappable.
   - Scrolling works when the finger STARTS on a button (raw ScreenTouch/ScreenDrag
     scrolling - BoxScroll); snake already shipped this pattern, both shops match.
   - The BLUE skin is no longer a dead 0-coin row: a price-0 skin IS the owned
     default (BLUE (ON) / EQUIP, equipping it always legal) - the snake shop's law.
   - Opening the shop WHILE THE GAME RUNS no longer hangs: the run pauses the
     tree, so the sheet (and its BoxScroll) gets PROCESS_MODE_ALWAYS like every
     other in-game sheet. The shop sheet also demanded its real width (560) -
     pong's CLOSE rides inside the scroll, so the scroll itself carries the width.
8. **Speed mods override the limits.** Explicit + probed: at the x5 ceiling the
   ball runs 340x5, BOOST stacks x1.5 past it, STRIKE x3 past it (the cap only
   ever clamps the natural burn, never a powerup).
9. **Lights brighter.** The court shreds: 30 -> 42, alpha 0.04..0.14 ->
   0.10..0.27, radius up, glow pass up; the goal strips 0.22/0.16 -> 0.32/0.24.
10. **Platform sparkles from the hit area.** The sparkle dust is born at the
    TRUE contact point (the swept bounce hands it over), thrown along the
    bounce direction in the platform's color (owner: "sparkles appear from the
    area got hit by the ball on the platform").

## BOX

11. **Tabs.** LEAST PLAYED renamed **LESS PLAYED**; new **MOST PLAYED** (most
    plays first) and **ABANDONED** (owned+played, longest since the last play
    first, top 10, stat line "1h ago - last play"). Six lists in the carousel.
12. **Strip thumbnails.** The strip card thumb now uses
    STRETCH_KEEP_ASPECT_CENTERED - the FULL artwork shows (the wide-short card
    used to crop the top off). Grid tiles keep COVERED.
13. **SOON keeps the purple ?.** New `assets/thumbs/soon.png` (drawn in the
    exact workshop `scene_soon` language: purple diagonals + the real ?
    glyph). SOON tiles and the stats rows wear it - final art belongs to
    SHIPPED games only.
14. **Ready badge follows reality.** The 2s menu tick now compares
    `Roadmap.can_play_now` per owned game against a cache; any flip (batteries
    filled, window opened, daily reset, wallet drained) rebuilds the feed
    immediately - a "not ready" tile turns ready (chip + alive face) without
    waiting for a manual refresh, and back.
15. **Per-game capacity holds while playing.** `Box.set_active_game /
    clear_active_game` (host hooks at launch, retry, quit, exit): a game's OWN
    battery pool clock is FROZEN the whole time its game is open - menu,
    another game, or the app closed are the only charging states. On release
    the played span is shifted out of the pool's charging window (and a process
    kill mid-play reconciles on the next boot via the persisted hold). Probe
    (flow_test): the countdown stands still while the game is open, ANOTHER
    game's pool keeps ticking, the played span charges nothing, and the hold
    follows the open game when switching.

## ART

16. **Phone cards lost the snake.** `tools/v023_assets.py` regenerated
    phone_vertical/horizontal.png WITHOUT the tiny blue wiggle (a leftover
    from the card's snake-only birth) - empty screen, universal phone.

## Tests

- `pong_probe` grew the v0.2.3 laws (ask silence, center serve, x5 ceiling +
  powerup override, swept bounce + beside-pad law, one-coin law + real asset,
  AI vision in/out of range, horizontal swap, END-per-state) - ALL PASS.
- `flow_test` grew the capacity-hold suite + the 6-list carousel with the
  LESS/MOST/ABANDONED ordering laws + the soon.png asset check - ALL PASS.
- `snake_probe`, `geometry_probe` green. Xvfb QA shots: menu (6 dots, fitted
  strip thumb), ask (the two cards only, no snake line), shop (BLUE (ON),
  gray unaffordable, fitted 560 width), run (coin asset on court, bright
  shreds, yellow ball + trail).

## Version

0.2.3 (base 30320: arm32 30321, arm64 30322). Version rule respected (+0.0.1 /
+10). Signature family SHA-256 6db87aca... unchanged.

## PATCH (v0.2.3 patch - same version, same codes, owner review round)

The owner tested the release build: "ok all correct" + three follow-ups.

17. **The SOON ? is total.** The locked and unlocked tiles were correct, but
    the pre-play (the page a tap opens) still showed the FINAL art - the
    sheet headers loaded `g["thumb"]` raw. `_header_block` and `_add_thumb`
    now apply `_soon_art` themselves, so the soon page, the gated page, the
    unlock page and the owned tiles/strips under the `all_owned` cheat all
    wear the purple workshop ? - locked + unlocked + pre-play show ONE image.

18. **Snake peace gets the END button.** Peace never dies on itself, so a
    quiet run could never be banked. `pause_end_run = peace` (set at setup
    and on the style toggle) gives the pause sheet its END row; the new
    `_goga_pause_end_ok` override keeps it to `_phase == "run"` - the ask,
    mode menu and ready card pause with the plain pair. The banking states
    the /0 rule: the dead menu prints "peace run - score bonus = S/0"
    instead of the fake "0 + 0" theatre, and the payout pays nothing
    (score_bonus_enabled was already the modular zero).

19. **Dev cheats toggle everything.** The dev sheet (five taps on the
    wordmark) grew the GAME OPTIONALS section: 13 rows of the games' OWN
    settings - snake more-enemies / pack size / power fruits / bugs /
    obstacles / jumping fruits / peace style / no-walls / place, pong more
    enemies / size / speed / sparkles. A flip is a REAL setting that also
    grants its shop unlock FOR REAL (logged under `__dev__`); ALL ON / ALL
    OFF sweep every feature row (peace style stays solo, the cycles are
    manual); RESET returns every flip to its default and removes exactly
    the granted unlocks - a real coin purchase survives. Found on the way:
    Godot 4.7 refuses `String(int)` (the pack-size cycle) - `str()` is the
    law for Variant values; the sheet-render test now walks every row.

Tests: flow_test grew the SOON-law suite (tiles AND page headers), the
peace-END economy suite (banks the score, pays zero, /0 safe) and the
optionals suite; snake_probe + pong_probe + geometry green; Xvfb QA shots
verified the dev sheet layout and the soon-page purple ?.

Version: stays 0.2.3 (base 30320: arm32 30321, arm64 30322), the v0.2.1a
precedent. Signature family SHA-256 6db87aca... unchanged.

## PATCH ROUND 2 - the owner's next-batch list (same version, same codes)

20. **Dev cheats: the toggle crash is DEAD - twice over.** Two real defects
    were behind "crash after each option toggle": (a) every flip REBUILT the
    sheet inside the tap callback, and (b) the rebuild's `_close_sheet`
    freed "the last 2 children of _root" - with no sheet yet up those two
    were the FEED MARGIN and the TOAST OVERLAY, so the first open nuked the
    menu content and the next tick/toggle walked into freed instances
    (signal 11, reproduced headless). THE PAIR LAW: `_sheet_base` records
    the exact dim+center pair it appended; `_close_sheet` frees exactly
    that pair - never "the last children". The quit-confirm rides
    `_sheet_base` now too. AND the flips no longer rebuild anything: a
    switch row rewrites its own label, repaints itself, toasts "noted -
    the box reloads on close", and the feed reloads from the live cheats
    when the sheet CLOSES (DONE button or back).

21. **Dev cheats: RESTART BOX.** The pinned action row (DONE + RESTART BOX)
    sits under the sheet; RESTART saves and reboots the whole box via a
    deferred scene reload.

22. **Dev cheats: "owned" is gone, optionals are gone, CODE is in.** The
    switch list is ALL_OWNED / GOGACOINS / BATTERY / CODE - all_owned is
    THE ownership cheat (the owner: "removing it and keeping all owned is
    much better anyway"); the whole GAME OPTIONALS table + its grant/reset
    machinery left the store (the owner: "i can buy using the infinite
    money"). CODE is the five-tap knock's arm switch: 1 (default) = the
    knock opens the sheet, 0 = the five taps do NOTHING.

23. **The carousel pre-play tap works.** The strip cards were registered on
    the OUTER feed scroll, but the nested strip scroll (also a BoxScroll)
    captured the touch first and marked the release handled - the tap never
    fired ("when i tap a game it does not show its pre-play menu"). THE
    NESTED-SCROLL LAW: `_nested_scroll_at` - a BoxScroll never captures a
    touch that lands inside a deeper BoxScroll; the cards now register on
    the strip itself, and the feed's index can never stick.

24. **Pong: the shop's dark overlay is dead.** A buy/skin re-opened the
    shop INSIDE the open shop, and the old teardown freed only the sheet's
    panel - Arc.sheet's dim+center are SIBLINGS, so every rebuy leaked one
    more full-screen STOP-mouse dim: the leaked stack WAS the dark overlay
    that ate every touch. The shop now owns its exact dim+center pair
    (`_shop_sheet_down`) and frees BOTH on every open/close.

25. **Pong: options land THE SECOND you tap them.** The optionals strip
    rebuilds the world on every toggle (`_rebuild_for_orientation`), and
    `_begin_run` rebuilds once more so every run starts on a world that
    matches the CURRENT options - size/speed/sparkles already read live;
    more-enemies spawned/despawned next boot ("fix this and make sure it
    does not happen with other stuff").

26. **Pong: the two courts really differ.** BOTH courts seat the USER at
    the bottom and the enemy up top; horizontal defends the WIDE bottom
    (short warning, huge span) with the more-enemy walls on the SMALL
    left/right edges, vertical crosses the LONG depth with the extras on
    the LONG side edges - "not just another angles". The center line lies
    along X in both.

27. **Pong: the extra walls are faster and smarter.** AI_SPEED_EXTRA
    356 -> 500 (quicker than the main rival - the owner's own prescribed
    fix for their short land of view on the small walls); per-pad brain
    knobs: extras think every 0.10s (main 0.13) and steady their aim
    (err 0.18 of the pad, main 0.30).

28. **Space Dodge.** The lane-dodger shipped as "Geometry Flash" but it was
    never the owner's Geometry Flash - it is SPACE DODGE now (id stays
    `lanes`; saves, orders and tests untouched; the spaceship thumb already
    fit). The REAL Geometry Flash joins the workshop as a SOON teaser
    (id `geometry`, direct reveal, visible from the start, never a
    mystery) - "put it as soon".

29. **The parking lot grew.** FUTURE_GAMES.md fourth dump: sokoban-like,
    amaze-go arrow maze (every tile wears an arrow, the rider SLIDES the
    chain), tomb-of-the-mask old maze (the character takes the WHOLE line,
    not steps), and Geometry Flash documented as the name that came home.

Tests: flow_test grew the dev-cheats suite (no owned switch, CODE arm +
default-1, all_owned-only ownership, optionals machinery gone, every sheet
row renders, a flip notes itself WITHOUT a rebuild, the feed reloads on
close, the strip tappables + the nested-defer law) and the registry suite
grew the rename + the 7th teaser; pong_probe grew the live-toggle, the two
courts and the extras-brain laws; snake_probe + geometry green; Xvfb QA
verified the new dev sheet (4 toggle rounds, zero crashes) and shot both
courts. Found on the way: a lambda can never reference the button its own
`Arc.button(...)` initializer is still declaring - build the row, THEN
connect.

Version: stays 0.2.3 (base 30320: arm32 30321, arm64 30322). Signature
family SHA-256 6db87aca... unchanged.
