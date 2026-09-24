# v042 — THE LAN ROUND (master plan + tracker)

> The owner's order (2026-09-24): work the LAN thing completely as v042 —
> core infra + cross-platform + in-games — accurately, all of it, before any
> platform-refactor talk. "we are not working on games as much we are
> working on the deep infra itself". Document first, then work. Tower
> Destroyer stays FROZEN. This file is the working memory: research → plan →
> tracker. The contract doc is ideas/LAN_MULTIPLAYER.md; the vision doc is
> ideas/THE_PLATFORM_ANSWER.md.

## 0. THE OWNER'S SPEC (the order, compressed)

- v042, LAN complete: hosting, joining, the button + its menu, name,
  wait/getting-in logic, solo fallback, CPU→user swap, GOGACoins per device,
  UI widgets, cross-platform (phone + PC in ONE session).
- Games wearing LAN seats: snake, dice conquer (jumpcube), snakes & ladders
  (snl), dominoes (domino), chess, squares, four + five in lines (fourline +
  bovo), THE one 3D game (towerball — TD is frozen), ping pong (rally).
- Multi-level LAN tags: phone-only / PC-only / both / 2P 3P 4P / a
  both-platforms game whose LAN is one platform only — designed for the
  search filters AND the pre-play menu.
- Pre-play page: a line under the LAN tags, live when a session exists —
  "how many players in the pre-play menu out of how many total players, and
  shows how many player waiting"; going-in when all went inside or after 10
  seconds of waiting and others are out; solo fallback when nobody enters.
- Name: EN Unicode letters only, NO emoji, max 20 chars ("the one and the
  only" — his example: "osama bin-ladin" is 15), the one and only identity
  (no @username).
- THE GOGAPROFILE SEED (new, same message): the multiplayer button's menu
  wears TWO options — PROFILE and MULTIPLAYER. A local player profile like a
  GitHub profile: PFP (the simple drawn one-guy), description, supporting
  links, age, role (gamer / developer / owner-unique), gender with "other".
  No database, no username; all details changeable anytime. Profiles stay
  local but resist manipulation via the device's special ID (the
  multi-billion-dollar move) — on BOTH platforms. Profiles must SURVIVE app
  deletion and data wipes (the cursed tricks). Members see each other's
  profiles in a session (visit from the multiplayer menu). This infra is
  needed later (GOGAProfile/ GitHub folders for devs, local push) — noted in
  THE_PLATFORM_ANSWER.md.
- THE VLAN LEG: bundle virtual networking so far players play without setup
  (embedded P2P — the libtailscale/zerotier/EOS shape: UDP hole punching,
  room codes). UI carries proper boxes/areas for LOCAL (LAN IP) and ONLINE
  (room code) tokens — "connection can happen in all directions".
- COMBO CO-OP (local + online under one session): the protocol carries
  per-device local seats (local_slot) so a host device can seat two local
  players beside remote ones — the infra lands in v042, games consume it in
  patches.
- VLANs (Tailscale/ZeroTier/Radmin virtual NICs) are "known things": GOGABox
  makes the LAN, and VLAN players get it for free when the LAN join works on
  a virtual NIC.
- The owner tests cross-platform ONLY (one PC, one phone). Self-testing via
  simulation is mandatory: "run on your machine some weird full simulation
  of 4 players playing or 2 players and different devices so you catch bugs
  that are obvious before me touching something".
- A refactor WILL come later ("there will be a refactor that will happen in
  the very close future") — this round must be good work, not refactor-proof
  work. "this is still not the real work of the infra stuff sooo, we are
  just warming up".

## 1. THE RESEARCH (what the box actually is — verified on c419a471)

- **Greenfield**: zero networking code exists (no ENet/TCP/multiplayer
  anywhere in game/). The notify plugin is the only OS-bridge precedent.
- **The contract**: games extend GogaGame (Node2D) / GogaGame3D (Node3D
  twin, law 51 mirror) — `_goga_setup` / `_goga_tick` / `_goga_input` +
  `finish_run` + sheet/back laws. The host duck-types both twins.
- **The injection pattern (the deep-infra door)**: every turn-based game
  already funnels ALL moves through ONE door that takes "who" —
  `_place` (squares L1111, domino L1693), `_apply_move(m, by_player)` (chess
  L1643), `_drop_disc(c, who)` (fourline L927), `_do_roll` (snl L1329),
  bovo's static core, jumpcube's pure `do_move`. QA rigs already drive these
  doors directly. A network seat drives the SAME doors. No new input path is
  invented — the door is the transport.
- **The seat reference**: towerdestroyer's PlayerSeat dict (angle, alive,
  score, is_cpu, ...) — "the future LAN seat swaps cpu for network and
  nothing else" (FROZEN — read, don't touch).
- **snl already seats 4** (`players 2..4`, `playing` array, round-robin).
  ludo seats 4 armies (X1/X2/X4) — ludo is NOT on the owner's v042 list.
- **Real-time games**: snake (own snake + AI enemies sharing one world),
  rally/pong (pads array with `user` flags, ball on host), towerball (3D,
  seeded round generation in towerball_data).
- **Economy**: fee charged once per launch on EACH DEVICE (GameHost.launch),
  coins recorded per device (`Box.record_run`, `earn`) — the per-device law
  holds by construction in LAN (every device launches its own session).
- **Persistence**: all saves ride `user://` (wiped on uninstall) — the
  profile needs the mirror trick. Windows precedent for wipe-survival: the
  notify toasts write HKCU registry + Scheduled Tasks. Android: the
  `Android/media/<package>/` public dir survives uninstall and is writable
  without permissions.
- **Permissions**: the box holds NO INTERNET permission today (the 0-ads
  OFFLINE LAW). Android forbids ALL sockets without it — even LAN ones. The
  LAN round must add it and say why (THE LAN PERMISSION NOTE).
- **Registry**: `game/core/registry.gd` `GameReg.GAMES` (one dict per game,
  documented schema at the top). Meta vocabulary in `game/core/meta.gd`
  (OS_TAGS/CTRL_TAGS pattern to copy for LAN tags).
- **Menu seams**: `_build_top_bar` (menu.gd L549) for the button;
  `_sheet_base`/`_close_sheet`/`Arc.fit_sheet` for sheets; `_open_search`
  chip rows (L1808) + `_passes_filters` (L1172) + `_save/_restore_feed_state`
  for the LAN filter; `_open_game_page` tag rows (L3254-3300) + `_page_tick`
  (L3558) for the live LAN line; settings seat (L2753) as the root-sheet
  pattern; `Arc.safe_poly` is the gate for drawn icons.
- **Tests**: `tools/test.sh gogabox` → flow_test (exit 0); probes are
  scenes run headless or under Xvfb (`/tmp/my-project/godot` works today).
  flow_test pins `playable().size() == 31` — no new games this round, so it
  holds.
- **Version law**: 0.4.1-3 → **0.4.2**, code base 31430 → **31440**
  (arm32 31441, arm64 31442), exe stamp `0.4.2.0`.

## 2. THE ARCHITECTURE (the deep infra)

### 2.1 The core — `game/core/lan.gd` (autoload `LAN`)

A LANBus core with a device singleton:

- **Transport**: plain TCP — `TCPServer` (host) + `StreamPeerTCP` (join),
  newline-delimited JSON messages (the box's own idiom). Default port
  **31440** (the code base number), +1..+9 retry on bind failure.
- **Identity**: every device carries `dev` (OS.get_unique_id, salted hash),
  `name` (the sanitized profile name), `pfp` variant, `role`.
- **Session state machine**: `idle → hosting|joining → lobby → (per-game:
  hold → match) → lobby` — the session dies with the app (THE HOST/JOIN
  LAW); the host owns the truth, clients mirror (host authority).
- **Seats**: `[{dev, name, pfp, role, seat, local_slot, state}]` —
  `local_slot` = combo co-op (0 = main, 1 = the host's second local seat);
  arrival order FIXES seat order (THE SEAT LAW).
- **Heartbeat**: 3s ping, 10s prune — silent deaths never ghost the lobby.
- **The hold system** (per game id, THE CROSS-GAME LAW): members report
  `open(game)`; the host aggregates who is HOLDING which game; the hold
  screen mirrors arrivals live; when someone commits → the host runs THE
  TEN SECONDS countdown (host clock, broadcast) — all in or quit → the
  match starts with the committed seats; a lone holder after a grace
  fallthrough plays solo (CPU restored — the REAL-ONLY LAW binds LAN
  matches, not solo).
- **The match relay**: `start{game, seed, seats}` (host broadcast, the seed
  = every device's RNG law so board games stay deterministic), then:
  - **TURN_RELAY** (board games): the acting seat broadcasts
    `act{game, who, a}`; every device applies it through the game's own move
    door. CPU seats simply do not exist in the match.
  - **HOST_AUTH** (pong): the host simulates the ball, 20 Hz `snap`
    broadcasts, clients interpolate; each device owns its pad's input
    locally (`in` messages).
  - **SELF_AUTH** (snake): every device simulates the shared world with the
    same seed; each device broadcasts its snake's direction changes; each
    device owns its own death (`die` broadcast); coins/events deterministic
    from the shared seed.
  - **RACE** (towerball): identical seeded towers on every device, only
    progress broadcasts (`prog{round, score}`, `die`) — last alive wins.
- **End of match**: `end{game, results}` — placements, then everyone's
  session returns to the lobby state. Fees/coins stay per device.
- **THE VLAN LEG (r1)**: the host attempts `UPnP.add_port_mapping(31440)`;
  a room code is the compact reversible encoding of `ip:port`
  (`GOGA-XXXX-XXXX-XXXX-XXXX`, base32, checksum char) — works over the
  internet with UPnP, works unchanged over any VLAN NIC (Tailscale/ZeroTier
  IPs are just IPs to the LAN join). The embedded virtual net (bundled
  libzerotier/EOS-style, zero-setup NAT traversal) is the documented PATCH
  PATH — it needs a native SDK decision and its own round.
- **Name sanitize**: Latin letters + space + `'` `.` `-` only (EN Unicode
  law), collapse spaces, trim, max 20, min 2, emoji/digits/CJK rejected at
  input AND at protocol intake (never trust a peer's name either).

### 2.2 The profile — `game/core/lan_profile.gd` (class LanProfile)

- **Fields**: `name` (the law above), `pfp` (drawn one-guy variant 0..7),
  `desc` (short bio), `links` (up to 3 http(s) strings), `age` (int),
  `role` ("gamer" | "developer" | "owner"), `gender` ("male" | "female" |
  "other"), `anchor` (the device salted hash).
- **The role law**: gamer/developer are freely choosable; `owner` is UNIQUE
  — first device to claim it keeps it (the claim is recorded under the
  anchor; a second device sees OWNER TAKEN). Honest note: with no server
  this is local-truth enforcement, documented as such.
- **The anchor law (the multi-billion-dollar move)**: `anchor = hash(OS.get_unique_id() + salt)`
  stored INSIDE the profile; sessions broadcast a short anchor hash so a
  cloned profile shows up as a GHOST (two seats, one anchor) in the lobby.
  No manipulation-proofness is claimed beyond that — no server exists.
- **THE SURVIVAL LAW (profiles never die with the app)**:
  - primary: `user://goga_profile.json`;
  - Android mirror: `/storage/emulated/0/Android/media/hakora.dev.gogabox/goga_profile/goga_profile.json`
    (the public per-package media dir — writable without permission, NOT
    removed on uninstall/data-clear);
  - Windows mirror: `%USERPROFILE%/GOGABox/profile/goga_profile.json`;
  - sync rule: the NEWEST copy wins (`saved_ts` inside), re-mirrored on
    every save and on every load. A wiped app re-adopts its own mirror on
    first boot.
- **The box save** gets a `profile` mirror too (store.gd `_defaults()`), so
  the menu reads one place; the mirror files are the durable truth.

### 2.3 The hold widget — `game/core/lan_hold.gd` (class LanHold, CanvasLayer)

System-owned (games get it free): seconds counter, arrivals with names +
PFPs, live session mirror, THE TEN SECONDS countdown, the lone fallthrough
note, CANCEL (back to box). Instantiated by both twins through their base
(`lan_hold_open()/lan_hold_close()` on GogaGame + GogaGame3D — the TWIN LAW
holds; the widget itself is ONE shared class). While a hold overlay lives,
the base input gate eats local input (same gate as sheets).

### 2.4 The registry vocabulary — the multi-level tags

New optional entry field (documented in the schema header):

```gdscript
"lan": {"players": 4, "platforms": ["android", "pc"], "cross": true}
```

- `players` = the LAN seat ceiling (2..4; no field = OUT OF RADAR — a 1-seat
  game never joins the LAN dance, THE OUT-OF-RADAR LAW).
- `platforms` = which device platforms may SIT in this game's LAN sessions.
- `cross` = mixed phone+PC sessions allowed.
- Derived tag ids (`Meta.lan_list(g)`): `lan` (any), `lan_phone` /
  `lan_pc` (single-platform sessions — a both-platforms game with
  `cross:false` wears BOTH), `lan_cross` (mixed sessions), `lan_2p` /
  `lan_3p` / `lan_4p` (the seat ceiling). Labels + chips in meta.gd next to
  OS_TAGS/CTRL_TAGS. The PLAYERS badge (its own area, never a genre badge):
  cards + the pre-play header show `PLAYERS 2-4`-style chips from the same
  field.

### 2.5 The menu surfaces (house style, laws 42/43/55 obeyed)

- **The button**: top bar icon — code-drawn plus+human through
  `Arc.safe_poly` (THE MENU BUTTON LAW: drawn, never an emoji glyph).
- **Its menu**: TWO options — PROFILE / MULTIPLAYER (full-width dark
  buttons, the settings seat).
- **PROFILE sheet**: view/edit — name field (sanitized live, 20), PFP
  variant picker (drawn figures), description, links, age, role, gender;
  OWNER TAKEN state where it applies.
- **MULTIPLAYER sheet**: the name row (edit shortcut), HOST (address +
  room code + session row with DELETE + members), JOIN (two boxes: LOCAL —
  IP:port; ONLINE — room code, with the VLAN one-liner), members list with
  visit-profile, LEAVE.
- **Search**: one more chip row `LAN` (ANY / 2P / 3P / 4P / CROSS / PHONE /
  PC), `_filter_lan`, `_passes_filters` clause, CLEAR reset, feed-state
  round-trip (THE RETURN LAW).
- **Pre-play**: the LAN tag chips row + THE LIVE LINE under it (when a
  session exists): `LAN: IN SESSION 3/4 · WAITING 1` for THIS game,
  `_page_tick`-driven; on games without it, nothing shows.
- **Cards**: the PLAYERS badge area on LAN games.

### 2.6 The games (the seat work, one pattern)

Every integration: (1) registry `"lan"` field; (2) the match boots through
`LAN` seats (`players`/`playing`/seats FROM the session, never the mode
sheet); (3) the acting human broadcasts through the move door
(`act` messages), receivers apply through the SAME door; (4) CPU seats are
not built in LAN matches (REAL-ONLY); (5) turn banners show profile names;
(6) `_resolve` rewards per the game's own laws on every device
(deterministic); (7) probe coverage.

| game | seats | model | the door(s) |
|---|---|---|---|
| snl | 2-4 | TURN_RELAY + shared seed | `_do_roll` / `roll` broadcast |
| domino | 2 | TURN_RELAY + private deal | `_place(who, hi, side)` / `_pass` |
| chess | 2 | TURN_RELAY | `_apply_move(m, by_player)` |
| squares | 2 | TURN_RELAY | `_place(e, who)` |
| fourline | 2 | TURN_RELAY | `_drop_disc(c, who)` |
| bovo | 2 | TURN_RELAY | the stone-place door |
| jumpcube | 2-4? | TURN_RELAY | `do_move` + roll broadcast |
| snake | 2-4 | SELF_AUTH + shared seed | dir broadcasts + `die` |
| rally (pong) | 2 | HOST_AUTH (ball) | pads local, snaps 20 Hz |
| towerball | 2-4 | RACE (seeded towers) | `prog` / `die` |

(The exact ceiling per game follows its real design — single-door games are
2P; the 4-seat ceilings go to snl/jumpcube/snake/towerball.)

### 2.7 The permission note (THE LAN PERMISSION)

Android needs `permissions/internet=true` (both presets) or every socket
dies — even on a LAN. The box gains NO servers, NO telemetry, NO online
services: it is a peer-to-peer LAN permission. The 0-ADS + OFFLINE-BEHAVIOR
laws stand; AGENTS.md §4 gets the amendment line and RELEASE_LAW gets the
note.

## 3. THE TRACKER

- [x] 1. research mapped (this file §1)
- [x] 2. docs first: LAN_MULTIPLAYER.md v042 section + THE_PLATFORM_ANSWER.md profile seed + this file
- [x] 3. LAN core: lan.gd (transport/session/hold/relay/code) + lan_profile.gd + project.godot autoload
- [x] 4. lan_hold.gd widget + base/3D twin hooks
- [x] 5. registry lan fields (10 games) + Meta.lan_* vocabulary + badge
- [x] 6. menu: button + PROFILE/MULTIPLAYER menus + profile sheets + join/host boxes (local + online)
- [x] 7. search LAN chips + pre-play LAN tags row + the live LAN line
- [x] 8. games: snl, squares, fourline, bovo, chess, domino, jumpcube (TURN_RELAY)
- [x] 9. games: snake (SELF_AUTH), rally (HOST_AUTH), towerball (RACE)
- [x] 10. tests: qa_v042_lan (the 4-device loopback sim) + flow_test LAN laws
- [x] 11. permissions + version 0.4.2/31440 + exe stamp + AGENTS laws + RELEASE_LAW note
- [x] 12. flow_test green + lan probe green + eye pass under Xvfb
- [x] 13. worklogs + push + CI watch

## 4. THE DECISIONS (taken while building)

- **"the one 3D game" = towerball** — towerdestroyer is FROZEN by the
  owner's earlier order ("we will ignore it for now"), and towerball is the
  graduated 3D game. If the owner meant TD, the seat work ports over cheap
  (the PlayerSeat pattern is the reference).
- **five in lines = bovo (FIVE IN ROW)** — the registry's five-in-line game.
- **The hold screen lives in the GAME session** (the box launches the game,
  the game shows the system hold) — matches the spec's "opened by two or
  more holding players becomes a real-everyone match".
- **Host-authoritative clocks** for the hold countdown and match starts (one
  clock, no drift between devices).
- **TCP JSON lines, not ENet/Godot high-level multiplayer** — debuggable,
  probe-able in-process, platform-flat (same code phone/PC), and the
  protocol survives the coming refactor (the transport is ONE class).
- **ludo stays off the v042 list** (not named by the owner; its X2 armies
  mode is its own patch).
