# v041-1 — THE OWNER'S TEST REPORT → WORK PLAN (the patch's own map)

Version target: config 0.4.1-1 / code base 31400 (arm32 31401, arm64 31402), exe 0.4.1.1.
Everything below came verbatim from the owner's v041-1 report. No item may be
skipped or faked; every fix needs a probe check or a rig still before push.

## A. CORE / APP INFRA

1. **LOG SPAM KILL**
   - [x] `Invalid polygon data, triangulation failed` — safe polygon wrapper
     (`UiKit.safe_poly`): skips <3 unique points / zero-area polys, all games
     route their polygon draws through it.
   - [x] `Orientation not supported by this display server` — screen_set_orientation
     calls are Android-only now (host_node + game_base ask-screens).
   - [x] `meta 'gear_btn'` — pop_siege get_meta without default guarded.
   - [x] `Lambda capture freed` + `rp_target null` + `no Tweeners` — host_node
     game-over theatre guards the freed-game path (the 0.55s await vs quit),
     toast/popup tween guards in achiever + Arc.
2. **DEV CHEATS** (five taps on the logo)
   - [x] No app restart anywhere in the flow (store.gd dev flips no longer
     reload the scene; the feed rebuild on close stays).
   - [x] "GIVE EVERYTHING" button: all games owned + full wallet + full
     batteries + every extra ON in one tap (the save-file hand-edit gave
     "some stuff and not all").
3. **RESOLUTION / WINDOW LAWS (the arch seat)**
   - [x] THE BLACK BARS ROOT KILL: Godot attaches the KEEP viewport to the
     design rect only — the rest of the window is NEVER rendered (verified on
     the rig). `ScaleRule.apply_pc` now re-attaches the viewport to the FULL
     window; the bars wear the box brown + the edge veil shades the app edge.
   - [x] Windowed LOCK: free drag-resize disabled (WINDOW_FLAG_RESIZE_DISABLED)
     — the window is always exactly the content's shape, nothing can stretch.
   - [x] THE LAUNCH RACE (the "game stays vertical inside a horizontal window"
     root): GameHost.launch sets active_host BEFORE add_child, so the menu's
     size_changed governor can never force the menu design back over the game.
   - [x] Rotation 1:1 like Android: a game's orientation re-windows/letterboxes
     the app automatically on launch and restores pc_position on exit; manual
     toggles stay blocked in-game (as the owner meant it).
   - [x] F10 flip re-calculates: re_window + apply_pc + layout on every flip;
     the flag law + the attach law kill the stale-scale states.
   - [x] Fullscreen in-game → windowed works: host re-asserts the window law
     (mode + shape + design) every frame on PC; a swallowed F11 can no longer
     strand the box in fullscreen.
4. **DYNAMIC SCALE NUKED** — rcas layer, shader, settings row, Box methods gone.
5. **GOGACURSOR REDESIGN** — new code-forged cursor: gold crosshair (+) with a
   center ball, closed by a circle, gold shading (bright inner lines, brown
   outlines, black outer outline), press/hold frame. The click re-paint bug
   fixed (a game that owns the cursor is never overpainted on click).
6. **SETTINGS** — AUDIO button brown like the rest; CONTROLS rows wear top+bottom
   separator lines; the gamepad line reads the new face-button order.
7. **UNIVERSAL RATE-LIMIT READS** — feed tiles gray by window_ok OR daily (snowy
   tower grays like pong); the "get back tomorrow" chip text shortened; both
   chips can no longer overlap.
8. **COINS CHIP** — main menu wallet = nnnK/M/B (no decimals); top-up keeps the
   exact display.
9. **MENU FEEL** — arrows scroll the feed SMOOTH (velocity ride, no grid steps);
   menu background breathes at 60 on PC; the picks LEFT arrow paints above the
   strip (z-order); the doomscroll shade: heavy at the bottom, light higher,
   plus a bottom spacer so the feed's last tile scrolls clear of the shade.
10. **PRE-PLAY** — platform + controls chips moved to the top of the genres
    section; search filters gain the CONTROLS row (touch / mouse+keys / gamepad).
11. **UI OVERFLOW LAW** — achievement + batteries-character popups autowrap into
    extra lines instead of shrinking/overflowing.
12. **CI** — the Windows artifact ships the exe only (no readmes).

## B. GAMES

13. **PING-PONG AI** — human profiles: reaction delay, speed tracks the ball,
    over-slide misses at high ball speed, 5 real difficulty tiers.
14. **POP SIEGE** — drag ghost: head centered, body alpha like the live look.
15. **SNAKE** — enemies "off" option back; survival gate re-checks the count on
    every change; survival always plays the big land (overrides wall cards);
    dead AI snakes stay dead, win = last alive; the pack wears the box's
    multi-profile AI brains (with programmed failures); fruits x1/x2/x3 sizes
    and values (static size, no snake-scaling).
16. **GOLD MINER** — score floors at 0; TIMED ROUNDS computed from the field
    (gold value, rocks, depth, claw travel) targeting ~60% of the gold; the
    thumbnail is an in-action capture.
17. **MARBLE POPPER** — the big untangle: PC cursor aim + RMB swap; marble at
    the MOUTH (secondary alone at the back); no crawl-to-connect; the insert
    pushes only its own segment; pop-back rolls only the matched segment and
    never freezes the chain; hole idol zooms only when the chain is close
    (faster when closer); win-menu LEVELS only on completion + no stuck-close;
    win text outlined; vanish pops itself only; rainbow-fies the shooter's
    ammo; top-left landing ghost killed.
18. **GEOMETRY FLASH** — stacked obstacles no longer eat a jump (slide/jump
    through; left behind only if the player never jumped).
19. **ROCK BREAKER** — PC: cursor+LMB steer, RMB/SPACE shoot, arrows move free
    (not grid); the rescue bounce heights 50/80/95% of the scene.
20. **HEAVY WAR** — the reticle owns the pointer in play (no box cursor return
    on click); the aim really follows the cursor; mouse = aim+fire only (no
    left-side steering); arrows/A-D steer.
21. **COSMIC SPUD** — arrows/WASD move accurately and stop on release.
22. **FIVE IN ROW PC** — board cells true-sized, no invisible cells (the PC
    subpixel rendering path fixed at the game's draw).

## C. THE HIDDEN BIG THING

The owner's hint: GOGABox's focus shifts from games to something else, and the
core architecture must be ready. This patch is deliberately arch-first: the
window/design state machine, the universal rate-limit reads, the input
translation seat, and the cursor ownership are all ONE law each, in core files,
so the next era can build on them.
