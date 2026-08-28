extends Node
## Sound engine: preloads SFX, round-robins a player pool, respects settings.
## Pops get pitch variation so cascades sound juicy instead of robotic.

const SOUNDS := {
	"pop1": "res://assets/audio/pops/pop_1.wav",
	"pop2": "res://assets/audio/pops/pop_2.wav",
	"pop3": "res://assets/audio/pops/pop_3.wav",
	"pop4": "res://assets/audio/pops/pop_4.wav",
	"pop_deep": "res://assets/audio/pops/pop_deep.ogg",
	"swap": "res://assets/audio/synth/swap.wav",
	"sparkle": "res://assets/audio/synth/sparkle.wav",
	"boom": "res://assets/audio/synth/boom.wav",
	"coin": "res://assets/audio/synth/coin.wav",
	"star": "res://assets/audio/synth/star.wav",
	"lose": "res://assets/audio/synth/lose.wav",
	"click": "res://assets/audio/ui/click.ogg",
	"confirm": "res://assets/audio/ui/confirm.ogg",
	"error": "res://assets/audio/ui/error.ogg",
	"buy": "res://assets/audio/ui/buy.ogg",
	"win": "res://assets/audio/jingles/win.ogg",
}

const POOL_SIZE := 12

var _streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _idx := 0
var _music: AudioStreamPlayer

func _ready() -> void:
	for key in SOUNDS:
		if ResourceLoader.exists(SOUNDS[key]):
			_streams[key] = load(SOUNDS[key])
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -8.0
	add_child(_music)
	if ResourceLoader.exists("res://assets/audio/music/loop.mp3"):
		var stream: AudioStream = load("res://assets/audio/music/loop.mp3")
		if stream is AudioStreamMP3:
			stream.loop = true
		_music.stream = stream

func play(name_: String, volume_db := 0.0, pitch := 1.0) -> void:
	if not GameState.data.get("sound", true):
		return
	if not _streams.has(name_):
		return
	var p := _pool[_idx]
	_idx = (_idx + 1) % POOL_SIZE
	p.stream = _streams[name_]
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()

## Pitched pop for match cascades: wave 1..5 -> rising pitch.
func pop(combo := 1) -> void:
	var names := ["pop1", "pop2", "pop3", "pop4"]
	play(names[randi() % names.size()], -2.0, clampf(0.9 + 0.12 * combo, 0.8, 1.6))

func ensure_music() -> void:
	if GameState.data.get("music", true) and not _music.playing:
		_music.play()

func set_music_enabled(on: bool) -> void:
	if on:
		ensure_music()
	else:
		_music.stop()
