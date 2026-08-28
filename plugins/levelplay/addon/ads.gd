extends Node
## Ads autoload (levelplay backend). Bridges Godot to the native Unity LevelPlay
## mediation plugin on Android; simulates the full ad flow on desktop so the
## same game code and tests run everywhere.
##
## LevelPlay = Unity's MEDIATION platform (ex-ironSource). Unity Ads, Meta,
## AdMob, AppLovin, Mintegral, ... compete for every impression; the active
## network set is configured on the LevelPlay dashboard per app.
##
## Runtime config: res://addons/levelplay/ads_config.json (per-project,
## injected by .ci/materialize-project.sh). Backend selection lives in
## config/projects.json -> "use_plugins".

signal init_complete
signal banner_shown_changed(visible: bool)

const DEFAULTS := {
        "backend": "levelplay",
        "enabled": true,
        "test_mode": true,
        "app_key": "",
        "ad_units": {
                "interstitial": "",
                "rewarded": "",
                "banner": ""
        },
        "interstitial_every_runs": 3,
        "banner_height": 90,
        "banner_enabled": true
}

var cfg: Dictionary = {}
var native: Object = null            # Engine.get_singleton("LevelPlayAds") on Android
var ready_ok := false                # native init finished OK
var init_failed := false             # native init failed (missing/invalid app key)
var desktop_sim := false             # true on non-Android builds

var _runs_since_interstitial := 0
var _pending_cb: Callable = Callable()
var _pending_rewarded := false       # what the pending callback is waiting for
var _rewarded_seen := false          # reward_received fired for current ad


func _ready() -> void:
        _load_config()
        if OS.has_feature("android") and Engine.has_singleton("LevelPlayAds"):
                native = Engine.get_singleton("LevelPlayAds")
                native.connect("init_complete", _on_native_init_complete)
                native.connect("init_failed", _on_native_init_failed)
                native.connect("ad_loaded", _on_native_loaded)
                native.connect("ad_failed", _on_native_ad_failed)
                native.connect("ad_closed", _on_native_closed)
                native.connect("reward_received", _on_reward_received)
                native.connect("banner_loaded", _on_banner_loaded)
                if String(cfg.app_key).is_empty():
                        # no dashboard key yet: stay inert, game keeps running ad-free
                        init_failed = true
                        push_warning("Ads[levelplay]: app_key empty - run the dashboard setup in docs/ADS.md, ads disabled until then")
                else:
                        native.configure(String(cfg.app_key), bool(cfg.test_mode), bool(cfg.banner_enabled))
        elif OS.has_feature("android"):
                push_warning("Ads[levelplay]: native LevelPlayAds singleton missing - ads disabled")
        else:
                desktop_sim = true
                ready_ok = true
                init_complete.emit()


func _load_config() -> void:
        cfg = DEFAULTS.duplicate(true)
        var f := FileAccess.open("res://addons/levelplay/ads_config.json", FileAccess.READ)
        if f:
                var parsed: Variant = JSON.parse_string(f.get_as_text())
                if parsed is Dictionary:
                        _merge(cfg, parsed)
        else:
                push_warning("Ads[levelplay]: ads_config.json not found - using defaults")
        if String(cfg.app_key).is_empty():
                push_warning("Ads[levelplay]: app_key empty - staying in sim/no-ads mode")


func _merge(base: Dictionary, over: Dictionary) -> void:
        for k in over:
                if base.has(k) and base[k] is Dictionary and over[k] is Dictionary:
                        _merge(base[k], over[k])
                else:
                        base[k] = over[k]


func ad_unit(kind: String) -> String:
        return String(cfg.ad_units.get(kind, ""))


func banner_height() -> float:
        return float(cfg.banner_height)


func available() -> bool:
        return native != null and ready_ok


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


## Rewarded ad. Callback receives true when the reward was granted
## (onAdRewarded fired - LevelPlay calls it exactly when the user earns it).
func show_rewarded(cb: Callable) -> void:
        if not enabled_ok():
                if cb.is_valid(): cb.call(false)
                return
        if desktop_sim:
                _simulate(true, cb)
                return
        if not available():
                if cb.is_valid(): cb.call(false)
                return
        if _pending_cb.is_valid():
                _flush_pending(false)  # a previous request is still in flight
        _pending_cb = cb
        _pending_rewarded = true
        _rewarded_seen = false
        if native.is_loaded("rewarded"):
                native.show("rewarded")
        else:
                native.load("rewarded")


func show_interstitial(cb: Callable = Callable()) -> void:
        if not enabled_ok():
                if cb.is_valid(): cb.call(false)
                return
        if desktop_sim:
                _simulate(false, cb)
                return
        if not available():
                if cb.is_valid(): cb.call(false)
                return
        if _pending_cb.is_valid():
                _flush_pending(false)
        _pending_cb = cb
        _pending_rewarded = false
        if native.is_loaded("interstitial"):
                native.show("interstitial")
        else:
                native.load("interstitial")


func banner_show() -> void:
        if not enabled_ok() or not bool(cfg.banner_enabled):
                return
        if desktop_sim:
                banner_shown_changed.emit(true)
                return
        if not available():
                return
        native.banner_show(ad_unit("banner"))
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
        if native and ready_ok:
                if not ad_unit("interstitial").is_empty():
                        native.set_ad_unit("interstitial", ad_unit("interstitial"))
                        native.load("interstitial")
                if not ad_unit("rewarded").is_empty():
                        native.set_ad_unit("rewarded", ad_unit("rewarded"))
                        native.load("rewarded")


func _flush_pending(ok: bool) -> void:
        if _pending_cb.is_valid():
                var cb := _pending_cb
                _pending_cb = Callable()
                _pending_rewarded = false
                cb.call(ok)


# ------------------------------------------------------------------ native -> godot

func _on_native_init_complete() -> void:
        ready_ok = true
        init_failed = false
        init_complete.emit()
        _preload_all()


func _on_native_init_failed(message: String) -> void:
        ready_ok = false
        init_failed = true
        push_warning("Ads[levelplay]: init failed: %s" % message)
        _flush_pending(false)


func _on_native_loaded(kind: String) -> void:
        if _pending_cb.is_valid() and _pending_rewarded and kind == "rewarded":
                native.show("rewarded")
        elif _pending_cb.is_valid() and not _pending_rewarded and kind == "interstitial":
                native.show("interstitial")


func _on_native_ad_failed(kind: String, _message: String) -> void:
        # load failed: drop the pending request so the game is never stuck waiting
        if _pending_cb.is_valid() and ((_pending_rewarded and kind == "rewarded") or (not _pending_rewarded and kind == "interstitial")):
                _flush_pending(false)


func _on_reward_received(_reward_name: String, _amount: int) -> void:
        _rewarded_seen = true


func _on_native_closed(kind: String) -> void:
        if not _pending_cb.is_valid():
                return
        if kind == "rewarded":
                var watched := _rewarded_seen
                _rewarded_seen = false
                _flush_pending(watched)
        elif kind == "interstitial":
                _flush_pending(true)


func _on_banner_loaded() -> void:
        banner_shown_changed.emit(true)


# ------------------------------------------------------------------ desktop sim

func _simulate(rewarded: bool, cb: Callable) -> void:
        var t := get_tree().create_timer(0.15)
        t.timeout.connect(func():
                if rewarded:
                        cb.call(true)   # simulated user always watches to the end
                else:
                        cb.call(true)
        )
