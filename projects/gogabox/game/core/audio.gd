extends Node
## Jukebox — box-wide audio. Two buses (Music / SFX), volumes from Box settings.
## Every game plays sfx through this so volumes stay consistent.

var _music := AudioStreamPlayer.new()
var _sfx_pool: Array = []
var _current_music := ""

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        _ensure_bus("Music")
        _ensure_bus("SFX")
        _music.bus = "Music"
        _music.volume_db = -6.0
        add_child(_music)
        for i in 8:
                var p := AudioStreamPlayer.new()
                p.bus = "SFX"
                add_child(p)
                _sfx_pool.append(p)
        apply_volumes()

func _ensure_bus(name_: String) -> void:
        if AudioServer.get_bus_index(name_) == -1:
                AudioServer.add_bus()
                AudioServer.set_bus_name(AudioServer.bus_count - 1, name_)

func apply_volumes() -> void:
        var mbus := AudioServer.get_bus_index("Music")
        var sbus := AudioServer.get_bus_index("SFX")
        AudioServer.set_bus_volume_db(mbus, linear_to_db(maxf(0.0001, Box.music_volume())))
        AudioServer.set_bus_mute(mbus, Box.music_volume() <= 0.001)
        AudioServer.set_bus_volume_db(sbus, linear_to_db(maxf(0.0001, Box.sfx_volume())))
        AudioServer.set_bus_mute(sbus, Box.sfx_volume() <= 0.001)

func music(track: String, restart := false) -> void:
        if _current_music == track and _music.playing and not restart:
                return
        _current_music = track
        var stream: AudioStream = load(track)
        if stream == null:
                return
        # box theme loops forever, with a soft fade-in so it never slams in
        if stream is AudioStreamMP3:
                (stream as AudioStreamMP3).loop = true
        elif stream is AudioStreamOggVorbis:
                (stream as AudioStreamOggVorbis).loop = true
        elif stream is AudioStreamWAV:
                (stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
        _music.stream = stream
        _music.volume_db = -38.0
        _music.play()
        var tw := _music.create_tween()
        tw.tween_property(_music, "volume_db", -6.0, 1.2) \
                        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func stop_music() -> void:
        _current_music = ""
        _music.stop()

func sfx(name_: String, volume_db := 0.0, pitch := 1.0) -> void:
        var path := _resolve(name_)
        if path.is_empty():
                return
        var stream: AudioStream = load(path)
        if stream == null:
                return
        for p in _sfx_pool:
                if not p.playing:
                        p.stream = stream
                        p.volume_db = volume_db
                        p.pitch_scale = pitch
                        p.play()
                        return
        # all busy: steal the first
        _sfx_pool[0].stream = stream
        _sfx_pool[0].volume_db = volume_db
        _sfx_pool[0].pitch_scale = pitch
        _sfx_pool[0].play()

const DIRS := [
        "res://assets/audio/ui/", "res://assets/audio/jingles/",
        "res://assets/audio/sfx/", "res://assets/audio/music/",
]

func _resolve(name_: String) -> String:
        for d in DIRS:
                for ext in [".ogg", ".wav", ".mp3"]:
                        var p: String = String(d) + name_ + ext
                        if ResourceLoader.exists(p):
                                return p
        return ""

func play_music_menu() -> void:
        music("res://assets/audio/music/box_theme.mp3")

func jingle_win() -> void:
        sfx("win", -2.0)

func jingle_lose() -> void:
        sfx("lose", -4.0)
