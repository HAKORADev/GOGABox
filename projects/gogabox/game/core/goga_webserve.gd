class_name GogaWebserve
extends Node
## THE WEB SEAT'S SERVER (v043 pass 3) - the box serves a web game's own
## files over localhost so the in-app surface (the Android WebView, the
## PC app-mode window) loads it like any site: relative paths, modules,
## wasm, textures - the whole modern web toolkit works, file:// quirks
## never happen. THE NO-TAB LAW holds: the server binds 127.0.0.1 ONLY,
## one package at a time, the seat is torn down when the game closes.
##
## The SDK bridge rides its own WebSocket door (goga_core, port 31443) -
## the page connects to ws://127.0.0.1:31443 and speaks the SAME ops
## vocabulary every other transport speaks (one API, four transports).

const PORT_RANGE := [31450, 31460]
const MIME := {
        "html": "text/html; charset=utf-8",
        "js": "text/javascript; charset=utf-8",
        "mjs": "text/javascript; charset=utf-8",
        "css": "text/css; charset=utf-8",
        "json": "application/json",
        "wasm": "application/wasm",
        "png": "image/png",
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "gif": "image/gif",
        "svg": "image/svg+xml",
        "webp": "image/webp",
        "ico": "image/x-icon",
        "ogg": "audio/ogg",
        "mp3": "audio/mpeg",
        "wav": "audio/wav",
        "m4a": "audio/mp4",
        "glb": "model/gltf-binary",
        "gltf": "model/gltf+json",
        "bin": "application/octet-stream",
        "ttf": "font/ttf",
        "otf": "font/otf",
        "woff": "font/woff",
        "woff2": "font/woff2",
        "txt": "text/plain; charset=utf-8",
        "map": "application/json",
        "pck": "application/octet-stream",
        "zip": "application/zip",
}

var server: TCPServer = null
var root_dir := ""
var port := 0
var _peers: Array = []          # [{conn: StreamPeerTCP, buf: PackedByteArray}]
var _in_flight := {}            # request-path -> PackedByteArray responses are built per hit

## Serve `dir` on the loopback. Returns the base URL or "" (honest fail).
func serve(dir: String) -> String:
        root_dir = ProjectSettings.globalize_path(dir) \
                if dir.begins_with("res://") else dir
        if not DirAccess.dir_exists_absolute(root_dir):
                return ""
        for p in range(PORT_RANGE[0], PORT_RANGE[1]):
                var s := TCPServer.new()
                if s.listen(p, "127.0.0.1") == OK:
                        server = s
                        port = p
                        break
        if server == null:
                return ""
        return "http://127.0.0.1:%d" % port

func stop() -> void:
        for p in _peers:
                var c: StreamPeerTCP = p["conn"]
                if c.get_status() != StreamPeerTCP.STATUS_ERROR:
                        c.disconnect_from_host()
        _peers.clear()
        if server != null:
                server.stop()
                server = null
        port = 0

func _exit_tree() -> void:
        stop()

func _process(_delta: float) -> void:
        if server == null:
                return
        while server.is_connection_available():
                var conn: StreamPeerTCP = server.take_connection()
                conn.set_no_delay(true)
                _peers.append({"conn": conn, "buf": PackedByteArray()})
        var alive: Array = []
        for p in _peers:
                var conn: StreamPeerTCP = p["conn"]
                if conn.get_status() != StreamPeerTCP.STATUS_CONNECTED:
                        conn.disconnect_from_host()
                        continue
                var n := conn.get_available_bytes()
                if n > 0:
                        # PackedByteArray is copy-on-write - reassign
                        # explicitly so the buffer inside the dict grows
                        var nb: PackedByteArray = p["buf"]
                        nb.append_array(conn.get_data(n)[1])
                        p["buf"] = nb
                var buf := p["buf"] as PackedByteArray
                var head_end := _find_head_end(buf)
                if head_end >= 0:
                        # answer and let the CLIENT close (Connection: close)
                        # - the peer stays seated until its socket reports
                        # the client's close, so the response bytes always
                        # flush before the StreamPeer dies
                        _answer(conn, buf.slice(0, head_end))
                        alive.append(p)
                        continue
                if buf.size() > 65536:
                        conn.disconnect_from_host()   # junk guard
                        continue
                alive.append(p)
        _peers = alive

static func _find_head_end(buf: PackedByteArray) -> int:
        var b := buf
        for i in range(0, b.size() - 3):
                if b[i] == 13 and b[i + 1] == 10 and b[i + 2] == 13 and b[i + 3] == 10:
                        return i
        return -1

func _answer(conn: StreamPeerTCP, head: PackedByteArray) -> void:
        var req := head.get_string_from_utf8()
        var first := req.split("\r\n")[0] if req.contains("\r\n") else req
        var parts := first.split(" ", false)
        if parts.size() < 2 or parts[0] != "GET":
                _send(conn, 405, "text/plain", "method not allowed".to_utf8_buffer())
                return
        var path := parts[1]
        # strip the query + the leading slash; resolve inside the root ONLY
        if path.contains("?"):
                path = path.substr(0, path.find("?"))
        var rel := path.trim_prefix("/").uri_decode()
        if rel.contains(".."):
                _send(conn, 403, "text/plain", "denied".to_utf8_buffer())
                return
        var target := root_dir.path_join(rel if rel != "" else "index.html")
        if DirAccess.dir_exists_absolute(target):
                target = target.path_join("index.html")
        if not FileAccess.file_exists(target):
                _send(conn, 404, "text/plain",
                                ("not found: %s" % rel).to_utf8_buffer())
                return
        var f := FileAccess.open(target, FileAccess.READ)
        if f == null:
                _send(conn, 500, "text/plain", "unreadable".to_utf8_buffer())
                return
        var body := f.get_buffer(int(f.get_length()))
        f.close()
        var ext := target.get_extension().to_lower()
        _send(conn, 200, MIME.get(ext, "application/octet-stream"), body)

func _send(conn: StreamPeerTCP, code: int, ctype: String, body: PackedByteArray) -> void:
        var head := "HTTP/1.1 %d %s\r\nContent-Type: %s\r\nContent-Length: %d\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n" \
                        % [code, "OK" if code == 200 else "ERR", ctype, body.size()]
        conn.put_data(head.to_utf8_buffer())
        conn.put_data(body)
