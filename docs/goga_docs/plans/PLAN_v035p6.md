# PLAN v0.3.5-6 - the pre-GDD polish round (the owner's 3-game list)

Every item below is the owner's own words turned into a law, all verified by
the probes + the qa_v035p6 Xvfb rigs before the build.

## MATCHER

- [x] **THE MATCH SPAWN LAW** (the owner: "drop-down mode still does not spawn
      more items ... spawning be like 3-6 items from a match"): the stream is
      MATCH-DRIVEN now - every match pays its size in parcels into the entry
      queue (a 3-match pays 3, a 5-match pays 5), and a 6+ wave - the full
      8-line included - rolls RANDOM 3..6 instead of paying 8 ("instead of
      dropping 8, make it random between 3-6 so it not be too easy"). The
      autonomous hatch clock is dead.
- [x] **THE ONE-AT-A-TIME LAW** ("each row should have one at a time and once
      one dropped, it will drop the next one from top"): the top line owns at
      most ONE parcel - the next queued parcel rides the refill in only after
      the previous one dropped out of the top line.
- [x] **THE OPENING LAW** ("starts with 2-4 items first"): the round opens
      with 2..4 parcels, each on its OWN row.
- [x] **THE FULL-BOARD LAW** ("the grids with no items takes no gems and I
      have to do one match so it fill them"): the deal never clears the top
      line anymore - the pour fills every seat with gems and the parcels
      replace a few of the not-yet-seen gems. The opened board is FULL.
- [x] **THE ROUND SAVED CHIP** ("the widget 'saved nn' shows total number
      between rounds which is wrong"): the butterflies chip reads the run's
      own `butter_saved` (reset every deal), not the lifetime Box counter.

## COSMIC SPUD

- [x] **THE EXPIRE LAW** ("dropped stuff do not expire ... giving them a time
      to fade out"): every world drop lives 14s, blinks through its last
      3.5s and vanishes. The GOGACoin waits forever (the trophy law).
- [x] **THE BUY-ONLY LAW** ("when I buy a place, it's auto-playing it
      replacing the one I am currently in ... it should just buy it without
      applying it"): the shop only OWNS the place - the worn one stays on;
      the armory's PLACES tab equips owned places for free (WEAR button).
- [x] **THE CLEAR MATH LAW** ("the info menu shows weird stuff in the
      decrease line ... make the math clearer"): the contradictory
      percent-of-base notes are dead. The result line now shows the exact
      ledger equation: `result: 122%  (110% + 20% - 8%)`.

## POP SIEGE

- [x] **THE FACE-IT LAW** ("bomber looks with it's butt and not the face"):
      the atlas mortars are drawn muzzle-RIGHT (the g3 cannon's firing
      opening is plainly on the right end) - head_offset PI -> 0, the
      bomb-thrower aims its face at every fight.
- [x] **THE HEAD TRUTH v3** ("Marichal and kaching looks somehow low
      quality, they need proper modification for their heads"): the war drum
      redrawn (golden standards, lacquered stave shell, double rims with
      bolts, Z-rope tension, crossed mallets, twin-tail banner; steel ->
      brass -> gold) and the bank vault redrawn (a real round safe: riveted
      ring, spoke wheel, dial, keyhole, coin mound + ingots).
- [x] **THE LIVE NIGHT LAW** ("if I opened map menu and selected night at
      the map I play on, it does not switch it dynamically"): the DAY/NIGHT
      chip re-themes the LIVE field the moment it flips (tint + lamp +
      fireflies rebuilt in place, no reload).
- [x] **THE SHOT DIES AT ITS TARGET** ("pyra's shot have that old bomber
      ball bug which is goes then flies forever"): aimed bullets end their
      flight at the aimed point + half a cell of grace - the same law the
      bomber shell got in v0.3.5-4.
- [x] **THE PORTRAIT LAW** ("the design of characters/weapons icons is bad
      ... pyra and boomo are good, make the others like that"): every face
      chip is the g1 head's trimmed content ZOOMED TO FILL the disc (no more
      tiny floating objects in empty circles).
- [x] **THE CENTERLINE TRUTH** ("the bloons are walking on non-perfect
      grid-based movement so they are visualized out of the center and on
      each direction they shift in much weirder positions"): MEASURED - the
      painted road sits at point*64 while the march walked at
      (point+0.5)*64, half a cell off in both axes. The runtime rides the
      raw points now; the march = the paint = the road_cells, and every
      path's walk-in lands exactly on the heart house (probe: 0.00 px
      off-road on the QA rig, 30/30 maps house-true).

## Verification

- matcher_probe 243/0 (x2), cs_probe 197/0, pd_probe 9513/0,
  slasher/merge/dario/tower ALL PASS, invaders ALL PASS on retry (the known
  sandbox flake), flow_test ALL PASS.
- qa_v035p6 Xvfb rigs eyeballed: pop field (bloons ON the paint, boomba's
  muzzle at the aim), pop heads (the new drum + vault in situ), pop night
  (the live field asleep behind the open menu), match drop (full board,
  parcels on own rows, the due queue chip), match butter ("saved 2"), cs
  info (the equation lines), cs expire (only the gogacoin survives 13s).
- version 0.3.5-6 / 30660 (arm32 30661 / arm64 30662), cert 6db87aca...
  unchanged (overwrite-install safe). NO release (the law).
