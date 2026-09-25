extends Node
## LAN FIND (v042-1, r2; r3 THE LIVE SCAN + THE SWITCH INVITE) - the box's
## own discovery service. THE SMART SCAN + THE INVITE leg.
##
## r3 (the owner: "make it more smart, like once it detect that player is
## in, it changes word from 'add' to something else ... so make it smart
## and low-level detection i mean"): the pong now carries the LIVE state -
## in_session, is_host, size, AND `playing` (the game a live match runs).
## The scan sheet re-pings while it is open, so a box that joins a session
## (or starts a match) while I watch flips its row live - no re-scan.
##
## r3 THE SWITCH INVITE: an invite is delivered even when I already ride
## a session - the top-level card offers LEAVE AND JOIN with synced
## updates (the owner's 3-device law: the second box must be able to
## abandon host 1 for host 3 from the card itself).
##
## THE WIRE: UDP pings on port 31445. The ping rides EVERY local
## interface's subnet-directed broadcast + the global one - Android
## quietly drops 255.255.255.255 on many networks, the subnet broadcast
## (192.168.x.255) is the one that actually crosses the wifi. No cloud,
## no rendezvous, no servers - pure local network (and VLAN NICs: an
## invite to a Tailscale/ZeroTier address is just a unicast).

signal found(peers: Array)          # a scan tick produced a fresh list
signal invite(name_v: String, addr: String, switch: bool)

const FIND_PORT := 31445
const SCAN_TICK := 1.0              # the scan's answer window per burst
const PEER_TTL := 4.0               # a listed peer stops answering -> gone

var _udp: PacketPeerUDP = null
var _peers := {}                    # dev -> {name, pfpm, size, is_host, in_session, playing, addr, seen}
var _scanning := false
var _scan_left := 0.0
var _self_info := {}

func _ready() -> void:
        # THE PAUSE LAW (r3): the answer side lives above the game pause -
        # a paused box must still answer pings and invites.
        process_mode = Node.PROCESS_MODE_ALWAYS
        _udp = PacketPeerUDP.new()
        if _udp.bind(FIND_PORT) != OK:
                _udp = null
                push_warning("lan_find: the discovery port is busy - scanning is off")

## Publish THIS box's live identity (called by the menu at boot and on
## every session change). The box answers pings ALWAYS now - the
## in_session flag says whether the answer is a live session or a free
## player.
func set_answering(on: bool, name_v := "", size_v := 0, is_host := false,
                pfpm := {}) -> void:
        _self_info = {"name": name_v, "size": size_v, "is_host": is_host,
                "pfpm": pfpm, "in_session": on}

## Every broadcast address worth pinging: the global 255.255.255.255
## plus, for every private local IPv4, its /24, /16 and /8 directed
## broadcasts (the home wifi answers the /24; Android quietly drops the
## global one on many networks, the subnet broadcast is what crosses).
func _broadcast_addrs() -> Array:
        var out := {"255.255.255.255": true}
        for a in IP.get_local_addresses():
                var ip := String(a)
                var quads := ip.split(".")
                if quads.size() != 4:
                        continue
                var ok := true
                for q in quads:
                        if not q.is_valid_int():
                                ok = false
                                break
                if not ok:
                        continue
                var a0 := int(quads[0])
                var a1 := int(quads[1])
                var a2 := int(quads[2])
                var a3 := int(quads[3])
                # private v4 only (the local network seat); never the
                # loopback's 127.x
                if a0 == 127 or a0 == 0 or ip == "":
                        continue
                if not ((a0 == 10) or (a0 == 172 and a1 >= 16 and a1 <= 31) \
                                or (a0 == 192 and a1 == 168) or a0 >= 224):
                        continue
                if a0 >= 224:      # multicast space - skip
                        continue
                out["%d.%d.%d.255" % [a0, a1, a2]] = true      # /24
                out["%d.%d.255.255" % [a0, a1]] = true         # /16
                out["%d.255.255.255" % a0] = true              # /8
        return out.keys()

## The answer's honest state block (what the scan sheet reads).
func self_state() -> Dictionary:
        var playing := ""
        var r: Dictionary = LAN.my_room()
        if not r.is_empty() and String(r.get("phase", "")) == "play":
                var g: Dictionary = GameReg.get_game(String(r.get("game", "")))
                playing = String(g.get("title", String(r.get("game", ""))))
        return {"in_session": LAN.session_active(), "size": LAN.session_size(),
                "is_host": LAN.is_host, "playing": playing}

func _process(delta: float) -> void:
        if _udp == null:
                return
        # THE ANSWER side - every GOGABox answers (the SCAN LAW r2)
        while _udp.get_available_packet_count() > 0:
                var pkt: Variant = _udp.get_var(false)
                var ip := String(_udp.get_packet_ip())
                var port := _udp.get_packet_port()
                if typeof(pkt) != TYPE_ARRAY or (pkt as Array).is_empty():
                        continue
                var m: Variant = (pkt as Array)[0]
                if typeof(m) != TYPE_DICTIONARY:
                        continue
                var msg: Dictionary = m
                match String(msg.get("t", "")):
                        "ping":
                                if port != 0:
                                        var pong := {"t": "iam",
                                                "dev": LAN.my_dev(),
                                                "name": String(_self_info.get("name", "")),
                                                "size": int(_self_info.get("size", 0)),
                                                "is_host": bool(_self_info.get("is_host", false)),
                                                "in_session": bool(_self_info.get("in_session", false)),
                                                "pfpm": _self_info.get("pfpm", {})}
                                        pong.merge(self_state(), true)
                                        _udp.set_dest_address(ip, FIND_PORT)
                                        _udp.put_var([pong])
                        "iam":
                                var dev := String(msg.get("dev", ""))
                                if dev == "" or dev == LAN.my_dev():
                                        continue
                                _peers[dev] = {"dev": dev,
                                        "name": LanProfile.sanitize_name(String(msg.get("name", "?"))),
                                        "size": int(msg.get("size", 0)),
                                        "is_host": bool(msg.get("is_host", false)),
                                        "in_session": bool(msg.get("in_session", false)),
                                        "playing": String(msg.get("playing", "")),
                                        "pfpm": msg.get("pfpm", {}),
                                        "addr": ip, "seen": Time.get_unix_time_from_system()}
                        "invite":
                                # r3 THE SWITCH INVITE: delivered even when
                                # I ride a session - the card carries the
                                # switch offer (the switch bool).
                                if String(msg.get("to", "")) == LAN.my_dev():
                                        invite.emit(String(msg.get("name", "PLAYER")),
                                                String(msg.get("addr", "")),
                                                LAN.session_active())
        # THE SCAN side: re-broadcast while scanning, expire stale peers
        if _scanning:
                _scan_left -= delta
                _udp.set_broadcast_enabled(true)
                for baddr in _broadcast_addrs():
                        _udp.set_dest_address(baddr, FIND_PORT)
                        _udp.put_var([{"t": "ping"}])
                if _scan_left <= 0.0:
                        _scanning = false
                        found.emit(peers())

        var now := Time.get_unix_time_from_system()
        for dev in _peers.keys():
                if now - float(_peers[dev]["seen"]) > PEER_TTL:
                        _peers.erase(dev)

## Fire one scan burst; found(peers) fires when the window closes.
func scan() -> void:
        if _udp == null:
                found.emit([])
                return
        _scanning = true
        _scan_left = SCAN_TICK

## The live list (also readable mid-scan for UI refreshes).
func peers() -> Array:
        var out := []
        for dev in _peers:
                out.append(_peers[dev])
        out.sort_custom(func(a, b): return String(a["name"]) < String(b["name"]))
        return out

## THE INVITE: press ADD on a scanned peer -> their app pops the card.
## Hosting (or riding) a session is NO LONGER a refusal - the invite
## carries the session I already hold (host_addr answers for the host AND
## the joiner; a joiner inviting a friend pulls them into the session
## they ride). The caller refuses peers already seated (the menu checks
## the dev against LAN.seats before this).
func invite_peer(peer: Dictionary) -> bool:
        if _udp == null:
                return false
        var addr := String(peer.get("addr", ""))
        if addr == "":
                return false
        if not LAN.session_active():
                var err := LAN.host_session()
                if err != "":
                        return false
        var target := LAN.host_addr
        if target == "":
                return false
        _udp.set_dest_address(addr, FIND_PORT)
        _udp.put_var([{"t": "invite", "to": String(peer.get("dev", "")),
                "name": LAN.my_name(), "addr": target}])
        return true
