extends Node
## VOICE (v042-1) - the box's real voice chat, THE VOICE LAW:
## per-player, TWO LAYERS - MIC (they hear me) and HEAR (I hear them) -
## with per-LAYER device detection ("so some people may hear only or
## listen only and that is ok"). His test rig: the phone has mic +
## speaker, the PC has speaker only.
##
## THE TRANSPORT: PCM16 mono 16 kHz, 20ms frames (320 samples = 640
## bytes), over UDP (PacketPeerUDP on session_port + 2). Every talker
## sends to the host; the host relays to the masked targets (the frame
## carries the target-seat bitmask). 2P rides the same host relay.
##
## THE CAPTURE: an AudioStreamMicrophone player on a muted "Record" bus
## wearing an AudioEffectCapture - the engine's own capture path, zero
## dependencies. Android asks RECORD_AUDIO at runtime (the toggle press
## is the ask); a device with no input devices reports has_mic = false
## and its MIC toggles never arm.
##
## THE PLAYBACK: one AudioStreamGenerator player per remote seat, a 2-3
## frame jitter buffer, dropped the moment their HEAR toggle dies or the
## peer leaves.

const RATE := 16000
const FRAME_MS := 20
const FRAME_SAMPLES := RATE * FRAME_MS / 1000     # 320
const FRAME_BYTES := FRAME_SAMPLES * 2            # PCM16
const JITTER_FRAMES := 2
const VOICE_PORT_OFF := 2                         # session port + 2

signal voice_state_changed

var mic_on := true                # THE MASTER MIC (the YOU row, layer 1)
var hear_on := true               # THE MASTER HEAR (the YOU row, layer 2)
var mic_to := {}                  # seat -> bool (layer 1: they hear me)
var hear_from := {}               # seat -> bool (layer 2: I hear them)

var has_mic := false              # THE DEVICE LAW, per layer
var has_out := true
var mic_granted := false          # Android RECORD_AUDIO state

var _udp: PacketPeerUDP = null
var _rec_player: AudioStreamPlayer = null
var _capture: AudioEffectCapture = null
var _ring := PackedFloat32Array()      # pending capture samples
var _seq := 0
var _players := {}                # seat -> {gen: AudioStreamGenerator, pl: AudioStreamPlayer, buf: PackedFloat32Array, seen}
var _peer_addrs := {}             # dev -> "ip:port" (learned from traffic)
var _hb := 0.0

func _ready() -> void:
        _detect_devices()
        # the session life rides the LAN's own signal - arm/drop with it
        LAN.session_changed.connect(_on_session_changed)

func _on_session_changed() -> void:
        if LAN.session_active():
                arm_session()
        else:
                drop_session()

func _detect_devices() -> void:
        has_mic = AudioServer.get_input_device_list().size() > 0
        has_out = AudioServer.get_output_device_list().size() > 0
        # the Android grant state: a request answers true only once granted;
        # the UI press re-asks (the runtime ask law - never at boot)
        if OS.get_name() != "Android":
                mic_granted = has_mic

## The Android runtime ask (called from the UI press, never at boot).
func request_mic() -> void:
        if OS.get_name() == "Android":
                mic_granted = OS.request_permission("RECORD_AUDIO")
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
        # THE VOICE HELLO: the host learns every seat's UDP address the
        # moment the session arms (a listener-only device still receives)
        _voice_hello()

func _voice_hello() -> void:
        if _udp == null or LAN.is_host:
                return
        var host_ip := LAN.host_addr.split(":")[0] if LAN.host_addr != "" else ""
        if host_ip == "":
                return
        _udp.set_dest_address(host_ip, 31440 + VOICE_PORT_OFF)
        _udp.put_var([{"t": "vh", "seat": LAN.my_seat_no()}])

func drop_session() -> void:
        if _udp != null:
                _udp.close()
                _udp = null
        if _rec_player != null:
                _rec_player.stop()
        for seat in _players:
                var st: Dictionary = _players[seat]
                if is_instance_valid(st["pl"]):
                        st["pl"].queue_free()
        _players = {}
        _ring = PackedFloat32Array()
        _peer_addrs = {}

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

## ---------- the toggles (the two layers) ----------

## LAYER 1 - MIC: they hear me. (the per-player button)
func set_mic_to(seat: int, on: bool) -> void:
        mic_to[seat] = on
        voice_state_changed.emit()

## LAYER 2 - HEAR: I hear them. (the per-player button)
func set_hear_from(seat: int, on: bool) -> void:
        hear_from[seat] = on
        if not on and _players.has(seat):
                var st: Dictionary = _players[seat]
                st["buf"] = PackedFloat32Array()
        voice_state_changed.emit()

func can_hear_me(seat: int) -> bool:
        return mic_on and bool(mic_to.get(seat, true))

func i_can_hear(seat: int) -> bool:
        return hear_on and bool(hear_from.get(seat, true))

## ---------- the pump ----------

func _process(delta: float) -> void:
        if _udp == null or not LAN.session_active():
                return
        _hb += delta
        # 1. CAPTURE -> my frame
        if _capture != null and mic_on and mic_granted:
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
        for seat in _players:
                _feed(seat)
        if _hb >= 1.0:
                _hb = 0.0
                _detect_devices()

func _send_frame(samples: PackedFloat32Array) -> void:
        var pcm := PackedByteArray()
        pcm.resize(samples.size() * 2)
        for i in samples.size():
                var v := int(clampf(samples[i], -1.0, 1.0) * 32767.0)
                pcm.encode_s16(i * 2, v)
        # the target mask: LAYER 1 - only the seats whose MIC toggle is on
        var mask := 0
        for s in LAN.seats:
                var seat := int(s.get("seat", 0))
                if seat != LAN.my_seat_no() and can_hear_me(seat):
                        mask |= 1 << (seat - 1)
        if mask == 0:
                return
        var pkt := {"t": "v", "seat": LAN.my_seat_no(), "seq": _seq,
                "mask": mask, "pcm": Marshalls.raw_to_base64(pcm)}
        _seq += 1
        var host_ip := LAN.host_addr.split(":")[0] if LAN.host_addr != "" else ""
        if host_ip == "":
                return
        if LAN.is_host:
                # the host relays its own frame directly to the masked seats
                _relay_frame(pkt, "")
        else:
                _udp.set_dest_address(host_ip, 31440 + VOICE_PORT_OFF)
                _udp.put_var([pkt])

func _on_frame(msg: Dictionary, from_addr: String) -> void:
        var t := String(msg.get("t", ""))
        if t == "vh":
                # the voice hello: learn the seat's UDP address (relay leg)
                if LAN.is_host:
                        _peer_addrs["dev" + str(int(msg.get("seat", 0)))] = from_addr
                return
        if t != "v":
                return
        var seat := int(msg.get("seat", 0))
        if seat == LAN.my_seat_no():
                return
        _peer_addrs["dev" + str(seat)] = from_addr
        if LAN.is_host:
                _relay_frame(msg, from_addr)
        # LAYER 2 - the receive gate
        if not i_can_hear(seat):
                return
        var pcm := Marshalls.base64_to_raw(String(msg.get("pcm", "")))
        if pcm.size() < 2:
                return
        if not _players.has(seat):
                _make_player(seat)
        var st: Dictionary = _players[seat]
        var buf: PackedFloat32Array = st["buf"]
        for i in range(0, pcm.size() - 1, 2):
                buf.append(float(pcm.decode_s16(i)) / 32768.0)
        st["buf"] = buf
        st["seen"] = Time.get_unix_time_from_system()

## The host's relay: the frame goes to every LIVE seat in the mask
## (except the talker and the direct sender).
func _relay_frame(msg: Dictionary, exclude_addr: String) -> void:
        var mask := int(msg.get("mask", 0))
        var talker := int(msg.get("seat", 0))
        for s in LAN.seats:
                var seat := int(s.get("seat", 0))
                if seat == talker or seat == LAN.my_seat_no():
                        continue
                if mask & (1 << (seat - 1)) == 0:
                        continue
                var addr := String(_peer_addrs.get("dev" + str(seat), ""))
                if addr == "":
                        continue
                var parts := addr.split(":")
                _udp.set_dest_address(parts[0], int(parts[1]) if parts.size() > 1 \
                                else 31440 + VOICE_PORT_OFF)
                _udp.put_var([msg])

func _make_player(seat: int) -> void:
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
        _players[seat] = {"gen": gen, "pl": pl, "buf": PackedFloat32Array(),
                "seen": Time.get_unix_time_from_system()}

func _feed(seat: int) -> void:
        var st: Dictionary = _players.get(seat, {})
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
                _players.erase(seat)

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

func toggle_hear_master() -> void:
        hear_on = not hear_on
        voice_state_changed.emit()

func toggle_mic_to(seat: int) -> void:
        set_mic_to(seat, not can_hear_me(seat))

func toggle_hear_from(seat: int) -> void:
        set_hear_from(seat, not i_can_hear(seat))
