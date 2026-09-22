# v041-2 r2 — SOURCE RESEARCH (scraped from the owner's exact sources)

Sources:
- Stack Bounce (gamesnacks, PlayCanvas): https://gamesnacks.com/games/stackbounce
  - game bundle: https://stackbounce.h5games.usercontent.goog/v/1aqsvv0aegbjg/__game-scripts.js (105KB, readable)
- Neon Tower (gamesnacks, famobi + THREE.js): https://gamesnacks.com/games/2mk3ok3s7jl88
  - game bundle: https://2mk3ok3s7jl88.h5games.usercontent.goog/v/39vfhh0oku1j8/game.js (1.7MB, minified, config JSON + logic readable)
- Stack Ball 1.2.38 XAPK (Azur Games, Unity il2cpp): winudf link (downloading; assets + global-metadata for constants)

## NEON TOWER — the exact mechanics (from the decompiled config `Sh` + playerBall class)

THE ANSWER TO "PLATFORM" MODE: the player does NOT move a breakout paddle.
The ball ORBITS the pole at a fixed radius and bounces vertically. The player
ROTATES THE TOWER of ring-platforms under the ball (pole.rotateBy / ball.rotateBy
delegates through the pole). That is why the owner calls it "you control the
platform". It plays like Stack Ball but YOU rotate instead of the tower auto-spinning,
and you TIME nothing — the ball bounces on its own; you steer the gaps under it.

### Original config (verbatim):
```
pointerRotationSensitivity: 0.007      // rad per drag px
keyboardRotationSensitivity: 0.0055
poleRadius: 2.8
poleInterRingHeight: 8.7               // vertical gap between rings
ringRadius: 6.3, ringHeight: 1.2
playerBallRadius: 0.54
playerBallHorizontalOffset: 4.55       // ball orbit radius (inside ring radius)
playerBallVerticalOffset: 6            // bounce apex height
playerBallGravity: -60
playerBallDrag: 0.02                   // QUADRATIC: a = g - sign(v)*v*v*drag
playerBallBounceVelocity: 23
playerBallHitAreaBottom: 0.35, playerBallHitAreaSide: 0.6
wallWidthDeg: 8, wallHeight: {low:3, high:6}
sectorMoveSpeed: {slow:1, fast:3}
comboThreshold: 4
comboColors: ["#54ff00","#88ff40","#aaff80","#ccffc0","#ffffff"]   // 5-step charge ramp
reviveLimit: 1, reviveTimeout: 3000, reviveInvincibilityTime: 3000
ringsLeftToTriggerGeneration: 20
scorePerCoin: 10 (puzzle pickable)
```

### Game loop (playerBall.tick):
- velocity += (gravity - sign(v)*v*v*drag) * dt; y += velocity*dt (ball never moves
  horizontally; angle controlled by rotation)
- pole.checkCollision(ballPrev, ballNext) -> collision events: "bounce" | "hole" | "death" | "complete"
- On "hole" (fell through a gap): score += comboCounter+1 (pending), combo.increment(),
  ring disposed, sound "fall/{9-min(combo,9)}" (9 pitch steps rising with combo!)
- On "bounce": velocity = bounceVelocity (23), combo.reset() — UNLESS combo.canUse()
  (combo meter charged): then the ball SMASHES THROUGH the platform instead
  ("platform-destroyed" sound), combo.use(), falls through, combo continues if still charged
- On "death" (landed on red/danger sector or rotated into a wall): death (or shield)
- rotateBy(amount): pole.getAvailableRotation — you CANNOT rotate through a solid
  sector wall; rotating into its side = death (isRotational)
- Walls stand on rings (widthDeg 8, height 3-6), some MOVE slowly/fast around the ring
- Score pending system: falls bank pendingScore, applied on next solid bounce (classic
  helix-jump feel)

### Level generator (endless in original):
- chunks: "start 0" first; difficulty easy(100%) -> mid steps in at ring 16 (-3/+3),
  hard at 26 (-1), cap at 40; difficultyMap easy[0,0] mid[1,1] hard[2,2]
- pickables rotate in by priority: fallAccelerator (auto-fall booster, 5 crashes),
  shield (survive 1), puzzle (coin pieces; complete = "surfer" coins on 21 rings)
- OUR round conversion: no endless — a round = tower of N rings (150..900 ladder),
  difficulty ramps with depth exactly like the probability table, win = clear the tower.

### Look: neon themes (pole #002b33 + edges #ccf7ff + sector #ff00f0 etc.) — the owner
said NO neon for Tower Ball. We keep the MECHANICS, re-skin to the casual look.

## STACK BOUNCE — the exact stack-ball algorithm (from the PlayCanvas bundle)

### Constants (verbatim):
```
DIST_BETW_RINGS = 0.5, RING_SIZE_Y = 0.5, ANG_BETW_RINGS = -4 deg per ring
ring spin speed: 80.5 deg/sec * slomo * rotatingKoef
ball: gravity -70, jumpForce 5, jumpCD 0.1s, moveDownSpeed 0.5 (dive), ballSize 0.8
ring part thrown: gravity -30, speed random 7..18
camera: follows ball
level ringsCount: irandom(120,200); every 3rd level irandom(200,350)
(preload rings when ballY-16 <= lastRingY)
ring types: 16 types, partsCount 2..8, per-type scale 0.9..1.4, startAngle, shift
ringScaling (breathing ring size) optional: lerp 0.8..1.2
```

### Dive + break law (tryBrokeRing):
- Holding while INGAME: ball moves DOWN at moveDownSpeed (0.5, or boosted lerp) and
  EVERY ring whose top the ball reaches breaks while holding (loop `while a.y-... <= lastNonBrokenY+...: tryBrokeRing()`)
- The part under the ball = ring.partUnderAngle(90) — the part at screen-front angle
- If that part is DEATH and not boosting -> fail flash (red pulse material) -> gameover("hitblack")
- Else: breakRing (parts fly), brokenRings++, progress = broken/ringsCount
- If a ring is "firstTouch" death part: warning pulse (scale 1.2 yoyo x2)

### STREAK + SCORE (exact):
```
n = max(round(streak), 1); streak += 1; addScore(n)
```
so the k-th consecutive break scores k points (1,1,2,3,4... actually 1,1,2,3...:
first break streak=0 -> n=1; second streak=1 -> n=1; third -> 2 ...). Consecutive
= the chain of breaks while diving/bouncing without dying. Break sound pitch
rises: playEx("break", 1 + floor(streak)/7).
Landing on a ring (bounce) does NOT reset the streak in Stack Bounce (streak only
drives pitch+score); the BOOST is the streak resetter.

### THE FIRE BALL (boost) — EXACT original numbers:
```
boostValue starts -0.25 (post-boost floor: -0.5, "cooldown before completely reset")
each break while not boosting/charging: boostValue += 0.03      // ~42 breaks from 0 to 1
boostValue >= 1: slomo = 0.1 (dramatic slow-mo), boostInitTime = 1.6s charge-up,
                 boostInitEffect on ball, "boostinit" sound
after 1.6s: boost() -> boosting = true; ball material = FIREBALL; trail white
while boosting:   boostValue -= 0.6/sec   (active burn ~1.67s of full bar)
while not boosting: boostValue -= 0.15/sec (passive decay when you stop breaking)
boostValue <= 0: stopBoosting, floor -0.5 (the COOLDOWN: from -0.5 the next fill
                 needs 50 breaks)
uiBoost bar visible when boostValue > 0.1
while boosting: dive speed = lerp(0.5*moveDownSpeed, boostSpeed(0.5), boostValue),
                death parts BREAK TOO (nothing kills during fire)
```
The owner said "after 12 platforms feels a little" about MY 12-streak — correct:
the original fills by VALUE (+0.03 per break ≈ 42 breaks), and the bar carries
over between chains (decays 0.15/s when idle, floors at -0.5). NOT a fixed streak
count. The circular design comes from the original Stack Ball (APK) — circular
gauge. Stack Bounce uses a masked bar (uiBoost/maskedBar).

### Death/lives:
- NO lives. One death = gameover (camera shake 0.5s amplitude 25, ball break,
  fade, interstitial). The owner: "the game ends when you crash yourself with
  no lives" = there are NO lives at all — crash = run over. REMOVE the lives system.
- Coin: on the finish platform area, Math.random()>0.9 spawns coin per platform
  (10%) — we keep OUR every-6-rounds coin law (the owner's law beats the source).

### Round flow (exact):
- STATE_INTRO: ball idles bouncing on top ring; tap (mouseY > 0.4 screen) starts
  level + dive control ("tap anywhere to start" — with the shop open it does NOT start)
- Each level: new random STYLE (bgColors/bgFadeColors/platColors/ballMaterials styleID)
  — the original re-colors each level; our skins law (designs, not colors) overrides.
- Level complete: confetti Serpantine x29 at finish, "cracker" sound, vibrate 500ms.

## STACK BALL APK (Azur Games) — for the FIRE BALL circular gauge + feel
(downloading; il2cpp — extract assets: fire textures, sounds, the circular boost
gauge sprites; global-metadata.dat string scan for streak constants)

## THE R2 REBUILD MAP (Tower Ball):
- BALL mode  = Stack Bounce/Stack Ball algorithm EXACTLY (auto-spin 80.5°/s,
  dive-and-break, boost gauge values above, partUnderAngle(90) law)
- PLATFORM mode = Neon Tower EXACTLY (the owner: "make the algorithm accurately
  like the exact originals"): ball orbits+bounces on its own, YOU rotate the tower
  (swipe/arrows/X gamepad), holes fall = combo score (comboCounter+1, threshold 4
  = the smash-through charge), red sectors + walls kill, rotation blocked by walls,
  quadratic drag physics, bounce apex 6, gravity -60, bounceVel 23
- Rounds: both modes round-based on the owner's ladder 150/300/450/600/750/900
  (round 1..6 walks it, 7+ holds 900). Platform mode "platforms" = rings.
- NO lives. Crash = gameover. Score +1 per round win, /5 bonus = coin every 5 wins
  (coin_div 5 — kept from r1, the owner confirmed the economy earlier).
- Fire ball: the EXACT boost values (0.03/break fill, 1.6s charge, 0.6/s burn,
  0.15/s decay, -0.5 floor) + circular gauge widget next to the score.
