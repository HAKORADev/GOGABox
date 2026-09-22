# v041-2 r2 — TRACKER (the owner's test report → the fix map)

The owner's verdict on r1: Tower Ball is "99.99% broken". The report, mapped:

## A. THE v041-1 BUGS (still open, "deep in the roots")
1. **ROTATION MIS-SCALE** — the orientation override rotates the window, but the
   game CONTENT internally still lays out for the OPPOSITE orientation. A vertical
   game opened with horizontal override = vertical image stretched in the horizontal
   view. Same when a dual-position game is asked for the opposite. Quitting
   re-rotates fine. "one thing deeply in the roots" — the design governor captures
   the window shape BEFORE/without the rotation landing; the game boots wearing the
   stale design. FIND: where the ask (rotate) meets the game load order, and where
   the design (KEEP/EXPAND) reads the window size. The r7 mid-flight guard was NOT
   enough. Suspect: the host reloads the game scene BEFORE the window actually
   reshapes (or before the frame where the OS reports the new size), so the game's
   first layout pass sees the OLD viewport. The fix must be order-of-operations at
   the ROOT: rotate -> wait for the REAL new viewport -> then boot/relayout the game.
2. **CURSOR LEAK** — the Heavy War in-game cursor (the "heavy war menus cursor")
   leaks to the MAIN MENU and ALL other games on click. GOGACursor returns only
   when quitting a game, then the war cursor re-appears on click. Suspect: heavywar
   arms a click cursor image via the shared goga_cursor seat and something
   re-arms it on every LMB (the game_base click-mirror kept a stale image / the
   disarm on quit resets only the normal image, the CLICK image stays war).

## B. TOWER BALL REBUILD (the 99.99% report)
3. **No position selection / no mode selection** — r1 had the optionals menu but
   the game booted straight into tap-anywhere. The optionals (mode + position
   cards) MUST be the first screen after the logo, then the run.
4. **Horizontal-only** — vertical must work (both orientations, both modes).
5. **LIVES REMOVED** — the owner's "(the game ends when you crash yourself with
   no lives)" meant there ARE NO LIVES. Crash = run over. Remove the lives widget.
6. **The empty widget** — replaced by the FIRE GAUGE widget left of the score:
   circular design (like the original Stack Ball), shows charge/heat + active time.
7. **The ball does not exist** — r1's ball never rendered/moved in the owner's
   build. Rebuild the ball FIRST, verify on film, then everything else.
8. **SKINS = DESIGNS, NOT COLORS** — breakable things: glass, rock, wood, water —
   different SHADERS + different BEHAVIORS + different SFX + wow factor. The black
   (death) part ALWAYS stays black. Ball skins: ice, metal, etc. 5 per category,
   first default, rest for GOGACoins.
9. **GAMEPAD** — X button + left/right for platform rotation.
10. **THUMBNAIL** — 2026 look: living world bg following the device's local day
    time (morning/night, sun, sky, clouds, stars, shadows, reflections, softness).
    Also in-game background = living world with the same day cycle.
11. **Fire ball** — exact original values (0.03/break, 1.6s charge, 0.6/s burn,
    0.15/s decay, -0.5 floor), circular gauge, streak works as a VALUE not a count.
12. **VFX upgrades** — platform breaking must feel better than the existing games.

## C. THE BOX (menu/feed)
13. **Doomscroll arrow release** — releasing an arrow key stops dead; must glide
    out with decaying force (same as touch release).
14. **Feed card vertical line** — "all games" cards have a stray vertical line on
    the very right edge reaching ~90% of the thumbnail height. Find and kill.

## D. DELIVER
- label: another round of v041-2 (r2) — no new patch number
- commit -> push -> CI -> Windows (no readme) + Android artifacts + changelog
- probes + film rig + eye pass + regression before push
