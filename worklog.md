---
Task ID: v041-2 r3
Agent: Super Z (main)
Task: the owner's report - the total input death (Tower Ball + the heavy war XP cards), the corrupted cursor-leak fix, the rotation roots ("make the automatic switches be the same as F10"), the Tower Ball flow/design/spin/gauge/thumbnail

Work Log:
- Sandbox verified (fdb13641 = v041-2 r2, clean); godot 4.7.2 alive at /tmp/my-project/godot; Xvfb :96 rig up
- THE ROOTS (all proven on a real Xvfb window, none guessed):
  (1) THE IMMORTAL BIRTH SHIELD - tests/pause_input_probe.gd: the r2 sheet shield connected `ready` AFTER add_child (ready had already fired inside it) so the kill-tween NEVER existed; the shield (full-rect STOP) sat over EVERY sheet_push sheet forever eating every click - Tower Ball's whole UI, the heavy war XP-level cards, "likely other games". A paused STOP control above an ALWAYS sheet still eats the pick (A2), and a pause-bound tween never dies (A3). FIX: ready connected BEFORE the add + PROCESS_MODE_ALWAYS + TWEEN_PAUSE_PROCESS (both twins), proven by A4-A7.
  (2) THE DEFERRED-CORPSE CURSOR KILL - the dying game's _exit_tree fired AFTER the next seat armed (the replay's cursor or the box arrow on quit); the unconditional game_disarm nulled the arrow and every custom cursor died (the OS arrow everywhere, the setting honestly ON). FIX: THE SEAT TOKEN LAW - game_arm mints a token, only the live token disarms, a stale corpse is a no-op, the live seat hands the pointer back to the box cursor the same frame it dies.
  (3) THE MENU'S UNGUARDED size_changed STOMP - menu._apply_base fired on every window echo during a game and rewrote the design to pc_menu_design: a landscape game rebooting inside a portrait canvas ("a vertical image in the horizontal view") on every automatic path while F10 always worked. FIX: the ONE-DESIGN-WRITER law (menu writes return while a host is active), the BOOT PARITY (pc_position restored inside boot_window BEFORE any shape write), the gate verifying BOTH truths (the real window px AND the canvas design), _assert_own_design(kind) explicit (the r7 probe caught my own first version asserting the portrait default mid-flight - MIDFLIGHT sample 0).
  (4) heavywar's ScaleRule.apply() (the poison design-follows-window pattern) removed.
- TOWER BALL: the r3 flow (snake verbatim: orient -> mode -> the ready card; the universal phone_*.png assets; the reload path lands on the mode screen; start_orientation skips the ask); THE BACK LAW (the ask screens are the root, back never closes them, the shop above them still closes); the spin slowed (0.4..1.3 rad/s); the two-tone discs/rings + the brighter world + the lifted night sky + the below-horizon stars; the landscape platform camera floor 15->18; the gauge after the score from the left (verified by eye); the thumbnail re-captured at the golden hour (the composer reads the real raw width now)
- TESTS: pause_input_probe (the shield laws), click_probe (REAL synthetic clicks through the real GUI: towerball 16/16 - the flow, the reload law, the rotation input, the shop rows, the back law; heavywar 6/6 - the XP cards open, a real click picks a card, the pause law holds), towerball_probe 19,952/0, flow_test ALL PASSED, v0411_r7_window_probe 18/18, the NEW v0411_r3_window_probe 16/16 (the REAL main scene: launch/reload/quit x windowed/fullscreen, 90-frame design sampling each), the film rig re-shot + eyeballed
- Docs: brainstorm/v041-2/r3 TRACKER, AGENTS law 54, the registry controls line re-worded to the r3 flow
- Committed + pushed as d2eaa213 -> CI 35809839320 SUCCESS; artifacts live: GOGABox-windows 124MB / arm64-v8a 115MB / armeabi-v7a 116MB

Stage Summary:
- v041-2 r3: the input death (the immortal shield), the cursor seat corruption (the deferred corpse), and the rotation roots (the menu stomp + the boot parity + the both-truths gate) all killed at the root with probe-proof; Tower Ball rebuilt around the universal three-screen flow with the owner's design laws. The owner-experience rig (real clicks) is now the ship gate for every sheet/UI fix.

---
Task ID: v041-3 docs (the reveal)
Agent: Super Z (main)
Task: the owner revealed the hidden plans (GOGABox as a store/platform) - document them verbatim-first next to the LAN + appstore docs, carry the LAN cross-platform/tagging update into the LAN file, DOCUMENT ONLY (zero code), then return a full opinion

Work Log:
- Sandbox verified (d0819b41 = v041-3 r2, clean) - confirmed to the owner that r2 WAS shipped (the summary had gone stale)
- Archaeology run (the owner's pointer): THE_APP_STORE_QUESTION.md re-read (v0.2.8 spark + the v0.3.7 age/GOGAds archive); git history dug - 70335dcf (rework + asset-store trials), 81351aca/0dbc1289 (windows forge + v0.3.4-3), 805b041a (THE GREAT UN-WINDOWING: "no windows builds, no way to make money from them"), 16db01d7 (THE OPEN-SOURCE ROUND: MIT + 0 ads + THE WINDOWS RETURN, "whose only reason is dead today"), 883ba438/f85ecbc1 (first windows test + v041 CI green)
- NEW docs/goga_docs/ideas/THE_PLATFORM_ANSWER.md - the reveal file: the owner's FULL message preserved verbatim at the top (his order), then THE ARC (the store idea's three returns + the runway-cleared reading), THE LAWS (trust / local simulation / no-api-limit raw trick / SDK dlls / packaging draft / formal look + overrides / LAN cross-platform / returning age laws / the fluidity disclaimer), THE SHAPE OF A GAME draft tree (game + dlls + index + gogabox + discover subfolders), THE DEVELOPER LOOP (local paths -> the binary validates -> the full GitHub-side pipeline simulated -> later pointed at real repos), THE OPEN QUESTIONS (true packaging, the token push, the age return, the discover shape, the SDK Android twin), THE WORKING AGREEMENT (talk step by step, no refactor-over-refactor)
- LAN_MULTIPLAYER.md: THE CROSS-PLATFORM UPDATE section added (phones + PC in ONE session; LAN support tagged with platform + player count inside the 4-player session cap; LAN gets its own tag family riding the registry) - header updated, nothing else touched
- ideas/README.md: the system docs table indexed THE_PLATFORM_ANSWER.md + the LAN row notes the update
- Both files read back and verified after writing (the owner's order)
- DOCUMENT ONLY kept: zero game/infra code touched, no version bump, no config change

Stage Summary:
- The hidden plans now live in the repo as documentation: the platform answer file (verbatim-first, dense, house-style) + the LAN cross-platform update. The talk agenda is explicit (5 open questions), the working agreement is recorded, and the runway story (spark -> pulled attempt -> MIT/0-ads/two-platform clean room -> reveal) is preserved with commit hashes so the "everything connects" reading survives.

---
Task ID: v042
Agent: Super Z (main)
Task: the owner's order - the LAN thing completely as v042: core infra + cross-platform + in-games (snake, jumpcube, snl, domino, chess, squares, fourline, bovo, towerball, rally), the GOGAProfile seed with the device anchor + wipe-surviving mirrors, the VLAN leg (room codes), combo co-op seats, multi-level LAN tags, the pre-play live line, documenting first

Work Log:
- Sandbox was STALE (head at v040-2 era) - re-synced hard to origin/main (c419a471) before any work
- DOCS FIRST: brainstorms/v042/MASTER.md (the spec + research + architecture + tracker); THE_PLATFORM_ANSWER.md += THE GOGAPROFILE SEED; LAN_MULTIPLAYER.md += THE V042 BUILD section
- THE CORE: game/core/lan.gd (autoload LAN) - TCP JSON lines, port 31440, host-authoritative session, heartbeat prune, per-game holds, THE TEN SECONDS on the host's one clock, match relays (TURN_RELAY/HOST_AUTH/SELF_AUTH/RACE), room codes (GOGA-XXXXXX-XXXXXXC + UPnP), the name sanitize, combo co-op local_slot seats; game/core/lan_profile.gd (the GitHub-shaped local profile, the device anchor, Android/media + Windows-home mirrors); game/core/lan_hold.gd (the system waiting room, one widget, both twins); lan hooks mirrored in game_base.gd + game_base3d.gd (law 51); host_node pre_open/report_open/report_close; the INTERNET permission on both Android presets (the LAN note in AGENTS 4 + RELEASE_LAW)
- THE TAGS: registry "lan" on exactly ten games (fourline cross:false = the both-platforms-same-platform-LAN case); Meta.lan_list/lan_label/players_badge; the search LAN row + _passes_filters + CLEAR + feed-state round-trip; the PLAYERS badge on cards; the pre-play LAN chips + the live line (the _page_tick law)
- THE MENU: the drawn plus+human LAN button (Arc.safe_poly), the TWO-OPTION menu (PROFILE/MULTIPLAYER), the profile sheet (name/PFP variants/desc/links/age/role-owner-unique/gender+other), the profile viewer, the LAN sheet (host + join with LOCAL and ONLINE boxes, members with visit, combo add/remove, delete/leave)
- THE GAMES: snl (roll relay + the seat-rotation perspective law), squares/fourline/bovo (edge/drop/stone relays, no CPU), chess (the seat-1-white law, by_player mapping), domino (the shared seeded shuffle + the seat-2 pair swap + place/pass/take relays), jumpcube (conquest relay), snake (SELF_AUTH: a shared portrait world with the fit-zoom, dir/eat/die broadcasts, the last-snake verdict), rally (HOST_AUTH: normalized 20Hz snaps, the mirrored view, the 30Hz pad stream), towerball (RACE: re-seeded identical towers, prog/dead, the last-ball verdict)
- THE TESTS: tests/qa_v042_lan (THE LOOPBACK RIG: 4 real LAN cores over real TCP - the session, the seats, the cap, combo, the hold, THE TEN SECONDS, the birth, the turn relay, THE LEFT-OUT, the solo fallback, THE LONE LAW, the prune) 77/0; flow_test += _t_lan_laws; the EYE PASS (7 shots under Xvfb: the button, the two-option menu, the profile sheet, the join boxes, the live session, the LAN tags + the live line, the waiting room over a real snl boot)
- THE TRAP CAUGHT: static set_name/name were SILENT no-ops (the engine's property-setter convention) - renamed to set_player_name/player_name, law 58 written; the profile _load's defaults-merge healed
- THE BUGS THE RIG KILLED BEFORE THE OWNER: the StreamPeerTCP.close() lie (disconnect_from_host is the truth), the start broadcast reaching the left-out seats, the solo-fallthrough leaving ghost holders, the left_out client path
- Version: 0.4.2 / code base 31440 (arm32 31441, arm64 31442), the exe stamp 0.4.2.0
- Gates: flow_test ALL PASSED + qa_v042_lan 77/0 + the eye pass reviewed

Stage Summary:
- v042: the LAN system is real end to end - the box, the wire, the waiting room, the profiles, the tags, ten games seated. The owner tests cross-platform (PC + phone); Tower Destroyer stayed frozen; ludo stays off the list per the order.
