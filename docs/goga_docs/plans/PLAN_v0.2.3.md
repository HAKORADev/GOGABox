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
