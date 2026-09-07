# PLAN v0.3.5-3 - POP SIEGE PATCH 3 (the owner's 14-item v0.3.5-2 report)

The owner's law: "work hard on this and polish the SFXs and the VFXs and the
designs". Every item below carries its AUDITED ROOT CAUSE (the assets and the
code were visually inspected this round - contact sheets in scripts/audit/).

## THE 14 ITEMS -> ROOT CAUSES -> FIXES

1+8. DARTY CROSS (the mis-aim + the detached head)
   - ROOT: pd_data.head_offset gives darty PI/2, but the drawn crossbow's
     arrow tip points RIGHT (offset 0). Longeye's tip points LEFT (offset PI)
     and also got PI/2. Both heads aim 90 degrees off the real shot.
   - ROOT 2: head.offset = (0, -h*0.42) parks the texture ABOVE the pivot, so
     rotating sweeps the whole crossbow AROUND the body - at 90/180 degrees it
     visually detaches ("body in a place, cross somewhere else").
   - ROOT 3: darts spawn at the node origin (the base belly), not the bow.
   - FIX: THE PIVOT LAW v2 - heads rotate around their OWN center seated on
     the mount (offset zero), head_offset becomes darty 0 / longeye PI,
     and every shot spawns at the MUZZLE (per-family distance along the aim).

2. SCORE ICON CLIPPED
   - ROOT: ic_pops.png content lives in the top 38% of its 192px canvas
     (bbox y 8..72). In a 34px KEEP_ASPECT_CENTERED box it renders tiny.
   - FIX: redrawn full-canvas glossy layered bloon (v035p3 art).

3. BLOONS SPAWN FAR AWAY + SEEN OFF-MAP
   - ROOT: entries are IN=2 cells off-board and bloon sprites stay visible
     the whole walk (the field Node2D does not clip). Right-side doors
     surfaced over the folk panel.
   - FIX: IN=1 (one grid away) + THE OFF-STAGE LAW: bloons hidden until the
     march carries them into the field rect (same for children + armor).

4+11. PATH CENTERING + ONE ROW
   - ROOT: every bloon gets lane = rand(-0.26, +0.26) cell - a wobbling
     pack, never a row. (The road paint and the walk share the same
     cell-center spline - audited.)
   - FIX: THE SINGLE FILE LAW - lane is dead, every bloon marches ON the
     path center. Children spread in TIME (dist offsets), not sideways.

5. DECOR PATHS + MULTI-START MAPS
   - ROOT: split-family maps share ONE entry head (branches, not doors);
     every 3rd lane of the highway merges into slabs; waves alternate
     GROUPS across paths which reads as "decor roads" mid-wave.
   - FIX: map data grows starts + wave_mode. NEW LAWS: ROTATE (each wave
     marches from ONE door, the next wave from the next), SLICE (the wave's
     groups alternate doors), BURST (every 3rd wave of a multi-start map
     splits EVERY group across ALL doors - the double-wave feel). At least
     6 maps carry separate doors (twin x3, cross x3, fortress, highway
     rebuilt as 3 true doors).

6. DRAG & DROP DEAD
   - ROOT: the card Control captures the touch (gui.touch_focus); Godot
     routes the following ScreenDrags AND the release to the CARD's
     gui_input - they never reach _unhandled_input, so the ghost never
     moved and the release never placed.
   - FIX: the card itself now drives the drag (local->global conversion,
     ghost follows, release places or cancels), plus mouse-motion support
     for desktop rigs. The unhandled-input escape hatch stays.

7. BUY OPENS ANOTHER WINDOW
   - ROOT: buy callbacks call _shop_open()/_maps_open() while a sheet is
     already open - sheet_push stacks another window every purchase.
   - FIX: THE REFRESH LAW - pop the top sheet, rebuild the SAME sheet in
     place (one window, updated rows). Day/Night toggles ride it too.

9. START LINE = ARROWS ONLY
   - ROOT: the bake draws a 3-ellipse "worn trail" at every door (the owner
     sees 3 circles) and top/bottom doors drew their chevrons off-canvas.
   - FIX: circles deleted; pure chevron arrows drawn for every door side.

10. TOASTS HANG / OVERLAP / FREEZE IN SHOP
   - ROOT: every call built a NEW CanvasLayer overlay; the fade tween lives
     on a pausable node - inside the shop (tree paused) it never fades and
     the layers stack.
   - FIX: THE TOAST LAW - the game base owns ONE overlay (PROCESS_MODE_
     ALWAYS), every game toast goes through it, a new toast kills the old
     tween (newest wins) and the fade always runs, shop or field.

12. WEAK VFX / BROKEN SFX
   - ROOT: p_bomb is an 18px dark dot; boomba's explosion is one flat
     flash; several synth SFX are thin/harsh (audit).
   - FIX: art v3 = real bomb + shell bodies with fuse sparks + trails,
     muzzle flashes, plumper explosions; sfx v3 = re-synthesized shoot /
     boom / pop set with honest envelopes (deeper booms, softer whooshes).

13. MAP DESIGNS BASIC
   - FIX: bake v3 - mottled ground, grass/pebble clusters hugging the road,
     road ruts + worn shoulders, banks around water, themed vignette,
     bolder decor; roads keep the full-cell grid law.

14. Z-ORDER + THE DOORWAY TREE
   - ROOT: props are flat siblings in paint order - a big tree never covers
     the small one "behind" it; nothing stops a giant tree spawning on the
     entry corridor.
   - FIX: THE WORLD SORT LAW - props + heart + folk live in ONE y-sorted
     layer (positioned at their base); the generator bans BIG props within
     2 cells of any door corridor; blimps face the march (nose right).

## DELIVERABLES
- tools/v035p3_pop_maps.py (maps + bakes + thumbs + maps_data.gd twin)
- tools/v035p3_pop_art.py (icon, projectiles, fx, blimp flip)
- tools/v035p3_pop_sfx.py (the re-synth)
- pop_siege.gd + pd_data.gd + game_base.gd (the laws above)
- pd_probe: new checks (offsets, muzzle, single file, off-stage, doors,
  wave modes, entry-safe props, toast singularity)
- version 0.3.5-3 / codes 3063x
