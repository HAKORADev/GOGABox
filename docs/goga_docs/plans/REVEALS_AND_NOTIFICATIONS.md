# GOGABox — Reveals & Notifications (v0.0.2)

How the feed grows over time, and how the box talks to the player while the
app is closed. This is the spec for `Roadmap` (game/core/roadmap.gd),
`Notify` (addons/notify, native: plugins/notify) and the feed tiles in
game/menu/menu.gd.

## 1. Why

The box must feel like it is ALWAYS growing. Showing every game at once kills
that. Instead: games hide, tease, and reveal as the player plays, buys and
waits. Some reveals need real-world time — that's where local notifications
come in ("come back, something finished baking!").

## 2. Tile states

```
HIDDEN   not rendered at all
MYSTERY  black tile, "?????"  -> tap shows orders progress or a countdown
GATED    revealed but faded + lock: "buy N games to unlock this one"
LOCKED   revealed + purchasable with GOGACoins; "New!" badge until first tap
SOON     workshop game whose conditions are met; script still baking
OWNED    in the library
```

Fresh install feed: Snake (owned) + Dario/Hen/Spud mystery tiles.
After the first Snake run: + Pong Rally (LOCKED, "New!").
The feed keeps growing forever — exactly one branch of the design pillar
"the app will feel always getting bigger and bigger".

## 3. Reveal conditions (registry `"reveal"` dict)

| kind | meaning | example |
|---|---|---|
| `chain` | previous playable game owned AND played >= 1 | rally..merge |
| `orders` | all order lines complete | dario, maze, xo, poptd |
| `inbox`  | total in-box play time >= N minutes | hen (20), matcher (45) |
| `real`   | N real-world hours since the tile first appeared | spud (24h), keys (72h) |

Extra knobs: `appear_after` (owned games needed before the teaser shows at
all), `needs_games` (owned games required to BUY once revealed -> GATED until
met), `price`.

Order line types (`orders`): `spend_in` (coins spent in game X), `earn_in`
(coins earned in game X), `plays` (rounds of game X), `beat_best` (beat the
high score X had when the teaser first appeared — baseline stamped at reveal).
Progress is computed LIVE from Box stats; nothing extra to persist.

State transitions are evaluated by `Roadmap.tick()` (menu refresh, after
runs/unlocks, and a 2s timer) which persists the state per game and emits
`Box.reveal_changed` on HIDDEN/MYSTERY -> LOCKED/GATED/SOON flips (the menu
celebrates those with a toast + jingle).

## 4. Local notifications (plugins/notify)

- Java v1 GodotPlugin (`NotifyPlugin`), no external deps.
- `Notify.schedule(id, title, body, delay_sec)` — AlarmManager
  `setAndAllowWhileIdle`; schedule persisted to SharedPreferences and
  re-armed after reboot by `BootReceiver` (RECEIVE_BOOT_COMPLETED).
- `Notify.cancel(id)` / `cancelAll()`; `permission_granted()` /
  `request_permission()` for Android 13+ POST_NOTIFICATIONS (asked once, on
  first menu open).
- Notification: channel `gogabox_general`, white G glyph
  (android-overlay/.../drawable-nodpi/ic_notify.png), tap opens the app.
- Used today: timed (`real`) mystery games schedule a "come see!" notification
  the moment their tile appears; the notification is cancelled if the reveal
  happens while the app is open. Roadmap._notify_id(game_id) gives stable ids.
- Later (hooks already in place): return reminders, order deadlines.

## 5. GOGACoin flow per game (for the stats screen)

```
entry fee  -> Box.spend + add_spent(game)
shop buys  -> buy_skin -> add_spent(game)
run payout -> Box.earn + add_earned(game)   (score->coins + in-run pickups)
ad double  -> add_earned(game)
play time  -> host accumulates in _process, flushed every 5s + on quit
```
