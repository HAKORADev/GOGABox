extends Node
## Ads autoload (staged from plugins/unity_ads). Bridges Godot to the native
## Unity Ads plugin on Android; simulates the full ad flow on desktop so the
## same game code and tests run everywhere.
##
## Runtime config: res://addons/unity_ads/ads_config.json (per-project,
## injected by .ci/materialize-project.sh).

signal init_complete
signal banner_shown_changed(visible: bool)

const DEFAULTS := {
	"enabled": true,
	"test_mode": true,
	"game_id": "",
	"placements": {
		"interstitial": "Interstitial_Android",
		"rewarded": "Rewarded_Android",
		"banner": "Banner_Android"
	},
	"interstitial_every_runs": 3,
	"banner_height": 90,
	"banner_enabled": true
}

var cfg: Dictionary = {}
var native: Object = null            # Engine.get_singleton("UnityAds") on Android
var ready_ok := false                # native init finished
var desktop_sim := false             # true on non-Android builds

var _runs_since_interstitial := 0
var _pending_cb: Callable = Callable()
var _last_result_ok := false

func _ready() -> void:
	_load_config()
	if OS.has_feature("android") and Engine.has_singleton("UnityAds"):
		native = Engine.get_singleton("UnityAds")
		native.connect("init_complete", _on_native_init_complete)
		native.connect("init_failed", func(_m): _on_native_init_failed())
		native.connect("ad_loaded", _on_native_loaded)
		native.connect("ad_closed", _on_native_closed)
		native.configure(String(cfg.game_id), bool(cfg.test_mode), bool(cfg.banner_enabled))
		_preload_all()
	elif OS.has_feature("android"):
		push_warning("Ads: native UnityAds singleton missing - ads disabled")
	else:
		desktop_sim = true
		ready_ok = true
		init_complete.emit()

func _load_config() -> void:
	cfg = DEFAULTS.duplicate(true)
	var f := FileAccess.open("res://addons/unity_ads/ads_config.json", FileAccess.READ)
	if f:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary:
			_merge(cfg, parsed)
	else:
		push_warning("Ads: ads_config.json not found - using defaults")
	if String(cfg.game_id).is_empty():
		push_warning("Ads: game_id empty - staying in test/sim mode")

func _merge(base: Dictionary, over: Dictionary) -> void:
	for k in over:
		if base.has(k) and base[k] is Dictionary and over[k] is Dictionary:
			_merge(base[k], over[k])
		else:
			base[k] = over[k]

func placement(kind: String) -> String:
	return String(cfg.placements.get(kind, ""))

func banner_height() -> float:
	return float(cfg.banner_height)

# ---------------------------------------------------------------- pacing API

func register_run() -> void:
	_runs_since_interstitial += 1

## Call when returning to menu/game-over: shows interstitial if the pacing
## counter reached interstitial_every_runs. Callback receives true if shown.
func maybe_interstitial(cb: Callable = Callable()) -> void:
	if int(cfg.interstitial_every_runs) <= 0 or _runs_since_interstitial < int(cfg.interstitial_every_runs):
		if cb.is_valid(): cb.call(false)
		return
	_runs_since_interstitial = 0
	show_interstitial(cb)

## Rewarded ad. Callback receives true when the ad was fully watched.
func show_rewarded(cb: Callable) -> void:
	_last_result_ok = false
	if not enabled_ok():
		if cb.is_valid(): cb.call(false)
		return
	if desktop_sim:
		_simulate(true, cb)
		return
	_pending_cb = cb
	if native and native.is_loaded(placement("rewarded")):
		native.show(placement("rewarded"))
	else:
		native.load(placement("rewarded"))

func show_interstitial(cb: Callable = Callable()) -> void:
	if not enabled_ok():
		if cb.is_valid(): cb.call(false)
		return
	if desktop_sim:
		_simulate(false, cb)
		return
	_pending_cb = cb
	if native and native.is_loaded(placement("interstitial")):
		native.show(placement("interstitial"))
	else:
		native.load(placement("interstitial"))

func banner_show() -> void:
	if not enabled_ok() or not bool(cfg.banner_enabled):
		return
	if desktop_sim:
		banner_shown_changed.emit(true)
		return
	if native: native.banner_show(placement("banner"))
	banner_shown_changed.emit(true)

func banner_hide() -> void:
	if desktop_sim:
		banner_shown_changed.emit(false)
		return
	if native: native.banner_hide()
	banner_shown_changed.emit(false)

func enabled_ok() -> bool:
	return bool(cfg.enabled)

func _preload_all() -> void:
	if native:
		native.load(placement("interstitial"))
		native.load(placement("rewarded"))

# ------------------------------------------------------------------ native -> godot

func _on_native_init_complete() -> void:
	ready_ok = true
	init_complete.emit()
	_preload_all()

func _on_native_init_failed() -> void:
	ready_ok = false

func _on_native_loaded(placement_id: String) -> void:
	# if something was waiting for a load, show it now
	if _pending_cb.is_valid() and placement_id == placement("rewarded"):
		native.show(placement_id)
	elif _pending_cb.is_valid() and placement_id == placement("interstitial"):
		native.show(placement_id)

func _on_native_closed(placement_id: String, completion_state: int) -> void:
	# UnityAdsShowCompletionState ordinals: SKIPPED=0, COMPLETED=1
	var watched := completion_state >= 1  # SKIPPED=0, COMPLETED=1 (ordinal)
	if _pending_cb.is_valid():
		var cb := _pending_cb
		_pending_cb = Callable()
		cb.call(watched)

# ------------------------------------------------------------------ desktop sim

func _simulate(rewarded: bool, cb: Callable) -> void:
	var t := get_tree().create_timer(0.15)
	t.timeout.connect(func():
		if rewarded:
			cb.call(true)   # simulated user always watches to the end
		else:
			cb.call(true)
	)
