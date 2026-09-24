extends Node
## LAN — the box's local-network multiplayer core (v042).
##
## THE LAN LAW: local network only — each player on their own device, one
## wifi, no accounts, no internet services, no servers. Plain TCP
## (TCPServer / StreamPeerTCP), newline-delimited JSON messages. The session
## dies with the app (THE HOST/JOIN LAW). The host owns the truth; clients
## mirror (one clock, no drift: the hold countdown and match starts are
## host-authoritative).
##
## THE REAL-ONLY LAW: a LAN match has NO CPU players — every seat is a human
## on a device. The verdict is simple: one winner, everyone else a loser.
##
## THE GAME CONTRACT (duck-typed, both twins):
##   lan_match_start(seed: int, seats: Array)      # configure + begin
##   lan_act(who: int, a: Dictionary)              # apply a relayed action
##   lan_snap(data: Dictionary)                    # apply a host snapshot
##   lan_prog(from_dev: String, data: Dictionary)  # a rival's progress
##   lan_end(results: Array)                       # the match verdict
##   lan_hold_end_solo()                           # hold fell through to solo
## GAMES CALL (apply locally FIRST, then broadcast):
##   LAN.send_act(a)      # TURN_RELAY: my move, to everyone
##   LAN.send_in(data)    # HOST_AUTH: client input to the host
##   LAN.send_snap(data)  # HOST_AUTH: host snapshot to everyone
##   LAN.send_prog(data)  # RACE / SELF_AUTH events to everyone

signal session_changed
signal hold_changed(game_id: String)
signal match_started(game_id: String, seed_v: int, seats: Array)
signal match_left_out(game_id: String)            # the match started without me
signal match_ended(game_id: String, results: Array)
signal act_received(game_id: String, who: int, a: Dictionary)
signal snap_received(game_id: String, data: Dictionary)
signal prog_received(game_id: String, from_dev: String, data: Dictionary)
signal solo_fallthrough(game_id: String)          # alone in the hold too long
signal lan_denied(game_id: String, why: String)   # the game's LAN rules refused me
signal session_died(why: String)                  # the host closed / the wire died

const BASE_PORT := 31440           # the code base number
const PORT_TRIES := 10
const HEARTBEAT := 3.0
const PRUNE_AFTER := 10.0
const LONE_GRACE := 5.0            # THE LONE LAW: alone in the hold -> solo
const COUNTDOWN := 10.0            # THE TEN SECONDS LAW
const SEAT_CAP := 4                # GOGABox limits one session to 4 players
var MY_PLATFORM := "android" if OS.has_feature("android") else "pc"

var mode := "idle"                 # idle | host | join
var seats: Array = []              # [{dev,name,pfp,role,anchor,seat,local_slot,platform,state}]
var is_host := false
var host_addr := ""                # "ip:port" as shown to joiners
var room_code := ""
var upnp_ok := false

var _srv: TCPServer = null
var _port := 0
var _host_conn: StreamPeerTCP = null       # when joining: the wire to the host
var _hello_sent := false
# v042-1 r2 THE JOIN HONESTY LAW: a join used to flip the badge and the
# sheet the MOMENT the connect was ASKED for - a blocked address (the
# firewall, the wrong IP, AP isolation) left the joiner in a silent
# 1-seat "session" wearing a LAN LIVE badge, playing solo forever (the
# owner: "we both are on the lan live thing, i was not even able to play
# lan, every time i play, i jump into solo"). The join now wears REAL
# states: connecting -> joined (the seats arrive) or an HONEST death.
var _joined := false
var _join_started := 0.0
var _conns := {}                           # dev -> StreamPeerTCP (host side)
var _buffers := {}                         # conn instance id -> partial line bytes
var _pending: Array = []                   # connections awaiting their hello
var _seen := {}                            # dev -> last heartbeat unix time
var _last_host_msg := 0.0                  # client side watchdog
var _hb_clock := 0.0
var _hold_bc_clock := 0.0
var _my_state := "lobby"                   # lobby | hold:<game> | committed:<game>
var _holds := {}                           # game -> {phase, t_left, committed: [dev]}
var _lone_clock := {}                      # game -> seconds with exactly 1 holder
var _countdown_clock := {}                 # game -> seconds left on THE TEN SECONDS
var _match_game := ""
var _open_game := ""

## ================= identity =================

## The probe identity overrides: four LAN cores can live in ONE process
## (the loopback rig) - each wears its own dev/name/anchor so the session
## simulates four REAL devices end to end over real TCP.
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

## v042-1 r2: the joiner's wire is truly IN (the welcome landed). A
## session that is merely "connecting" holds no badges and no holds.
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
        _holds = {}
        _lone_clock = {}
        _countdown_clock = {}
        _conns = {}
        _buffers = {}
        _pending = []
        _seen = {}
        _my_state = "lobby"
        _match_game = ""
        _add_local_seat(0)
        _start_upnp()
        _broadcast_seats()
        session_changed.emit()
        return ""

func _start_upnp() -> void:
        upnp_ok = false
        room_code = ""
        if _port == 0:
                return
        var ext := ""
        var upnp := UPNP.new()
        if upnp.discover(500, 2) == UPNP.UPNP_RESULT_SUCCESS and upnp.get_gateway() != null:
                if upnp.add_port_mapping(_port, _port, "GOGABox LAN", "TCP", 3600) == UPNP.UPNP_RESULT_SUCCESS:
                        upnp_ok = true
                        ext = upnp.query_external_address()
        if ext == "":
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
        _holds = {}
        _my_state = "lobby"
        _match_game = ""
        _last_host_msg = Time.get_unix_time_from_system()
        session_changed.emit()
        return ""

func leave_session() -> void:
        if mode == "join" and _host_conn != null:
                _send_to(_host_conn, {"t": "bye"})
        _close_all()
        mode = "idle"
        is_host = false
        seats = []
        _holds = {}
        _lone_clock = {}
        _countdown_clock = {}
        _match_game = ""
        _my_state = "lobby"
        chat_log = []                 # THE CHAT LAW: never saved, dies here
        chat_bytes = 0
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

## COMBO CO-OP v042-1 (the owner: "it makes a copy of me for no reason and
## i can visit it, remove this mechanic... adding a local player means
## adding a player using it's details only"): the host seats a second
## LOCAL player BY ITS DETAILS - the name comes from the caller, the face
## is the placeholder guy. No clone, no fake tint.
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

## ================= the hold system (per game) =================

## The box asks BEFORE booting a game: should this boot wear the LAN hold?
func pre_open(game_id: String) -> bool:
        if not session_active() or seats.size() < 2:
                return false
        if not joined_ok():
                return false
        return platform_ok(game_id)

## The box announces the game is open (after the game node exists).
## Returns true if the hold is live for this game.
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
        _set_state("hold:" + game_id)
        if is_host:
                _refresh_hold(game_id)
                _broadcast_seats()
        else:
                _send_to(_host_conn, {"t": "open", "game": game_id})
        hold_changed.emit(game_id)
        return true

func report_close(game_id: String) -> void:
        if _open_game == game_id:
                _open_game = ""
        if not session_active():
                return
        _set_state("lobby")
        if is_host:
                _refresh_hold(game_id)
                _broadcast_seats()
        else:
                _send_to(_host_conn, {"t": "lobby", "game": game_id})
        hold_changed.emit(game_id)

func _set_state(st: String) -> void:
        _my_state = st
        for s in seats:
                if String(s.get("dev", "")) == my_dev():
                        s["state"] = st

## The player pressed GET IN inside the hold.
func commit(game_id: String) -> void:
        _set_state("committed:" + game_id)
        if is_host:
                _refresh_hold(game_id)
                _broadcast_seats()
        else:
                _send_to(_host_conn, {"t": "commit", "game": game_id})
        hold_changed.emit(game_id)

func holders_of(game_id: String) -> Array:
        var out := []
        for s in seats:
                var st := String(s.get("state", ""))
                if st == "hold:" + game_id or st == "committed:" + game_id:
                        out.append(s)
        return out

func committed_of(game_id: String) -> Array:
        var out := []
        for s in seats:
                if String(s.get("state", "")) == "committed:" + game_id:
                        out.append(s)
        return out

func hold_info(game_id: String) -> Dictionary:
        return _holds.get(game_id, {})

func _refresh_hold(game_id: String) -> void:
        if not is_host:
                return
        var holders := holders_of(game_id)
        var committed := committed_of(game_id)
        if holders.is_empty():
                _holds.erase(game_id)
                _lone_clock.erase(game_id)
                _countdown_clock.erase(game_id)
                _broadcast_hold(game_id)
                return
        var info := {"phase": "waiting", "t_left": -1.0, "committed": []}
        if committed.is_empty() and holders.size() == 1:
                if not _lone_clock.has(game_id):
                        _lone_clock[game_id] = 0.0
        else:
                _lone_clock.erase(game_id)
                if not committed.is_empty():
                        if not _countdown_clock.has(game_id):
                                _countdown_clock[game_id] = COUNTDOWN
                        info["phase"] = "count"
                        info["t_left"] = float(_countdown_clock[game_id])
                        var devs := []
                        for s in committed:
                                devs.append(String(s["dev"]))
                        info["committed"] = devs
                else:
                        _countdown_clock.erase(game_id)
        _holds[game_id] = info
        _broadcast_hold(game_id)

func _broadcast_hold(game_id: String) -> void:
        if not is_host:
                return
        var msg := {"t": "hold", "game": game_id, "hold": _holds.get(game_id, {})}
        for dev in _conns:
                _send_to(_conns[dev], msg)
        hold_changed.emit(game_id)

## ================= the match relays =================

func send_act(a: Dictionary) -> void:
        send_act_as(my_seat_no(), a)

## v042-1 COMBO: a relayed act can ride a NON-primary local seat (the
## combo player's own roll) - who carries THAT seat's number, so every
## device can gate the act to the right turn.
func send_act_as(seat: int, a: Dictionary) -> void:
        if _match_game == "" or not session_active():
                return
        var msg := {"t": "act", "game": _match_game, "who": seat, "a": a}
        if is_host:
                for dev in _conns:
                        _send_to(_conns[dev], msg)
        elif _host_conn != null:
                _send_to(_host_conn, msg)

func send_snap(data: Dictionary) -> void:
        if _match_game == "" or not is_host:
                return
        var msg := {"t": "snap", "game": _match_game, "data": data}
        for dev in _conns:
                _send_to(_conns[dev], msg)

func send_in(data: Dictionary) -> void:
        if _match_game == "" or is_host or _host_conn == null:
                return
        _send_to(_host_conn, {"t": "in", "game": _match_game, "data": data})

func send_prog(data: Dictionary) -> void:
        if _match_game == "" or not session_active():
                return
        var msg := {"t": "prog", "game": _match_game, "dev": my_dev(), "data": data}
        if is_host:
                for dev in _conns:
                        _send_to(_conns[dev], msg)
        elif _host_conn != null:
                _send_to(_host_conn, msg)

func report_match_end(game_id: String, results: Array) -> void:
        if not is_host or _match_game != game_id:
                return
        var msg := {"t": "end", "game": game_id, "results": results}
        for dev in _conns:
                _send_to(_conns[dev], msg)
        _end_match_local(game_id, results)

func _end_match_local(game_id: String, results: Array) -> void:
        _match_game = ""
        _holds.erase(game_id)
        _countdown_clock.erase(game_id)
        _lone_clock.erase(game_id)
        for s in seats:
                var st := String(s.get("state", ""))
                if st.begins_with("hold:") or st.begins_with("committed:") or st.begins_with("playing:"):
                        s["state"] = "lobby"
        _my_state = "lobby"
        if is_host:
                _broadcast_seats()
        match_ended.emit(game_id, results)
        session_changed.emit()

## ================= the pump =================

func _process(delta: float) -> void:
        if not session_active():
                return
        var now := Time.get_unix_time_from_system()
        if is_host:
                _pump_host(now)
                _tick_countdowns(delta)
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
                if dev == my_dev() or dev == my_dev() + "-p2":
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
                _send_to(_host_conn, {"t": "hello", "proto": 1, "dev": my_dev(),
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
        # v042-1 the session extras route first (chat / kick / the face wire)
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
                "hold":
                        _touch()
                        var game := String(msg.get("game", ""))
                        if game != "":
                                _holds[game] = msg.get("hold", {})
                                hold_changed.emit(game)
                "open":
                        if is_host:
                                _mark_state(who, "hold:" + String(msg.get("game", "")))
                                _refresh_hold(String(msg.get("game", "")))
                                session_changed.emit()
                "lobby":
                        if is_host:
                                _mark_state(who, "lobby")
                                _refresh_hold(String(msg.get("game", "")))
                                session_changed.emit()
                "commit":
                        if is_host:
                                var g := String(msg.get("game", ""))
                                _mark_state(who, "committed:" + g)
                                _refresh_hold(g)
                                session_changed.emit()
                "start":
                        _touch()
                        _on_match_start(String(msg.get("game", "")), int(msg.get("seed", 0)), msg.get("seats", []))
                "solo":
                        _touch()
                        _set_state("lobby")
                        _send_to(_host_conn, {"t": "lobby", "game": String(msg.get("game", ""))})
                        solo_fallthrough.emit(String(msg.get("game", "")))
                "left_out":
                        _touch()
                        match_left_out.emit(String(msg.get("game", "")))
                "denied":
                        _touch()
                        lan_denied.emit(String(msg.get("game", "")), String(msg.get("why", "the host refused")))
                "act":
                        _touch()
                        var g := String(msg.get("game", ""))
                        var a: Dictionary = msg.get("a", {})
                        var w := int(msg.get("who", 0))
                        if is_host:
                                for dev in _conns:
                                        if String(dev) != who:
                                                _send_to(_conns[dev], msg)
                        if g == _match_game:
                                act_received.emit(g, w, a)
                "in":
                        if is_host and String(msg.get("game", "")) == _match_game:
                                act_received.emit(_match_game, -1, msg.get("data", {}))
                "snap":
                        _touch()
                        if String(msg.get("game", "")) == _match_game:
                                snap_received.emit(_match_game, msg.get("data", {}))
                "prog":
                        _touch()
                        var pg := String(msg.get("game", ""))
                        var from := String(msg.get("dev", ""))
                        if is_host:
                                for dev in _conns:
                                        if String(dev) != who:
                                                _send_to(_conns[dev], msg)
                        if pg == _match_game and from != my_dev():
                                prog_received.emit(pg, from, msg.get("data", {}))
                "end":
                        _touch()
                        var eg := String(msg.get("game", ""))
                        if eg == _match_game:
                                _end_match_local(eg, msg.get("results", []))
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

func _drop_peer(dev: String) -> void:
        var conn: StreamPeerTCP = _conns.get(dev)
        if conn != null:
                conn.disconnect_from_host()
        _conns.erase(dev)
        _seen.erase(dev)
        for i in seats.size():
                if String(seats[i].get("dev", "")) == dev:
                        seats.remove_at(i)
                        break
        _reseat()
        for game in _holds.keys():
                _refresh_hold(String(game))
        _broadcast_seats()

func _host_died(why: String) -> void:
        _close_all()
        mode = "idle"
        is_host = false
        _joined = false
        seats = []
        _holds = {}
        _lone_clock = {}
        _countdown_clock = {}
        _match_game = ""
        _my_state = "lobby"
        chat_log = []                 # THE CHAT LAW: never saved, dies here
        chat_bytes = 0
        session_died.emit(why)
        session_changed.emit()

## ================= hold ticking + match birth (host) =================

func _tick_countdowns(delta: float) -> void:
        for game in _countdown_clock.keys():
                var g := String(game)
                var left: float = maxf(0.0, float(_countdown_clock[game]) - delta)
                _countdown_clock[game] = left
                var info: Dictionary = _holds.get(g, {})
                info["t_left"] = left
                _holds[g] = info
                if left <= 0.0:
                        _birth_match(g)
        # hold broadcasts ride a half-second clock while anything is live
        _hold_bc_clock += delta
        if not _countdown_clock.is_empty() and _hold_bc_clock >= 0.5:
                _hold_bc_clock = 0.0
                for game in _countdown_clock.keys():
                        var g2 := String(game)
                        var msg := {"t": "hold", "game": g2, "hold": _holds.get(g2, {})}
                        for dev in _conns:
                                _send_to(_conns[dev], msg)
        # THE LONE LAW tick
        for game in _lone_clock.keys():
                var g := String(game)
                if holders_of(g).size() == 1 and committed_of(g).is_empty():
                        _lone_clock[game] = float(_lone_clock[game]) + delta
                        if float(_lone_clock[game]) >= LONE_GRACE:
                                _lone_clock.erase(game)
                                _holds.erase(g)
                                var holder: Dictionary = holders_of(g)[0]
                                var dev := String(holder.get("dev", ""))
                                if dev == my_dev():
                                        _set_state("lobby")
                                elif _conns.has(dev):
                                        _send_to(_conns[dev], {"t": "solo", "game": g})
                                _broadcast_hold(g)
                                solo_fallthrough.emit(g)
                else:
                        _lone_clock.erase(game)

func _birth_match(game_id: String) -> void:
        _countdown_clock.erase(game_id)
        var committed := committed_of(game_id)
        if committed.size() == 1:
                # the countdown ran and NOBODY joined the committer - the room
                # falls through to the solo fallback (the owner's own law)
                _holds.erase(game_id)
                _lone_clock.erase(game_id)
                for st in seats:
                        if String(st.get("state", "")) == "hold:" + game_id \
                                        or String(st.get("state", "")) == "committed:" + game_id:
                                var dv := String(st.get("dev", ""))
                                if dv == my_dev():
                                        _set_state("lobby")
                                        solo_fallthrough.emit(game_id)
                                elif _conns.has(dv):
                                        _send_to(_conns[dv], {"t": "solo", "game": game_id})
                _broadcast_hold(game_id)
                return
        if committed.size() < 2:
                _refresh_hold(game_id)
                return
        var seed_v := int(Time.get_unix_time_from_system() * 1000.0) & 0x7fffffff
        var match_seats := []
        for s in committed:
                match_seats.append({"dev": String(s["dev"]), "name": String(s["name"]),
                        "pfp": int(s["pfp"]), "role": String(s["role"]),
                        "seat": int(s["seat"]), "local_slot": int(s["local_slot"]),
                        "anchor": String(s.get("anchor", ""))})
                _mark_state(String(s["dev"]), "playing:" + game_id)
        # THE START RIDES THE COMMITTED SEATS ONLY - the holders that never
        # committed get the left_out note instead (never the match)
        var msg := {"t": "start", "game": game_id, "seed": seed_v, "seats": match_seats}
        for s2 in committed:
                var dv2 := String(s2["dev"])
                if _conns.has(dv2):
                        _send_to(_conns[dv2], msg)
        _holds.erase(game_id)
        _lone_clock.erase(game_id)
        # the holders that never committed are LEFT OUT
        for s in seats:
                if String(s.get("state", "")) == "hold:" + game_id:
                        var dev := String(s.get("dev", ""))
                        if dev == my_dev():
                                match_left_out.emit(game_id)
                        elif _conns.has(dev):
                                _send_to(_conns[dev], {"t": "left_out", "game": game_id})
        _broadcast_hold(game_id)
        _on_match_start(game_id, seed_v, match_seats)

func _on_match_start(game_id: String, seed_v: int, match_seats: Array) -> void:
        _match_game = game_id
        if not is_host:
                seats = _clean_seats(match_seats)
                for s in seats:
                        if String(s.get("dev", "")) == my_dev():
                                s["state"] = "playing:" + game_id
        match_started.emit(game_id, seed_v, match_seats)
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
        return {"mode": mode, "seats": seats.duplicate(true), "holds": _holds.duplicate(true),
                "match": _match_game, "port": _port, "addr": host_addr, "code": room_code}

# ============================================== v042-1 THE SESSION EXTRAS
## THE CHAT LAW, THE FACE WIRE, THE REMOVE/KICK, THE PFP TRANSFER.

signal chat_received(msg: Dictionary)          # one chat line landed
signal kicked(why: String)                     # the host removed me
signal invite_arrived(from_name: String, addr: String)   # a scan invite

const CHAT_MAX_MSGS := 100
const CHAT_MAX_BYTES := 10 * 1024 * 1024       # the 10MB ceiling
const CHAT_MSG_MAX := 1000                     # the 1K per-message law
const CHAT_COOLDOWN := 5.0                     # the 5-second cooldown
const PFP_CHUNK := 48000                       # base64 bytes per wire line

var chat_log: Array = []                       # {seat, name, pfpm, text, reply_to, ts}
var chat_bytes := 0
var _chat_last_sent := -60.0
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

## THE REMOVE LAW (the owner: "make in that list, a remove button to
## remove a player"): the host removes anyone; the removed device is
## dropped with a note. A member removing the combo local slot is handled
## by remove_local_slot - this is the HOST's remove.
func kick_member(dev: String) -> bool:
        if not is_host or dev == my_dev():
                return false
        var conn: StreamPeerTCP = _conns.get(dev)
        if conn != null:
                _send_to(conn, {"t": "kick", "why": "the host removed you"})
        _drop_peer(dev)
        return true

## THE CHAT LAW (v042-1): one shared per-session chat, EN-only no-emoji,
## 1K chars, 5s cooldown, 100 messages / 10MB then the earliest slides
## out. NEVER saved - the log dies with the session (it lives HERE, and
## leave_session clears it).
func send_chat(text: String, reply_to := -1) -> String:
        if not session_active():
                return "no session"
        var now := Time.get_unix_time_from_system()
        if now - _chat_last_sent < CHAT_COOLDOWN:
                return "wait %d s" % int(ceilf(CHAT_COOLDOWN - (now - _chat_last_sent)))
        var clean := LanProfile.sanitize_chat(text)
        if clean == "":
                return "nothing to send"
        _chat_last_sent = now
        var msg := {"t": "chat", "seat": my_seat_no(), "name": my_name(),
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

func _chat_land(msg: Dictionary) -> void:
        var m := msg.duplicate()
        m["text"] = LanProfile.sanitize_chat(String(m.get("text", "")))
        var rt := int(m.get("reply_to", -1))
        m["reply_to"] = rt if (rt >= 0 and rt < chat_log.size()) else -1
        m["ts"] = Time.get_unix_time_from_system()   # THE ARRIVAL CLOCK
        chat_log.append(m)
        chat_bytes += m["text"].to_utf8_buffer().size()
        while chat_log.size() > CHAT_MAX_MSGS \
                        or chat_bytes > CHAT_MAX_BYTES:
                var gone: Dictionary = chat_log.pop_front()
                chat_bytes -= String(gone.get("text", "")).to_utf8_buffer().size()
                if chat_log.is_empty():
                        chat_bytes = 0
                        break
        chat_received.emit(m)

func _handle_chat(msg: Dictionary) -> void:
        if is_host:
                # the host relays to everyone else (the TURN law)
                for dev in _conns:
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

## THE FACE WIRE (v042-1): a visitor fetches a member's media face in
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

## ================= the wire routing (v042-1 extension) =================

func _handle_line_ext(msg: Dictionary, who: String) -> bool:
        var t := String(msg.get("t", ""))
        match t:
                "chat":
                        _touch()
                        _handle_chat(msg)
                        return true
                "kick":
                        _touch()
                        _close_all()
                        mode = "idle"
                        is_host = false
                        seats = []
                        _holds = {}
                        _match_game = ""
                        _my_state = "lobby"
                        chat_log = []
                        chat_bytes = 0
                        kicked.emit(String(msg.get("why", "the host removed you")))
                        session_changed.emit()
                        return true
                "pfp_get":
                        _handle_pfp_get(msg, who)
                        return true
                "pfp_data":
                        _handle_pfp_data(msg, who)
                        return true
        return false

# probe marker 2026
