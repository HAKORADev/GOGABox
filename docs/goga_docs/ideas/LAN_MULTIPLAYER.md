# LAN MULTIPLAYER — the box-level system (owner spec, v040-7 round; cross-platform update, the v041-3-era reveal)

> The owner's own spec, verbatim-shaped into laws. This is the dedicated
> home of the LOCAL NETWORK multiplayer system — it grew out of the
> parking-lot notes (FUTURE_GAMES.md's "1 2 3 4 player games" mine and the
> WHO-PLAYS-FIRST pairing note, plus BRAINSTORM.md's v0.2.8 "shared
> system, not a game feature" call). DOCUMENT ONLY — nothing here is
> scheduled or built yet. When the owner green-lights it, it becomes a
> `plans/PLAN_vX.Y.Z.md` task list and this file is the contract every
> game and the box both read.

## THE SYSTEM IN ONE BREATH

Players on their own phones, one wifi, no servers: the main menu grows a
multiplayer seat (HOST or JOIN), games that offer multiplayer wear a
PLAYERS badge (1 up to 4), and a multiplayer-capable game opened by two or
more holding players becomes a real-everyone match — CPU eliminated, one
winner, the rest losers.

## THE OWNER'S LAWS (binding, from the v040-7 message)

- **THE LAN LAW**: "it will be a LAN". Local network only — each player
  on their own device, one wifi. No accounts, no internet, no servers.
  This is the device-per-player direction the owner chose back in the
  v0.2.4 note: the per-round economy (fees, GOGACoins, batteries per
  device) works because every player pays from their own wallet.
- **THE MENU BUTTON LAW**: "in main menu there will be button visualized
  as the (symbol + and a human emoji but not emoji)". The multiplayer
  button in the main menu is DRAWN — a plus symbol and a human figure,
  code-drawn icons in the box's own style (never an emoji glyph).
- **THE HOST/JOIN LAW**: "will have two buttons which is host or join".
  - **HOST** "will make IP or something": starts a session and shows the
    address the others join (the device's LAN IP + port). The host "will
    see the active session and can delete it" — a live session row with
    an end/delete action — and the session "will auto-delete when the
    app is closed" (no zombie sessions; closing the app kills it).
  - **JOIN** "will let player to enter IP to join": a text field for the
    host's address, then the handshake.
- **THE PLAYERS BADGE LAW**: "games that offer multiplayer will have
  special badge area and not a normal badge in genres, it will be called
  'players' then show 1 up to 4". A dedicated badge AREA (its own slot,
  visually apart from the genre/sub badges) carrying the supported player
  count 1..4.
- **THE OUT-OF-RADAR LAW**: "a game that is one, it is single player even
  in LAN, completely out of radar". A game whose player count is 1 never
  joins the LAN dance at all — no hold screen, no badge, no multiplayer
  path. The registry carries the count per game; 1 means the system
  pretends the game does not exist.
- **THE HOLD SCREEN LAW**: "a game that is 2 or 2+ when opened it will
  wait in holding screen and seconds counting waiting for others". Every
  multiplayer-capable game opens into a HOLDING SCREEN with a running
  seconds counter. The law of seats: "the one who opened first will be
  first and second will be second" — arrival order fixes the seat order.
- **THE LONE LAW**: "if no one opened the game except one, he will play
  the single player, that's it". One holder alone eventually plays the
  normal single-player game (the hold is not a trap — it waits a grace,
  then falls through to the ordinary game).
- **THE HOLD MIRROR LAW**: "the hold screen will show if others are in
  hold or not" — the screen mirrors the session live: who is holding,
  their name beside their figure. "If there is another one waiting, they
  will appear in the hold screen" as they arrive; "if they left the
  game, they will not show up" — leaves are reflected instantly.
- **THE CROSS-GAME LAW**: "if the others entered, then that's a game gone
  for the one in hold" — holding matches THE SAME GAME only. Players
  holding a different game are a different hold; they never appear in
  this game's screen, and a hold never drags anyone across games.
- **THE TEN SECONDS LAW**: "once they are ready, if someone get into the
  game, others will get 10 seconds count down, all of them should whether
  get in or quit then the game will start". When any holder commits and
  gets into the game, EVERY other holder gets a 10-second countdown —
  each of them either gets in or quits — and then the match starts with
  whoever is in. No infinite waiting once someone has committed.
- **THE NAME LAW**: "in the multiplayer menu in main menu, it will let
  player write display name so it will be displayed next to him (only
  english unicode letters acceptable)". The multiplayer menu owns a
  display-name field — English letters only — shown beside the player
  everywhere the system shows people (the hold screen, the match). The
  name exists "just so players know each other".
- **THE PFP LAW**: "the PFP will just be simple one guy". No avatars, no
  picker — every player is the same simple drawn one-guy figure (the
  menu button's human, reused at person scale). The name is the
  identity; the figure is the face.
- **THE REAL-ONLY LAW**: "in it, CPU will be eliminated, all will be
  real, all sides are real and when one win, others are losers, simple
  logic i mean". A multiplayer match has NO CPU players — every seat is
  a human on a device. The verdict is simple: one winner, everyone else
  a loser. Games keep their own win logic; the system only guarantees
  the seats are real.

## THE GAMES (the owner's list)

"games, like S&L or domino or chess or squares or dice conquer or even
space invaders or more" — the first multiplayer-capable shelf the owner
names: Snakes & Ladders, Domino, Chess, Squares, Conquer Dice, Space
Invaders, and whatever graduates later. Each game's GDD carries its own
multiplayer notes (seat count, what the opponents replace); this system
carries everything shared.

## THE FLOW (the whole loop, end to end)

1. The player opens the multiplayer menu (the plus+human button), writes
   a display name once.
2. HOST starts a session: the box shows the join address and the live
   session row (with delete). The session dies with the app.
3. Another player taps JOIN, enters the address, the handshake lands
   them in the same session.
4. Everyone picks a multiplayer-capable game (the PLAYERS badge shows
   2+). Opening it lands them in that game's HOLDING SCREEN — seconds
   counting, arrivals appearing with their names, leaves vanishing.
5. A holder alone long enough falls through to single player. A holder
   joined by others waits.
6. Someone commits (gets into the game): the rest get the 10-second
   countdown — get in or quit.
7. The match starts with the committed seats, CPU eliminated, all real.
8. One wins; the others lose. The box economy charges/pays per device as
   it always does.

## THE CROSS-PLATFORM UPDATE (the hidden plans, the v041-3-era reveal — document only)

The owner's reveal of 2026-09-24 (see THE_PLATFORM_ANSWER.md, the sequel to
THE_APP_STORE_QUESTION.md) carries LAN forward on three points. Nothing else
in this spec changes — the host/join flow, the hold screen, the ten-seconds
law, the real-only law all stand as written above.

- **THE CROSS-PLATFORM LAW**: LAN will be cross-platform — phones and the
  PC build in ONE session on the same network. The box itself became a
  two-platform ship again in v0.4.0-16's Windows return, and the LAN system
  follows it: a phone holder and a PC holder meet in the same hold screen.
- **THE LAN TAG LAWS**: LAN support becomes TAGGED data on each game:
  - a **platform tag** — which platform(s) a game's LAN supports, so a
    cross-platform session only pairs seats the game actually supports;
  - a **player-count tag** — how many players the game supports. GOGABox
    caps one session at 4 players anyway (the PLAYERS badge 1..4, below);
    the tag carries the game's own supported count inside that ceiling.
- **LAN GETS ITS OWN TAGS**: LAN is its own tag family in
  discovery/search — not squeezed into the genre badges — the same spirit
  as THE PLAYERS BADGE LAW making players its own badge AREA. The tags ride
  the registry entry next to the "players" field (THE OPEN TECH NOTES
  below), so the feed, the store page, the search and the LAN system all
  read the same numbers.

## THE V042 BUILD (the round that built this — 2026-09-24)

The owner green-lit the whole system as **v042** ("work on the LAN thing
completely as v042 ... implement all of it accurately"), with the working
plan in brainstorms/v042/MASTER.md. What the build carries, on top of
everything above:

- **THE CORE** (`game/core/lan.gd`, autoload `LAN`): plain TCP
  (`TCPServer`/`StreamPeerTCP`, JSON lines), port 31440, host-authoritative
  session, heartbeat prune, per-game holds, THE TEN SECONDS countdown on
  the host's one clock, `start{game, seed, seats}` match births with a
  shared seed so every device's board game stays deterministic, and the
  match relays (TURN_RELAY for the board games, HOST_AUTH for the ball,
  SELF_AUTH for snake, RACE for towerball). The session dies with the app.
- **THE CROSS-PLATFORM LAW, BUILT**: phones and the PC build hold the same
  sessions (same TCP road, same UI seats).
- **THE LAN TAGS, BUILT** (the multi-level vocabulary): registry
  `"lan": {"players": 2..4, "platforms": [...], "cross": bool}` → derived
  chips `lan / lan_phone / lan_pc / lan_cross / lan_2p / lan_3p / lan_4p`
  (a both-platforms game with `cross:false` wears lan_phone AND lan_pc —
  the owner's "supports both platforms but LAN is for one platform only").
  They ride the search sheet's LAN row, the pre-play tag rows, and the
  PLAYERS badge (its own area on cards + the pre-play header — never a
  genre badge).
- **THE LIVE LINE, BUILT**: the pre-play page wears, under the LAN tags, a
  live row when a session exists — how many of the session's players hold
  THIS game out of the session size, and how many are waiting in the hold —
  refreshed every second while the page is open.
- **THE GOGAPROFILE** (`game/core/lan_profile.gd` + the PROFILE option in
  the button's menu): the GitHub-shaped local profile — name (EN letters,
  no emoji, max 20), drawn one-guy PFP variants, description, supporting
  links, age, role (gamer / developer / owner-unique), gender with
  "other". The device anchor resists casual manipulation; the
  Android-media + Windows-home mirrors make the profile survive app
  deletion and data wipes. Full laws: THE_PLATFORM_ANSWER.md, THE
  GOGAPROFILE SEED.
- **THE BUTTON, BUILT**: the main menu's plus+human drawn icon opens the
  TWO-OPTION menu: PROFILE / MULTIPLAYER. The multiplayer menu carries the
  name row, HOST (address + room code + the live session row with delete),
  JOIN with TWO boxes — LOCAL (IP:port) and ONLINE (room code) — the
  members list with visit-profile, and LEAVE.
- **THE VLAN LEG (r1)**: the host tries UPnP on the port; a room code is
  the reversible encoding of ip:port (works over the internet with UPnP,
  works unchanged over any VLAN NIC — Tailscale/ZeroTier IPs are just IPs
  to the LOCAL box). The EMBEDDED virtual net (bundled libzerotier/EOS-style
  zero-setup NAT traversal, UDP hole punching) is the documented PATCH
  PATH — it needs a native SDK decision and its own round; the UI's
  ONLINE box is its seat.
- **COMBO CO-OP (the infra)**: seats carry `local_slot` (0/1) so one device
  can seat two local players beside remote ones; the host sheet offers the
  second local seat on 4-seat games; games consume it in patches.
- **THE LAN PERMISSION NOTE**: Android forbids ALL sockets without
  `INTERNET` — even LAN ones. The presets now carry it; the box gains NO
  servers, NO telemetry, NO online services — the OFFLINE-BEHAVIOR law
  stands (peer-to-peer only).
- **THE GAMES, BUILT**: snl (2-4), jumpcube (dice conquer), domino, chess,
  squares, fourline, bovo (five in row) — TURN_RELAY through each game's
  own move door; snake (2-4, SELF_AUTH shared world), rally (ping pong, 2P,
  HOST_AUTH ball), towerball (the 3D game, 2-4 RACE on identical seeded
  towers). CPU seats do not exist in LAN matches (THE REAL-ONLY LAW); a
  lone holder falls through to the ordinary solo game. Tower Destroyer
  stays FROZEN.

## THE OPEN TECH NOTES (for the plan that builds this)

- Transport: plain TCP over the LAN (Godot's StreamPeerTCP/WebSocket
  family) — host = server on a port, join = client to the address. The
  "IP or something" is the host's LAN IP + port, shown as text.
- Session lifecycle: host-owned. A heartbeat (a few seconds) prunes
  silently-gone devices — "if they left the game, they will not show up"
  has to survive crashed apps, not just clean quits.
- The hold screen's seconds counter, seat order and the 10-second
  countdown are SYSTEM-owned (every game gets them free); games only
  implement "start the match with these seats".
- The PLAYERS badge rides the registry entry (a "players" field, 1..4) —
  the feed, the store page and the system all read the same number.
- The display name lives in the box save (one field, English letters
  sanitized at input).
- Fairness note: the per-round economy already charges every device its
  own fee — multiplayer changes WHO you play against, never who pays.

## THE V042-1 PATCH — THE FIRST REPORT ROUND (the owner's eyes on the build)

The owner tested the v042 build (downloaded, not yet a real match) and
the report plus the queued shreds landed as ONE patch. The plan lives in
`docs/brainstorm/v042-1/MASTER.md`; the laws that CHANGE or GROW:

- **THE INPUT LAW (Android first)**: a LineEdit never mutates its own text
  mid-composition, never runs disk work per keystroke, and the OS keyboard
  does the filtering (`virtual_keyboard_type`). A sheet holding a focused
  field never rebuilds itself. This was the double/triple-writing +
  caret-to-head bug that blocked the real match test.
- **THE PFP MEDIA LAW**: the profile's face is the yellow one-guy on the
  brown theme plate (THE ONE PLACEHOLDER), or LOCAL MEDIA — any image the
  engine decodes (png/jpg/webp/bmp/tga), animated GIFs (the box's own
  decoder), or Theora video (.ogv), up to 60 seconds, compressed to 720p,
  hashed (SHA-256) into a 30-day LRU cache (the live face is pinned,
  unused caches swept), riding ONE renderer (`GogaPfp`) that animates
  while focused and paints ONE frame while away. Media travels to
  visitors over the session wire in cached hash-addressed chunks. mp4/
  webm are refused honestly — the engine has no decoder for them.
- **THE VISITOR VIEW LAW**: a visited profile shows the name, the face,
  the ABOUT line, REAL links (validated by the lite `Arc.link_ok` check —
  http(s) or a dotted-domain shape; invalid links never render, valid ones
  open the OS browser), the age (numbers over 21 wear "21+"), and the
  gender. The device anchor + ID lines are GONE (useless). The SHOWCASE
  button opens this exact view for your own profile.
- **THE AGE SELECT LAW**: age is a select menu of numbers, max 3 chars,
  anything above 21 renders "21+".
- **THE ROLE REMOVAL**: gamer/developer/owner chips are gone from the
  profile sheet (useless + tap-dead). The role field survives in the
  protocol for the future dev identities; the sheet no longer offers it.
- **THE ADD-PLAYER LAW**: "add local player" never clones you again. It
  adds a player BY ITS DETAILS (name entry, a combo seat) or by SMART
  NETWORK SCANNING — the UDP discovery service (`lan_find.gd`, port
  31445) lists nearby GOGABox boxes; pressing ADD sends an INVITE and the
  target's app pops the accept sheet that joins the session. The members
  list wears a REMOVE button per row (the host removes anyone; the
  removed device is dropped to the menu with a note).
- **THE BADGE PLACEMENT LAW**: LAN tagging lives in the PRE-PLAY page and
  the SEARCH FILTER — nowhere else. Thumbnails carry NO LAN badge in
  normal play; a small LAN LIVE badge appears ONLY while this device is
  in an active session (host or joiner).
- **THE 3D SEAT CORRECTION**: the owner's word — the 3D game that wears
  LAN is TOWER DESTROYER, not tower ball ("i am not sure if this was my
  or your mistake"). The registry seat moved; TD races on identical seeded
  towers (the v042 towerball RACE pattern, one shooter seat per device);
  towerball returns to solo-only.
- **THE EMBEDDED VIRTUAL NET (the honest line)**: the box ships its own
  UDP discovery + the room-code leg (UPnP + VLAN NICs ride free). A
  bundled ZeroTier/Tailscale userspace stack is a native-library round —
  documented as the next step, never faked in GDScript.
- **THE VOICE LAW**: per-player, two layers — MIC (they hear me) and HEAR
  (I hear them) — toggles on every row including YOU; PCM 16kHz over UDP
  through the host; per-layer device detection (a mic-less PC listens
  only; RECORD_AUDIO is requested at runtime on Android).
- **THE CHAT LAW**: one shared per-session chat, English-only, no emojis,
  name + PFP labels, timestamp (hh:mm:ss) under every message, 1K chars
  per message, a 5-second send cooldown, 100 messages / 10MB then the
  earliest slides out, tap-to-reply (tap again cancels, tap another
  switches) — and it is NEVER saved: the chat dies with the session.
  The seat: a CHAT button in active-multiplayer games between the back
  button and the first game button, plus Ctrl+T on PC.
- **THE PAUSE ROSTER LAW**: the pause sheet wears a MULTIPLAYER button
  opening the roster — every player NUMBER and who is behind it (face,
  name, platform, YOU/HOST), one shared widget for both twins.
- **THE COMBO CONSUMPTION**: turn-based boards (snl + ludo) seat their
  local_slot players for real — one device, two seats, pass-the-device
  turns; each seat's acts carry its own seat number.
- **BOARD LUDO WEARS LAN** (the queued shred): 2-4 armies, TURN_RELAY,
  the shared seeded shuffle, the CPU never wakes in a LAN match.
