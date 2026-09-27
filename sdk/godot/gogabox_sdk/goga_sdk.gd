class_name GogaSdk
extends Node
## THE GOGABOX SDK - one API for every game, two transports:
##
##   EMBEDDED (the game runs INSIDE the box, a .pck package):
##     the box's own GOGA autoload serves every call directly.
##   STANDALONE (the game runs as its own process - the Steam model):
##     this node talks to the RUNNING box over localhost TCP (port 31442,
##     newline-delimited JSON, THE SDK BRIDGE in goga_core.gd). No box
##     running? Every call answers honestly (ok=false / 0 / ""), never
##     hangs longer than the 2.5s deadline.
##
## Usage (the developer's whole contract):
##   GogaSdk.coins() -> int                  # the player's GOGACoins
##   GogaSdk.spend(10) -> bool               # true when it landed
##   GogaSdk.earn(5)                         # reward the player
##   GogaSdk.save_write("save", data_str)    # THE PORTABLE SAVE LAW
##   GogaSdk.save_read("save") -> String     # (empty when unset)
##   GogaSdk.toast("hello from the game")    # a top-level box note
##   GogaSdk.is_box() -> bool                # embedded inside the box?
##
## A standalone game adds this script as an autoload named GogaSdk; the
## client id defaults to the project name - set CLIENT_ID to override.

const PORT := 31442
const PROTO := 1
const CLIENT_ID := ""   # override per game; default = the project name
const DEADLINE_MS := 2500

var _embedded := false
var _peer: StreamPeerTCP = null
var _handshook := false

func _ready() -> void:
        _embedded = Engine.get_main_loop() != null \
                and _find_box_goga() != null
        if _embedded:
                pass   # nothing to wire - the box's doors are already here
        else:
                _ensure_wire()

## The honest seat: a standalone game may refuse to run without the box
## (the Steam model) - the game decides, the SDK just answers.
func is_box() -> bool:
        return _embedded

func wire_ok() -> bool:
        return _embedded or _ensure_wire()

# ------------------------------------------------------------ the doors

func coins() -> int:
        if _embedded:
                return _box().coins_balance()
        var res := _roundtrip({"op": "coins.balance"})
        return int(res.get("coins", 0)) if bool(res.get("ok", false)) else 0

func spend(n: int) -> bool:
        if _embedded:
                return _box().coins_spend(n)
        return bool(_roundtrip({"op": "coins.spend", "n": n}).get("ok", false))

func earn(n: int) -> void:
        if _embedded:
                _box().coins_earn(n)
                return
        _roundtrip({"op": "coins.earn", "n": n})

func save_write(key: String, data: String) -> bool:
        if _embedded:
                return _box().sdk_save_write(_client(), key, data)
        return bool(_roundtrip({"op": "save.write", "key": key, "data": data}).get("ok", false))

func save_read(key: String) -> String:
        if _embedded:
                return _box().sdk_save_read(_client(), key)
        var res := _roundtrip({"op": "save.read", "key": key})
        return String(res.get("data", "")) if bool(res.get("ok", false)) else ""

func toast(msg: String) -> void:
        if _embedded:
                _box().sdk_toast(msg)
                return
        _roundtrip({"op": "toast", "msg": msg})

# ------------------------------------------------------------ the transports

func _box() -> Node:
        return _find_box_goga()

func _find_box_goga() -> Node:
        var root := get_tree().root
        for child in root.get_children():
                if child.has_method("entries") and child.has_method("mount_for"):
                        return child
        return null

func _client() -> String:
        if CLIENT_ID != "":
                return CLIENT_ID
        return String(ProjectSettings.get_setting("application/config/name", "goga_client"))

## The wire: connected, handshaken, or null (no box).
func _ensure_wire() -> bool:
        if _peer != null and _peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
                return true
        _handshook = false
        _peer = StreamPeerTCP.new()
        if _peer.connect_to_host("127.0.0.1", PORT) != OK:
                _peer = null
                return false
        var deadline := Time.get_ticks_msec() + DEADLINE_MS
        while Time.get_ticks_msec() < deadline:
                _peer.poll()
                if _peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
                        break
                if _peer.get_status() == StreamPeerTCP.STATUS_ERROR:
                        _peer = null
                        return false
        if _peer == null or _peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
                return false
        # the hello handshake
        _peer.put_data((JSON.stringify({
                "op": "hello", "client": _client(), "proto": PROTO}) + "\n")
        var res := _pump_line()
        _handshook = bool(res.get("ok", false))
        return _handshook

## One synchronous request -> answer round (send, pump until a line).
func _roundtrip(req: Dictionary) -> Dictionary:
        if not _ensure_wire():
                return {"ok": false, "err": "no box running"}
        _peer.put_data((JSON.stringify(req) + "\n").to_utf8_buffer())
        return _pump_line()

func _pump_line() -> Dictionary:
        var deadline := Time.get_ticks_msec() + DEADLINE_MS
        var buf := ""
        while Time.get_ticks_msec() < deadline:
                _peer.poll()
                if _peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
                        return {"ok": false, "err": "wire closed"}
                var n := _peer.get_available_bytes()
                if n > 0:
                        var got := _peer.get_data(n)
                        if got[0] == OK:
                                buf += (got[1] as PackedByteArray).get_string_from_utf8()
                while buf.contains("\n"):
                        var line := buf.substr(0, buf.find("\n")).strip_edges()
                        var res: Variant = JSON.parse_string(line)
                        if res is Dictionary and String((res as Dictionary).get("op", "")) != "hello":
                                return res
                        if res is Dictionary:
                                return res
                        buf = buf.substr(buf.find("\n") + 1)
        return {"ok": false, "err": "timeout"}
