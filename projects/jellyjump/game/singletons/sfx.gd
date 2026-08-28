extends Node
## Tiny sound engine: preloads all SFX, round-robins a pool of players.

const SOUNDS := {
	"jump": "res://assets/audio/synth/jump.wav",
	"coin": "res://assets/audio/synth/coin.wav",
	"spring": "res://assets/audio/synth/spring.wav",
	"crumble": "res://assets/audio/synth/crumble.wav",
	"gameover": "res://assets/audio/synth/gameover.wav",
	"click": "res://assets/audio/ui/click.ogg",
	"confirm": "res://assets/audio/ui/confirm.ogg",
	"error": "res://assets/audio/ui/error.ogg",
	"buy": "res://assets/audio/ui/buy.ogg",
	"win": "res://assets/audio/jingles/win.ogg",
	"daily": "res://assets/audio/jingles/daily.ogg",
}

const POOL_SIZE := 10

var _streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _idx := 0

func _ready() -> void:
	for key in SOUNDS:
		if ResourceLoader.exists(SOUNDS[key]):
			_streams[key] = load(SOUNDS[key])
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)

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
