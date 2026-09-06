# COSMIC SPUD — PATCH 4 (v0.3.4-4) — the owner's played-again round
(The owner tested v0.3.4-3 on device + the Windows build; this is the fix list.
The GitHub front lives in docs/goga_docs/plans/PLAN_v034p4_ONE_BUILD.md.)

## THE OWNER'S LIST → THE LAWS

1. **"remove the shooting flickers/lights or whatever VFX you did, it's ugly
   anyway"** → **THE NO-SHOOT-VFX LAW**: the muzzle-flash particle is dead
   (the patch-3 FLASH LAW with it), the wobbly aim laser line is dead, and
   the rotated-texture draw branch died with its only user. The gun speaks
   through its sound alone. Hit feedback (iframe flicker, hurt flash, dust,
   sfx) is not shooting VFX and stays.

2. **"the widget you made for gogacoins is not the right widget that is
   universally used in gogabox... you even made the GOGAcoins widget to show
   total coins instead of the collected"** → **THE UNIVERSAL WIDGET LAW**:
   the HUD GOGACoins widget IS `Arc.chip` + `res://assets/ui/coin.png` -
   the exact chip every game's HUD wears - and it counts the coins
   **COLLECTED THIS RUN** (starts 0, ticks via add_run_coins), never the
   wallet total. The total lives in the shop header. Silence law unchanged.

3. **"the shop button opens the game shop which is not what i said it should
   do... shop button opens a list that lets you buy things that costs real
   GOGAcoins like the themes or weapons or the merging"** → **THE SHOP LIST
   LAW**: the HUD SHOP button opens THE SHOP — the universal GOGACoins
   LIST, the invaders/matcher shape (Arc.coin_chip wallet header +
   Arc.coin_button rows + CLOSE). Four shelves, every price REAL GOGACoins:
   - **THE PLACES** — Decayed Desert (free default), Abandoned Park (400)
   - **THE GUNS** — Scatter Spud 300 / Laser Peeler 350 / Rail Tater 450 /
     Gravity Well 550; owning one plants its offer in EVERY wave market
     roll, first in the shelf (the invaders "they join the wave loot" law)
   - **THE LAB** — WEAPON LAB 800 (the merging, learned forever) + FOUNDRY
     500 (merges -25%); the buys flip the SAME tree flags (one source of
     truth) via `CSMeta.gogabuy_node`
   - **THE CREW** — the six allies at 250-400; owning one lists it in the
     deploy rows forever (`meta.own_ally`)
   The four-tab cosmic-coin store is **THE ARMORY** again (the door's
   ARMORY button); the wave market stays the break's own flow. The SHOP
   buys are idempotent-safe (box-owned never double-charges; it syncs the
   game ownership and wears/deploys).

4. **"in the optionals menu when the theme not bought, it says buy nn
   GOGACOINS... it should show the coin icon because this is how the design
   is"** → **THE COIN-ICON PRICE LAW**: a GOGACoins price is NEVER spelled
   out in words. The optionals theme card and the armory themes tab say
   "BUY 400" + THE coin icon (`_cs_coin_button`, the universal
   Arc.coin_button design wearing the CS face). The patch-2 "full words"
   law is dead — the owner overrode it.

5. **"XP and level meters are broken, XP shows always empty and level shows
   always full... the health bar should move dynamically for each HP with
   color goes dynamically from green to red in a better way"** → **THE
   HONEST METERS LAW**: ROOT CAUSE probe-proven (tests/meter_probe rig,
   298 → 100 → 298): a Container (PanelContainer) resets a child's manual
   geometry whenever a sibling's minimum size changes — the HP bar's own
   number label churned every frame and snapped its fill back to FULL;
   every manual-size meter was one sibling-churn away from breaking.
   ALL FOUR meters (HP / XP / wave / boss) are now `_cs_meter` — a
   custom-drawn PLAIN Control no container can touch, drawn trough + fill
   + rim, driven by `set_ratio`:
   - HP **moves** for each HP (animated approach, ~0.2s to settle), color
     runs a continuous green → yellow → red by the true ratio
     (`_hp_color`), number label rides on top.
   - XP shows the TRUE `run_xp / xp_for_run_level(run_level)` and
     animates BOTH ways (a level-up visibly drains it).
   - Wave time + boss HP animate the same way.
   The meter state is probe-readable via the `state` meta.

## DATA
- `CSData.SHOP_GUNS` / `CSData.SHOP_CREW` — the GOGACoins shelves.
- `CSMeta.gogabuy_node(nid)` — the shop's lab buys, one tree truth.

## PROBES
cs_probe 148 checks 0 fails — new batteries: the universal widget (collected
count + the coin icon + the chrome chips), the no-muzzle volley, the four
container-proof meters (ratios settle at the truth, the color ramp, the
level-up drain), the shop list shape (the four shelves + CLOSE + coin icon
everywhere), the shop-guns market guarantee (planted FIRST, 4 offers), the
lab buy → merging_learned, the crew buy → deployable, the coin-icon price
law (no spelled-out GOGACOINS words on the door + the icon present).
flow_test + every game probe green. qa_v034p4 rigs: shop / door / arena.

## VERSION
0.3.4-4 / version_code_base 30510; preset stamps 0.3.4.4; THE one Windows
preset (`Windows x86_32` → `GOGABox.exe`, architecture x86_32 — the
hand-written "x86" value never matched the editor's template names and was
never exported until this patch).
