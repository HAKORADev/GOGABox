extends Node
## LAN FIND (v042-1) - the box's own discovery service. THE SMART SCAN
## (the owner: "by smart network scanning to see if someone else exist as
## local player and i press add") + THE INVITE leg + the honest
## "embedded virtual net" line.
##
## THE WIRE: UDP broadcast pings on port 31445 ("who is in a session?"),
## every GOGABox process that hosts OR rides a session answers with its
## identity + seat count. A scan lists the answers; ADD sends a unicast
## INVITE; the target's app pops the accept sheet and JOINS (the address
## rides the invite). No cloud, no rendezvous, no servers - pure local
## network (and VLAN NICs: the broadcast rides every interface the OS
## gives us, and an invite to a Tailscale/ZeroTier address is just a
## unicast - the virtual-LAN leg works unchanged).
##
## THE EMBEDDED VIRTUAL NET, HONESTLY (docs/brainstorm/v042-1/MASTER.md
## §1e): this service + the room codes + UPnP + free VLAN-NIC support is
## the no-setup ladder. A bundled ZeroTier/Tailscale userspace stack is a
## native-library round and is NOT faked in GDScript.

signal found(peers: Array)          # a scan tick produced a fresh list
signal invite(name_v: String, addr: String)

const FIND_PORT := 31445
const SCAN_TICK := 1.0              # the scan's answer window per burst
const PEER_TTL := 4.0               # a listed peer stops answering -> gone

var _udp: PacketPeerUDP = null
var _peers := {}                    # dev -> {name, pfp, pfpm, size, is_host, addr, seen}
var _scanning := false
var _scan_left := 0.0
var _answering := false             # this box answers pings while in a session

func _ready() -> void:
        _udp = PacketPeerUDP.new()
        if _udp.bind(FIND_PORT) != OK:
                _udp = null
                push_warning("lan_find: the discovery port is busy - scanning is off")

## Start answering discovery pings (the box is in a session).
func set_answering(on: bool, name_v := "", size_v := 0, is_host := false,
                pfpm := {}) -> void:
        _answering = on
        if on:
                _self_info = {"name": name_v, "size": size_v, "is_host": is_host,
                        "pfpm": pfpm}

var _self_info := {}

func _process(delta: float) -> void:
        if _udp == null:
                return
        # THE ANSWER side
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
                                if _answering and port != 0:
                                        var pong := {"t": "iam", "dev": LAN.my_dev(),
                                                "name": String(_self_info.get("name", "")),
                                                "size": int(_self_info.get("size", 0)),
                                                "is_host": bool(_self_info.get("is_host", false)),
                                                "pfpm": _self_info.get("pfpm", {})}
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
                                        "pfpm": msg.get("pfpm", {}),
                                        "addr": ip, "seen": Time.get_unix_time_from_system()}
                        "invite":
                                if String(msg.get("to", "")) == LAN.my_dev() \
                                                and not LAN.session_active():
                                        invite.emit(String(msg.get("name", "PLAYER")),
                                                String(msg.get("addr", "")))
        # THE SCAN side: re-broadcast while scanning, expire stale peers
        if _scanning:
                _scan_left -= delta
                _udp.set_broadcast_enabled(true)
                _udp.set_dest_address("255.255.255.255", FIND_PORT)
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

## THE INVITE: press ADD on a scanned peer -> their app pops the sheet.
func invite_peer(peer: Dictionary) -> bool:
        if _udp == null or LAN.session_active():
                return false
        var addr := String(peer.get("addr", ""))
        if addr == "":
                return false
        # the invite carries MY host address (open a session first if needed)
        var target := LAN.host_addr
        if not LAN.session_active():
                var err := LAN.host_session()
                if err != "":
                        return false
                target = LAN.host_addr
        _udp.set_dest_address(addr, FIND_PORT)
        _udp.put_var([{"t": "invite", "to": String(peer.get("dev", "")),
                "name": LAN.my_name(), "addr": target}])
        return true
