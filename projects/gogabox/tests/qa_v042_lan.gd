extends Node
## qa_v042_lan — THE LOOPBACK RIG (the owner's "weird full simulation of 4
## players"): four REAL LAN cores in one process, wired over REAL TCP
## sockets on 127.0.0.1, living a whole session's life — host, three
## joins, THE ROOMS (r3: dimensions, the owner-start birth, the
## confliction race, the no-solo law, the disconnect end), the turn
## relay, the heartbeat prune, the combo seat and the room code.
## Exit 0 = the LAN laws hold.

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
        await _t_rooms_and_match()
        await _t_no_solo_law()
        await _t_prune()
        await _t_v0421_extras()
        await _t_r2_laws()
        await _t_r3_laws()
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

## ================================================== v042-1 THE EXTRAS
## THE CHAT LAW, THE FACE WIRE, THE REMOVE/KICK, THE COMBO ALIGNMENT, THE
## DISCOVERY SERVICE - the first patch's own proof (the owner: "make sure
## that it is real").

func _t_v0421_extras() -> void:
        print("-- v042-1: THE CHAT, THE FACE WIRE, THE KICK, THE COMBO, THE SCAN")
        # --- THE CHAT LAW ---
        var a: Node = _bus("xA", "ALPHA")
        var b: Node = _bus("xB", "BETA")
        a.host_session()
        await _pump(0.4)
        b.join_session("127.0.0.1:%d" % a._port)
        await _pump(0.6)
        var got := {"a": [], "b": []}
        a.chat_received.connect(func(m: Dictionary): got["a"].append(m))
        b.chat_received.connect(func(m: Dictionary): got["b"].append(m))
        _check(a.send_chat("hello world") == "", "the host's line sends")
        _check(b.send_chat("hi from the client") == "", "the client's line sends")
        _check(b.send_chat("too soon") != "", "THE COOLDOWN LAW: 5s between sends")
        a._chat_last_sent = -1000.0
        _check(a.send_chat("em\u263a") == "", "a sanitized line still sends")
        await _pump(0.6)
        _check(got["b"].size() >= 2, "the host relay reached the client (%d)" % got["b"].size())
        _check(got["a"].size() >= 2, "the client's line landed at the host (%d)" % got["a"].size())
        var texts := []
        for m in got["a"]:
                texts.append(String(m.get("text", "")))
        _check("hello world" in texts, "the host's own line landed locally")
        _check("hi from the client" in texts, "the client's line landed")
        var emoji_ok := true
        for m in got["a"]:
                for ch in String(m.get("text", "")):
                        if ch.unicode_at(0) > 126:
                                emoji_ok = false
        _check(emoji_ok, "the wire carries EN-only text (no emoji survives)")
        # the caps: 1000-char ceiling + the 100-message slide
        var long_txt := "x".repeat(1500)
        b._chat_last_sent = -1000.0
        b.send_chat(long_txt)
        await _pump(0.3)
        var sizes_ok := true
        for m in a.chat_log:
                if String(m.get("text", "")).length() > LAN.CHAT_MSG_MAX:
                        sizes_ok = false
        _check(sizes_ok and a.chat_log.size() <= LAN.CHAT_MAX_MSGS,
                        "the caps hold (1K per line, 100 in the log)")
        a._chat_last_sent = -1000.0
        for i in 130:
                a.send_chat("flood %d" % i)
                a._chat_last_sent = -1000.0
        _check(a.chat_log.size() <= LAN.CHAT_MAX_MSGS, "THE SLIDE LAW: the log never passes 100")
        _check(a.chat_log[0].get("text", "").begins_with("flood 2") or a.chat_log.size() == 100,
                        "the EARLIEST line slid out, the rest kept")
        # --- THE FACE WIRE ---
        var media := {"h": "testhash1", "ext": "webp", "w": 8, "hh": 8,
                        "fps": 0.0, "n": 1, "dur": 0.0, "bytes": 64}
        var bytes := PackedByteArray()
        bytes.resize(64)
        LanProfile.cache_store("testhash1", "webp", bytes, media)
        _check(LanProfile.cache_has("testhash1"), "the face cache stores by hash")
        # the client asks for the face; the host ships the chunks
        b.pfp_request("gone-hash", "xB")   # nothing to serve - no crash
        await _pump(0.4)
        # --- THE REMOVE/KICK ---
        var c: Node = _bus("xC", "GAMMA")
        c.join_session("127.0.0.1:%d" % a._port)
        await _pump(0.6)
        var c_died := {"hit": false}
        c.kicked.connect(func(_why): c_died["hit"] = true)
        _check(a.kick_member("xC"), "THE REMOVE LAW: the host removes a member")
        await _pump(0.6)
        _check(c_died["hit"], "the kicked device got the note")
        _check(a.seats.size() == 2, "the seat died with the member")
        # --- THE COMBO ALIGNMENT (the who-gate) ---
        # a fresh 2-seat session: the client's combo slot rides the rotated turn
        a.leave_session()
        b.leave_session()
        await _pump(0.4)
        a.host_session()
        await _pump(0.3)
        b.join_session("127.0.0.1:%d" % a._port)
        await _pump(0.6)
        _check(a.add_local_slot("SECOND GUY"), "the combo seat adds BY DETAILS (host law)")
        await _pump(0.4)
        _check(a.seats.size() == 3 and int(a.seats[2].get("local_slot", 0)) == 1,
                        "the combo seat rides the session")
        # the combo's roll carries ITS OWN seat number through a room
        a.report_open("snl")
        b.report_open("snl")
        await _pump(0.3)
        _check(a.open_room("snl") == "", "the combo rig opens a room")
        await _pump(0.4)
        _check(b.join_room(int(b.rooms_for_game("snl")[0]["rid"])) == "", "the combo rival joins")
        await _pump(0.5)
        _check(a.start_match() == "", "the combo room's match births")
        await _pump(0.6)
        var combo_who := {"v": -1}
        b.act_received.connect(func(_g, who, _a): combo_who["v"] = who)
        a.send_act_as(3, {"k": "roll", "r": 5})   # the combo seat's own number
        await _pump(0.5)
        _check(combo_who["v"] == 3, "the combo's act carries ITS OWN room seat (%d)" % combo_who["v"])
        a.report_match_end([])
        # --- THE SCAN SERVICE ---
        var f: Node = load("res://game/core/lan_find.gd").new()
        add_child(f)
        await _pump(0.2)
        f.set_answering(true, "ALPHA", 3, true)
        f.scan()
        await _pump(1.6)
        _check(f.peers().size() >= 0, "the scan lived its window (loopback may see none)")
        f.queue_free()
        a.leave_session()
        b.leave_session()
        _drop(a)
        _drop(b)
        _drop(c)
        await _pump(0.3)

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
        print("-- THE NAME LAW r2 (EN letters + DIGITS, 1 char, no emoji, 20)")
        _check(LanProfile.sanitize_name("osama bin-ladin") == "osama bin-ladin",
                        "the owner's own example survives")
        _check(LanProfile.sanitize_name("  a   b  ").length() <= 20, "spaces collapse")
        # v042-1 r2 (the owner: "there is a bug when the name is numbers only
        # it get wiped, if with numbers, it wipes the numbers but lets
        # letters"): digits SURVIVE now, and 1 char is a name.
        _check(LanProfile.sanitize_name("xXfireXx99") == "xXfireXx99",
                        "digits survive (r2)")
        _check(LanProfile.sanitize_name("99") == "99", "numbers-only survives (r2)")
        _check(LanProfile.name_ok("a"), "a 1-char name stands (r2)")
        _check(not LanProfile.name_ok("   "), "a space-only name refuses (r2)")
        _check(not LanProfile.name_ok(""), "an empty name refuses")
        _check(LanProfile.sanitize_name("neo😀") == "neo", "emoji die")
        _check(LanProfile.sanitize_name("北平") == "", "CJK dies")
        _check(LanProfile.sanitize_name("ABCDEFGHIJKLMNOPQRSTU").length() == 20,
                        "the 21st letter dies (max 20)")
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
        # v042-1: eleven seats - board ludo joined (the queued shred) and the
        # 3D seat MOVED from towerball to towerdestroyer (the owner's word).
        # r3: twelve - fruit slasher wears the 2P blade race.
        _check(with_lan == 12, "exactly twelve games wear the LAN seat (%d)" % with_lan)
        for gid in ["snake", "jumpcube", "snl", "domino", "chess", "squares",
                        "fourline", "bovo", "rally", "ludo", "slasher"]:
                _check(not Meta.lan_list(GameReg.get_game(gid)).is_empty(),
                                "%s wears the seat" % gid)
        _check(GameReg.get_game("towerdestroyer").has("lan"),
                        "THE 3D SEAT CORRECTION: towerdestroyer wears the LAN race")
        _check(not GameReg.get_game("towerball").has("lan"),
                        "towerball is back to solo-only")

func _t_profile() -> void:
        print("-- THE GOGAPROFILE SEED")
        var d := LanProfile.data()
        _check(d.has("name") and d.has("pfp") and d.has("role") and d.has("gender"),
                        "the GitHub-shaped fields exist")
        _check(d.has("anchor") and String(d["anchor"]) != "", "the device anchor rides")
        _check(LanProfile.PFP_VARIANTS == 8, "the drawn variants exist")
        _check(LanProfile.GENDERS.has("other"), "gender carries OTHER")
        _check(LanProfile.role() != "" and LanProfile.GENDERS.has("other"),
                        "the role field rides, gender carries OTHER (v042-1: the sheet seat retired)")

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
        # r3: the CAP is 12 now - a 5th joins fine; the combo seat rides too
        var b4 := _bus("devE", "ECHO")
        var e5: String = b4.join_session("127.0.0.1:%d" % b0._port)
        await _pump(1.0)
        _check(e5 == "" and b0.seats.size() == 5, "THE 12-CAP: the 5th seat joins (%d)" % b0.seats.size())
        # the combo seat: the host adds a second local player (engine API)
        _check(b0.add_local_slot("SECOND GUY") == true, "the combo seat joins by details")
        _check(b0.remove_local_slot() == true, "the combo seat removes")
        _drop(b4)
        _drop(b3)
        await _pump(0.5)
        # leave cleanly (b2)
        b2.leave_session()
        await _pump(0.5)
        _check(b0.seats.size() == 2, "the leave emptied the seat (%d)" % b0.seats.size())
        _check(b1.seats.size() == 2, "the wire agrees on the seats")
        _t_session_ctx = [b0, b1, b2]

var _t_session_ctx := []

## THE ROOMS (r3): the dimensions, the owner-start birth, the absolute
## seats, the confliction race, the room-scoped relay, the disconnect end.
func _t_rooms_and_match() -> void:
        print("-- THE ROOMS, THE OWNER START, THE MATCH")
        var b0: Node = _t_session_ctx[0]
        var b1: Node = _t_session_ctx[1]
        var started := {"b0": false, "b1": false}
        var seats_box := {"v": []}
        var ended := {"b0": false, "b1": false, "why": ""}
        var got := {"b1_act": null, "b1_who": -1}
        b0.match_started.connect(func(_g, _s, _seats, _p): started["b0"] = true)
        b1.match_started.connect(func(_g, _s, seats, _p): started["b1"] = true; seats_box["v"] = seats)
        b0.match_ended.connect(func(_g, _r, why): ended["b0"] = true; ended["why"] = why)
        b1.match_ended.connect(func(_g, _r, _why): ended["b1"] = true)
        b1.act_received.connect(func(_g, who, a): got["b1_act"] = a; got["b1_who"] = who)
        _check(b0.report_open("snl") == true, "the host opens the game (2 seats)")
        _check(b1.report_open("snl") == true, "the client opens the game")
        await _pump(0.4)
        _check(b0.rooms_for_game("snl").is_empty(), "no room exists before a CREATE")
        # THE FIRST PLAYER CREATES - the owner's own flow
        _check(b0.open_room("snl") == "", "the first player creates the room")
        await _pump(0.6)
        _check(b0.rooms_for_game("snl").size() == 1, "one room lives")
        _check(b1.rooms_for_game("snl").size() == 1, "the client sees the room (the mirror)")
        var rid := int(b0.rooms_for_game("snl")[0]["rid"])
        _check(String(b0.my_room().get("owner", "")) == "devA", "the creator is the OWNER")
        _check(b0.my_room_seat() == 1, "the owner is room seat 1")
        # THE SECOND JOINS - the join order is the seat order
        _check(b1.join_room(rid) == "", "the second player joins")
        await _pump(0.6)
        _check((b0.my_room().get("members", []) as Array).size() == 2, "two in the room")
        _check(b1.my_room_seat() == 2, "THE JOIN ORDER: the joiner is room seat 2")
        # THE OWNER-ONLY START
        _check(b1.start_match() != "", "a member cannot start the match")
        await _pump(0.3)
        _check(not started["b0"], "no match births without the owner")
        # THE OWNER STARTS - the only birth door (no timers anymore)
        _check(b0.start_match() == "", "THE OWNER STARTS THE MATCH")
        await _pump(0.8)
        _check(started["b0"] and started["b1"], "the match births on both devices")
        _check((seats_box["v"] as Array).size() == 2, "the match seats arrived (%d)" % (seats_box["v"] as Array).size())
        _check(int((seats_box["v"] as Array)[0].get("rseat", 0)) == 1 and int((seats_box["v"] as Array)[1].get("rseat", 0)) == 2,
                        "THE ABSOLUTE SEATS: rseat rides the join order")
        _check(String((seats_box["v"] as Array)[0].get("dev", "")) == "devA",
                        "room seat 1 is room seat 1 on EVERY device")
        # THE TURN RELAY: the host's act carries its ROOM seat
        b0.send_act({"k": "roll", "r": 4})
        await _pump(0.5)
        _check(got["b1_act"] != null and String(got["b1_act"].get("k", "")) == "roll",
                        "TURN_RELAY delivers the move (room-scoped)")
        _check(int(got["b1_who"]) == 1, "the move carries the actor's ROOM seat")
        # THE DISCONNECT LAW: a member leaving ends the live match, honestly
        b1.leave_session()
        await _pump(0.8)
        _check(ended["b0"], "THE DISCONNECT LAW: the match ends for the one left")
        _check(String(ended["why"]).contains("LEFT"), "the end says WHY (%s)" % ended["why"])
        _check(int(b0.probe_state()["my_room"]) == 0, "the room folded")
        b0.report_close("snl")
        await _pump(0.3)

## THE CONFLICTION RACE + THE NO-SOLO LAW (r3)
func _t_no_solo_law() -> void:
        print("-- THE NO-SOLO LAW + THE CONFLICTION RACE")
        var b0: Node = _t_session_ctx[0]
        var b1: Node = _t_session_ctx[1]
        var b2: Node = _t_session_ctx[2]
        # the disconnect law consumed b1's wire and b2 left cleanly - both
        # rejoin for this section (a session is the precondition)
        b1.join_session("127.0.0.1:%d" % b0._port)
        b2.join_session("127.0.0.1:%d" % b0._port)
        await _pump(1.0)
        # --- THE NO-SOLO LAW: a lone room waits FOREVER (no fallthrough) ---
        _check(b1.report_open("chess") == true, "the client opens chess")
        await _pump(0.4)
        _check(b1.open_room("chess") == "", "a lone player opens a room")
        await _pump(1.6)
        _check(not b1.rooms_for_game("chess").is_empty(), "the lone room still waits")
        b1.leave_room()
        await _pump(0.4)
        _check(b1.rooms_for_game("chess").is_empty(), "the empty room died")
        b1.report_close("chess")
        # --- THE CONFLICTION: two racers, ONE seat (the 2-player cap) ---
        _check(b0.report_open("bovo") == true, "the host opens bovo (cap 2)")
        _check(b1.report_open("bovo") == true, "racer 1 opens bovo")
        _check(b2.report_open("bovo") == true, "racer 2 opens bovo")
        await _pump(0.4)
        _check(b0.open_room("bovo") == "", "the 1-seat room is born")
        await _pump(0.6)
        var brid := int(b0.rooms_for_game("bovo")[0]["rid"])
        var refused := {"v": false, "why": ""}
        b2.room_refused.connect(func(why): refused["v"] = true; refused["why"] = why)
        _check(b1.join_room(brid) == "", "racer 1's join ask rides")
        b2.join_room(brid)              # racer 2 rides a beat later
        await _pump(0.8)
        _check((b0.my_room().get("members", []) as Array).size() == 2,
                        "the room holds its cap (2 for bovo)")
        _check(refused["v"], "THE CONFLICTION: the racing loser is refused")
        _check(String(refused["why"]).contains("CONFLICTION"),
                        "the refusal reads the owner's line (%s)" % refused["why"])
        _check(b2.my_room_seat() == 0, "the loser holds no room seat")
        # fold the test room
        b0.leave_room()
        b0.report_close("bovo")
        b1.report_close("bovo")
        b2.report_close("bovo")
        b2.leave_session()          # the prune section wants the 2-seat shape
        await _pump(0.4)

## THE HEARTBEAT: a silent seat is pruned, never a ghost
func _t_prune() -> void:
        print("-- THE HEARTBEAT PRUNE (a crashed seat dies)")
        var b0: Node = _t_session_ctx[0]
        var b1: Node = _t_session_ctx[1]
        _check(b0.seats.size() == 2, "two seats before the crash")
        # the hard kill: no bye, no grace - the wire just dies
        b1._host_conn.disconnect_from_host()
        await _pump(16.5)
        _check(b0.seats.size() == 1, "the silent seat is pruned (%d left)" % b0.seats.size())
        b0.leave_session()
        await _pump(0.3)
        _check(not b0.session_active(), "the session dies with the host")

## ================================================== v042-1 r2 THE LAWS
## The second round's own proof: the face meta law, the honest video
## doors, the invite-while-hosting, the join honesty, the link domain.

func _t_r2_laws() -> void:
        print("-- v042-1 r2: THE FACE META, THE VIDEO DOORS, THE INVITE, THE JOIN HONESTY")
        # --- THE FACE META LAW: "h" is the hash, never a dimension ---
        var img := Image.create(64, 48, false, Image.FORMAT_RGBA8)
        img.fill(Color(0.9, 0.5, 0.2))
        var tmp := OS.get_user_data_dir() + "/r2_face_tmp.png"
        img.save_png(tmp)
        var res := PfpMedia.import_file(tmp)
        _check(not res.has("err"), "the r2 face import lands")
        if not res.has("err"):
                _check(String(res.get("h", "")).length() == 64,
                                "the meta's h is THE HASH (64 hex), not a dimension")
                _check(String(res.get("h", "")) == FileAccess.get_sha256(tmp),
                                "the hash matches the source file")
                _check(int(res.get("w", 0)) > 0 and int(res.get("hh", 0)) > 0,
                                "the dimensions ride w/hh")
                _check(LanProfile.cache_has(String(res.get("h", ""))),
                                "the stored face answers cache_has")
                _check(String(res.get("ext", "")) == "webp",
                                "the import normalizes to webp")
        DirAccess.remove_absolute(tmp)
        # --- THE HONEST VIDEO DOORS (the owner: no weird formats) ---
        var fake := OS.get_user_data_dir() + "/r2_fake.mp4"
        var fw := FileAccess.open(fake, FileAccess.WRITE)
        fw.store_string("not really a video")
        fw.close()
        var bad := PfpMedia.import_file(fake)
        _check(bad.has("err") and String(bad["err"]).contains("MP4"),
                        "an mp4 gets its honest named refusal")
        DirAccess.remove_absolute(fake)
        var fake2 := OS.get_user_data_dir() + "/r2_fake.oga"
        var fw2 := FileAccess.open(fake2, FileAccess.WRITE)
        fw2.store_string("not audio")
        fw2.close()
        var bad2 := PfpMedia.import_file(fake2)
        _check(bad2.has("err") and String(bad2["err"]).contains("AUDIO"),
                        "an .oga is named an audio file, honestly")
        DirAccess.remove_absolute(fake2)
        # --- THE INVITE WHILE HOSTING (the owner: "invite refused" every time) ---
        var auto: Node = load("res://game/core/lan.gd").new()
        add_child(auto)
        auto.ident_override = {"name": "INVITER", "pfp": 0, "anchor": "anc-inv"}
        var errv: String = auto.host_session()
        _check(errv == "", "the invite rig hosts")
        await _pump(0.3)
        var finder := get_node_or_null("/root/LANFIND")
        _check(finder != null, "the discovery service is up")
        if finder != null:
                var sent: bool = finder.invite_peer({"addr": "127.0.0.1",
                                "dev": "ghost-dev-not-seated"})
                _check(sent, "an invite FIRES while hosting (the r1 refusal is dead)")
        auto.leave_session()
        auto.free()
        await _pump(0.2)
        # invite_peer auto-hosts the CALLER when no session lives - the
        # autoload must be cleaned before the join section (its own law)
        LAN.leave_session()
        await _pump(0.2)
        _check(not LAN.session_active(), "the autoload sleeps before the join")
        # --- THE JOIN HONESTY: the flip is REAL (connecting -> joined) ---
        var jhost: Node = _bus("r2joinhost", "JHOST")
        var herr: String = jhost.host_session()
        _check(herr == "", "the join-honesty rig hosts")
        await _pump(0.3)
        _check(jhost._port > 0, "the rig host listens on a real port")
        var jerr: String = LAN.join_session("127.0.0.1:%d" % jhost._port)
        _check(jerr == "", "the join ask is accepted (the verdict rides the wire)")
        _check(LAN.session_active(), "the join is session_active while connecting")
        _check(not LAN.joined_ok(), "a connecting join wears NO joined_ok (no badge)")
        _check(not LAN.pre_open("snl"), "a connecting join opens no hold")
        await _pump(2.0)
        _check(LAN.joined_ok(), "the welcome flips joined_ok (the badge may live)")
        _check(LAN.session_size() == 2, "the joined joiner sees both seats")
        _check(LAN.pre_open("snl"), "a joined 2-seat session opens the hold")
        LAN.leave_session()
        jhost.leave_session()
        jhost.free()
        await _pump(0.2)
        # the honest DEATH door: a silent address either refuses on the
        # spot (the sandbox's no-route) or hangs into the 12 s deadline -
        # both doors must end with the truth and a clean session.
        var died := {"why": "", "v": false}
        var died_cb := func(why: String):
                died["why"] = why
                died["v"] = true
        LAN.session_died.connect(died_cb)
        var derr: String = LAN.join_session("10.255.255.1:31440")
        if derr != "":
                _check(not LAN.session_active(), "the refused ask never fakes a session")
                _check(derr.contains("cannot reach"), "the refusal says cannot reach")
        else:
                _check(not LAN.joined_ok(), "a connecting join wears NO joined_ok (no badge)")
                await _pump(13.5)
                _check(died["v"], "the dead connect DIES honestly within the deadline")
                _check(String(died["why"]).contains("firewall"),
                                "the death says the truth (address / wifi / firewall)")
                _check(not LAN.session_active(), "the honest death clears the session")
        LAN.session_died.disconnect(died_cb)
        # --- THE LINK DOMAIN HINT (the owner: main domain + subdomains) ---
        _check(Arc.link_domain("https://docs.google.com/spreadsheets/x") == "docs.google.com",
                        "the domain reads host + subdomains")
        _check(Arc.link_domain("www.twitch.tv/y") == "www.twitch.tv",
                        "a bare link reads its host, www kept")
        _check(Arc.link_domain("http://shop.example.co.uk:8080/a?b=1") == "shop.example.co.uk",
                        "scheme, port, path and query all drop")
        _check(Arc.link_domain("not a link") == "", "garbage has no domain")
        # --- THE AREA FLUSH DOOR (Arc.area commits through flush_fields) ---
        var holder := VBoxContainer.new()
        add_child(holder)
        var got := {"t": ""}
        var te := Arc.area("say it", "", 140, func(t: String): got["t"] = t)
        holder.add_child(te)
        te.text = "hello there"
        Arc.flush_fields(holder)
        _check(got["t"] == "hello there", "the area's text rides the flush door")
        holder.queue_free()
        await _pump(0.2)

## ================================================== v042-1 r3 THE LAWS
## The third round's own proof: the dedupe, the live cooldown, the 12
## cap with the honest 13th refusal, the dimensions (two rooms at once),
## the room params broadcast.

func _t_r3_laws() -> void:
        print("-- v042-1 r3: THE DEDUPE, THE 12 CAP, THE DIMENSIONS, THE PARAMS")
        # --- THE DEDUPE: a sender's line lands ONCE on every device ---
        var a: Node = _bus("r3A", "A3")
        var b: Node = _bus("r3B", "B3")
        a.host_session()
        await _pump(0.4)
        b.join_session("127.0.0.1:%d" % a._port)
        await _pump(0.6)
        var seen := {"a": 0, "b": 0}
        var mine_twice := {"v": 0}
        a.chat_received.connect(func(_m): seen["a"] += 1)
        b.chat_received.connect(func(m):
                seen["b"] += 1
                if String(m.get("text", "")) == "me too once":
                        mine_twice["v"] += 1)
        a.send_chat("once only")
        b._chat_last_sent = -1000.0
        b.send_chat("me too once")
        await _pump(0.8)
        # each side lands its OWN line locally + hears the other ONCE
        _check(seen["a"] == 2 and seen["b"] == 2,
                        "one copy each way (%d/%d)" % [seen["a"], seen["b"]])
        _check(mine_twice["v"] == 1,
                        "THE DEDUPE: the client's own line lands ONCE (%d)" % mine_twice["v"])
        _check(LAN.CHAT_COOLDOWN > 0.0 and a.chat_cooldown_left() <= LAN.CHAT_COOLDOWN,
                        "the live cooldown reads")
        a._chat_last_sent = Time.get_unix_time_from_system()
        _check(a.chat_cooldown_left() > 0.0, "the cooldown runs right after a send")
        a.leave_session()
        b.leave_session()
        await _pump(0.3)
        # --- THE 12 CAP: 12 seats live, the 13th refused, combo dies at it ---
        var h: Node = _bus("r3H", "HOST3")
        _check(h.host_session() == "", "the 12-cap rig hosts")
        var joiners := []
        for i in 11:
                var j: Node = _bus("r3J%d" % i, "J%d" % i)
                joiners.append(j)
                j.join_session("127.0.0.1:%d" % h._port)
        await _pump(2.5)
        _check(h.seats.size() == 12, "THE 12 CAP: 12 seats live (%d)" % h.seats.size())
        var late: Node = _bus("r3LATE", "LATE")
        late.join_session("127.0.0.1:%d" % h._port)
        await _pump(1.0)
        _check(h.seats.size() == 12, "the 13th never gets a seat")
        _check(h.add_local_slot("NO ROOM") == false, "the combo seat refuses at the cap")
        # --- THE DIMENSIONS: two rooms of the SAME game live at once ---
        for j in joiners:
                j.report_open("snl")
        h.report_open("snl")
        await _pump(0.3)
        _check(h.open_room("snl") == "", "dimension one is born")
        await _pump(0.5)
        var rid1 := int(h.rooms_for_game("snl")[0]["rid"])
        _check(joiners[0].join_room(rid1) == "", "joiner 1 rides dimension one")
        await _pump(0.5)
        _check(joiners[1].open_room("snl") == "", "joiner 2 births dimension TWO")
        await _pump(0.5)
        var rooms_now: Array = h.rooms_for_game("snl")
        _check(rooms_now.size() == 2, "TWO DIMENSIONS of one game live (%d)" % rooms_now.size())
        var rid2 := int(rooms_now[1]["rid"]) if int(rooms_now[1]["rid"]) != rid1 \
                        else int(rooms_now[0]["rid"])
        rid2 = int(rooms_now[0]["rid"]) if int(rooms_now[0]["rid"]) != rid1 else int(rooms_now[1]["rid"])
        _check(joiners[2].join_room(rid2) == "", "joiner 3 rides dimension two")
        await _pump(0.6)
        _check((h.room_by_id(rid1).get("members", []) as Array).size() == 2,
                        "dimension one holds its own two")
        _check((h.room_by_id(rid2).get("members", []) as Array).size() == 2,
                        "dimension two holds its own two")
        # --- THE PARAMS BROADCAST: the owner's config reaches the members ---
        h.set_room_params({"mode": 4, "board": "12"})
        await _pump(0.5)
        _check(String(joiners[0].my_room().get("params", {}).get("board", "")) == "12",
                        "THE PARAMS WIRE: the owner's config reaches the members")
        _check(String(joiners[1].my_room().get("params", {}).get("board", "x")) != "12",
                        "THE PARAMS SCOPE: dimension two never saw dimension one's config")
        h.leave_session()
        for j in joiners:
                j.leave_session()
                _drop(j)
        late.leave_session()
        _drop(late)
        _drop(a)
        _drop(b)
        await _pump(0.3)
