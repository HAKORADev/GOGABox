extends Node
## LAN — the box's local-network multiplayer core (v042; v042-1 r3 THE ROOM
## LAW). Plain TCP (TCPServer / StreamPeerTCP), newline-delimited JSON
## messages. The session dies with the app (THE HOST/JOIN LAW). The host
## owns the truth; clients mirror (one clock, no drift).
##
## THE ROOM LAW (v042-1 r3, the owner's third report):
##   "in games there is whether server-side world or the host-side world,
##   currently we do not have the host-side world ... make a host be able
##   handle up to 12 different players, 11 next to the host itself ...
##   make it possible to each different group of players to play at the
##   same time, like if group one 2 players joined ludo, then other 3
##   players can play ludo in another dimension".
## A session is now a LOBBY of up to 12 seats. Any member opens a ROOM
## ("dimension") for a game; the room's members are its players in JOIN
## order (first, second, third ... = who got ready first); the room's
## OWNER carries the config and starts the match - the game is never
## loaded or initialized before that moment. Many rooms live at once and
## every relay is scoped to its own room. THE LONE LAW and THE TEN
## SECONDS LAW are DEAD (the owner: "in the wait menu, it auto-ends the
## wait and jump solo, remove this mechanic" + "the wait after someone is
## ready should stay"). A room seat is claimed FIRST-COME on the host's
## one pump - the first message always wins, the loser reads "confliction
## happened with another player".
##
## THE ABSOLUTE SEAT LAW (the owner: "make the color of the player be
## different and not same ... both players see themself as shazam and
## both see the other player as marble ... in ping pong both players are
## controlling red"): match seats are ABSOLUTE - room seat 1 is room seat
## 1 on every device, wearing the same color and the same name. The local
## player is highlighted with YOU, never re-colored.
##
## THE DISCONNECT LAW (the owner: "when someone get disconnected or close
## game whether he is host or joiner, it corrupts the game, just end the
## game when one disconnected ... with notifications"): a member leaving
## mid-match ends the room's match for everyone left, honestly.
##
## THE REAL-ONLY LAW: a LAN match has NO CPU players - every seat is a
## human on a device.
##
## THE GAME CONTRACT (duck-typed, both twins - unchanged shapes):
##   lan_match_start(seed: int, seats: Array)      # configure + begin
##   lan_act(who: int, a: Dictionary)              # apply a relayed action
##   lan_snap(data: Dictionary)                    # apply a host snapshot
##   lan_prog(from_dev: String, data: Dictionary)  # a rival's progress
##   lan_end(results: Array)                       # the match verdict
##   lan_solo()                                    # the LAN refused me
## GAMES CALL (apply locally FIRST, then broadcast):
##   LAN.send_act(a)      # my move - who rides MY room seat automatically
##   LAN.send_in(data)    # HOST_AUTH: client input to the host
##   LAN.send_snap(data)  # HOST_AUTH: host snapshot to the room
##   LAN.send_prog(data)  # RACE / SELF_AUTH events to the room
## MATCH CONFIG: LAN.match_params (the owner's room settings) + the room
## screen's optional game hook lan_room_settings(parent).

signal session_changed
signal rooms_changed
signal match_started(game_id: String, seed_v: int, seats: Array, params: Dictionary)
signal match_ended(game_id: String, results: Array, why: String)
signal act_received(game_id: String, who: int, a: Dictionary)
signal snap_received(game_id: String, data: Dictionary)
signal prog_received(game_id: String, from_dev: String, data: Dictionary)
signal lan_denied(game_id: String, why: String)   # the game's LAN rules refused me
signal session_died(why: String)                  # the host closed / the wire died
signal room_refused(why: String)                  # confliction / full / gone
signal kicked(why: String)                        # the host removed me
signal chat_received(msg: Dictionary)             # one chat line landed
signal vst_arrived(msg: Dictionary)               # a peer's voice state
signal face_arrived(hash_v: String)               # a PFP landed in the cache

const BASE_PORT := 31440           # the code base number
const PORT_TRIES := 10
const HEARTBEAT := 3.0
const PRUNE_AFTER := 15.0          # r3: the games can stall a frame - 10s lied
const SEAT_CAP := 12               # r3: the host handles 12 players (11 + host)
var MY_PLATFORM := "android" if OS.has_feature("android") else "pc"

var mode := "idle"                 # idle | host | join
var seats: Array = []              # [{dev,name,pfp,pfpm,role,anchor,seat,local_slot,platform,state}]
var is_host := false
var host_addr := ""                # "ip:port" as shown to joiners
var room_code := ""
var upnp_ok := false
var online_ready := false          # r3 THE ONLINE HONESTY LAW: the router opened the port

var _srv: TCPServer = null
var _port := 0
var _host_conn: StreamPeerTCP = null       # when joining: the wire to the host
var _hello_sent := false
var _joined := false
var _join_started := 0.0
var _conns := {}                           # dev -> StreamPeerTCP (host side)
var _buffers := {}                         # conn instance id -> partial line bytes
var _pending: Array = []                   # connections awaiting their hello
var _seen := {}                            # dev -> last heartbeat unix time
var _last_host_msg := 0.0                  # client side watchdog
var _hb_clock := 0.0
var _my_state := "lobby"                   # lobby | room:<rid> | play:<rid>
var _open_game := ""

# ================= THE ROOMS (v042-1 r3) =================
# host: the live truth. client: the mirror of the last broadcast.
# room = {rid, game, owner, members:[dev,...], params:{}, phase:"wait"|"play"}
var rooms := {}                            # rid -> room (HOST side)
var _rooms_mirror := {}                    # rid -> room (CLIENT side)
var _next_rid := 1
var _my_room := 0                          # the rid I ride (0 = none)
var match_params := {}                     # the room's config for MY match

## ================= identity =================

## The probe identity overrides: up to 12 LAN cores can live in ONE
## process (the loopback rig) - each wears its own dev/name/anchor so the
## session simulates REAL devices end to end over real TCP.
var dev_override := ""
var ident_override := {}

func my_dev() -> String:
        if dev_override != "":
                return dev_override
        return "d" + str(hash(ANCHOR_MIX + OS.get_unique_id()))

const ANCHOR_MIX := "gogabox-dev-v1"

## ================= session lifecycle =================

func session_active() -> bool:
        return mode != "idle"

## The joiner's wire is truly IN (the welcome landed). A session that is
## merely "connecting" holds no badges and no rooms.
func joined_ok() -> bool:
        if mode == "host":
                return true
        return mode == "join" and _joined

func session_size() -> int:
        return seats.size()

func my_seat_no() -> int:
        for s in seats:
                if String(s.get("dev", "")) == my_dev():
                        return int(s.get("seat", 1))
        return 1

func seat_by_dev(dev: String) -> Dictionary:
        for s in seats:
                if String(s.get("dev", "")) == dev:
                        return s
        return {}

## The registry's LAN rules vs THIS device + the live session.
func platform_ok(game_id: String) -> bool:
        var g: Dictionary = GameReg.get_game(game_id)
        var lan: Dictionary = g.get("lan", {})
        if lan.is_empty():
                return false
        var plats: Array = lan.get("platforms", [])
        if not plats.has(MY_PLATFORM):
                return false
        if not bool(lan.get("cross", false)):
                for s in seats:
                        if String(s.get("platform", MY_PLATFORM)) != MY_PLATFORM:
                                return false
        return true

## A game's room capacity (the registry's players law).
func game_room_cap(game_id: String) -> int:
        var g: Dictionary = GameReg.get_game(game_id)
        var lan: Dictionary = g.get("lan", {})
        return clampi(int(lan.get("players", 2)), 2, SEAT_CAP)

## HOST — open a session. Returns "" on success or an error line.
func host_session() -> String:
        if session_active():
                return "already in a session"
        for i in PORT_TRIES:
                var p := BASE_PORT + i
                var srv := TCPServer.new()
                if srv.listen(p, "0.0.0.0") == OK:
                        _srv = srv
                        _port = p
                        break
        if _srv == null:
                return "every port is busy"
        is_host = true
        mode = "host"
        seats = []
        rooms = {}
        _rooms_mirror = {}
        _next_rid = 1
        _my_room = 0
        match_params = {}
        _conns = {}
        _buffers = {}
        _pending = []
        _seen = {}
        _my_state = "lobby"
        _open_game = ""
        _add_local_seat(0)
        _start_upnp()
        _broadcast_seats()
        session_changed.emit()
        return ""

## r3 THE ONLINE HONESTY LAW (the owner: "i have tried the online thing,
## it failed ... i bet you are just trolling me and have not truly
## integrated the tech for real here"): the mapping is attempted HARDER
## (a longer discover, three mapping tries) and the session sheet SAYS
## whether online is real: online_ready = the router opened the port and
## the code carries the PUBLIC address. Without it the code stays the LAN
## address and the sheet says LAN + VPN only - never a silent lie.
func _start_upnp() -> void:
        upnp_ok = false
        online_ready = false
        room_code = ""
        if _port == 0:
                return
        var ext := ""
        var upnp := UPNP.new()
        if upnp.discover(2000, 3) == UPNP.UPNP_RESULT_SUCCESS \
                        and upnp.get_gateway() != null:
                for i in 3:
                        if upnp.add_port_mapping(_port, _port,
                                        "GOGABox LAN", "TCP", 0) \
                                        == UPNP.UPNP_RESULT_SUCCESS:
                                upnp_ok = true
                                ext = upnp.query_external_address()
                                break
        if ext != "":
                online_ready = true
        else:
                ext = _lan_ip()
        host_addr = "%s:%d" % [ext, _port]
        room_code = encode_code(ext, _port)

## JOIN — connect to a host by "ip:port" or room code. Returns "" or error.
func join_session(addr_raw: String) -> String:
        if session_active():
                return "already in a session"
        var addr := addr_raw.strip_edges()
        if addr.begins_with("GOGA-"):
                var decoded := decode_code(addr)
                if decoded == "":
                        return "bad room code"
                addr = decoded
        var parts := addr.split(":")
        if parts.size() < 1 or parts[0].strip_edges() == "":
                return "enter the host address"
        var ip := parts[0].strip_edges()
        var port := BASE_PORT
        if parts.size() > 1 and parts[1].to_int() > 0:
                port = parts[1].to_int()
        var conn := StreamPeerTCP.new()
        if conn.connect_to_host(ip, port) != OK:
                return "cannot reach " + ip
        mode = "join"
        is_host = false
        _joined = false
        _join_started = Time.get_unix_time_from_system()
        host_addr = "%s:%d" % [ip, port]
        _host_conn = conn
        _hello_sent = false
        seats = []
        rooms = {}
        _rooms_mirror = {}
        _my_room = 0
        match_params = {}
        _my_state = "lobby"
        _open_game = ""
        _last_host_msg = Time.get_unix_time_from_system()
        session_changed.emit()
        return ""

func leave_session() -> void:
        if mode == "join" and _host_conn != null:
                _send_to(_host_conn, {"t": "bye"})
        _close_all()
        _reset_session()

func _reset_session() -> void:
        _teardown_match_local("THE SESSION ENDED")
        mode = "idle"
        is_host = false
        seats = []
        rooms = {}
        _rooms_mirror = {}
        _my_room = 0
        _my_state = "lobby"
        _open_game = ""
        chat_log = []                 # THE CHAT LAW: never saved, dies here
        chat_bytes = 0
        chat_unread = 0
        chat_mention_unread = 0
        session_changed.emit()

func _close_all() -> void:
        if _srv != null:
                _srv.stop()
                _srv = null
        for k in _conns:
                var c: StreamPeerTCP = _conns[k]
                c.disconnect_from_host()
        _conns = {}
        _buffers = {}
        _pending = []
        _seen = {}
        if _host_conn != null:
                _host_conn.disconnect_from_host()
                _host_conn = null

## ================= the seat book =================

func _add_local_seat(local_slot := 0) -> void:
        var idn := _ident()
        var seat := {"dev": my_dev(), "name": String(idn.get("name", "")),
                "pfp": int(idn.get("pfp", 0)),
                "pfpm": idn.get("pfpm", {}),
                "desc": String(idn.get("desc", "")),
                "links": idn.get("links", []),
                "age": int(idn.get("age", 0)),
                "gender": String(idn.get("gender", "other")),
                "role": String(idn.get("role", "gamer")),
                "anchor": String(idn.get("anchor", "")),
                "seat": seats.size() + 1, "local_slot": local_slot,
                "platform": MY_PLATFORM, "state": _my_state}
        seats.append(seat)

## COMBO CO-OP v042-1 (kept for the game-side API; the host menu's
## ADD LOCAL PLAYER button is retired r3 - the owner: "the button add
## local player is useless"): the host seats a second LOCAL player BY ITS
## DETAILS. No clone, no fake tint.
const COMBO_DEV := "-p2"

func add_local_slot(p_name: String) -> bool:
        if not is_host:
                return false
        for s in seats:
                if String(s.get("dev", "")) == my_dev() + COMBO_DEV:
                        return false
        if seats.size() >= SEAT_CAP:
                return false
        var name_v := LanProfile.sanitize_name(p_name)
        if name_v.length() < LanProfile.NAME_MIN:
                return false
        var seat := {"dev": my_dev() + COMBO_DEV,
                "name": name_v,
                "pfp": 0, "pfpm": {},
                "desc": "", "links": [], "age": 0, "gender": "other",
                "role": "gamer", "anchor": "",
                "seat": seats.size() + 1, "local_slot": 1,
                "platform": MY_PLATFORM, "state": "lobby"}
        seats.append(seat)
        _reseat()
        _broadcast_seats()
        session_changed.emit()
        return true

func remove_local_slot() -> bool:
        if not is_host:
                return false
        for i in seats.size():
                if String(seats[i].get("dev", "")) == my_dev() + COMBO_DEV:
                        seats.remove_at(i)
                        _reseat()
                        _broadcast_seats()
                        session_changed.emit()
                        return true
        return false

func _reseat() -> void:
        for i in seats.size():
                seats[i]["seat"] = i + 1

## ================= the game door (open/close) =================

## The box asks BEFORE booting a game: should this boot wear the LAN room
## screen? A real session with a real partner and a LAN-capable game.
func pre_open(game_id: String) -> bool:
        if not session_active() or seats.size() < 2:
                return false
        if not joined_ok():
                return false
        return platform_ok(game_id)

## The box announces the game is open (after the game node exists).
## Returns true if the room screen should mount. The room itself is born
## when a player CREATES it (or joins one) - never silently here.
func report_open(game_id: String) -> bool:
        _open_game = game_id
        if not session_active():
                return false
        if not platform_ok(game_id):
                var why := "this game's LAN does not seat %s" % ("phones" if MY_PLATFORM == "android" else "PCs")
                lan_denied.emit(game_id, why)
                return false
        if seats.size() < 2:
                return false
        return true

func report_close(game_id: String) -> void:
        if _open_game == game_id:
                _open_game = ""
        if not session_active():
                return
        # THE DISCONNECT LAW: closing the game's screen leaves the room -
        # if the match was live, the rest of the room reads the honest end.
        if _my_room != 0 and room_game(_my_room) == game_id:
                leave_room()
        _set_state("lobby")
        if is_host:
                _broadcast_seats()
        else:
                _send_to(_host_conn, {"t": "state", "st": "lobby"})

func _set_state(st: String) -> void:
        _my_state = st
        for s in seats:
                if String(s.get("dev", "")) == my_dev():
                        s["state"] = st

## ================= the rooms (dimensions) =================

## The rooms list for the UI: the live truth (host) or the mirror (client).
func rooms_list() -> Array:
        var src: Dictionary = rooms if is_host else _rooms_mirror
        var out := []
        for rid in src:
                out.append(src[rid])
        out.sort_custom(func(a, b): return int(a.get("rid", 0)) < int(b.get("rid", 0)))
        return out

func rooms_for_game(game_id: String) -> Array:
        var out := []
        for r in rooms_list():
                if String(r.get("game", "")) == game_id:
                        out.append(r)
        return out

func room_by_id(rid: int) -> Dictionary:
        var src: Dictionary = rooms if is_host else _rooms_mirror
        return src.get(rid, {})

func room_game(rid: int) -> String:
        return String(room_by_id(rid).get("game", ""))

func my_room() -> Dictionary:
        if _my_room == 0:
                return {}
        return room_by_id(_my_room)

## My seat number inside MY room (1-based join order; 0 = no room).
func my_room_seat() -> int:
        var r := my_room()
        if r.is_empty():
                return 0
        var members: Array = r.get("members", [])
        var idx := members.find(my_dev())
        return idx + 1 if idx >= 0 else 0

func room_members(rid: int) -> Array:
        var out := []
        for dev in room_by_id(rid).get("members", []):
                var s := seat_by_dev(String(dev))
                if not s.is_empty():
                        out.append(s)
        return out

func room_state_text(rid: int) -> String:
        var r := room_by_id(rid)
        if r.is_empty():
                return ""
        var g: Dictionary = GameReg.get_game(String(r.get("game", "")))
        var title := String(g.get("title", String(r.get("game", ""))))
        var n: int = (r.get("members", []) as Array).size()
        if String(r.get("phase", "wait")) == "play":
                return "PLAYING %s" % title.to_upper()
        return "IN ROOM - %s (%d/%d)" % [title.to_upper(), n, game_room_cap(String(r.get("game", "")))]

## CREATE a room for a game. Returns "" or an error line (the UI toasts).
func open_room(game_id: String, params := {}) -> String:
        if not session_active() or not joined_ok():
                return "no session"
        if not platform_ok(game_id):
                return "this game's LAN does not seat this device"
        if _my_room != 0:
                leave_room()
        if is_host:
                _host_open_room(my_dev(), game_id, params)
        else:
                if _host_conn == null:
                        return "the wire is gone"
                _send_to(_host_conn, {"t": "room_open", "game": game_id,
                        "params": params})
        return ""

## JOIN a room by rid. FIRST-COME on the host's one pump: the first
## message wins, a racing loser reads the confliction line.
func join_room(rid: int) -> String:
        if not session_active() or not joined_ok():
                return "no session"
        if is_host:
                return _host_join_room(my_dev(), rid)
        if _host_conn == null:
                return "the wire is gone"
        _send_to(_host_conn, {"t": "room_join", "rid": rid})
        return ""

## LEAVE my room (the room screen's exit, the game close, the session
## quit). A live match ends honestly for everyone left.
func leave_room() -> void:
        if _my_room == 0:
                return
        var rid := _my_room
        _my_room = 0
        if is_host:
                _host_leave_room(my_dev(), rid)
        elif _host_conn != null:
                _send_to(_host_conn, {"t": "room_leave", "rid": rid})

## THE OWNER'S CONFIG: live params while the room waits.
func set_room_params(params: Dictionary) -> void:
        var r := my_room()
        if r.is_empty() or String(r.get("owner", "")) != my_dev():
                return
        if is_host:
                _host_room_params(_my_room, params)
        elif _host_conn != null:
                _send_to(_host_conn, {"t": "room_params", "rid": _my_room,
                        "params": params})

## THE OWNER STARTS THE MATCH - the only birth door. The game is never
## initialized before this moment (the owner's own law).
func start_match() -> String:
        var r := my_room()
        if r.is_empty():
                return "no room"
        if String(r.get("owner", "")) != my_dev():
                return "only the room's owner starts the game"
        if String(r.get("phase", "wait")) != "wait":
                return "the match already started"
        var members: Array = r.get("members", [])
        if members.size() < 2:
                return "wait for one more player"
        if is_host:
                return _host_start_match(_my_room)
        if _host_conn != null:
                _send_to(_host_conn, {"t": "room_start", "rid": _my_room})
        return ""

## ---- the host's room truth (single pump = single serializer) ----

func _host_open_room(dev: String, game_id: String, params: Dictionary) -> void:
        if not platform_ok(game_id):
                _refuse_conn(dev, "this game's LAN does not seat this device")
                return
        var rid := _next_rid
        _next_rid += 1
        rooms[rid] = {"rid": rid, "game": game_id, "owner": dev,
                "members": [dev], "params": params, "phase": "wait"}
        _host_mark_room_state(dev, rid, false)
        _push_rooms()

func _host_join_room(dev: String, rid: int) -> String:
        var r: Dictionary = rooms.get(rid, {})
        if r.is_empty():
                _refuse_conn(dev, "the room is gone")
                return "the room is gone"
        var game := String(r.get("game", ""))
        if not platform_ok(game):
                _refuse_conn(dev, "this game's LAN does not seat this device")
                return "platform"
        if String(r.get("phase", "wait")) != "wait":
                _refuse_conn(dev, "the match already started")
                return "started"
        var members: Array = r.get("members", [])
        if members.has(dev):
                return ""
        if members.size() >= game_room_cap(game):
                # THE CONFLICTIONION LAW: two devices raced for the last
                # seat - the first message won, this one reads the line.
                _refuse_conn(dev, "CONFLICTION HAPPENED WITH ANOTHER PLAYER")
                return "full"
        if _my_room_of_dev(dev) != 0:
                _host_leave_room(dev, _my_room_of_dev(dev))
        members.append(dev)
        r["members"] = members
        rooms[rid] = r
        _host_mark_room_state(dev, rid, false)
        _push_rooms()
        return ""

func _host_leave_room(dev: String, rid: int) -> void:
        var r: Dictionary = rooms.get(rid, {})
        if r.is_empty():
                return
        var members: Array = r.get("members", [])
        if not members.has(dev):
                return
        var was_owner := String(r.get("owner", "")) == dev
        var was_play := String(r.get("phase", "wait")) == "play"
        members.erase(dev)
        r["members"] = members
        if was_play and members.size() >= 1:
                var leaver := String(seat_by_dev(dev).get("name", "A PLAYER"))
                _host_end_match(rid, [{"name": String(leaver), "dq": true}],
                        "%s LEFT THE MATCH - GAME OVER" % String(leaver).to_upper())
        # a folded match room stays folded - never resurrect it
        if was_owner or members.is_empty() or was_play:
                rooms.erase(rid)   # the room dies with its owner / the match
        elif not rooms.has(rid):
                rooms[rid] = r     # a wait room keeps living without the leaver
        _mark_state(dev, "lobby")
        _push_rooms()

func _host_room_params(rid: int, params: Dictionary) -> void:
        var r: Dictionary = rooms.get(rid, {})
        if r.is_empty() or String(r.get("phase", "wait")) != "wait":
                return
        r["params"] = params
        rooms[rid] = r
        _push_rooms()

func _host_start_match(rid: int) -> String:
        var r: Dictionary = rooms.get(rid, {})
        if r.is_empty():
                return "the room is gone"
        if String(r.get("phase", "wait")) != "wait":
                return "the match already started"
        var members: Array = r.get("members", [])
        if members.size() < 2:
                return "wait for one more player"
        var game := String(r.get("game", ""))
        r["phase"] = "play"
        rooms[rid] = r
        var seed_v := int(Time.get_unix_time_from_system() * 1000.0) & 0x7fffffff
        var match_seats := _host_room_seats(rid)
        for dev in members:
                _mark_state(String(dev), "play:" + str(rid))
        _push_rooms()
        # THE ABSOLUTE SEATS: the join order IS the seat order, on every
        # device, forever (never rotated to the reader).
        var msg := {"t": "start", "game": game, "seed": seed_v,
                "seats": match_seats, "rid": rid,
                "params": r.get("params", {})}
        for dev in members:
                if dev == my_dev():
                        continue
                if _conns.has(dev):
                        _send_to(_conns[dev], msg)
        _apply_match_start(game, seed_v, match_seats, rid, r.get("params", {}))
        return ""

## The match seat array in JOIN ORDER - each entry carries rseat (the
## absolute room seat, 1-based). Colors/names key off this everywhere.
func _host_room_seats(rid: int) -> Array:
        var out := []
        var r: Dictionary = rooms.get(rid, {})
        var members: Array = r.get("members", [])
        for i in members.size():
                var s := seat_by_dev(String(members[i]))
                if s.is_empty():
                        continue
                var ms := {
                        "dev": String(s.get("dev", "")),
                        "name": String(s.get("name", "PLAYER")),
                        "pfp": int(s.get("pfp", 0)),
                        "pfpm": s.get("pfpm", {}),
                        "role": String(s.get("role", "gamer")),
                        "anchor": String(s.get("anchor", "")),
                        "local_slot": int(s.get("local_slot", 0)),
                        "platform": String(s.get("platform", "pc")),
                        "rseat": i + 1,
                }
                out.append(ms)
        return out

func _my_room_of_dev(dev: String) -> int:
        for rid in rooms:
                if (rooms[rid].get("members", []) as Array).has(dev):
                        return int(rid)
        return 0

func _host_mark_room_state(dev: String, rid: int, playing: bool) -> void:
        _mark_state(dev, ("play:" if playing else "room:") + str(rid))

## The rooms broadcast: the truth rides to every seat (and repaints the
## menu, the room screen, the badges).
func _push_rooms() -> void:
        if not is_host:
                return
        var arr := []
        for rid in rooms:
                arr.append(rooms[rid])
        var msg := {"t": "rooms", "rooms": arr}
        for dev in _conns:
                _send_to(_conns[dev], msg)
        _apply_rooms(arr)
        rooms_changed.emit()
        session_changed.emit()

func _refuse_conn(dev: String, why: String) -> void:
        var conn: StreamPeerTCP = _conns.get(dev)
        if conn != null:
                _send_to(conn, {"t": "room_denied", "why": why})

## CLIENT: apply the rooms broadcast. My room = the room that holds me.
func _apply_rooms(arr: Array) -> void:
        _rooms_mirror = {}
        for r in arr:
                if typeof(r) == TYPE_DICTIONARY:
                        _rooms_mirror[int(r.get("rid", 0))] = r
        var mine := 0
        for rid in _rooms_mirror:
                if (_rooms_mirror[rid].get("members", []) as Array).has(my_dev()):
                        mine = int(rid)
                        break
        if mine != _my_room:
                _my_room = mine
        rooms_changed.emit()
        session_changed.emit()

## The match was born (HOST + CLIENT via "start"): seat states, params,
## the game's duck call.
func _apply_match_start(game_id: String, seed_v: int, match_seats: Array,
                rid: int, params: Dictionary) -> void:
        match_params = params
        _my_state = "play:" + str(rid)
        for s in seats:
                if String(s.get("dev", "")) == my_dev():
                        s["state"] = _my_state
        match_started.emit(game_id, seed_v, match_seats, params)
        session_changed.emit()

## The match ended locally: the room folds, the seats return.
func _teardown_match_local(why: String, results: Array = []) -> void:
        var had_room := _my_room
        if had_room != 0 and String(room_by_id(had_room).get("phase", "")) == "play":
                var gid := room_game(had_room)
                _my_room = 0
                _my_state = "lobby"
                for s in seats:
                        var st := String(s.get("state", ""))
                        if st.begins_with("room:") or st.begins_with("play:"):
                                s["state"] = "lobby"
                if gid != "":
                        match_ended.emit(gid, results, why)
        else:
                _my_room = 0
                _my_state = "lobby"
        session_changed.emit()

## ================= the match relays (room-scoped) =================

## My move. The `who` rides MY ROOM SEAT automatically - the absolute
## join-order number, the same on every device (THE ABSOLUTE SEAT LAW).
func send_act(a: Dictionary) -> void:
        send_act_as(my_room_seat(), a)

## A relayed act for a specific room seat (the combo seat's own roll).
func send_act_as(seat: int, a: Dictionary) -> void:
        if _my_room == 0 or not session_active():
                return
        var game := room_game(_my_room)
        if game == "":
                return
        var msg := {"t": "act", "game": game, "room": _my_room,
                "who": seat, "a": a}
        if is_host:
                _host_relay_room(msg, "")
        elif _host_conn != null:
                _send_to(_host_conn, msg)

func send_snap(data: Dictionary) -> void:
        if _my_room == 0 or not is_host:
                return
        var msg := {"t": "snap", "game": room_game(_my_room),
                "room": _my_room, "data": data}
        _host_relay_room(msg, "")

func send_in(data: Dictionary) -> void:
        if _my_room == 0 or is_host or _host_conn == null:
                return
        _send_to(_host_conn, {"t": "in", "game": room_game(_my_room),
                "room": _my_room, "data": data})

func send_prog(data: Dictionary) -> void:
        if _my_room == 0 or not session_active():
                return
        var msg := {"t": "prog", "game": room_game(_my_room),
                "room": _my_room, "dev": my_dev(), "data": data}
        if is_host:
                _host_relay_room(msg, "")
        elif _host_conn != null:
                _send_to(_host_conn, msg)

## The host relays a room message to the room's OTHER members.
func _host_relay_room(msg: Dictionary, except_dev: String) -> void:
        var rid := int(msg.get("room", 0))
        var r: Dictionary = rooms.get(rid, {})
        if r.is_empty():
                return
        for dev in r.get("members", []):
                var d := String(dev)
                if d == except_dev or d == my_dev():
                        continue
                if _conns.has(d):
                        _send_to(_conns[d], msg)

## The verdict (a game's own end). The room folds for everyone.
func report_match_end(results: Array) -> void:
        if _my_room == 0 or not is_host:
                return
        _host_end_match(_my_room, results, "")

func _host_end_match(rid: int, results: Array, why: String) -> void:
        var r: Dictionary = rooms.get(rid, {})
        if r.is_empty():
                return
        var game := String(r.get("game", ""))
        var members: Array = r.get("members", [])
        for dev in members:
                _mark_state(String(dev), "lobby")
        rooms.erase(rid)
        _push_rooms()
        var msg := {"t": "end", "game": game, "rid": rid,
                "results": results, "why": why}
        for dev in members:
                if dev == my_dev():
                        continue
                if _conns.has(dev):
                        _send_to(_conns[dev], msg)
        _my_room = 0
        _my_state = "lobby"
        for s in seats:
                var st := String(s.get("state", ""))
                if st.begins_with("play:") or st.begins_with("room:"):
                        s["state"] = "lobby"
        if game != "":
                match_ended.emit(game, results, why)
        session_changed.emit()

## ================= the pump =================

func _ready() -> void:
        # THE PAUSE LAW (the joiner-drop root): the games pause the tree -
        # a paused LAN pump stops the heartbeats and both sides prune each
        # other mid-match. The session lives ABOVE the pause now.
        process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
        if not session_active():
                return
        var now := Time.get_unix_time_from_system()
        if is_host:
                _pump_host(now)
        else:
                _pump_join(now)
        _hb_clock += delta
        if _hb_clock >= HEARTBEAT:
                _hb_clock = 0.0
                _heartbeat(now)

func _pump_host(now: float) -> void:
        if _srv == null:
                return
        while _srv.is_connection_available():
                var conn := _srv.take_connection()
                if conn != null:
                        _pending.append(conn)
                        _buffers[conn.get_instance_id()] = PackedByteArray()
        # established peers
        for dev in _conns.keys():
                var conn: StreamPeerTCP = _conns[dev]
                conn.poll()
                var st := conn.get_status()
                if st != StreamPeerTCP.STATUS_CONNECTED:
                        _drop_peer(String(dev))
                        continue
                for line in _drain_lines(conn):
                        _handle_line(line, String(dev))
        # pending: waiting for their hello
        for conn in _pending.duplicate():
                var peer := conn as StreamPeerTCP
                peer.poll()
                var st := peer.get_status()
                if st != StreamPeerTCP.STATUS_CONNECTED:
                        _pending.erase(peer)
                        _buffers.erase(peer.get_instance_id())
                        continue
                for line in _drain_lines(conn):
                        var parsed: Variant = JSON.parse_string(line)
                        if typeof(parsed) == TYPE_DICTIONARY and String(parsed.get("t", "")) == "hello":
                                _admit(conn, parsed)
                                break
        # prune silent seats
        for s in seats.duplicate():
                var dev := String(s.get("dev", ""))
                if dev == my_dev() or dev == my_dev() + COMBO_DEV:
                        continue
                var seen: float = float(_seen.get(dev, 0.0))
                if seen > 0.0 and now - seen > PRUNE_AFTER:
                        _drop_peer(dev)

func _pump_join(now: float) -> void:
        if _host_conn == null:
                return
        _host_conn.poll()
        var st := _host_conn.get_status()
        if st == StreamPeerTCP.STATUS_ERROR or st == StreamPeerTCP.STATUS_NONE:
                _host_died("cannot reach the host - check the address, the wifi and the firewall")
                return
        if st != StreamPeerTCP.STATUS_CONNECTED:
                # still connecting - the honest deadline (12 s of silence
                # means the address is not answering, say so and drop)
                if now - _join_started > 12.0:
                        _host_died("cannot reach the host - check the address, the wifi and the firewall")
                return
        if not _joined:
                _joined = true
                session_changed.emit()
        if not _hello_sent:
                _hello_sent = true
                var idn := _ident()
                _send_to(_host_conn, {"t": "hello", "proto": 3, "dev": my_dev(),
                        "name": String(idn.get("name", "")), "pfp": int(idn.get("pfp", 0)),
                        "pfpm": idn.get("pfpm", {}),
                        "desc": String(idn.get("desc", "")),
                        "links": idn.get("links", []),
                        "age": int(idn.get("age", 0)),
                        "gender": String(idn.get("gender", "other")),
                        "role": String(idn.get("role", "gamer")),
                        "anchor": String(idn.get("anchor", "")),
                        "platform": MY_PLATFORM})
        for line in _drain_lines(_host_conn):
                _handle_line(line, "__host")
        if _joined and now - _last_host_msg > PRUNE_AFTER:
                _host_died("the host is gone")

func _drain_lines(conn: StreamPeerTCP) -> Array:
        var count := conn.get_available_bytes()
        if count <= 0:
                return []
        var res := conn.get_partial_data(count)
        if res[0] != OK:
                return []
        var id := conn.get_instance_id()
        var buf: PackedByteArray = _buffers.get(id, PackedByteArray())
        buf.append_array(res[1])
        var text := buf.get_string_from_utf8()
        if not text.contains("\n"):
                _buffers[id] = buf
                return []
        var parts := text.split("\n")
        _buffers[id] = parts[parts.size() - 1].to_utf8_buffer()
        var lines := []
        for i in parts.size() - 1:
                if parts[i].strip_edges() != "":
                        lines.append(parts[i])
        return lines

func _send_to(conn: StreamPeerTCP, msg: Dictionary) -> void:
        if conn == null:
                return
        conn.put_data((JSON.stringify(msg) + "\n").to_utf8_buffer())

## ================= the protocol =================

func _handle_line(line: String, who: String) -> void:
        var parsed: Variant = JSON.parse_string(line)
        if typeof(parsed) != TYPE_DICTIONARY:
                return
        var msg: Dictionary = parsed
        # the session extras route first (chat / kick / the face wire / vst)
        if _handle_line_ext(msg, who):
                return
        var t := String(msg.get("t", ""))
        match t:
                "welcome":
                        _touch()
                        seats = _clean_seats(msg.get("seats", []))
                        session_changed.emit()
                "seats":
                        _touch()
                        seats = _clean_seats(msg.get("seats", []))
                        session_changed.emit()
                "rooms":
                        _touch()
                        _apply_rooms(msg.get("rooms", []))
                "state":
                        if is_host:
                                _mark_state(who, String(msg.get("st", "lobby")))
                                _broadcast_seats()
                "room_open":
                        if is_host:
                                _host_open_room(who, String(msg.get("game", "")),
                                        msg.get("params", {}))
                "room_join":
                        if is_host:
                                _host_join_room(who, int(msg.get("rid", 0)))
                "room_leave":
                        if is_host:
                                var rid := int(msg.get("rid", 0))
                                if _my_room_of_dev(who) == rid:
                                        _host_leave_room(who, rid)
                "room_params":
                        if is_host:
                                var rr: Dictionary = rooms.get(int(msg.get("rid", 0)), {})
                                if String(rr.get("owner", "")) == who:
                                        _host_room_params(int(msg.get("rid", 0)),
                                                msg.get("params", {}))
                "room_start":
                        if is_host:
                                var rs: Dictionary = rooms.get(int(msg.get("rid", 0)), {})
                                if String(rs.get("owner", "")) == who:
                                        _host_start_match(int(msg.get("rid", 0)))
                "room_denied":
                        _touch()
                        room_refused.emit(String(msg.get("why", "the room refused")))
                "start":
                        _touch()
                        var rid := int(msg.get("rid", 0))
                        if rid == _my_room:
                                _apply_match_start(String(msg.get("game", "")),
                                        int(msg.get("seed", 0)),
                                        msg.get("seats", []), rid,
                                        msg.get("params", {}))
                "denied":
                        _touch()
                        lan_denied.emit(String(msg.get("game", "")), String(msg.get("why", "the host refused")))
                "act":
                        _touch()
                        var g := String(msg.get("game", ""))
                        var a: Dictionary = msg.get("a", {})
                        var w := int(msg.get("who", 0))
                        var rm := int(msg.get("room", 0))
                        if is_host:
                                _host_relay_room(msg, who)
                        if rm == _my_room and g == room_game(_my_room) and w != my_room_seat():
                                act_received.emit(g, w, a)
                "in":
                        if is_host:
                                var gi := String(msg.get("game", ""))
                                var ri := int(msg.get("room", 0))
                                if ri == _my_room and gi == room_game(_my_room):
                                        act_received.emit(gi, -1, msg.get("data", {}))
                "snap":
                        _touch()
                        if int(msg.get("room", 0)) == _my_room:
                                snap_received.emit(String(msg.get("game", "")), msg.get("data", {}))
                "prog":
                        _touch()
                        var pg := String(msg.get("game", ""))
                        var from := String(msg.get("dev", ""))
                        var pr := int(msg.get("room", 0))
                        if is_host:
                                _host_relay_room(msg, who)
                        if pr == _my_room and from != my_dev():
                                prog_received.emit(pg, from, msg.get("data", {}))
                "end":
                        _touch()
                        var eg := String(msg.get("game", ""))
                        var er := int(msg.get("rid", 0))
                        if er == _my_room:
                                _my_room = 0
                                _my_state = "lobby"
                                for s in seats:
                                        var st2 := String(s.get("state", ""))
                                        if st2.begins_with("play:") or st2.begins_with("room:"):
                                                s["state"] = "lobby"
                                match_ended.emit(eg, msg.get("results", []),
                                        String(msg.get("why", "")))
                                session_changed.emit()
                "ping":
                        if is_host:
                                _send_to(_conns.get(who), {"t": "pong"})
                        else:
                                _touch()
                                _send_to(_host_conn, {"t": "pong"})
                "pong":
                        if is_host:
                                _seen[who] = Time.get_unix_time_from_system()
                        else:
                                _touch()
                "bye":
                        if is_host:
                                _drop_peer(who)

func _touch() -> void:
        _last_host_msg = Time.get_unix_time_from_system()

func _admit(conn: StreamPeerTCP, hello: Dictionary) -> void:
        _pending.erase(conn)
        var dev := String(hello.get("dev", ""))
        if dev == "" or dev == my_dev() or _conns.has(dev) or seats.size() >= SEAT_CAP:
                _send_to(conn, {"t": "denied", "game": "", "why": "the session is full"})
                _buffers.erase(conn.get_instance_id())
                conn.disconnect_from_host()
                return
        _conns[dev] = conn
        _seen[dev] = Time.get_unix_time_from_system()
        var name_v := LanProfile.sanitize_name(String(hello.get("name", "PLAYER")))
        if name_v.length() < LanProfile.NAME_MIN:
                name_v = "PLAYER %d" % (seats.size() + 1)
        var seat := {"dev": dev, "name": name_v,
                "pfp": clampi(int(hello.get("pfp", 0)), 0, LanProfile.PFP_VARIANTS - 1),
                "pfpm": hello.get("pfpm", {}),
                "desc": String(hello.get("desc", "")),
                "links": hello.get("links", []),
                "age": clampi(int(hello.get("age", 0)), 0, 999),
                "gender": String(hello.get("gender", "other")),
                "role": String(hello.get("role", "gamer")), "anchor": String(hello.get("anchor", "")),
                "seat": seats.size() + 1, "local_slot": 0,
                "platform": String(hello.get("platform", "pc")), "state": "lobby"}
        for s in seats:
                if String(s.get("anchor", "")) != "" and String(s.get("anchor", "")) == seat["anchor"] \
                                and String(s.get("dev", "")) != dev:
                        seat["ghost"] = true
        seats.append(seat)
        _reseat()
        _send_to(conn, {"t": "welcome", "you": dev, "seats": seats})
        var arr := []
        for rid in rooms:
                arr.append(rooms[rid])
        _send_to(conn, {"t": "rooms", "rooms": arr})
        _broadcast_seats()

func _mark_state(dev: String, st: String) -> void:
        for s in seats:
                if String(s.get("dev", "")) == dev:
                        s["state"] = st

func _broadcast_seats() -> void:
        if not is_host:
                return
        var msg := {"t": "seats", "seats": seats}
        for dev in _conns:
                _send_to(_conns[dev], msg)
        session_changed.emit()

## THE DISCONNECT LAW: a dropped/kicked member ends the live match of
## every room they were in - honestly, with the note the owner asked for.
func _drop_peer(dev: String) -> void:
        var conn: StreamPeerTCP = _conns.get(dev)
        if conn != null:
                conn.disconnect_from_host()
        _conns.erase(dev)
        _seen.erase(dev)
        var leaver := "A PLAYER"
        for i in seats.size():
                if String(seats[i].get("dev", "")) == dev:
                        leaver = String(seats[i].get("name", "A PLAYER"))
                        seats.remove_at(i)
                        break
        _reseat()
        if is_host:
                for rid in rooms.keys():
                        var r: Dictionary = rooms[rid]
                        if (r.get("members", []) as Array).has(dev):
                                _host_leave_room(dev, int(rid))
        _broadcast_seats()
        rooms_changed.emit()

func _host_died(why: String) -> void:
        _close_all()
        _teardown_match_local("THE HOST IS GONE" if why == "" else why, [])
        mode = "idle"
        is_host = false
        _joined = false
        seats = []
        rooms = {}
        _rooms_mirror = {}
        chat_log = []                 # THE CHAT LAW: never saved, dies here
        chat_bytes = 0
        session_died.emit(why)
        session_changed.emit()

func _heartbeat(now: float) -> void:
        if is_host:
                for dev in _conns:
                        _send_to(_conns[dev], {"t": "ping"})
        elif _host_conn != null:
                _send_to(_host_conn, {"t": "ping"})

func _clean_seats(arr: Array) -> Array:
        var out := []
        for s in arr:
                if typeof(s) == TYPE_DICTIONARY:
                        var d: Dictionary = s.duplicate()
                        d["name"] = LanProfile.sanitize_name(String(d.get("name", "PLAYER")))
                        if String(d["name"]).length() < LanProfile.NAME_MIN:
                                d["name"] = "PLAYER"
                        out.append(d)
        return out

## ================= the room code (the VLAN leg) =================

## "GOGA-XXXXXX-XXXXXXC" — hex(ip:4 + port:2) + a checksum letter.
## Reversible without any server; works over UPnP internet plays and over
## VLAN NICs (Tailscale/ZeroTier) unchanged.
const CODE_ALPHA := "ABCDEFGHJKMNPQRSTUVWXYZ"

func encode_code(ip: String, port: int) -> String:
        var quads := ip.split(".")
        if quads.size() != 4:
                return ""
        var bytes := PackedByteArray()
        for q in quads:
                var v := q.to_int()
                if v < 0 or v > 255:
                        return ""
                bytes.append(v)
        bytes.append((port >> 8) & 0xFF)
        bytes.append(port & 0xFF)
        var hex := bytes.hex_encode().to_upper()
        var chk := CODE_ALPHA[absi(hash(hex)) % CODE_ALPHA.length()]
        return "GOGA-%s-%s%s" % [hex.substr(0, 6), hex.substr(6, 6), chk]

func decode_code(code: String) -> String:
        var c := code.strip_edges().to_upper().replace(" ", "")
        if not c.begins_with("GOGA-"):
                return ""
        var body := c.substr(5).replace("-", "")
        if body.length() != 13:
                return ""
        var hex := body.substr(0, 12)
        var chk := body.substr(12, 1)
        if CODE_ALPHA[absi(hash(hex)) % CODE_ALPHA.length()] != chk:
                return ""
        var bytes := PackedByteArray()
        for i in range(0, 12, 2):
                bytes.append(("0x" + hex.substr(i, 2)).hex_to_int())
        var ip := "%d.%d.%d.%d" % [bytes[0], bytes[1], bytes[2], bytes[3]]
        var port := (bytes[4] << 8) | bytes[5]
        return "%s:%d" % [ip, port]

func _lan_ip() -> String:
        for ip in IP.get_local_addresses():
                var s := String(ip)
                if s.begins_with("192.168.") or s.begins_with("10.") or s.begins_with("172."):
                        return s
        return "127.0.0.1"

## ================= debug (probes) =================

func probe_state() -> Dictionary:
        var arr := []
        for rid in rooms:
                arr.append(rooms[rid])
        return {"mode": mode, "seats": seats.duplicate(true), "rooms": arr,
                "my_room": _my_room, "port": _port, "addr": host_addr,
                "code": room_code, "online": online_ready}

# ============================================== v042-1 r3 THE SESSION EXTRAS
## THE CHAT LAW (ids, the honest dedupe, the live unread), THE FACE WIRE,
## THE REMOVE/KICK, THE VOICE STATE WIRE.

const CHAT_MAX_MSGS := 100
const CHAT_MAX_BYTES := 10 * 1024 * 1024       # the 10MB ceiling
const CHAT_MSG_MAX := 1000                     # the 1K per-message law
const CHAT_COOLDOWN := 5.0                     # the 5-second cooldown
const PFP_CHUNK := 48000                       # base64 bytes per wire line

var chat_log: Array = []                       # {id, dev, seat, name, pfpm, text, reply_to, ts}
var chat_bytes := 0
var _chat_last_sent := -60.0
var _chat_mid := 0
var chat_unread := 0                           # lines that landed with no chat UI open
var chat_mention_unread := 0                   # of those, the ones that name me
var chat_ui_open := false                      # the chat sheet sets this
var chat_read_id := ""                        # r3: the newest line's id I actually saw

var _pfp_out := {}                             # hash -> {meta, bytes} (the sender side)
var _pfp_in := {}                              # hash -> {meta, parts, got}
var _pfp_want := {}                            # hash -> requester dev (the host's relay leg)

## The identity rides the media meta now (the FACE WIRE): hello/seats carry
## pfpm so a visitor knows what face to fetch.
func _ident() -> Dictionary:
        if not ident_override.is_empty():
                return ident_override
        var fm := LanProfile.face_media()
        if not fm.is_empty() and not LanProfile.cache_has(String(fm.get("h", ""))):
                fm = {}        # the media file is gone - the drawn guy rides
        return {"name": LanProfile.player_name(), "pfp": LanProfile.pfp(),
                "pfpm": fm, "role": LanProfile.role(),
                "desc": LanProfile.desc(), "links": LanProfile.links(),
                "age": LanProfile.age(), "gender": LanProfile.gender(),
                "anchor": LanProfile.anchor_short()}

## THE REMOVE LAW: the host removes anyone; the removed device is dropped
## with a note.
func kick_member(dev: String) -> bool:
        if not is_host or dev == my_dev():
                return false
        var conn: StreamPeerTCP = _conns.get(dev)
        if conn != null:
                _send_to(conn, {"t": "kick", "why": "the host removed you"})
        _drop_peer(dev)
        return true

## THE CHAT LAW (v042-1; r3 THE DEDUPE + THE ID LAW): one shared
## per-session chat, EN-only no-emoji, 1K chars, 5s cooldown, 100 messages
## / 10MB then the earliest slides out. NEVER saved. The host NEVER
## echoes a sender's line back (the sender lands it locally - the echo
## was the double message). Every line carries a stable id so a reply
## survives the sliding window (the index reply died with evictions).
func send_chat(text: String, reply_to := "") -> String:
        if not session_active():
                return "no session"
        var now := Time.get_unix_time_from_system()
        if now - _chat_last_sent < CHAT_COOLDOWN:
                return "wait %d s" % int(ceilf(CHAT_COOLDOWN - (now - _chat_last_sent)))
        var clean := LanProfile.sanitize_chat(text)
        if clean == "":
                return "nothing to send"
        _chat_last_sent = now
        _chat_mid += 1
        var msg := {"t": "chat", "id": "%d.%d.%s" % [int(now * 1000.0), _chat_mid,
                        my_dev().substr(my_dev().length() - 4, 4)],
                "dev": my_dev(), "seat": my_seat_no(), "name": my_name(),
                "pfpm": my_face_meta(), "text": clean, "reply_to": reply_to,
                "ts": now}
        if is_host:
                for dev in _conns:
                        _send_to(_conns[dev], msg)
                _chat_land(msg)
        elif _host_conn != null:
                _send_to(_host_conn, msg)
                _chat_land(msg)       # my own line lands immediately
        return ""

## THE LIVE COOLDOWN (the owner: "the cooldown is not dynamic, it waits
## to a send to be toggled so it shows wait nn, make it show always wait
## nn accurately then after count down it enables sending more").
func chat_cooldown_left() -> float:
        if not session_active():
                return 0.0
        return maxf(0.0, CHAT_COOLDOWN - (Time.get_unix_time_from_system() - _chat_last_sent))

func chat_mark_read() -> void:
        chat_unread = 0
        chat_mention_unread = 0
        if not chat_log.is_empty():
                chat_read_id = String(chat_log[chat_log.size() - 1].get("id", ""))

func _chat_land(msg: Dictionary) -> void:
        var m := msg.duplicate()
        m["text"] = LanProfile.sanitize_chat(String(m.get("text", "")))
        var rt := String(m.get("reply_to", ""))
        m["reply_to"] = rt
        m["ts"] = Time.get_unix_time_from_system()   # THE ARRIVAL CLOCK
        chat_log.append(m)
        chat_bytes += str(m.get("text", "")).to_utf8_buffer().size()
        while chat_log.size() > CHAT_MAX_MSGS \
                        or chat_bytes > CHAT_MAX_BYTES:
                var gone: Dictionary = chat_log.pop_front()
                chat_bytes -= str(gone.get("text", "")).to_utf8_buffer().size()
                if chat_log.is_empty():
                        chat_bytes = 0
                        break
        if not chat_ui_open:
                chat_unread += 1
                if _is_mention(String(m.get("text", ""))):
                        chat_mention_unread += 1
        else:
                chat_read_id = String(m.get("id", ""))
        chat_received.emit(m)

## THE MENTION LAW: the line names ME (a plain name token or @name).
func _is_mention(text: String) -> bool:
        var nm := my_name().to_lower()
        if nm == "":
                return false
        var low := text.to_lower()
        if low.contains("@" + nm):
                return true
        var rx := RegEx.new()
        if rx.compile("\\b" + nm + "\\b") == OK:
                return rx.search(low) != null
        return false

func _handle_chat(msg: Dictionary, who: String) -> void:
        if is_host:
                # THE DEDUPE LAW: the host relays to everyone EXCEPT the
                # sender - the sender landed its own line already, and the
                # echo back was the double message.
                for dev in _conns:
                        if String(dev) != who:
                                _send_to(_conns[dev], msg)
        _chat_land(msg)

func my_name() -> String:
        for s in seats:
                if String(s.get("dev", "")) == my_dev():
                        return String(s.get("name", "PLAYER"))
        return LanProfile.player_name()

func my_face_meta() -> Dictionary:
        var idn := _ident()
        return idn.get("pfpm", {})

## THE FACE WIRE: a visitor fetches a member's media face in
## hash-addressed base64 chunks; the receiving cache makes re-visits free.
## The wire is a STAR: the request rides to the host, the host serves OR
## forwards to the owning seat, the chunks ride back through the host.
func pfp_request(hash_v: String, owner_dev: String) -> void:
        if hash_v == "" or _pfp_in.has(hash_v):
                return
        if LanProfile.cache_has(hash_v):
                return
        var msg := {"t": "pfp_get", "h": hash_v, "want_dev": my_dev()}
        if is_host:
                _serve_or_forward_pfp(hash_v, my_dev())
        elif _host_conn != null:
                _send_to(_host_conn, msg)

## THE ROW LAW (r3, the placeholder-forever fix): every seat that shows a
## face asks for its media ONCE - the profile viewer was the only asker,
## so member rows held the placeholder forever. Idempotent, cache-aware.
func pfp_touch(seat: Dictionary) -> void:
        var pm: Variant = seat.get("pfpm", {})
        if typeof(pm) != TYPE_DICTIONARY:
                return
        var meta: Dictionary = pm
        if meta.is_empty() or bool(seat.get("ghost", false)):
                return
        var h := String(meta.get("h", ""))
        if h == "" or LanProfile.cache_has(h):
                return
        var dev := String(seat.get("dev", ""))
        if dev == "" or dev == my_dev():
                return
        pfp_request(h, dev)

## the host's leg: serve from cache, or forward the ask to the owner seat
func _serve_or_forward_pfp(hash_v: String, want_dev: String) -> void:
        if LanProfile.cache_has(hash_v):
                _send_pfp_chunks(hash_v, want_dev)
                return
        for s in seats:
                var pm: Variant = s.get("pfpm", {})
                if typeof(pm) == TYPE_DICTIONARY \
                                and String(pm.get("h", "")) == hash_v:
                        var owner := String(s.get("dev", ""))
                        _pfp_want[hash_v] = want_dev
                        if _conns.has(owner):
                                _send_to(_conns[owner],
                                                {"t": "pfp_get", "h": hash_v})
                        return

func _handle_pfp_get(msg: Dictionary, who: String) -> void:
        var hash_v := String(msg.get("h", ""))
        if hash_v == "":
                return
        if is_host:
                var want := String(msg.get("want_dev", who))
                _serve_or_forward_pfp(hash_v, want)
                return
        # a client asked ME (I own the face) - the chunks ride to the host,
        # which relays them to the waiter
        _send_pfp_chunks(hash_v, "__host")

func _send_pfp_chunks(hash_v: String, target_dev: String) -> void:
        if not LanProfile.cache_has(hash_v):
                return
        var meta := LanProfile.cache_meta(hash_v)
        var path := LanProfile.media_path(hash_v, String(meta.get("ext", "webp")))
        var f := FileAccess.open(path, FileAccess.READ)
        if f == null:
                return
        var bytes := f.get_buffer(f.get_length())
        f.close()
        if bytes.size() > LanProfile.MEDIA_WIRE_MAX or bytes.is_empty():
                return
        var b64 := Marshalls.raw_to_base64(bytes)
        var parts := ceili(float(b64.length()) / float(PFP_CHUNK))
        var target: StreamPeerTCP = _conns.get(target_dev)
        if target == null and (target_dev == "__host" or not is_host):
                target = _host_conn
        if target == null:
                return
        for i in parts:
                _send_to(target, {"t": "pfp_data", "h": hash_v, "ext": meta.get("ext", "webp"),
                        "meta": meta, "idx": i, "of": parts,
                        "b64": b64.substr(i * PFP_CHUNK, PFP_CHUNK)})

func _handle_pfp_data(msg: Dictionary, who: String) -> void:
        var hash_v := String(msg.get("h", ""))
        if hash_v == "":
                return
        if is_host and _pfp_want.has(hash_v):
                # the relay leg: the owner's chunks ride on to the waiter
                var want := String(_pfp_want[hash_v])
                var target: StreamPeerTCP = _conns.get(want)
                if target != null:
                        _send_to(target, msg)
                if int(msg.get("idx", 0)) + 1 >= int(msg.get("of", 1)):
                        _pfp_want.erase(hash_v)
                return
        var st: Dictionary = _pfp_in.get(hash_v, {"parts": [], "of": int(msg.get("of", 1))})
        var parts: Array = st["parts"]
        var idx := int(msg.get("idx", 0))
        while parts.size() <= idx:
                parts.append("")
        parts[idx] = String(msg.get("b64", ""))
        st["parts"] = parts
        st["of"] = int(msg.get("of", st.get("of", 1)))
        _pfp_in[hash_v] = st
        var of := int(st["of"])
        var full := parts.size() >= of
        for p in parts:
                if String(p) == "":
                        full = false
                        break
        if not full:
                return
        var b64 := "".join(PackedStringArray(parts.map(func(x): return String(x))))
        var bytes := Marshalls.base64_to_raw(b64)
        if bytes.is_empty() or bytes.size() > LanProfile.MEDIA_WIRE_MAX:
                _pfp_in.erase(hash_v)
                return
        var ext := String(msg.get("ext", "webp"))
        LanProfile.cache_store(hash_v, ext, bytes, msg.get("meta", {}))
        _pfp_in.erase(hash_v)
        face_arrived.emit(hash_v)

## THE VOICE STATE WIRE: every device publishes its mic/hear truth so the
## rosters show the REMOTE states live (the owner's semantics law).
func send_vst(mic: bool, hear: bool, has_mic: bool) -> void:
        if not session_active():
                return
        var msg := {"t": "vst", "dev": my_dev(), "mic": mic, "hear": hear,
                "hm": has_mic}
        if is_host:
                for dev in _conns:
                        _send_to(_conns[dev], msg)
        elif _host_conn != null:
                _send_to(_host_conn, msg)

## ================= the wire routing (extension) =================

func _handle_line_ext(msg: Dictionary, who: String) -> bool:
        var t := String(msg.get("t", ""))
        match t:
                "chat":
                        _touch()
                        _handle_chat(msg, who)
                        return true
                "kick":
                        _touch()
                        _close_all()
                        _teardown_match_local("THE HOST REMOVED YOU")
                        mode = "idle"
                        is_host = false
                        _joined = false
                        seats = []
                        rooms = {}
                        _rooms_mirror = {}
                        _my_room = 0
                        chat_log = []
                        chat_bytes = 0
                        kicked.emit(String(msg.get("why", "the host removed you")))
                        session_changed.emit()
                        return true
                "vst":
                        _touch()
                        vst_arrived.emit(msg)
                        return true
                "pfp_get":
                        _handle_pfp_get(msg, who)
                        return true
                "pfp_data":
                        _handle_pfp_data(msg, who)
                        return true
        return false
