# HEAVY WAR — ROGUE ARSENAL (v040-4 rework master notes)
> Owner's verbatim directive, recorded 2026-09-16 (his 6:30 AM, before sleep).
> "just note these things here, even if sandbox got reset, you will not forgot this"
> Prototype: `upload/heavywar_rogue_arsenal.html` (Drive id 1TwxicDpX0U5MTzOpTKfW3XKIUoi3jcO4)
> — an HTML file, all art is code-generated; extract the drawings with code to view them.

## WHY THE REWORK
- We used the original Heavy Weapon's assets as placeholders. v040-4 switches to
  OUR OWN originals: "you will remove all original assets too, you will make all
  your own things accurately with all SFXs and VFXs and proper shaders and animating,
  i bet you could even create assets that looks better than the original".
- The owner speed-ran the prototype ("i am actually too tired so i did the speed-run
  this time") — it contains the fixes we could not land accurately: world movements
  and the tank arm are FIXED in it; the tunnel is NOT accurate yet; tank body design
  is garbage and needs the redesign below.
- Keep the CURRENT Heavy War next to the rework: "copy the original game files
  somewhere else or move them and keep reading from it to make this rework" — the
  current one is semi-complete, lots of logic (shop/economy/waves) migrates from it.
  The new game = the same game, but next to it.

## THE GAME (one line)
"the whole game is some upgrades with shooting and trying to survive the
 semi-endless waves of enemies" — a SURVIVAL ROGUE-LIKE (like Cosmic Spud, our
 other rogue-like — use it as the design reference).

## CONTROLS (from the prototype, his fixes)
- NO NUKES. "i do not want nukes, just aiming and moving."
- "the current movements you did are wrong, if you want to make it correctly, look
  at SNOWY TOWER CONTROLS, i bet they are similar" — read Snowy Tower's control
  scheme and port it.
- Prototype: mouse/keyboard + touch; aim = pointer; steering = hold sides.
  Tank arm follows the AIM (his fix, already in the HTML).

## TANK DESIGN (his notes)
- "tank body looks garbage, i guess there is a design where it could look like a
  BIG ONE TANK PART and putting the weapons at the OUT PART of the side facing
  the player instead of making it the shitty look currently."
- "canon does not shot real balls, they are something else which is bad thing
  i left" — the cannon must fire real cannonballs.
- "the tunnel thing i still has not make it too accurate" — tunnels need work.

## WAVES / PLACES / BOSSES (his numbers)
- Waves much longer: PER TIME + PER ENEMIES, maximum 3 minutes per wave; at max
  the enemy count keeps increasing over and over.
- A place takes 10 WAVES; a BOSS appears after every 10th wave.
- 10 PLACES (not 5 themes): "having 10 different places is more cooler than
  having 5 themes". Each place has EXCLUSIVE enemies + SHARED ones.
- 10 BOSSES (prototype has 5 — double it). "work hard on the designs of each
  boss and enemy and the environment."
- Bosses are TOO EASY in the prototype — make them harder.
- Enemies are DYNAMIC: scale with the tank's power — "when tank gets more
  powerful, they and the bosses do the same."

## PROGRESSION (rogue-like)
- HEALTH SYSTEM instead of life points.
- MANY PER-XP-LEVEL CARDS — "there is many per-XP-level cards that needs attention
  from you because current game difficulty or progression is semi-instant."
- Upgrades must NOT feel like cheating: "i mean the magnet as upgrade or extra
  coins, they should not exist" (as upgrades).
- SCORE = kills only. "score should be only based on kills where each kill is
  extra point."

## SHOP / ECONOMY (from current Heavy War's logic)
- Same shop logic as current Heavy War: extra weapons locked behind the shop,
  tank skins.
- NEW: "mini tanks" — paid for EXPENSIVE gogacoins. In the upgrades shop there
  are 4 mini tanks, each with its own weapon:
  1. ROCKET mini tank
  2. AIM-ABLE MACHINE GUN mini tank
  3. ICE BALLS mini tank (slows enemies)
  4. MAGNET mini tank (collects drops for the big tank)
- GOGACOIN: "should appear after specific amount of time or kills i guess but
  dropping from an enemy when it dies."

## ART / AUDIO BAR
- GOGABox design standards — the prototype's design is "shitty"/poor by his own
  words; keep its MECHANICS, replace its LOOK: "you know what is GOGABox games
  design must look like."
- Enemy planes and other designs "are too poor as fuck, even the environment
  looks bad too."
- All assets OURS: sprites, SFX, VFX, proper shaders, animation. No original
  Heavy Weapon bytes anywhere.

## GOGABOX APP BUGS (owner says MORE IMPORTANT than the game)
1. Feed return position is INACCURATE: sometimes exact, most times a little up,
   except when opening a game at the very bottom. Fix to EXACT state restore.
2. Trophies/achievements menu: CLOSE BUTTON does not close it; ANDROID BACK
   button instead shows the exit-GOGABox dialog. Both must close the menu.
3. Exit-GOGABox dialog: strip the "too helpful details that not needed, let
   title and the buttons."

## DELIVERY
- Push v040-4 when done — owner wakes up, tests, returns "with a cool report
  for everything with long list of findings."
- Next reports will have NO videos (upload too slow) — self-testing quality
  matters more (THE VISION LAW, AGENTS.md method 32).
