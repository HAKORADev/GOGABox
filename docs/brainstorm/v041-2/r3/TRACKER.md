# v041-2 r3 — the owner's test report: the input death, the cursor seat, the rotation roots, the Tower Ball flow

## The report (verbatim roots)
- "the game itself even the shop in it and everything, does not listen to
  any inputs at all" (Tower Ball) / "in heavy war XP-level cards selection,
  mouse clicks aren't recognized, the app is not frozen"
- the cursor-leak fix "silently kills custom cursor and turns it off but in
  settings it is still recognized as on ... if i exited, i see system cursor
  and not GOGACursor"
- "the rotation bug has not been fixed at all ... the app only switches
  accurately to F10 switches ... make the automatic switches be the same"
- Tower Ball: position selection FIRST, mode/optionals second, tap anywhere
  last; follow the other games' design; the optionals must not close on back;
  the fire gauge after the score from the left; platforms spin too fast; the
  design is depressed; the thumbnail is bad.

## The roots (all proven, none guessed)
1. THE IMMORTAL BIRTH SHIELD: sheet_push connected the shield's ready AFTER
   add_child (ready fired inside add_child -> the kill-tween never existed),
   and the tween was pause-bound anyway. EVERY sheet since r2 wore a
   permanent full-rect click-eater. -> pause_input_probe A2-A7 (Xvfb).
2. THE DEFERRED-CORPSE CURSOR KILL: the dying game's _exit_tree (queue_free)
   fired AFTER the next seat armed -> the token law.
3. THE MENU'S UNGUARDED size_changed STOMP: the menu rewrote the design
   (pc_menu_design) on every window echo during a game -> the
   one-design-writer law + the boot parity (pc_position restored before
   boot_window) + the gate verifying BOTH truths + _assert_own_design(kind)
   never guessing a default mid-flight (the r7 probe caught my own first
   version of this bug - MIDFLIGHT sample 0 - before the ship).
4. heavywar's ScaleRule.apply() = the poison "design follows the window"
   pattern on PC - removed.

## The Tower Ball r3 changes
- THE FLOW (snake verbatim): orient (the universal phone_*.png cards) ->
  mode (BALL/PLATFORM cards) -> the ready card (TAP ANYWHERE TO START +
  the subline, scale-in). The reload path lands on the mode screen.
  start_orientation skips the ask (the snake law).
- THE BACK LAW: the ask screens are the game's root - back can never close
  them (the shop sheet above them still closes). No stuck state.
- spin: 0.7..2.4 -> 0.4..1.3 rad/s (the readable seat).
- the two-tone discs/rings (top / sides -18% / bottom -38% - baked vertex
  color, zero extra draws) + the brighter ambient + the night sky lifted
  (101a3e/243562, energy 0.85) + the stars walk below the horizon.
- the landscape platform camera floor 15 -> 18 (the pole filled the frame).
- the thumbnail re-captured at the golden hour (the composer reads the real
  raw width - the r2 810 assumption printed black strips).

## The proof
- pause_input_probe: the fixed shield dies running AND paused; clicks land.
- click_probe towerball 16/16 + heavywar 6/6 (REAL clicks end to end).
- towerball_probe 19,952/0; flow_test ALL PASSED; r7 window probe 18/18;
- v0411_r3_window_probe 16/16 (the REAL main scene: launch/reload/quit x
  windowed/fullscreen, 90-frame design sampling each).
