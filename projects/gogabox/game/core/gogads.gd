extends Node
## GOGAds - the GOGABox in-house ad framework (v0.3.7-1, the owner's spec).
##
## THE THREE SOURCES:
##   baked  - the owner-managed ads that ship inside the app
##            (assets/gogads/index.json + the media files). A game just
##            declares TAGS per state; the picker rolls the index.
##   dev    - a developer registers their own ads at runtime
##            (register_dev_ad: tags + media path + link + link text).
##            THE SHARED SYSTEM: a dev ad also serves OTHER games that
##            define no ad of their own. only_me = 1 keeps a game's ad
##            breaks loyal to the dev's own set; 0 mixes the owner's in.
##   link   - a link ad opens the DEVICE BROWSER over an internal frame
##            (the browser fetches and plays the page/video itself; video
##            only, per the spec).
##
## THE BREAK: a game calls maybe_interstitial(game_id, "start"/"end") at
## its run start / death states. The registry entry configures the break:
##   "gogads": {"start": {"frequency": 3, "total": 6, "tags": ["puzzle"]},
##              "end":   {"frequency": 2, "total": 10, "tags": ["arcade"]}}
## frequency = an ad every Nth event of that state; total = the daily cap
## per state (the ledger resets at 12AM, lazy).
##
## THE AD SPEC (tags in English, lists in code):
##   tags  one or many (the game's content family: arcade, puzzle, ...)
##   subs  the finer cuts (horror: jumpscares/psychological; gambling:
##         slots/cards/betting; adult: straight/lgbtq/softcore/explicit;
##         violence: cartoon/fantasy/blood/gore/realistic; ...)
##   level the WTF-ometer 0..3 - 0 mild, 1 edgy, 2 heavy, 3 extreme.
##         An ad wears ONE level or a RANGE [min, max]; a break accepts
##         ads within its own level window (the registry may pin it).
##
## THE PLAYER: full-screen, works portrait + landscape, runs 10s..10min,
## skippable after the first 10s. A tap PAUSES the clock and shows the
## tappable go-to link bar at the bottom (the owner sets the text).
## Desktop never crashes: no media = a styled GOGAds card.

const TAGS := ["arcade", "puzzle", "action", "shooter", "platformer",
        "racing", "sports", "kids", "retro", "strategy", "simulation",
        "adventure", "rpg", "horror", "gambling", "adult", "casino",
        "fighting", "idle", "music", "casual", "family"]

## the finer cuts, grouped by family (the picker matches ad subs against
## the break's subs; an ad with no subs fits any break of its family)
const SUBS := {
        "violence": ["cartoon", "fantasy", "blood", "gore", "realistic"],
        "horror": ["jumpscares", "psychological", "supernatural", "creepy"],
        "gambling": ["slots", "cards", "betting", "lottery", "realistic_money"],
        "adult": ["innuendo", "softcore", "explicit", "straight", "lgbtq"],
        "illegal": ["drugs", "weapons", "theft", "fantasy_crime"],
        "general": ["family", "casual", "competitive", "retro_pixel",
                "brain", "clicker", "runner", "tower_defense"],
}

## the WTF-ometer: what a level MEANS (the picker only reads the numbers)
const LEVELS := {
        0: "mild - nothing edgy anywhere",
        1: "edgy - cartoon conflict, mild themes",
        2: "heavy - blood, dread, adult themes",
        3: "extreme - the raw stuff, adults only",
}

const SKIP_AFTER := 10.0        # the skip unlocks at 10s (the spec)
var baked: Array = []           # the owner's index (loaded at boot)
var dev_ads: Array = []         # the runtime-registered dev ads
var ledger := {}                # "game|state" -> {"day": "y-m-d", "n": int, "runs": int}

var _layer: CanvasLayer = null
var _root: Control = null
var _t := 0.0
var _dur := 10.0
var _paused := false
var _link_open := false
var _current := {}
var _on_done := Callable()

func _ready() -> void:
        _load_baked()

## THE BAKED INDEX: assets/gogads/index.json - a list of ad specs the
## owner manages. Missing file = an empty shelf (the framework still runs,
## dev ads still serve).
func _load_baked() -> void:
        baked.clear()
        var f := FileAccess.open("res://assets/gogads/index.json", FileAccess.READ)
        if f == null:
                return
        var parsed: Variant = JSON.parse_string(f.get_as_text())
        if typeof(parsed) == TYPE_ARRAY:
                for a in parsed:
                        if typeof(a) == TYPE_DICTIONARY:
                                baked.append(a)

## THE DEV DOOR: register the developer's own ad. spec:
##   {"tags": ["puzzle"], "subs": [], "level": 1, "media": "res://...png|ogv",
##    "link": "https://...", "link_text": "PLAY NOW", "duration": 12.0}
func register_dev_ad(spec: Dictionary) -> void:
        dev_ads.append(spec)

## THE ONE CALL a game makes. state: "start" | "end" (the death/finish
## state - the registry entry carries the break rules per state).
## done (optional) fires when the break closes (shown or skipped).
func maybe_interstitial(game_id: String, state: String, only_me := false,
                done := Callable()) -> void:
        var rules: Dictionary = GameReg.get_game(game_id).get("gogads", {}) \
                        .get(state, {}) as Dictionary
        if rules.is_empty():
                if done.is_valid():
                        done.call()
                return
        var key := "%s|%s" % [game_id, state]
        var today := _today()
        var l: Dictionary = ledger.get(key, {"day": today, "n": 0, "runs": 0})
        if String(l["day"]) != today:
                l = {"day": today, "n": 0, "runs": 0}   # THE 12AM RESET
        l["runs"] = int(l["runs"]) + 1
        var freq := maxi(1, int(rules.get("frequency", 1)))
        var total := int(rules.get("total", 10))
        ledger[key] = l
        var owe: bool = int(l["runs"]) % freq == 0 and int(l["n"]) < total
        if not owe:
                if done.is_valid():
                        done.call()
                return
        var ad := _pick(rules, only_me)
        if ad.is_empty():
                if done.is_valid():
                        done.call()
                return
        l["n"] = int(l["n"]) + 1
        _show(ad, done)

## THE PICKER: the break's tags/subs/level window vs the ad spec.
## only_me = 1 keeps the break loyal to the dev's registered ads.
func _pick(rules: Dictionary, only_me: bool) -> Dictionary:
        var pool: Array = []
        var want_tags: Array = rules.get("tags", []) as Array
        var want_subs: Array = rules.get("subs", []) as Array
        var lv_lo := int(rules.get("level_min", 0))
        var lv_hi := int(rules.get("level_max", 3))
        var candidates: Array = []
        if not only_me:
                candidates += baked
        candidates += dev_ads
        for ad in candidates:
                var a_tags: Array = ad.get("tags", []) as Array
                if not want_tags.is_empty() and not _hits(a_tags, want_tags):
                        continue
                var a_subs: Array = ad.get("subs", []) as Array
                if not want_subs.is_empty() and not _hits(a_subs, want_subs):
                        continue
                var lv := _ad_level(ad)
                if lv < lv_lo or lv > lv_hi:
                        continue
                pool.append(ad)
        if pool.is_empty():
                return {}
        return pool[randi() % pool.size()]

func _hits(a: Array, want: Array) -> bool:
        for w in want:
                if a.has(String(w)):
                        return true
        return false

func _ad_level(ad: Dictionary) -> int:
        var lv: Variant = ad.get("level", 0)
        if typeof(lv) == TYPE_ARRAY:
                if (lv as Array).is_empty():
                        return 0
                return int(lv[0])
        return int(lv)

## THE PLAYER: one overlay, rebuilt per break. Portrait + landscape both
## fit (the anchors cover the screen; the media keeps aspect).
func _show(ad: Dictionary, done: Callable) -> void:
        _current = ad
        _on_done = done
        _t = 0.0
        _dur = clampf(float(ad.get("duration", 12.0)), 10.0, 600.0)
        _paused = false
        _link_open = false
        if _layer != null and is_instance_valid(_layer):
                _layer.queue_free()
        _layer = CanvasLayer.new()
        _layer.layer = 95
        add_child(_layer)
        _root = Control.new()
        _root.set_anchors_preset(Control.PRESET_FULL_RECT)
        _root.mouse_filter = Control.MOUSE_FILTER_STOP
        _layer.add_child(_root)
        var veil := ColorRect.new()
        veil.color = Color(0.02, 0.02, 0.03, 0.97)
        veil.set_anchors_preset(Control.PRESET_FULL_RECT)
        veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _root.add_child(veil)
        # the media
        var media := String(_current.get("media", ""))
        if media != "" and ResourceLoader.exists(media) and media.ends_with(".png"):
                var tr := TextureRect.new()
                tr.texture = load(media)
                tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                tr.set_anchors_preset(Control.PRESET_FULL_RECT)
                tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
                _root.add_child(tr)
        else:
                # no media (or the file missed): the styled GOGAds card
                var card := PanelContainer.new()
                var sb := StyleBoxFlat.new()
                sb.bg_color = Color(0.09, 0.09, 0.13)
                sb.set_corner_radius_all(24)
                card.add_theme_stylebox_override("panel", sb)
                card.set_anchors_preset(Control.PRESET_CENTER)
                card.custom_minimum_size = Vector2(560, 320)
                _root.add_child(card)
                var cv := VBoxContainer.new()
                cv.alignment = BoxContainer.ALIGNMENT_CENTER
                card.add_child(cv)
                var head := Label.new()
                head.text = "GOGAds"
                head.add_theme_font_size_override("font_size", 44)
                head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                cv.add_child(head)
                var body := Label.new()
                body.text = String(_current.get("link_text", "an ad break"))
                body.add_theme_font_size_override("font_size", 24)
                body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                cv.add_child(body)
        # the countdown + the skip
        var hud := VBoxContainer.new()
        hud.set_anchors_preset(Control.PRESET_TOP_RIGHT)
        hud.offset_left = -220.0
        hud.offset_top = 16.0
        hud.offset_right = -16.0
        hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _root.add_child(hud)
        var cd := Label.new()
        cd.name = "Countdown"
        cd.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        cd.add_theme_font_size_override("font_size", 26)
        cd.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
        hud.add_child(cd)
        var skip := Button.new()
        skip.name = "Skip"
        skip.text = "SKIP >"
        skip.visible = false
        skip.pressed.connect(func(): _close(false))
        hud.add_child(skip)
        # the go-to link bar (hidden until a tap pauses the ad)
        var bar := Button.new()
        bar.name = "LinkBar"
        var lt := String(_current.get("link_text", "LEARN MORE"))
        bar.text = lt
        bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
        bar.offset_left = 24.0
        bar.offset_right = -24.0
        bar.offset_top = -120.0
        bar.offset_bottom = -52.0
        bar.visible = false
        bar.pressed.connect(func():
                        var link := String(_current.get("link", ""))
                        if link != "":
                                OS.shell_open(link))
        _root.add_child(bar)
        # a tap anywhere pauses + reveals the link bar (the spec)
        _root.gui_input.connect(func(e: InputEvent):
                        if e is InputEventScreenTouch \
                                        and (e as InputEventScreenTouch).pressed:
                                _paused = true
                                _link_open = true
                                (bar as Button).visible = true)
        set_process(true)

func _process(delta: float) -> void:
        if _layer == null or not is_instance_valid(_layer):
                set_process(false)
                return
        if not _paused:
                _t += delta
        if _root == null or not is_instance_valid(_root):
                return
        var cd: Label = _root.find_child("Countdown", true, false)
        var skip: Button = _root.find_child("Skip", true, false)
        if cd != null:
                var left := maxi(0, int(ceilf(_dur - _t)))
                cd.text = "%ds" % left
                if _paused and _link_open:
                        cd.text += "  -  tap the link below"
        if skip != null:
                skip.visible = _t >= SKIP_AFTER
        if _t >= _dur:
                _close(true)

func _close(finished: bool) -> void:
        # link ads open the browser over the frame (the spec: the browser
        # fetches the page/video itself)
        if finished and String(_current.get("kind", "")) == "link" \
                        and String(_current.get("link", "")) != "":
                OS.shell_open(String(_current["link"]))
        if _layer != null and is_instance_valid(_layer):
                _layer.queue_free()
        _layer = null
        _root = null
        set_process(false)
        if _on_done.is_valid():
                var cb := _on_done
                _on_done = Callable()
                cb.call()

func _today() -> String:
        var d := Time.get_date_dict_from_system()
        return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]
