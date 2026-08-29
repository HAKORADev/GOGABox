# GOGABatteries + play windows (v0.0.3)

Healthy-play systems: they lower saturation and addiction pressure WITHOUT
making the box boring. Everything here is honest, timestamp-based math —
no background timers, no drift.

## 1. GOGABatteries (charges)

Two pools, one currency:

| pool | cap | refill | where |
|---|---|---|---|
| game pool | per game (`charges.capacity`, default 10) | +1 / 5 min, **always** (in and out of the box) | `Box.game_battery(id)` |
| box pool | 50 (`Box.BOX_BATTERY_CAP`) | +1 / 5 min, **only while the app is closed** | `Box.box_batteries()` |

- A charged game declares `charges: {"per_round": n, "capacity": n}` in the
  registry. Games WITHOUT the key (snake) never touch batteries.
- Launching a round consumes `per_round` from the GAME pool
  (`Box.consume_round_batteries`). No batteries -> no play.
- Empty game pool? The game page offers **REFILL FROM BOX**: pours the global
  pool into the game pool 1:1 (`Box.refill_game_from_box`). This is what
  makes the box-wide 50 meaningful: an emergency reserve you top up while
  the app is closed.
- Global regen is computed from `meta.closed_ts` (written on
  `NOTIFICATION_APPLICATION_PAUSED`, consumed on `RESUMED`) — literally
  "charges while the app is closed".
- **Notifications**: on pause, Box schedules "batteries full" pings for the
  box pool and every owned charged game that isn't full (AlarmManager via
  plugins/notify). Cancelled on resume / re-armed when pools change.
- Battery UI is drawn dynamically (`Arc.battery_control`): body + level fill,
  color green > 50%, amber > 25%, red below. Top bar chip shows global
  `n/50`; the game page shows the game pool with regen countdown.

## 2. Time windows (third system)

Registry keys on a game:

- `"hours": {"from": 16, "to": 22}`  -> playable ONLY inside the window
- `"blocked_hours": {"from": 1, "to": 8}` -> NOT playable inside the window

Wrap-safe (`from > to` = overnight window). All times are the device's local
hour. The game page disables PLAY with a human reason ("this one rests
01:00-08:00"); `Roadmap.window_ok/window_text` are the single source of
truth. Current users: Snowy Tower (evening arcade 16-22), Geometry Flash
(sleeps 01-08).

## 3. Free play (anti-softlock, narrowed)

Only **Snake** (the starter) is ever free to play when the wallet is empty.
Every other game needs real coins — PLAY shows the fee with the coin icon and
a "need N more GOGACoins" hint when short. This gives GOGACoins real weight
(owner decision, v0.0.3).

## 4. Coin honesty

The game-over sheet now breaks earnings down: `pickups +X · score bonus +Y`,
so coins never feel random. Every coin-priced control carries the coin icon
(`Arc.coin_button`).
