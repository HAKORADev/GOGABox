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
        "banner_enabled": true,
        # TIERED rewarded payouts (owner rule: 5s ads pay nothing):
        #   watch >= half -> 50%, >= p75 -> 75%, >= full -> 100%
        "reward_tiers": {"half": 15, "p75": 20, "full": 30}
}

var cfg: Dictionary = {}
var native: Object = null            # Engine.get_singleton("UnityAds") on Android
var ready_ok := false                # native init finished
var desktop_sim := false             # true on non-Android builds

var _runs_since_interstitial := 0
var _pending_cb: Callable = Callable()
var _last_result_ok := false
var _pending_since_ms := 0
var _banner_wanted := false        # banner requested before init finished
var _showing := false              # an ad is on screen (watchdog paused)
var _load_retries := {}            # placement -> retries while a cb waits
var _ad_start_ms := 0              # when the current ad started SHOWING
var _banner_retrying := false      # gdscript-side banner retry in flight

func _ready() -> void:
        _load_config()
        if OS.has_feature("android") and Engine.has_singleton("UnityAds"):
                native = Engine.get_singleton("UnityAds")
                native.connect("init_complete", _on_native_init_complete)
                native.connect("init_failed", func(_m): _on_native_init_failed())
                native.connect("ad_loaded", _on_native_loaded)
                native.connect("ad_failed", _on_native_failed)
                native.connect("ad_closed", _on_native_closed)
                native.connect("ad_shown", _on_native_shown)
                native.connect("banner_loaded", func(): _banner_retrying = false)
                native.connect("banner_failed", func(_m): _schedule_banner_retry())
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

## Pre-load everything again. Call when the menu opens / after a session -
## interstitials and banners expire, so a fresh load right before the moment
## we might show one massively raises fill ("per-turn ads never show" fix).
func refresh() -> void:
        if desktop_sim or not enabled_ok():
                return
        _preload_all()

# ----------------------------------------------------------- rewarded tiers

func tier_secs(kind: String) -> int:
        var t: Dictionary = cfg.get("reward_tiers", DEFAULTS["reward_tiers"])
        return int(t.get(kind, 15))

## Payout multiplier for a fully-watched ad of `watched_secs` length.
## Skipped/too-short -> 0 (no reward; the caller keeps the base payout).
func reward_mult(watched_secs: float) -> float:
        if watched_secs >= float(tier_secs("full")):
                return 1.0
        if watched_secs >= float(tier_secs("p75")):
                return 0.75
        if watched_secs >= float(tier_secs("half")):
                return 0.5
        return 0.0

func reward_hint() -> String:
        return "watch %ds+ = half  ·  %ds+ = 75%%  ·  %ds = full reward" % [
                        tier_secs("half"), tier_secs("p75"), tier_secs("full")]

## Call the owner callback with as many args as it declared (legacy 1-arg
## lambdas keep working; new callers get [watched, mult, watch_seconds]).
func _resolve_cb(watched: bool, mult: float, secs: float) -> void:
        if not _pending_cb.is_valid():
                return
        var cb := _pending_cb
        _pending_cb = Callable()
        if cb.get_argument_count() >= 3:
                cb.call(watched, mult, secs)
        else:
                cb.call(watched)

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
        _pending_since_ms = 0
        if native and native.is_loaded(placement("rewarded")):
                _showing = true
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
        _pending_since_ms = 0
        if native and native.is_loaded(placement("interstitial")):
                _showing = true
                native.show(placement("interstitial"))
        else:
                native.load(placement("interstitial"))

func banner_show() -> void:
        if not enabled_ok() or not bool(cfg.banner_enabled):
                return
        if desktop_sim:
                banner_shown_changed.emit(true)
                return
        _banner_wanted = true
        if native and ready_ok:
                native.banner_show(placement("banner"))
        banner_shown_changed.emit(true)

func banner_hide() -> void:
        if desktop_sim:
                banner_shown_changed.emit(false)
                return
        _banner_wanted = false
        if native and ready_ok:
                native.banner_hide()
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
        if _banner_wanted and native:
                native.banner_show(placement("banner"))

func _on_native_init_failed() -> void:
        ready_ok = false

func _on_native_loaded(placement_id: String) -> void:
        # if something was waiting for a load, show it now
        _load_retries[placement_id] = 0
        if _pending_cb.is_valid() and (placement_id == placement("rewarded") \
                        or placement_id == placement("interstitial")):
                _showing = true
                native.show(placement_id)

func _on_native_failed(placement_id: String, _message: String) -> void:
        # load/show failed: NEVER leave the caller's callback dangling (this was
        # the "back to box hangs" bug). Retry ONCE quietly, then skip the ad.
        _showing = false
        if not _pending_cb.is_valid():
                return
        var kind := _kind_of(placement_id)
        if kind == "":
                return
        var tries := int(_load_retries.get(placement_id, 0))
        if tries < 1 and native != null:
                _load_retries[placement_id] = tries + 1
                native.load(placement_id)   # loaded -> _on_native_loaded shows it
                return
        _load_retries[placement_id] = 0
        _resolve_cb(false, 0.0, 0.0)

func _kind_of(placement_id: String) -> String:
        if placement_id == placement("rewarded"):
                return "rewarded"
        if placement_id == placement("interstitial"):
                return "interstitial"
        return ""

func _process(_delta: float) -> void:
        # watchdog: if a pending ad never resolves (no fill + no failed event),
        # release the caller after 8s so the game never stalls. While an ad is
        # actually SHOWING (can be 30s+), the watchdog stays paused.
        if not _pending_cb.is_valid() or _showing:
                return
        if _pending_since_ms == 0:
                _pending_since_ms = Time.get_ticks_msec()
                return
        if Time.get_ticks_msec() - _pending_since_ms > 8000:
                var cb := _pending_cb
                _pending_cb = Callable()
                _pending_since_ms = 0
                if cb.get_argument_count() >= 3:
                        cb.call(false, 0.0, 0.0)
                else:
                        cb.call(false)

## Fired when an ad actually starts playing - the watch-time clock starts here
## (tiers need REAL seconds watched, not time since request).
func _on_native_shown(_placement_id: String) -> void:
        _ad_start_ms = Time.get_ticks_msec()

## GDScript-side banner safety net: if the native loader gives up (no fill
## twice), we keep trying every 12s while the banner is still wanted. Together
## with the Java-side retry loop this makes "banner never came back" impossible.
func _schedule_banner_retry() -> void:
        if not _banner_wanted or _banner_retrying or not ready_ok or native == null:
                return
        _banner_retrying = true
        var t := get_tree().create_timer(12.0)
        t.timeout.connect(func():
                _banner_retrying = false
                if _banner_wanted and ready_ok and native != null:
                        native.banner_show(placement("banner")))

func _on_native_closed(placement_id: String, completion_state: int) -> void:
        # UnityAdsShowCompletionState ordinals: SKIPPED=0, COMPLETED=1
        var watched := completion_state >= 1  # SKIPPED=0, COMPLETED=1 (ordinal)
        _showing = false
        _pending_since_ms = 0
        # watch-time = show-start -> close. This drives the tiered payout:
        # 15s+ = half, 20s+ = 75%, 30s+ = full (reward_tiers in config).
        var secs := 0.0
        if _ad_start_ms > 0:
                secs = float(Time.get_ticks_msec() - _ad_start_ms) / 1000.0
        _ad_start_ms = 0
        var mult := reward_mult(secs) if watched else 0.0
        _resolve_cb(watched, mult, secs)

# ------------------------------------------------------------------ desktop sim

func _simulate(rewarded: bool, cb: Callable) -> void:
        var t := get_tree().create_timer(0.15)
        t.timeout.connect(func():
                if rewarded:
                        # simulated user always watches a full-length ad
                        var full := float(tier_secs("full"))
                        if cb.get_argument_count() >= 3:
                                cb.call(true, 1.0, full)
                        else:
                                cb.call(true)
                else:
                        if cb.get_argument_count() >= 3:
                                cb.call(true, 1.0, 0.0)
                        else:
                                cb.call(true)
        )
