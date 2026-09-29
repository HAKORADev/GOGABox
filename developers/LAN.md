# LAN.md — local multiplayer

GOGABox has a built-in LAN system: one player hosts a session on their
wifi, everyone else joins from the multiplayer menu, and the whole thing
runs on the local network — no servers, no accounts, nothing online. A
game can ignore all of it (single-player games are invisible to the LAN
radar) or sit in it with one tag.

## The tag

In `game.json`:

```json
"lan": {
  "players": 4,
  "platforms": ["android", "pc"],
  "cross": true
}
```

- `players` — the seat ceiling for one room (2..4 for turn-passing games
  today; the session itself holds up to 12 people).
- `platforms` — which devices may sit in a room of this game.
- `cross` — mixed phone+PC rooms allowed.

With the tag, the box derives the search chips (`lan`, `lan_2p`..`4p`,
`lan_cross`...), shows the PLAYERS badge on your tile, seats the session
lines on your pre-play page, and opens the system waiting room when your
game starts inside a live session. Your game code checks the seat like
the shipped games do (see `snake`, `rally`, `domino` — each wears a
slightly different relay shape, from shared-board turns to mirrored
real-time).

## What the box owns (you never build this)

- The session: host truth, seats, joins/leaves/kicks, the heartbeat.
- Rooms: many games can run in parallel rooms on one session; the room's
  members are its players in join order.
- The waiting room UI, the chat, the voice chat, the profile faces.
- The locks: mid-match, only the room OWNER changes settings — the box
  guards the shop/options doors for you.

## The rules your game inherits

- The host owns the truth; clients mirror. Relay your turns through the
  session, never simulate the opponent locally.
- The room's seat order is ABSOLUTE — seat 1 is seat 1 on every device,
  same color, same name.
- A match ends for everyone when the host folds it (the END law) —
  nobody plays a folded match.
- In a LAN match the CPU never wakes; a lone player falls through to
  solo automatically.

The LAN leg is strictly LOCAL: the session lives on the wifi's address,
the join sheet takes the host's address, and there is no port mapping,
no room codes, no internet play — by design, since v044.
