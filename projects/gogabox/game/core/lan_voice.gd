extends Node
## VOICE (v042-1; r3 THE VOICE TRUTH ROUND) - the box's real voice chat.
##
## THE SEMANTICS LAW (the owner's own words, verbatim): "other players
## mic's mean you do not hear them, and their speakers mean they do not
## hear you and your mic means none of them hear you and your speaker
## means you hear none of them". Four honest gates per pair:
##   - THEIR MIC off  -> their transmission stops (their device gates it),
##   - THEIR HEAR off -> their device drops my frames (they don't hear me),
##   - MY MIC off     -> I transmit nothing,
##   - MY HEAR off    -> I play nothing.
## The r2 build had the four gates but the UI could not SEE the remote
## states - r3 puts them on the wire (THE VST LAW) and in the roster.
##
## r3 THE DEV-KEY LAW: every voice map is keyed by the device id, never
## by the seat number - the seats renumbered on every leave and silently
## re-pointed the toggles and the frames to the WRONG humans. Devs are
## forever.
##
## r3 THE BEACON LAW: every device re-announces its UDP address every 2s
## while the session lives (the r2 hello fired once - a lost packet meant
## the host never learned the address and relayed to NOBODY: "my voice
## from phone mic did not reached PC").
##
## THE TRANSPORT: PCM16 mono 16 kHz, 20ms frames (320 samples = 640
## bytes), over UDP (PacketPeerUDP on session_port + 2). Every talker
## sends to the host; the host relays to the frame's target devs.
##
## THE CAPTURE: an AudioStreamMicrophone player on a muted "Record" bus
## wearing an AudioEffectCapture - the engine's own capture path, zero
## dependencies. Android asks RECORD_AUDIO at runtime (the toggle press
## is the ask); the grant state is POLLED (a grant answers live, the
## roster's disabled buttons un-stick by themselves).

const RATE := 16000
const FRAME_MS := 20
const FRAME_SAMPLES := RATE * FRAME_MS / 1000     # 320
const FRAME_BYTES := FRAME_SAMPLES * 2            # PCM16
const JITTER_FRAMES := 2
const VOICE_PORT_OFF := 2                         # session port + 2
const BEACON_SECS := 2.0

signal voice_state_changed

var mic_on := true                # THE MASTER MIC (my transmission)
var hear_on := true               # THE MASTER HEAR (my playback)
var mic_to := {}                  # dev -> bool (they hear me)
var hear_from := {}               # dev -> bool (I hear them)

var has_mic := false              # THE DEVICE LAW
var has_out := true
var mic_granted := false          # Android RECORD_AUDIO state (polled)

# r3 THE REMOTE TRUTH: dev -> {mic, hear, hm} - the VST wire's mirror,
# what the rosters read to show the REMOTE states.
var remote_state := {}

var _udp: PacketPeerUDP = null
var _rec_player: AudioStreamPlayer = null
var _capture: AudioEffectCapture = null
var _ring := PackedFloat32Array()      # pending capture samples
var _seq := 0
var _players := {}                # dev -> {gen, pl, buf, seen}
var _peer_addrs := {}             # dev -> "ip:port" (learned from traffic)
var _hb := 0.0
var _beacon := 0.0

func _ready() -> void:
        # THE PAUSE LAW (r3): a paused tree stopped the capture pump and
        # the beacons - the voice died the moment a sheet opened. The
        # voice lives above the pause now.
        process_mode = Node.PROCESS_MODE_ALWAYS
        _detect_devices()
        # the session life rides the LAN's own signal - arm/drop with it
        LAN.session_changed.connect(_on_session_changed)
        # r3 THE VST WIRE: the peers' mic/hear truth lands here
        LAN.vst_arrived.connect(apply_remote)

func _on_session_changed() -> void:
        if LAN.session_active():
                arm_session()
        else:
                drop_session()

func _detect_devices() -> void:
        has_mic = AudioServer.get_input_device_list().size() > 0
        has_out = AudioServer.get_output_device_list().size() > 0
        # the Android grant state: POLLED - the user answers the ask while
        # the roster is open, and the roster wakes up by itself.
        if OS.get_name() != "Android":
                mic_granted = has_mic
        else:
                mic_granted = "RECORD_AUDIO" in OS.get_granted_permissions()

## The Android runtime ask (called from the UI press, never at boot).
func request_mic() -> void:
        if OS.get_name() == "Android":
                OS.request_permission("RECORD_AUDIO")
        _detect_devices()

## ---------- the session life ----------

func arm_session() -> void:
        if _udp != null:
                return
        _udp = PacketPeerUDP.new()
        var port := 31440 + VOICE_PORT_OFF
        for i in 10:
                if _udp.bind(port + i) == OK:
                        break
        _setup_capture()
        # THE DEFAULT TOGGLES: everyone hears everyone on both layers
        mic_to = {}
        hear_from = {}
        remote_state = {}
        _beacon = BEACON_SECS        # the first beacon fires immediately
        _publish_state()

func drop_session() -> void:
        if _udp != null:
                _udp.close()
                _udp = null
        if _rec_player != null:
                _rec_player.stop()
        for dev in _players:
                var st: Dictionary = _players[dev]
                if is_instance_valid(st["pl"]):
                        st["pl"].queue_free()
        _players = {}
        _ring = PackedFloat32Array()
        _peer_addrs = {}
        remote_state = {}

func _setup_capture() -> void:
        if not has_mic or _capture != null:
                return
        # the Record bus: mic stream in, muted out (no feedback), capture on
        var bus := AudioServer.bus_count
        AudioServer.add_bus(bus)
        AudioServer.set_bus_name(bus, "Record")
        AudioServer.set_bus_mute(bus, true)
        _capture = AudioEffectCapture.new()
        _capture.buffer_length = 0.2
        AudioServer.add_bus_effect(bus, _capture)
        _rec_player = AudioStreamPlayer.new()
        var mic := AudioStreamMicrophone.new()
        _rec_player.stream = mic
        _rec_player.bus = "Record"
        _rec_player.autoplay = false
        add_child(_rec_player)
        _rec_player.play()

## ---------- the toggles (the four honest gates) ----------

## LAYER 1 - MIC: they hear me. (per-player, dev-keyed)
func set_mic_to(dev: String, on: bool) -> void:
        mic_to[dev] = on
        voice_state_changed.emit()

## LAYER 2 - HEAR: I hear them. (per-player, dev-keyed)
func set_hear_from(dev: String, on: bool) -> void:
        hear_from[dev] = on
        if not on and _players.has(dev):
                var st: Dictionary = _players[dev]
                st["buf"] = PackedFloat32Array()
        voice_state_changed.emit()

func can_hear_me(dev: String) -> bool:
        return mic_on and bool(mic_to.get(dev, true))

func i_can_hear(dev: String) -> bool:
        return hear_on and bool(hear_from.get(dev, true))

## My publishable truth: the master gates + whether a mic even exists.
func my_state() -> Dictionary:
        return {"mic": mic_on and mic_granted and has_mic,
                "hear": hear_on, "hm": has_mic}

## r3 THE VST LAW: my state rides the LAN wire on every toggle.
func _publish_state() -> void:
        var s := my_state()
        LAN.send_vst(bool(s["mic"]), bool(s["hear"]), bool(s["hm"]))

## The LAN wire hands a peer's state over (LAN.vst_arrived -> here).
func apply_remote(msg: Dictionary) -> void:
        var dev := String(msg.get("dev", ""))
        if dev == "" or dev == LAN.my_dev():
                return
        remote_state[dev] = {"mic": bool(msg.get("mic", false)),
                "hear": bool(msg.get("hear", true)),
                "hm": bool(msg.get("hm", false))}
        voice_state_changed.emit()

## The remote truth for the roster (defaults honest: a silent peer with
## no state published yet reads as mic-off until its first beacon).
func remote_of(dev: String) -> Dictionary:
        return remote_state.get(dev, {"mic": false, "hear": true, "hm": false})

## ---------- the pump ----------

func _process(delta: float) -> void:
        if _udp == null or not LAN.session_active():
                return
        _hb += delta
        _beacon += delta
        if _beacon >= BEACON_SECS:
                _beacon = 0.0
                _beacon_hello()
        # 1. CAPTURE -> my frame
        if _capture != null and mic_on and mic_granted and has_mic:
                var frames := _capture.get_frames_available()
                if frames > 0:
                        var data := _capture.get_buffer(frames)
                        for v in data:
                                _ring.append(v.x)
                        while _ring.size() >= FRAME_SAMPLES:
                                _send_frame(_ring.slice(0, FRAME_SAMPLES))
                                _ring = _ring.slice(FRAME_SAMPLES)
        # 2. NETWORK -> playback
        while _udp.get_available_packet_count() > 0:
                var pkt: Variant = _udp.get_var(false)
                if typeof(pkt) != TYPE_ARRAY or (pkt as Array).is_empty():
                        continue
                var m: Variant = (pkt as Array)[0]
                if typeof(m) == TYPE_DICTIONARY:
                        _on_frame(m, "%s:%d" % [_udp.get_packet_ip(),
                                        _udp.get_packet_port()])
        # 3. keep the players fed
        for dev in _players.keys():
                _feed(String(dev))
        if _hb >= 1.0:
                _hb = 0.0
                var was := mic_granted
                _detect_devices()
                if was != mic_granted:
                        voice_state_changed.emit()
                        _publish_state()

## THE BEACON: my UDP address rides to the host every 2s (the host needs
## it to relay the room's frames TO me - a listener-only device too).
func _beacon_hello() -> void:
        if _udp == null:
                return
        if LAN.is_host:
                return          # the host's addr is known (host_addr)
        var host_ip := LAN.host_addr.split(":")[0] if LAN.host_addr != "" else ""
        if host_ip == "":
                return
        _udp.set_dest_address(host_ip, 31440 + VOICE_PORT_OFF)
        _udp.put_var([{"t": "vh", "dev": LAN.my_dev()}])

func _send_frame(samples: PackedFloat32Array) -> void:
        var pcm := PackedByteArray()
        pcm.resize(samples.size() * 2)
        for i in samples.size():
                var v := int(clampf(samples[i], -1.0, 1.0) * 32767.0)
                pcm.encode_s16(i * 2, v)
        # THE TARGET LIST: the devs whose MIC gate lets them hear me -
        # dev-keyed (the seat-number mask renumbered itself into silence).
        var targets := []
        for s in LAN.seats:
                var dev := String(s.get("dev", ""))
                if dev == LAN.my_dev() or dev == LAN.my_dev() + LAN.COMBO_DEV:
                        continue
                if can_hear_me(dev):
                        targets.append(dev)
        if targets.is_empty():
                return
        var pkt := {"t": "v", "dev": LAN.my_dev(), "seq": _seq,
                "to": targets, "pcm": Marshalls.raw_to_base64(pcm)}
        _seq += 1
        var host_ip := LAN.host_addr.split(":")[0] if LAN.host_addr != "" else ""
        if host_ip == "":
                return
        if LAN.is_host:
                # the host relays its own frame directly to the targets
                _relay_frame(pkt, "")
        else:
                _udp.set_dest_address(host_ip, 31440 + VOICE_PORT_OFF)
                _udp.put_var([pkt])

func _on_frame(msg: Dictionary, from_addr: String) -> void:
        var t := String(msg.get("t", ""))
        if t == "vh":
                # THE BEACON: the sender's UDP address (relay leg)
                if LAN.is_host:
                        _peer_addrs[String(msg.get("dev", ""))] = from_addr
                return
        if t != "v":
                return
        var dev := String(msg.get("dev", ""))
        if dev == "" or dev == LAN.my_dev():
                return
        _peer_addrs[dev] = from_addr
        if LAN.is_host:
                _relay_frame(msg, from_addr)
        # LAYER 2 - the receive gate (my HEAR for THIS dev)
        if not i_can_hear(dev):
                return
        var pcm := Marshalls.base64_to_raw(String(msg.get("pcm", "")))
        if pcm.size() < 2:
                return
        if not _players.has(dev):
                _make_player(dev)
        var st: Dictionary = _players[dev]
        var buf: PackedFloat32Array = st["buf"]
        for i in range(0, pcm.size() - 1, 2):
                buf.append(float(pcm.decode_s16(i)) / 32768.0)
        st["buf"] = buf
        st["seen"] = Time.get_unix_time_from_system()

## The host's relay: the frame goes to every LIVE target dev in its list
## (except the talker and the direct sender). A target with no learned
## address is skipped this frame - its next beacon fixes it.
func _relay_frame(msg: Dictionary, exclude_addr: String) -> void:
        var talker := String(msg.get("dev", ""))
        for dev in msg.get("to", []):
                var d := String(dev)
                if d == talker or d == LAN.my_dev():
                        continue
                var addr := String(_peer_addrs.get(d, ""))
                if addr == "":
                        continue
                if addr == exclude_addr:
                        continue
                var parts := addr.split(":")
                _udp.set_dest_address(parts[0], int(parts[1]) if parts.size() > 1 \
                                else 31440 + VOICE_PORT_OFF)
                _udp.put_var([msg])

func _make_player(dev: String) -> void:
        var gen := AudioStreamGenerator.new()
        gen.mix_rate = RATE
        gen.stereo = false
        gen.buffer_length = 0.3
        var pl := AudioStreamPlayer.new()
        pl.stream = gen
        pl.bus = "Master"
        pl.volume_db = -2.0
        add_child(pl)
        pl.play()
        _players[dev] = {"gen": gen, "pl": pl, "buf": PackedFloat32Array(),
                "seen": Time.get_unix_time_from_system()}

func _feed(dev: String) -> void:
        var st: Dictionary = _players.get(dev, {})
        var gen: AudioStreamGenerator = st.get("gen")
        var pl: AudioStreamPlayer = st.get("pl")
        if gen == null or pl == null or not is_instance_valid(pl):
                return
        var buf: PackedFloat32Array = st["buf"]
        # THE JITTER: hold 2 frames before the first push, then ride
        if buf.size() >= FRAME_SAMPLES * JITTER_FRAMES:
                var to_push := mini(buf.size(),
                                FRAME_SAMPLES * 2)
                var data := PackedVector2Array()
                data.resize(to_push)
                for i in to_push:
                        data[i] = Vector2(buf[i], 0.0)
                var n: int = gen.get_frames_available()
                if n > 0:
                        gen.push_buffer(data.slice(0, mini(n, to_push)))
                        buf = buf.slice(mini(n, to_push))
                st["buf"] = buf
        # a silent seat for 5s loses its player (the honest prune)
        if Time.get_unix_time_from_system() - float(st.get("seen", 0.0)) > 5.0 \
                        and buf.size() < FRAME_SAMPLES:
                pl.queue_free()
                _players.erase(dev)

## The device notes for the UI (per-layer detection, the owner's law).
func mic_note() -> String:
        if not has_mic:
                return "NO MIC ON THIS DEVICE"
        if OS.get_name() == "Android" and not mic_granted:
                return "MIC PERMISSION NOT GIVEN YET"
        return ""

## The human toggle handlers (the pause roster's buttons).
func toggle_mic_master() -> void:
        mic_on = not mic_on
        voice_state_changed.emit()
        _publish_state()

func toggle_hear_master() -> void:
        hear_on = not hear_on
        voice_state_changed.emit()
        _publish_state()

func toggle_mic_to(dev: String) -> void:
        set_mic_to(dev, not can_hear_me(dev))

func toggle_hear_from(dev: String) -> void:
        set_hear_from(dev, not i_can_hear(dev))
