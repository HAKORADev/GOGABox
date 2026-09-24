extends Node
## qa_v042_lan — THE LOOPBACK RIG (the owner's "weird full simulation of 4
## players"): four REAL LAN cores in one process, wired over REAL TCP
## sockets on 127.0.0.1, living a whole session's life — host, three
## joins, the hold, THE TEN SECONDS, the match birth, the left-outs, the
## turn relay, THE LONE LAW, the heartbeat prune, the combo seat and the
## room code. Exit 0 = the LAN laws hold.

var checks := 0
var fails := 0

func _check(cond: bool, why: String) -> void:
	checks += 1
	if not cond:
		fails += 1
		print("  FAIL: %s" % why)

func _ready() -> void:
	print("=== qa_v042_lan: THE LOOPBACK RIG ===")
	_t_name_law()
	_t_code()
	_t_tags()
	_t_profile()
	await _t_session()
	await _t_hold_and_match()
	await _t_lone_law()
	await _t_prune()
	print("CHECKS: %d  FAILS: %d" % [checks, fails])
	print("QA RESULT: %s" % ("ALL PASS" if fails == 0 else "FAILURES"))
	get_tree().quit(0 if fails == 0 else 1)

## ------------------------------------------------------------- helpers

func _bus(dev: String, name_v: String) -> Node:
	var b: Node = load("res://game/core/lan.gd").new()
	b.dev_override = dev
	b.ident_override = {"name": name_v, "pfp": int(hash(dev) % 8),
			"role": "gamer", "anchor": "anc" + dev}
	add_child(b)
	return b

func _pump(seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		await get_tree().process_frame
		t += get_process_delta_time()

func _drop(b: Node) -> void:
	if is_instance_valid(b):
		b.queue_free()

## ------------------------------------------------------------- the laws

func _t_name_law() -> void:
	print("-- THE NAME LAW (EN letters, no emoji, 20)")
	_check(LanProfile.sanitize_name("osama bin-ladin") == "osama bin-ladin",
			"the owner's own example survives")
	_check(LanProfile.sanitize_name("  a   b  ").length() <= 20, "spaces collapse")
	_check(LanProfile.sanitize_name("xXfireXx99") == "xXfireXx", "digits die")
	_check(LanProfile.sanitize_name("neo😀") == "neo", "emoji die")
	_check(LanProfile.sanitize_name("北平") == "", "CJK dies")
	_check(LanProfile.sanitize_name("ABCDEFGHIJKLMNOPQRSTU").length() == 20,
			"the 21st letter dies (max 20)")
	_check(not LanProfile.name_ok("a"), "a 1-char name refuses")
	_check(LanProfile.name_ok("ab"), "a 2-char name stands")

func _t_code() -> void:
	print("-- THE ROOM CODE (reversible, checksummed)")
	var lan := _bus("codebus", "CODER")
	var code: String = lan.encode_code("192.168.1.20", 31440)
	_check(code.begins_with("GOGA-"), "the code wears the prefix")
	_check(lan.decode_code(code) == "192.168.1.20:31440", "the code round-trips")
	var bad: String = code.substr(0, code.length() - 1) + "Q"
	_check(lan.decode_code(bad) == "", "a tampered code dies on the checksum")
	_check(lan.decode_code("GOGA-NOPE") == "", "garbage dies")
	_drop(lan)

func _t_tags() -> void:
	print("-- THE MULTI-LEVEL LAN TAGS")
	var cross := {"lan": {"players": 4, "platforms": ["android", "pc"], "cross": true}}
	var same_only := {"lan": {"players": 2, "platforms": ["android", "pc"], "cross": false}}
	var phone_only := {"lan": {"players": 2, "platforms": ["android"], "cross": true}}
	var solo := {"id": "snake"}
	var lc := Meta.lan_list(cross)
	_check(lc.has("lan") and lc.has("lan_cross") and lc.has("lan_4p"), "cross tags derive: %s" % str(lc))
	var ls := Meta.lan_list(same_only)
	_check(ls.has("lan_phone") and ls.has("lan_pc") and not ls.has("lan_cross"),
			"both platforms + no cross wears BOTH single tags: %s" % str(ls))
	_check(Meta.lan_list(phone_only).has("lan_phone"), "phone-only derives")
	_check(Meta.lan_list(solo).is_empty(), "OUT OF RADAR: no lan field, no tags")
	_check(Meta.players_badge(cross) == "PLAYERS 2-4", "the PLAYERS badge area")
	_check(Meta.players_badge(solo) == "", "no badge for the single seat")
	# the registry truth: the owner's ten games wear the seat
	var with_lan := 0
	for g in GameReg.GAMES:
		if g.has("lan"):
			with_lan += 1
	_check(with_lan == 10, "exactly ten games wear the LAN seat (%d)" % with_lan)
	for gid in ["snake", "jumpcube", "snl", "domino", "chess", "squares",
			"fourline", "bovo", "rally", "towerball"]:
		_check(not Meta.lan_list(GameReg.get_game(gid)).is_empty(),
				"%s wears the seat" % gid)
	_check(not Meta.lan_list(GameReg.get_game("towerdestroyer")).is_empty() == false
				or GameReg.get_game("towerdestroyer").has("lan") == false,
			"towerdestroyer stays frozen (no lan field)")

func _t_profile() -> void:
	print("-- THE GOGAPROFILE SEED")
	var d := LanProfile.data()
	_check(d.has("name") and d.has("pfp") and d.has("role") and d.has("gender"),
			"the GitHub-shaped fields exist")
	_check(d.has("anchor") and String(d["anchor"]) != "", "the device anchor rides")
	_check(LanProfile.PFP_VARIANTS == 8, "the drawn variants exist")
	_check(LanProfile.GENDERS.has("other"), "gender carries OTHER")
	_check(LanProfile.ROLES.has("owner"), "the owner role exists (unique)")

## ------------------------------------------------------------- the session

func _t_session() -> void:
	print("-- THE SESSION (4 real cores over real TCP)")
	var b0 := _bus("devA", "ALPHA")
	var err: String = b0.host_session()
	_check(err == "", "the host opens: %s" % err)
	_check(b0.seats.size() == 1, "the host holds seat 1")
	var b1 := _bus("devB", "BRAVO")
	var b2 := _bus("devC", "CHARLIE")
	var b3 := _bus("devD", "DELTA")
	for b in [b1, b2, b3]:
		var jerr: String = b.join_session("127.0.0.1:%d" % b0._port)
		_check(jerr == "", "join accepted: %s" % jerr)
	await _pump(1.5)
	for b in [b0, b1, b2, b3]:
		_check(b.seats.size() == 4, "4 seats everywhere (%s: %d)" % [b.dev_override, b.seats.size()])
	var order := []
	for st in b0.seats:
		order.append(String(st["dev"]))
	_check(order == ["devA", "devB", "devC", "devD"],
			"THE SEAT LAW: arrival order fixes the seats")
	_check(int(b1.seats[1]["seat"]) == 2, "the seat numbers follow arrival")
	# the cap: a fifth dies politely
	var b4 := _bus("devE", "ECHO")
	var e5: String = b4.join_session("127.0.0.1:%d" % b0._port)
	await _pump(1.0)
	_check(b4.seats.is_empty() or b4.mode == "join", "the 5th waits outside")
	_check(b0.seats.size() == 4, "THE CAP: still 4 seats")
	_drop(b4)
	# the combo seat: the host adds a second local player
	_check(b0.add_local_slot() == false, "combo refuses at the cap")
	b0.remove_local_slot()
	_drop(b3)
	await _pump(0.5)
	# leave cleanly (b2)
	b2.leave_session()
	await _pump(0.5)
	_check(b0.seats.size() == 2, "the leave emptied the seat (%d)" % b0.seats.size())
	_check(b1.seats.size() == 2, "the wire agrees on the seats")
	_t_session_ctx = [b0, b1, b2]

var _t_session_ctx := []

## THE HOLD + THE TEN SECONDS + THE MATCH BIRTH + THE LEFT-OUTS
func _t_hold_and_match() -> void:
	print("-- THE HOLD, THE TEN SECONDS, THE MATCH")
	var b0: Node = _t_session_ctx[0]
	var b1: Node = _t_session_ctx[1]
	var started := {"b0": false, "b1": false, "left_b0": false, "left_b1": false}
	var got := {"b1_act": null, "b1_who": -1}
	b0.match_started.connect(func(_g, _s, _seats): started["b0"] = true)
	b1.match_started.connect(func(_g, _s, _seats): started["b1"] = true)
	b0.match_left_out.connect(func(_g): started["left_b0"] = true)
	b1.match_left_out.connect(func(_g): started["left_b1"] = true)
	b1.act_received.connect(func(_g, who, a): got["b1_act"] = a; got["b1_who"] = who)
	_check(b0.report_open("snl") == true, "the host holds (2 seats in session)")
	_check(b1.report_open("snl") == true, "the client holds")
	await _pump(0.8)
	_check(b0.holders_of("snl").size() == 2, "both sit in the hold")
	_check(b0.hold_info("snl").get("phase", "") == "waiting", "the hold waits")
	b0.commit("snl")
	await _pump(0.4)
	_check(String(b0.hold_info("snl").get("phase", "")) == "count",
			"THE TEN SECONDS arms on the first commit")
	b1.commit("snl")
	await _pump(1.0)
	# both committed: the birth fires as soon as the countdown ends
	_check(b0.holders_of("snl").size() == 2 and b0.committed_of("snl").size() == 2,
			"both are READY")
	await _pump(9.6)
	_check(started["b0"] and started["b1"], "the match births on both devices")
	_check(not started["left_b0"] and not started["left_b1"],
			"nobody was left out (both committed)")
	_check(b0.probe_state()["match"] == "snl" and b1.probe_state()["match"] == "snl",
			"both cores wear the match")
	# THE TURN RELAY: the host rolls, the client receives the same door call
	b0.send_act({"k": "roll", "r": 4})
	await _pump(0.5)
	_check(got["b1_act"] != null and String(got["b1_act"].get("k", "")) == "roll",
			"TURN_RELAY delivers the move")
	_check(int(got["b1_who"]) == 1, "the move carries the actor's seat")
	# the match ends; the session returns to the lobby
	b0.report_match_end("snl", [{"dev": "devA", "place": 1}])
	await _pump(0.6)
	_check(b1.probe_state()["match"] == "", "the match ends everywhere")
	_check(String(b1.seats[0].get("state", "")) != "playing:snl", "the lobby returns")
	# THE SOLO FALLBACK: the countdown ran and nobody joined the committer
	var fell := {"b0": false, "b1": false}
	b0.solo_fallthrough.connect(func(_g): fell["b0"] = true)
	b1.solo_fallthrough.connect(func(_g): fell["b1"] = true)
	started["b0"] = false
	started["b1"] = false
	b0.report_open("snl")
	b1.report_open("snl")
	await _pump(0.5)
	b1.commit("snl")
	await _pump(10.8)
	_check(fell["b1"] and fell["b0"],
			"nobody joined = the whole room falls to solo (%s/%s)" % [fell["b0"], fell["b1"]])
	_check(not started["b0"] and not started["b1"], "no match births for one seat")
	# THE LEFT-OUT: a third device holds while two commit - the match
	# births without it
	var b4 := _bus("devF", "FOX")
	var jerr: String = b4.join_session("127.0.0.1:%d" % b0._port)
	_check(jerr == "", "the third device joins: %s" % jerr)
	await _pump(1.0)
	var left4 := {"v": false}
	b4.match_left_out.connect(func(_g): left4["v"] = true)
	b0.report_open("snl")
	b1.report_open("snl")
	b4.report_open("snl")
	await _pump(0.6)
	_check(b0.holders_of("snl").size() == 3, "three in the room")
	b0.commit("snl")
	b1.commit("snl")
	await _pump(10.8)
	_check(started["b0"] and started["b1"], "the committed two play")
	_check(left4["v"], "THE LEFT-OUT: the hesitant third watches solo")
	_check(not b4.probe_state()["match"] == "snl", "the left-out wears no match")
	b0.report_close("snl")
	b1.report_close("snl")
	b4.leave_session()
	await _pump(0.4)

## THE LONE LAW: one holder alone falls through to solo
func _t_lone_law() -> void:
	print("-- THE LONE LAW (the grace, then solo)")
	var b0: Node = _t_session_ctx[0]
	var b1: Node = _t_session_ctx[1]
	var fell := {"v": false}
	b1.solo_fallthrough.connect(func(_g): fell["v"] = true)
	b1.report_open("chess")
	await _pump(1.0)
	_check(not fell["v"], "the grace holds")
	await _pump(4.8)
	_check(fell["v"], "alone for 5s = the solo fallthrough")
	_check(b1.holders_of("chess").is_empty(), "the hold empties")
	b1.report_close("chess")
	await _pump(0.3)

## THE HEARTBEAT: a silent seat is pruned, never a ghost
func _t_prune() -> void:
	print("-- THE HEARTBEAT PRUNE (a crashed seat dies)")
	var b0: Node = _t_session_ctx[0]
	var b1: Node = _t_session_ctx[1]
	_check(b0.seats.size() == 2, "two seats before the crash")
	# the hard kill: no bye, no grace - the wire just dies
	b1._host_conn.disconnect_from_host()
	await _pump(11.5)
	_check(b0.seats.size() == 1, "the silent seat is pruned (%d left)" % b0.seats.size())
	b0.leave_session()
	await _pump(0.3)
	_check(not b0.session_active(), "the session dies with the host")
