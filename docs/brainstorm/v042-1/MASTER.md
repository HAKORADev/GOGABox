# v042-1 — THE LAN FIRST PATCH (master plan + tracker)

> The owner's order (2026-09-24): the v042 test report worked to the bone,
> plus every queued shred ("if yes, do it as part of this patch too") —
> the embedded virtual net, board ludo, combo per-game. And the bar: "it
> currently looks like a dummy and not real thing...yet, so make sure that
> it is real or at least will be real so i do not have to test another
> dummy build". Document first, then work. This file is the working memory.

## 0. THE OWNER'S REPORT (the order, every item)

1. **The LAN button icon is bad** — "the icon of guy and plus is bad, the
   body is not well-done, needs real reworking, probably you can make it
   first in svg then use it".
2. **Android text input is broken** (PC unaffected): every writable field —
   top-up, profile name/description, join boxes — "writes the thing double
   or triple and the head of the writing area is mis-placed... when i write
   something, it puts me before the first or even second letters". Writing
   on Android is "lagging and weird". THE BLOCKER: "the fields of join a
   session both local and online are un-write-able and this is why i was
   not able to test real playing".
3. **Profile rework**:
   - ONE placeholder only — the yellow guy on the brown background, on theme.
   - PFP supports LOCAL MEDIA UPLOAD (an image), shared with others when
     they visit the profile.
   - The PFP is bigger.
   - AGE: a select menu of specific numbers; anything over 21 visualizes as
     "21+"; max 3 chars.
   - ROLES are removed ("it is useless, regardless of the bug that makes it
     impossible to tap/click something in it, just remove it").
   - GENDER must be tappable (it currently is not). The PFP placeholders
     also are not clickable (the IGNORE-mouse bug).
4. **Visitor profile view**: currently only name/role/device — must show
   the "about you" line, the links as REAL executable links, and the age +
   gender. The device anchor + ID lines are useless — removed.
5. **PFP media everywhere**: the uploaded PFP must resize accurately in
   every seat; support ALL image formats ("even webp or webm"), and VIDEOS
   + GIFs as PFPs up to 1 minute, CACHED WITH A HASH (a change busts the
   cache), cache kept up to 30 days, unused caches deleted; a 1-minute
   thing compresses to 720p; videos/GIFs run normally and show ONE FRAME
   when un-focused/away.
6. **Combo "add local player" is wrong**: it "makes a copy of me for no
   reason and i can visit it" — remove that mechanic. Adding a local player
   means adding a player BY ITS DETAILS ONLY, or by SMART NETWORK SCANNING
   (see someone else exists and press add). The members list wears a REMOVE
   button per player.
7. **Thumbnail badges**: LAN tagging belongs in the PRE-PLAY and the SEARCH
   FILTER only — no badge on thumbnails "for no reason"; if a badge shows,
   ONLY while the player (host or joiner) is in an active LAN.
8. **The 3D LAN game was TOWER DESTROYER, not tower ball** ("i am not sure
   if this was my or your mistake" — the v042 decision said towerball
   because TD was frozen; the owner's correction overrides the freeze for
   this one seat).
9. **Link validity**: the app never renders invalid link formats — "all
   links start with http... or ends with .something" — a lite internal
   check decides shown/not-shown in a fraction of a second.
10. **SHOWCASE**: a profile-menu toggle that shows exactly how the profile
    is visible to others.
11. **The queued shreds ride THIS patch**: embedded virtual net, board
    ludo, combo per-game.
12. **In-game multiplayer surface** (the second message):
    - The pause menu wears a MULTIPLAYER button: each player NUMBER and who
      is behind it, "in a proper well-designed way".
    - VOICE CHAT in the same menu: two buttons per player (including YOU) —
      HEARING (they hear me) and LISTENING (I hear them), per-player
      muting on TWO layers (mic + speaker), per-LAYER device detection
      (a mic-less PC listens only; that is OK). His phone has mic +
      speaker, his PC speaker only — that is the test rig.
    - TEXT CHAT: a button in active-multiplayer games BETWEEN the back
      button and the shop button, labeled CHAT; PC shortcut (Ctrl+T); one
      shared chat, no muting; ENGLISH ONLY, no emojis; each message labeled
      with the user name + PFP; up to 100 messages AND 10MB total — the
      earliest slides out (never a full wipe); per-game and NOT SAVED at
      all; a timestamp (hour:minute:second received) under each message;
      tap a message to REPLY, tap again to cancel, tap another to switch;
      1K chars per message; a 5-second cooldown.
13. **"Make sure that it is real"** — every feature above must actually
    work on both platforms. No dummies.

## 1. THE RESEARCH (what the report actually means in the code)

### 1a. The Android input bug — the diagnosis

The known Godot 4 Android IME failure class, all four of our triggers
present at once:

- **Live text mutation** — `_line_row(numeric)` rewrites `le.text = clean`
  on EVERY `text_changed`; on Android this fights the IME's composing
  region: the engine re-syncs the LineEdit against the composition, the
  caret jumps to the head, the composing text re-lands (doubles/triples).
- **Heavy work inside text_changed** — every keystroke in the name/desc
  rows ran `LanProfile.save()` = THREE synchronous file writes (user:// +
  Android/media mirror + JSON.stringify). Frame stalls behind the IME sync
  read as "lagging and weird".
- **Focus steal on keyboard-open** — `windowSoftInputMode=adjustResize`
  resizes the surface when the keyboard shows; the menu's resize path
  re-applies resolution/layout. Any rebuild that touches the sheet while a
  field is composing kills the composition (and Android re-sends it into
  the fresh field = duplicates).
- **The join boxes are plain LineEdits with NO handler** — their
  unwritable feel is the same caret/composition chaos, amplified by the
  sheet's live ticker (`_page_tick`) that REBUILDS the whole LAN sheet
  whenever the session signature changes — typing while a heartbeat/seat
  broadcast lands = the field dies mid-word.

THE FIX LAWS (the input kit):
- NEVER mutate `LineEdit.text`/`caret_column` while typing. Validation
  happens at COMMIT (submit / focus-out / sheet close), never per keystroke.
- NEVER run disk work inside `text_changed`. Saves ride a debounce timer
  (0.6s) + the commit doors.
- The OS keyboard does the filtering: `virtual_keyboard_type` NUMBER for
  digits, URL for links, DEFAULT elsewhere (no letters on a number pad).
- A field's sheet NEVER rebuilds while a field holds focus — the LAN
  ticker's rebuild is deferred until focus is out; `apply_resolution`
  skips re-layout while the virtual keyboard is up (the height returns and
  the layout re-applies then).
- `max_length` stays (engine-side, composition-safe).

### 1b. The IGNORE-mouse kill — why PFP/role/gender were dead

The v042 picker buttons were built following the BoxScroll-tappable
pattern (`b.mouse_filter = IGNORE` + register), but those sheets are NOT
BoxScroll-wrapped (fit_sheet's `_has_slider`/LineEdit rule keeps
LineEditText sheets native). An IGNORE button under plain GUI = a control
that can never be clicked. Fix: the sheet's buttons keep their native
STOP filter. (The role row dies anyway — removed; the gender + PFP rows
come alive.)

### 1c. The PFP media pipeline (the real one)

- **In**: Android SAF via FileDialog access + PC native dialog. Godot's
  runtime ImageLoader reads png/jpg/webp/bmp/tga/pnm — that covers "all
  image formats even webp". Animated GIF: Godot has NO runtime GIF
  decoder — the box ships its own (`pfp_gif.gd`, a pure-GDScript LZW GIF
  decoder, frames + disposal + delays). VIDEO: the engine's only runtime
  streamer is Theora (`VideoStreamTheora`, .ogv) — mp4/webm are H.264/VP8
  and are honestly refused with a toast ("the engine has no decoder — use
  gif/webp/png/jpg/ogv"). THE REAL BAR: refuse what cannot truly play,
  never fake it.
- **Budget**: the media is capped at 60 seconds, resized to fit 720p
  (the long side <= 720), GIFs above 60s of frames truncated. THE OGV
  HONEST NOTE: the engine cannot re-encode video, so a .ogv face rides
  through UN-transcoded - the 16MB import cap and the 60s playback cap
  police it; the 720p compression law is real for images (webp re-encode)
  and GIFs (the decode budget), and documented as "not applicable" for
  ogv rather than faked.
- **The cache law**: content hash (SHA-256 of the source bytes) names the
  cache entry (`user://pfp_cache/<hash>.*` + a .meta json with fps/frames/
  duration/w/h). The profile stores ONLY the hash + meta + a tiny thumb
  (64px webp) — the profile JSON stays small. The visitor's side caches
  received PFPs under the same hash: a re-visit never re-transfers.
- **30 days**: boot-time sweep — cache entries untouched for 30 days are
  deleted; the CURRENT PFP's entry is pinned (never swept).
- **Focus law**: one `GogaPfp` control class renders EVERY seat (variant
  guy / static image / GIF frames / theora video). While its
  `focused` flag is false (a rival's PFP on a row, a game HUD, the menu
  unfocused) it paints ONE frame; focused it animates at the media's fps.
- **The wire**: hello/seats carry `pfp_media` {h, fps, n, dur, w, h,
  bytes}; a visitor pressing VISIT fetches the bytes in base64 chunks
  (`pfp_get` / `pfp_chunk`) capped at 2MB, cached by hash. Variant-PFP
  seats transfer nothing.

### 1d. Smart network scanning (the discovery service)

`lan_find.gd` — the box's own UDP discovery: a GOGABox instance in a
session (host OR joiner answers for the session) answers broadcast pings
on port 31445 with {dev, name, pfp, session_size, is_host}. The add-local
scan and the join sheet both read the same list. The INVITE: the scanner
sends a unicast invite; the target gets an in-app popup (ACCEPT joins the
inviter's session via the carried address). No cloud, no rendezvous —
pure local network.

### 1e. The embedded virtual net — the honest architecture

What v042 shipped: room codes (hex ip:port + checksum) + UPnP mapping +
free VLAN-NIC support (Tailscale/ZeroTier addresses are just IPs).
What this patch adds: the discovery service above + the mesh connect
ladder. What stays OUT (and the doc says why): bundling a real
ZeroTier/Tailscale userspace stack is a C-library/SDK round (libzerotier
or tsnet compiled per-platform) — pure GDScript cannot do NAT traversal
across arbitrary NATs without a rendezvous server. The room-code leg
already crosses networks wherever UPnP or a VLAN NIC exists, and the
ladder (LAN scan -> room code -> UPnP -> VLAN NIC) is the honest "no
setup" path. Documented in LAN_MULTIPLAYER.md, not faked.

### 1f. Voice chat — the real transport

- Capture: `AudioServer` bus "Record" + `AudioEffectCapture`; the mic
  input device is added only when present (`OS.has_feature("web_android")`
  no — `AudioServer.get_input_device_list()` + the RECORD_AUDIO runtime
  permission on Android, `OS.request_permission("RECORD_AUDIO")`).
- Transport: raw `PacketPeerUDP` frames (seat, seq, PCM16 16kHz mono
  20ms) peer-to-peer through the host for 3+ (the host relays; 2P rides
  direct). ~32KB/s per active talker — LAN-flat.
- Playback: one `AudioStreamGenerator` player per remote seat, a 4-frame
  jitter buffer, dropped on toggle-off.
- Layers: my MIC (send) per-player flags ride every packet's `targets`
  mask; my HEAR (receive) gates playback. Device detection per layer:
  `has_mic` (input devices + permission granted), `has_out` (always true
  on both platforms today — the speakers exist; a headset-less TV out
  still counts). A mic-less device's MIC buttons show NO MIC and never
  send.
- THE TWIN LAW: the voice core is an autoload-adjacent Node owned by LAN;
  the pause menu widget is one shared builder both twins mount.

### 1g. Text chat — the real transport

- `LAN.send_chat(text)` -> host relays `chat` lines; the chat state lives
  in the session ONLY (a RingBuffer in lan.gd, never on disk).
- Caps: 1000 chars/message, 100 messages, 10MB total text bytes; the
  earliest message slides out first (never a wipe).
- Each message: {seat, name, pfp(+media meta), text, reply_to, ts} — the
  timestamp is the RECEIVER's arrival clock (hour:minute:second), the
  cooldown is 5s per sender, EN-only no-emoji sanitized at send AND at
  receive (never trust a peer).
- UI: `lan_chat_ui.gd` — one shared builder; the game HUD wears the CHAT
  button between back and the first game button ONLY in active
  multiplayer matches (lan_seats not empty), PC rides Ctrl+T.

### 1h. Tower Destroyer wears the LAN seat

The registry entry moves (towerball loses `lan`, TD gains it). TD's RACE:
identical seeded platform sequences (the match seed rides the per-platform
spawn RNG), every device simulates ONLY its own cannon (the PlayerSeat
law: the input source swaps, nothing else), progress relays {score, dead}
exactly like towerball's race, verdict = last shooter standing; the
towerball LAN block is stripped (registry + code) so no dead code remains.
The freeze note: the owner's correction overrides the freeze for THIS
seat only — nothing else in TD changes.

### 1i. Board ludo wears LAN

The snl TURN_RELAY pattern: lan_match_start seeds the shared RNG + seats
the armies (2-4, one army per seat), the roll + the move are the two
relayed acts, THE SEAT PERSPECTIVE LAW holds (the local player's army
renders as seat 1 on every device), the CPU never wakes in a LAN match.

### 1j. Combo per-game (the pass-the-device law)

The v042 infra carries local_slot seats; this patch makes the TURN-BASED
boards consume them (snl + ludo first): "my turn" becomes "one of MY
seats' turns" — the die rolls per seat, each seat's move is sent with its
own seat number, the trays show who is behind each army. Action games
(snake/rally/TD) stay one-seat-per-device this patch (a split-control
seat is its own design round — documented in the open questions).

## 2. THE TRACKER

- [x] 1. docs first: this file + LAN_MULTIPLAYER.md v042-1 + THE_PLATFORM_ANSWER.md profile note
- [x] 2. A1 the input kit: Arc.line factory + commit-door saves + keyboard types + focus-aware sheets + ticker deferral
- [x] 3. A2 the LAN button SVG
- [x] 4. A3+A4+A5 profile: placeholder law, bigger PFP, upload, GogaPfp renderer, gif decoder, cache laws, visitor view, showcase, link validator, age select, roles gone, gender alive
- [x] 5. A6 the session sheet: details/scan add, invites, remove/kick
- [x] 6. A7 the badge law: cards clean, LAN LIVE only in session
- [x] 7. A8 TD wears the seat (registry + RACE + towerball strip)
- [x] 8. B1 the discovery service (lan_find.gd) + scan UI + invites
- [x] 9. B2 ludo LAN
- [x] 10. B3 combo per-game (snl + ludo)
- [x] 11. C1 the pause multiplayer panel
- [x] 12. C2 voice chat (capture/transport/playback/toggles/detection)
- [x] 13. C3 text chat (core + UI + HUD seat + shortcut)
- [x] 14. D tests: qa_v042_lan extensions (chat/caps/face-cache/kick/combo/scan, 97/0) + flow_test ALL PASSED + the v0421 eye pass (8 shots: the new button, the profile sheet with the yellow-guy placeholder, the age select, the visitor view with the filtered link, the scan sheet, the chat sheet over a live boot) + version 0.4.2-1/31450 + AGENTS laws 59-62 + push
- [x] 15. the face wire's STAR relay (client-to-client faces ride the host; pending-request relay) + the TD perspective maps fixed (the rotation law)

## 3. THE DECISIONS (taken while building)

- The name law's sanitizer keeps its exact v042 shape (EN letters + ' . -
  space, 20 cap) — the report changed nothing about names.
- "webm" was the owner reaching for webp — webp IMAGES ride the full law;
  webm VIDEO is refused honestly (no engine decoder) with a clear toast.
- The 10MB chat ceiling counts decoded text bytes (UTF-8), recomputed on
  every push — simplest honest meter.
- Voice UDP ports ride the session's base port +2 (31442+) — the TCP
  session stays the control plane.
- The invite popup lives on the main menu (the scanned target is always
  in the menu — the scanner can only see boxes whose app is open).
- The showcase button opens the VISITOR view of MY OWN profile — the same
  builder, zero duplication.
- fit_sheet's LineEdit rule stands (no BoxScroll around text sheets) —
  the input fix does not need it, and the wrap would eat nothing today.

---

## r2. THE OWNER'S ROUND-2 REPORT (2026-09-25, verbatim anchors) + THE R2 PLAN

> "this will be done as just v042-1 round 2 at this point" - every item of
> the second test report, and the roots found behind each.

1. **The main-menu icon** - "supposed to show normal circle and an
   arch-like curve as the body and plus sign at top left, current design
   is more not-accurate for now" -> icon_lan.svg/.png redrawn to exactly
   that (law 70).
2. **The PFP placeholder** - "make it like the button icon but without
   plus sign and be yellow and bigger, current thing tries to be full
   body buy it is bad and wrong and not even accurate" -> paint_pfp IS
   the icon's bust now (law 70).
3. **Video formats + the source dump + the Windows placeholder**:
   - "make video support, like video formats normally, and not weird
     things, like WTF even is .oga" -> the picker filter carries the
     NORMAL shapes (png/jpg/webp/bmp/tga/gif + mp4/webm/mov/ogv); an
     undecodable video dies with its NAMED honest reason
     (PfpMedia.VIDEO_REFUSE). The engine ships ONE decoder (Theora .ogv
     - probed in ClassDB); mp4/webm stay honest refusals, never fakes.
   - "dump/cache the PFP source file in somewhare safe ... if user
     deleted original one, the PFP still exist until removed or
     changed" -> ALREADY the cache law (user://pfp_cache hash entries +
     the face mirror beside the profile); it never worked because of the
     meta bug below.
   - "after putting/selecting a PFP image on windows, the app behaves
     like the image is set for real, but the thing visualized is still
     the placeholder one" -> ROOT: _import_image wrote the fitted HEIGHT
     over meta["h"] (the HASH) - cache_has(height) false forever. Law 69.
4. **The typing roots** - "sometimes it double the letter ... jumps me
   off-place ... deletes the wrong thing ... if i changed the head of
   the place of writing, it returns me to the end after one char ...
   the thing must be logical and easy like any writing area" (both
   platforms, letters only - numbers/dots clean) -> ROOT: the box's own
   WASD->arrow injection moved the caret inside focused fields (W=start,
   S=end, A/D=walk). Law 63 + the commit-on-change law 64.
5. **The Android explorer** - "it shows the gogabox file explorer while
   on windows it should the windows explorer, android has one, make it
   use it ... showed folders accurately, but showed no files in them" ->
   use_native_dialog on BOTH platforms (the system SAF picker), clean
   filters, the photo permission asks stay (law 69).
6. **Showcase real-time** - "not update in real-time, it requires me to
   close and re-open menu" -> the commit-on-change law + the flush belt.
7. **The name law** - "hosting or joining can not even happen without
   having a name, even 1 char is enough (must be not space only ...
   there is a bug when the name is numbers only it get wiped" -> law 68
   (digits survive, 1 char, space-only dies, the three doors gate).
8. **The scan + the invites + the add-local** - "scan the network do
   nothing, it only lists players that in the session ... when i press
   add, it says invite refused ... add local player never adds anything"
   -> law 66: every box answers pings, subnet broadcasts cross the wifi,
   invites fire while hosting, the combo ADD reads the field directly.
9. **The joiner's quit** - "make the joiners have the ability to 'quit'
   the session when they open multiplayer menu in-session and see their
   name" -> the QUIT SESSION button (the leave was there; it is NAMED
   now).
10. **The badge lie + the solo fall-through** - "when an session-on
    session-off state toggled, the box main menu do not get updated
    real-time ... we both are on the 'lan live' thing, i was not even
    able to play lan, every time i play, i jump into solo" -> the badge
    gate is a REAL partner (joined_ok + 2 seats) and repaints LIVE
    (law 67); the join wears connecting/joined/honest-death states with
    a 12s deadline and a firewall-honest toast.
11. **The smart extra-line** - the owner's own recommendation, now law
    65 (Arc.area + the 3-line link rows with the domain hint).
12. **Chat/voice** - untested (the session never really started); the
    v042-1 implementations stand; the r2 join honesty is what lets them
    be tested for real.

### THE R2 PROOF

- qa_v042_lan: 130 checks 0 fails (the r2 section: the face meta law,
  the honest video doors, the invite-while-hosting, the join flip
  connecting->joined over real loopback TCP + the honest death, the
  link domain, the area flush door).
- flow_test: ALL PASSED (the r2 name law wears 5 new checks).
- The eye pass (tests/v0421r2_shot, 5 shots under Xvfb, reviewed by
  eye): the icon in the bar, the yellow bust placeholder, the visitor
  links (invalid never renders + domain hints), the scan rows (FREE
  PLAYER / HOSTS n/4), the honest 1-seat badge gate.
- config 0.4.2-2 / code base 31460 (arm32 31461, arm64 31462), exe
  stamp 0.4.2.2.

---

## R3 - THE ROOM ROUND (the owner's third report, worked to the roots)

The owner tested v042-1 r2 on real devices and the report re-seated the
whole infra. Verbatim anchors (the full report lives in the session
journal): "PFP is set, accurately, BUT! only for me, on other devices, i
see the placeholder forever" / "make a host be able handle up to 12
different players" / "make it possible to each different group of
players to play at the same time ... other 3 players can play ludo in
another dimension" / "in the wait menu, it auto-ends the wait and jump
solo, remove this mechanic" / "i managed to join on other device by
clicking same button at exact same moment, this thing should not even
happen" / "when someone get disconnected or close game whether he is
host or joiner, it corrupts the game, just end the game when one
disconnected" / "i bet you are just trolling me and have not truly
integrated the tech for real here" / "make the color of the player be
different and not same" / "change label CPU anywhere to the perspective
player name" / "make the game fruit ninja be LAN 2 players ... blue as
the first player and red is the second" / "make all of them be top-level
to appear anywhere any time in any position even in-games" / "android
app deleting deletes profile data, you have not accurately made it
immune against hard-wipes".

1. **The rooms** - law 71: 12-seat lobby, rooms (dimensions), the owner
   start, live params, join-order seats, room-scoped relays. The lone
   law and the ten seconds are dead.
2. **The absolute seats** - law 72: colors/names/turns ride the room
   seat everywhere; the local rotation era is over (the dual-P1 dice bug
   was its child).
3. **The serialized claims** - law 73: the host's one pump is the
   serializer; the racing loser reads the owner's confliction line.
4. **The honest ends** - law 74: disconnects fold the match with a dq
   row and the why; the pause-proof pump (law 75) kills the random
   drop root.
5. **Anywhere notifications** - law 76 (LanNotes, the switch invite).
6. **The live scan** - law 77; **the online honesty** - law 78; **the
   add-local-player retirement** - law 79.
7. **Chat r3** - law 80 (dedupe, live cooldown, dots, last-read, ids).
8. **Voice r3** - law 81 (the four gates on the wire, dev keys, the
   beacon, the unhang).
9. **Face r3** - law 82 (row asks, arrival repaint, 8MB wire, the clip,
   re-adopt, verified mirrors).
10. **The CPU word law** - 83; **the slasher LAN 2P** - law 84.

### THE R3 PROOF

- qa_v042_lan: 165 checks 0 fails (the r3 sections: the rooms, the
  owner start, the absolute rseats, the disconnect fold, the no-solo
  law, the confliction race, the 12 cap + the honest 13th, the two
  dimensions, the params wire + scope, the dedupe, the live cooldown).
- flow_test: ALL TESTS PASSED (the 12-game LAN seat law).
- The eye pass (tests/v0421r3_shot, Xvfb, 6 shots reviewed by eye): the
  session sheet (12 seats, the ONLINE OFF truth, no add-local-player),
  the live scan rows (FREE / HOSTS 2/12 / IN A SESSION - PLAYING LUDO),
  the top-level invite card over the feed AND over a running game, the
  room picker, the owner's room (1ST/2ND, YOU - OWNER, START THE GAME).
- config 0.4.2-3 / code base 31470 (arm32 31471, arm64 31472).

---

## R4 - THE WIRE + THE LOCK ROUND (the owner's fourth report, verbatim anchors)

> "ok here it is my report so you work on v042-1 another round and not new
> version: first, the profile image syncing is not instant, there is some
> weird stuff happens like i should rejoin so it loads the downloaded image
> or weird things, make it accurate and not buggy like this, for vLAN
> (online) it does not work saying wifi refused the port, try to fix it, if
> you will keep trolling, then just remove it if it is not really possible,
> i do not want players to run another tool to play vLAN but you are not
> helping"

- THE FACE: seats' pfpm was a join-time snapshot -> THE FACE-CHANGE WIRE
  (law 94): announce_face on the profile doors, the host re-books the
  seats, face_arrived repaints, the pong reads the face fresh. No rejoin.
- THE ONLINE: the honest single-protocol answer became THE REAL MAPPING
  STACK (law 99): UPnP -> NAT-PMP -> PCP in a thread, the public-address
  ask is part of the success, the LAN truth is the code until a door
  opens, ONLINE ON means a real internet dial.

> "also the invitation when declined, the host do not even know the
> decline, also the join/decline when appear in main menu, it is
> tap-through and not tappable, it is tappable in-game, but in menu, it
> taps the thing behind it or if nothing behind it, the click/tap do
> nothing there"

- THE DECLINE WIRE (law 90): the no (and the 20s silence) rides back to
  the inviter's discovery socket; the top-level note layer delivers.
- THE CARD BLOCK LAW (law 91): the root cause was BoxScroll._input's
  sibling-only overlay law - another CanvasLayer was invisible to it;
  the live card registers its rect, the scroll yields.

> "also, the voice chat still not correct, looks like it is not even
> sending data at all, also the click on the toggles still has that gray
> look, it should be off/on and that gray be on-click only and not waiting
> for another click to happen somewhere else to get updated, also make the
> toggles more direct like listen/talk, more better, where 'you' will not
> listen/hear or not be heard/listened, same for others where listen is
> their device do not take the user talk and their talk means user device
> do not hear their talk, and make them for real, there is something
> likely in the core of the LAN infra prevents streaming of the stuff"

- THE CAPTURE TRUTH (law 96): the root was the once-only capture arm -
  the Android mic permission almost never preceded it; the arm is live
  now and a fresh grant restarts the stream.
- THE REAL-WIRE VOICE LAW (law 97): the frames/beacons ride conn_addr -
  a mapped public host_addr was a hairpin death for LAN voice.
- THE TALK/LISTEN LAW (law 98): the owner's own words on the chips, the
  live THEY TALK / THEY LISTEN truth, and every stylebox owned so the
  engine's gray can never hang.

> "also, both fruit slasher and tower destroyer crashed in multiplayer
> wait menu even before the game starts"

- THE ROOM SCREEN LAW (law 102): the ticks ticked null worlds (the
  painters/camera were never built under the hold) - the base skips
  _goga_tick while the room screen lives. Rig-proven: both room screens
  run 4+ seconds, zero script errors.

> "also i spotted a bug related to rotation in dominoes and fruit slasher
> ... if game started as horizontal and i switched it to vertical, the app
> resolution will be correct, ratio is correct, scale is correct, but
> background, appears from top to middle, under middle is the brown GOGABox
> fallback"

- THE KIND WATCHER (law 103): the stuck class (the world wearing the old
  shape under the moved canvas - the refused-settle / foreign-stomp
  paths) heals through the host's own reload door; the host's early
  return honors the game's own view_kind. The Xvfb rig verified the
  reload path seats full-bleed backgrounds (domino census 1.3% host
  brown in the bottom half; slasher's wood covers edge to edge).

> "also about rooms, make sure if two pressed 'make room' at same time,
> the app will choose only one ... also make sure if a third player opened
> wait menu, he will see the first room as in-game and grayed out so he
> can not join ofc, that's first, about the same multiplayer things, as
> example, when someone quit game, it only shows a notification and not
> end game for others, also if someone pressed 'end' instead of quit, the
> others will not be game over-ed and this is very stupid, also the room
> maker/host-er is not the rule-er here, i mean others can still de-sync
> things like change game position and make corrupted room where the room
> maker see that the other player still here while the other went solo
> weirdly, also others can change board sizes or skins on their own, this
> should not happen, host should make a thing, and all get it as a must,
> whether it is position or board size or whatever"

- THE ONE-WAITING-ROOM LAW (85) + THE PICKER TRUTH (86): the host's pump
  chooses one; the IN-GAME room is grayed, dead to taps.
- THE END LAW (87) + THE FOLD VERDICT (88): the END seat folds the room
  from EVERY seat; the base owns the honest end for every game (lan_end
  games keep their verdict; everything else gets the RUN OVER + the
  banked coins).
- THE DEEP SETTINGS LOCK (89): ONE function pair in both twins, the HUD
  doors guard inside the base - "make like function or whatever" is the
  letter of the law; the orientation asks of domino/slasher ride it.

> "also i even realized the profile menu is not up-down scrollable, make
> it scrollable" / "ummmm, also make sure video media like gif will be
> loop-ed as described earlier and the out of focus thing and like that i
> mean" / "also make sure a host-er can not be a join-er at the same time"

- THE SCROLLABLE PROFILE (93) + THE FIELD LAW (92) + THE POSTER
  EVERYWHERE (95) + THE ONE-SESSION LAW (101).

> "i am not going to test this next build directly, i will just let you
> work on it accurately and take your time on it, next thing we are going
> to do is the games as standalone stuff and not baked in the binary, so
> take your time doing your work in the infra itself because we will need
> it later, make sure to make the locking thing very deep so you do not
> have to code every single game to it, make like function or whatever,
> just try to work and make something perfect, keep testing it"

- The infra-first posture held: every law above landed in the CORE (lan.gd,
  lan_find.gd, lan_notes.gd, lan_voice.gd, lan_roster.gd, lan_hold.gd,
  scroll_box.gd, goga_pfp.gd, game_base.gd, game_base3d.gd, host_node.gd,
  menu.gd) - the games touched only where the report named them
  (domino/slasher orientation guards). THE STANDALONE-SPLIT POSTURE: the
  lock, the fold, the params wire and the room lifecycle are all
  duck-typed base surfaces a split-out game binary will inherit for free.

### THE R4 PROOF
- qa_v042_lan: 185 checks 0 fails (+ the r4 sections: the create race +
  the one-waiting-room law, the dimension-after-start law, the END law
  from a joiner seat, the face-change wire both halves, the decline wire
  over the real UDP loopback).
- flow_test: ALL TESTS PASSED (the r4 eye-pass scene boots the real main
  scene; the towerball/towerdestroyer 3D laws still green after the
  watcher - the Node3D viewport lesson is in the law text).
- THE EYE PASS tests/v0421r4_shot under Xvfb (law 32): the scrollable
  profile (portrait + the bounded landscape wrap), the invite card
  taking a REAL click over the feed and going down (the tap-through fix
  proven by the click, not by an assert), domino's landscape ask ->
  VERTICAL pick -> full-bleed bg, slasher's same dance, and both the
  named crash games' LAN room screens alive with zero script errors.
- config 0.4.2-4 / code base 31480 (arm32 31481, arm64 31482).
