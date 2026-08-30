# PLAN v0.1.4 — THE ECONOMY UPDATE (all six owner brainstorms)

Owner directive (2026-08-31): the v0.1.3 economy brainstorms were recorded but
not built ("the v0.1.3 was supposed to include my brainstorms - ok do them in
v0.1.4"). Everything below shipped in this one version. The resolution system
from v0.1.3 is UNTOUCHED - this plan is 100% economy/content.

## 1. THE MYSTERY QUEUE - cap of 4 (Roadmap)

Owner: "Make all available mysteries only up to 4 and others stay inexistent
completely and untracked but inside the code there will be a list so when a
mystery revealed, the code knows what next game to show as mystery."

- `Roadmap.MYSTERY_CAP := 4`; `_mystery_rank(id)` = position in the queue:
  the CATALOG ORDER of mystery-able teasers (kinds orders / inbox / real)
  that are eligible (appear_after met) and still unresolved. That list IS
  "the list inside the code".
- `state()`: an unresolved mystery-able teaser with rank >= 4 -> HIDDEN.
  Inexistent: never rendered (feed_rows skips HIDDEN), never badged, never
  notified, no countdown visible anywhere.
- When an earlier mystery resolves (bought/played/timed out), its slot frees
  and the next teaser in catalog order slides up to MYSTERY automatically
  (pure derivation - no queue state to persist, can't corrupt).
- Queue at launch: dario (orders) -> hen (inbox 20min) -> spud (real 24h) ->
  maze (orders) are the 4 slots; xo + poptd wait beyond the cap.

## 2. LOCKED WITHOUT BEING A MYSTERY (registry)

Owner: "some games be locked without being a mystery and requires owning
games to be bought."

- The `direct` reveal kind shows a REAL tile (name + thumb, never a black
  box) from the start. matcher: appear_after 0 (visible day one), needs 3
  owned games. keys: appear_after 2, needs 4 owned.
- They combine with the GOGACharges meters (section 3): the full flow is
  VISIBLE TILE -> CHARGING (pour charges) -> GATED (own games) -> SOON.

## 3. GOGACharges UNLOCK METERS - 100 / 200 (store + menu)

Owner: "make mysteries have orders about spending GOGACharges and some games
to be unlocked to be bought may require charging like 100 charges or 200,
there will be a button in the pre-play to give it charges and track the
capacity meter."

- GOGACharges ARE the box-bank batteries, spent on purpose:
  - `Box.give_charges(id, n)` pours min(n, bank, meter-room) from the box
    bank into game `id`'s unlock meter (`charges_in`, per-game slot).
  - `Box.charges_spent()` = every box-bank pour ever (give + refills) -
    the currency counter the new mystery order reads.
  - Wipes of game progress do NOT refund the meter (spent economy).
- Registry: `charge_unlock: 100` on matcher, `charge_unlock: 200` on keys.
- New feed state CHARGING: visible, faded thumb, lock, live "charges x/y"
  chip. Resolves through Roadmap.tick the moment the meter fills.
- New pre-play page (_open_charging_page): capacity meter (live-updatable),
  GIVE 10 CHARGES button, box-bank hint, fill celebration + feed refresh.
- Mystery ORDERS gain the `spend_charges` type: maze now also demands
  "spend 50 GOGACharges" (order_lines renders it like any order).

## 4. DAILY LIMITS - rounds / playtime, reset 12AM 00:00 (store + menu)

Owner: "some will have limited rounds per day and get reset at 12AM 00:00
and some have limited playtime per day too, the limit will be visible in the
pre-play menu in a proper place and when reaches the limit, it will fade-out
the thumbnail and shows get back tomorrow to play, some games may have
limited rounds and limited time btw."

- Registry fields `daily_rounds` / `daily_minutes`:
  rally 6 rounds - lanes 6 rounds AND 15 min - slasher 20 min - merge 8
  rounds. snake: NEVER (the starter must stay unblockable).
- Save model: per-game slot `daily = {day, rounds, secs}`; LAZY ROLLOVER at
  the first read after the local day string changes - no timers, no clocks,
  survives kills/timezones; 12AM 00:00 IS the day-string flip.
- `Box.daily_usage/daily_ok`; record_run bumps rounds, add_time bumps secs.
- Oracle: `Roadmap.can_play_now` now includes daily_ok (so the feed chip
  disappears too), `GameHost.launch` refuses capped games, and the
  game-over sheet's PLAY AGAIN refuses with a toast (coins never charged).
- Pre-play page: DAILY LIMIT panel in the proper place (progress + "resets
  at 12 AM"); when reached: thumbnail fades + "daily limit reached - get
  back tomorrow to play". Feed tiles fade + wear "get back tomorrow to
  play" instead of "ready to play".
- The menu's 2s tick watches the local day key and refreshes the feed at
  midnight, so the reset is VISIBLE live.

## 5. TIME WINDOWS VISIBLE PRE-PLAY - live "unlocks at nn AM/PM" (menu)

Owner: "in the pre-play we will ensure that the game times window is
visible ... also fade-out the thumbnail of it and shows unlocks at nn AM/PM
which will feels more responsive while the nn is updates in real-time."

- `Roadmap.window_text` now speaks AM/PM ("playable 4 PM - 10 PM",
  "rests 1 AM - 8 AM"); `Roadmap.fmt_hour` = the 24h -> "12 AM"/"1 PM" math.
- `Roadmap.next_unlock_at(id)` = unix ts the window next opens (0 = open
  now); wrap-safe for overnight windows.
- Pre-play page for a window-blocked game: thumbnail fades + a LIVE line
  "unlocks at 4 PM - in 2h 13m" driven by a 1s page ticker (_page_tick);
  when the window opens while watching, the page REBUILDS ITSELF and the
  PLAY button comes alive without any reopen.

## 6. THE SNAKE ENTRY FIX - partial pay (owner's exploit closure)

Owner: "instead of if coins less than 10 then it's free to play, will make
it if money is +0 and -10, use all money so the player plays and have 0
coins ... also same for retry logic too."

- `Box.snake_entry_cost(fee)` = min(fee, wallet) - THE one rule.
- GameHost.launch: snake charges min(fee, wallet). 0 coins still plays free
  (anti-softlock for the starter). Non-snake games keep the full fee.
- Retry (host_node game-over sheet): same rule at tap time (re-derived -
  the wallet may have moved via the rewarded DOUBLE), button label shows
  the real charge, daily caps + batteries gate BEFORE any coin moves.
- Pre-play button label mirrors it: "PLAY -9" with 9 coins, "PLAY FREE" at 0.
- Guide sheet states it in plain words: "less coins in the box? you play
  for ALL of them".

## Verification

- flow_test: 24 suites ALL PASS, including 5 new ones:
  mystery queue cap 4, GOGACharges meters, snake partial pay, daily limits
  12AM reset, AM/PM + live unlock math.
- geometry_probe: PASS (aspect matrix + end-to-end + rotation ping-pong;
  the new CHARGING tiles fit every design).

## Version

0.1.4 / base 30230 (arm32 30231, arm64 30232). Cert chain unchanged
(overwrite-install safe over 0.1.3).
