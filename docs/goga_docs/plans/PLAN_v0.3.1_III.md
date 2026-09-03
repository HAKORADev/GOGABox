# PLAN v0.3.1 - PATCH III (the owner playtest round II)

Version stays 0.3.1 per owner law ("just make it another v031 patch").
Build codes move UP so overwrite-install works: arm32 30403, arm64 30404.

## FRUIT SLASHER - the collision is WRONG (the circle-slash bug)
Owner: "if i made a circle with the slash, if a fruit get into the circle
thing, it will be cut! each object should have a collision that shaped
like it first, then the slash should only slash when the slash visual
line really collides with the thing from side to side except bomb bombs
when just slash it's side without waiting to pass through it"
- [x] ROOT CAUSE: `_on_drag` cuts anything within `hit_r = 100*scale`
      (~200px swath, 8x the blade ribbon) of the swipe segment - a drawn
      circle around a fruit clips it without the line ever touching it.
- [x] SHAPED COLLISION: every item carries its real shape at launch -
      circle for round produce (apple/basaha/peach/sandia/coin/bomb),
      capsule for the long ones (banana/carrot/eggplant/corn), both
      sized from the DRAWN pixels (r ~= 0.42 of the drawn width), the
      capsule axis rotates with the sprite spin.
- [x] THE CROSSING LAW: a fruit dies only when the slash SEGMENT truly
      crosses its shape (segment-vs-circle / segment-vs-capsule). A line
      beside the fruit, or a loop AROUND it, never entering the shape =
      nothing happens.
- [x] THE BOMB LAW: a bomb detonates on a GRAZE - segment distance to
      its circle < r + blade margin. No pass-through needed.
- [x] probe: near-miss stays alive, a loop around a fruit does NOT cut,
      a real crossing cuts, a bomb graze detonates, a capsule fruit cuts
      only through its own body.

## GOGABOX - the load screen thumbnail is a clipped square
Owner: "the game thumbnail when appears, it looks like a box instead of
the rectangle-like shape and with clipped side edges"
- [x] ROOT CAUSE: loader.gd builds the thumb frame as `Vector2(side,
      side)` (SQUARE) + STRETCH_KEEP_ASPECT_COVERED on a 1.5-aspect
      texture = square crop with the sides cut off.
- [x] FIX: the frame wears the thumbnail's real 3:2 aspect (width-limited),
      the art fits complete, the scan bar sweeps the real height.

## CURSED DARIO - the big list
1. [x] THE DIZZY SPEEDS: bg layers are 3x-scaled sprites while the region
       offset used raw `cam.x * f` -> the mid forest scrolled at 1.5x
       CAMERA speed (faster than the ground!), far at 0.75x. The region
       offset now divides by the scale: apparent speed = f exactly
       (far 0.22, mid 0.5, ground 1.0). Dario's walk speed stays 470
       (the owner: "the movement speed of dario is cool").
2. [x] THE EMPTY UPPER SIDE: the maps were 12 rows with 6 EMPTY sky rows
       = half the screen is nothing. NEW TEN MAPS at 15 rows with a real
       vertical structure (three shelf bands at the 3-row jump rhythm
       11 -> 8 -> 5 -> 2, bats high, spitters on shelves) + THE ZOOM:
       the world renders at k = view_h/(8.5 rows) clamped 1.0..2.4, the
       camera follows dario vertically inside the taller world - the
       dead sky band is never on screen, everything reads bigger.
3. [x] THE SUNK BODY: the landing snapped the player's CENTER onto the
       tile top - half the body underground (and stomps misread as side
       hits). Landing now rests the FEET on the surface: center =
       tile_top - h/2 (ground, ghost platforms, movers, ceilings too).
4. [x] THE SPIKES DO NOTHING: the hazard scan read grid "^" but spikes
       are stored as "." - the scan was DEAD. Spike cells are now real
       entities; touching their band hurts (jumping on them included).
5. [x] THE L4 TELEPORT PLATFORM: the mover carry added `off - last`
       (missing the base) - the FIRST ride frame shoved dario ~-4400px
       = "teleported to the start of the level". The delta is now
       `(a.x + off) - last`. AND the mover art WAS two platforms in one
       texture (the yellow studs row + the plank = "one yellow and one
       red") - re-sliced to the single clean plank.
6. [x] POWER JUMP: was JUMP_V * 2.0 = 4x height ("jump far away"). Now
       JUMP_V * sqrt(2) = EXACTLY 2x the jump distance.
7. [x] ENEMIES HAVE NO PATHS: walkers now patrol LANES (min/max x around
       their spawn, walls/ledges still flip them); blockers CHASE dario
       when he is close; the bat HUNTS (see 9).
8. [x] THE ONE-SIDED PEA SHOOTER: the spitter aimed bolts at dario while
       its body never turned (flip was tied to its zero speed). It now
       FACES dario whenever he is in sight, then shoots.
9. [x] THE BAT IS A DECOR: the fly now HUNTS - when dario is within
       reach it dives at him (screen wake window fixed for the zoom),
       he can stomp it or dodge; otherwise it patrols its hover lane.
10. [x] THE SPIKY TURTLE LIES: the art mapping was INVERTED (spikes-out
        art shown while SAFE, spikes-in art while DEADLY - the owner
        "died when stepped on it without spikes"). Fixed: spikes-out art
        = deadly, in = stompable; the down window is longer (2.6s down /
        1.6s up) and it FLASHES 0.35s before the spikes come out.
11. [x] THE RHINO SPRINT HIT: the blocker IS the rhino (Pixel Adventure
        Rino art). New attack: when it faces dario within ~7 tiles it
        WINDS UP (0.45s flash), then SPRINTS (~2.4x speed) until a wall,
        its lane end or 9 tiles - jump it, dodge it, stomp it after.
12. [x] THE CUP IN THE GROUND: the trophy was centered + offset by eye
        with a padded 128px canvas. It now bottom-aligns to the ground
        via its real opaque bounding box.
13. [x] DEATH = -100 (was -200; registry desc updated).
14. [x] DEATH QUOTES: dario talks when he dies ("i hate it when it
        happens", "one time i may be gone forever...", +8 more) in the
        white bubble after he respawns.
15. [x] THE SMOOTH DEATH: fade to black (0.45s), respawn at the level
        start, fade back in (0.45s). No more instant snap.
16. [x] THE RESTART ROLLBACK: the level start snapshots score + run
        coins; a death restores BOTH (minus the 100 fee) - nothing
        collected in the lost attempt survives.
17. [x] THE WITCHER'S SEAT: her spawn/float height was hardcoded to row
        6 - now it reads her map cell (the 15-row arena hangs her climb
        higher: the ghost ladder is a REAL climb again).

## TESTS / SHIP
- [x] dario_probe: -100 law, the rollback law, the FEET-ON-GROUND law,
      the mover no-teleport law, the spike hazard law, the spiky art
      law, the rhino charge, the bat hunt, the spitter facing, the 2x
      power jump, the 15-row maps + zoom framing law.
- [x] slasher_probe: the shaped-collision laws.
- [x] qa_v031c: LANDSCAPE dario shots (the owner plays landscape) +
      the loader frame + the slasher near-miss.
- [x] build arm32 30403 + arm64 30404 (version stays 0.3.1), backup,
      commit, push.
