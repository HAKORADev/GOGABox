# PLAN v0.2.2 — THE SNAKE ECONOMY + PONG BECOMES A GAME

Owner brief: "make v0.2.2 but not a new game...yet!" — the snake gets a
real score economy, and pong rally stops being "a game for no reason".

## SNAKE
1. THE SCORE LAW: the speed multiplier lives INSIDE the score, in correct
   integers. Every award feeds a hidden accumulator; whole points pop out
   when the math crosses 1. At x1.21 five fruits pay 6 and the FIFTH
   fruit is the one that gives 2 (the owner's literal example). Probe:
   jumps == [1,1,1,1,2].
2. Speed is score-based (it already was - now the score itself inflates
   with the multiplier, so the law bites: eating faster literally makes
   the multiplier raise the speed faster).
3. MAN-EATER economics: biting YOURSELF costs the eaten part's value;
   biting OTHERS' tails pays the fruits that part cost - and the victim
   PAYS the same value. Parts are worth LEN_PER_APPLE fractions, scaled
   by the current multiplier, through the same accumulator.
4. KILL REWARDS (the owner's "wrapping-death"): a snake that dies ON
   another snake gifts its points to the killer - player head-to-head
   wins, enemies wrapping into the player's body, enemy-vs-enemy duels;
   dying ON an enemy gifts the run's points to IT. Transfers are exact
   (no multiplier games on a kill). Hunting the war has a meaning now.
5. JUMPING FRUITS (shop unlock 350 + optionals toggle): the fruit lives a
   random 4-7.5s window, vanishes with a poof, reappears elsewhere after
   a 0.7-1.5s void. Catchable, never comfortable.

## PONG (renamed from "Pong Rally"; the registry wears PONG + auto)
1. THE DEAD-BALL BUG: the old game never checked the enemy edge - the
   ball flew away forever. The rebuild scores EVERY edge.
2. THE GOAL ECONOMY: a goal for the user = +1 point, a goal on the user
   = -1 (never below 0). The goals widget shows both counts - the user's
   number in the platform color, the enemy's in red.
3. END (pause sheet): pong has no natural death - the universal pause
   sheet gained an END button (GogaGame.pause_end_run) that banks the
   run through the normal dead menu. The only way to cash out.
4. THE BALL: x1.1 heat per EVERY hit (wall or platform), reset per serve,
   capped at x3.5; it burns yellow -> red with the heat and the tail
   grows longer/brighter (PGB v1.3.8 trail, grown up). Boost = +50%
   until respawn; STRIKE = +200% until the next hit of anything.
5. THE SERVE: the ball is born at the edge of the platform that
   CONCEDED - no farming the same side forever.
6. COINS: spawn every 5-20s FROM THE LAST COLLECTION; the last platform
   that kicked the ball earns the coin; every 3 points pays one bonus
   coin.
7. CONTROLS: hold anywhere, the platform follows the finger ALONG its
   axis only - up/down wander never steals the paddle (vertical courts
   move in X, horizontal courts in Y).
8. THE AI: a prediction tracker with a reaction lag (0.13s), a human
   aim error, a speed cap the heat can beat (not hard), and real returns
   aimed at the user's edge (not stupid). All enemies aim at THE PLAYER.
9. MORE ENEMIES (shop 500 + toggle): two extra platforms on the other
   walls, all hunting the player - more goals both ways.
10. SIZE MODS (shop 400 + toggle, FIXED px): wide +36 / shrink -36
    forever (clamped 64..420 - at the floor/ceiling they do nothing);
    MEGA x3 the normal and MINI x1/3 for 10s. The AI steers returns
    away from bad pickups.
11. SPEED MODS (shop 350 + toggle): the boost/strike badges ride the
    ball, collected by whoever's kick drives it there.
12. SHOP + SKINS: five platform skins (BLUE default free / MINT / EMBER
    / VIOLET / GOLD), PLATFORM SPARKLES (250): the court's light shreds
    wear the platform color + hit dust. The court itself went dark
    (#0e0e13 - the owner's 0a0a0a idea, warmed up) with drifting light
    shreds and owner-colored goal strips.
13. THE POSITION ASK: the universal window-truth ask (the snake's law) -
    vertical plays walls top/bottom, horizontal plays the long side
    edges left/right, designed for both.

## AUDIO (all designed in tools/v022_sfx.py - no downloads)
- pong: serve / hit (pitch bends with the heat) / wall / goal-for /
  concede / coin / pu good / pu bad / strike whoosh / end settle, plus
  THE COURT - a 19.2s dark pulse loop (kick, bass eighths, pad, hats,
  a sparse lead) that loops through the Jukebox.
- The box's music + SFX sliders route every voice (the Jukebox buses).

## BOX
- Registry: rally -> title "PONG", orientation auto, shop true, new
  desc/controls. flow_test's battery-ping stub updated to the new title.
- Thumbnail: rally.png re-crafted in the new language (dark court, the
  burn ball with its tail, the coin + a speed badge).

## TESTS
- tests/pong_probe.gd: 40 checks - the ask, the serve-at-the-conceder,
  +1/-1 clamped, the 3-point coin, the heat law + boost + strike, the
  fixed-px size clamps, the coin economy, the axis-only controls, more
  enemies, the AI intent, END banking.
- snake_probe grew: the fifth-fruit law, the negative carry, the kill
  transfers, the jump window/lock/respawn.
- flow_test green, geometry green, Xvfb shots verified: ask, options
  (ON states), the hot rally, the burn ball, the goals widget, the
  landscape-forced court, the snake score world.
- version 0.2.2 (base 30310: arm32 30311, arm64 30312)
