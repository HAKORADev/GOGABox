class_name Loader
extends CanvasLayer
## The universal GOGABox pre-launch loading screen. Every game gets it:
##   - warm dark veil + the game's thumbnail in a rounded frame
##   - an animated scan bar sweeping the thumb (feels alive, hides any hitch)
##   - real loading: the game script + its asset textures load during the show
##   - progress bar + % + rotating tips; "READY!" flash; fade-out
##
## Usage: await Loader.load_game(host, game_def)
## Minimum showtime keeps it satisfying even when loading is instant.

const MIN_SHOW := 1.5
const TIPS := [
        "tip: GOGACoins are shared by every game in the box",
        "tip: high scores and achievements live here forever",
        "tip: mystery tiles hide orders - complete them for surprises",
        "tip: entry fees keep the arcade honest. earn them back!",
        "tip: watch an ad after a run to DOUBLE your coins",
]

static func load_game(parent: Node, g: Dictionary) -> void:
        var l: Loader = load("res://game/core/loader.gd").new()
        l.layer = 30
        parent.add_child(l)
        await l._run(g)

func _run(g: Dictionary) -> void:
        var W := 720.0
        var H := 1280.0
        var vp := get_viewport().get_visible_rect().size
        W = vp.x
        H = vp.y

        var root := Control.new()
        root.set_anchors_preset(Control.PRESET_FULL_RECT)
        root.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(root)

        var veil := ColorRect.new()
        veil.color = Color(0.11, 0.06, 0.02, 1.0)
        veil.set_anchors_preset(Control.PRESET_FULL_RECT)
        veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
        root.add_child(veil)

        # CenterContainer keeps the block centered in ANY viewport (expand aspect
        # grows the viewport on tall phones - anchoring a VBox to 0.5 without
        # centering offsets shoved everything to the bottom-right).
        var center := CenterContainer.new()
        center.set_anchors_preset(Control.PRESET_FULL_RECT)
        center.mouse_filter = Control.MOUSE_FILTER_IGNORE
        root.add_child(center)

        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 18)
        v.alignment = BoxContainer.ALIGNMENT_CENTER
        center.add_child(v)

        # ---- thumb frame with scan bar
        # v0.3.1 PATCH III (the owner: "the game thumbnail when appears, it
        # looks like a box instead of the rectangle-like shape and with
        # clipped side edges"): the frame was SQUARE (side x side) with a
        # COVERED stretch - every 3:2 thumbnail rendered as a clipped box.
        # The frame now wears the thumbnail's real aspect: the WHOLE art
        # shows, complete, exactly like everywhere else in the box.
        var frame := Panel.new()
        var sb := Arc.panel_style(Color(0, 0, 0, 0.35), 26)
        sb.border_color = Arc.ACCENT
        sb.set_border_width_all(3)
        frame.add_theme_stylebox_override("panel", sb)
        var fw := minf(380.0, W * 0.66)
        var fh := fw / 1.5          # the thumbs are 960x640 - keep them so
        frame.custom_minimum_size = Vector2(fw, fh)
        frame.clip_contents = true
        frame.size_flags_horizontal = BoxContainer.SIZE_SHRINK_CENTER
        v.add_child(frame)

        var thumb := TextureRect.new()
        var tpath := String(g.get("thumb", ""))
        thumb.texture = load(tpath) if ResourceLoader.exists(tpath) else null
        thumb.set_anchors_preset(Control.PRESET_FULL_RECT)
        thumb.offset_left = 6
        thumb.offset_top = 6
        thumb.offset_right = -6
        thumb.offset_bottom = -6
        thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
        frame.add_child(thumb)

        var scan := ColorRect.new()
        scan.color = Color(1.0, 0.72, 0.15, 0.55)
        scan.mouse_filter = Control.MOUSE_FILTER_IGNORE
        scan.size = Vector2(fw, 6)
        scan.position = Vector2(0, 10)
        frame.add_child(scan)
        var stw := scan.create_tween().set_loops()
        stw.tween_property(scan, "position:y", fh - 16.0, 0.8) \
                        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        stw.tween_property(scan, "position:y", 10.0, 0.8) \
                        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

        # ---- title + bar + percent
        var title := Arc.label(String(g.get("title", "")), 40, Arc.CARD)
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        title.size_flags_horizontal = BoxContainer.SIZE_SHRINK_CENTER
        v.add_child(title)

        var bar_bg := Panel.new()
        bar_bg.add_theme_stylebox_override("panel", Arc.panel_style(Color(0, 0, 0, 0.5), 12))
        bar_bg.custom_minimum_size = Vector2(minf(440.0, W * 0.62), 22)
        bar_bg.size_flags_horizontal = BoxContainer.SIZE_SHRINK_CENTER
        bar_bg.clip_contents = true
        v.add_child(bar_bg)
        var fill := ColorRect.new()
        fill.color = Arc.ACCENT
        fill.position = Vector2(4, 4)
        fill.size = Vector2(0, 14)
        fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
        bar_bg.add_child(fill)

        var pct := Arc.label("0%", 26, Arc.ACCENT)
        pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        pct.size_flags_horizontal = BoxContainer.SIZE_SHRINK_CENTER
        v.add_child(pct)

        var tip := Arc.label(TIPS[randi() % TIPS.size()], 20, Color(1, 0.86, 0.6, 0.85), false)
        tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        tip.size_flags_horizontal = BoxContainer.SIZE_SHRINK_CENTER
        v.add_child(tip)

        # fade the whole veil in
        root.modulate.a = 0.0
        var fin := root.create_tween()
        fin.tween_property(root, "modulate:a", 1.0, 0.22)

        # ---- actually load resources, spread across the minimum showtime
        var steps: Array = []
        var id := String(g["id"])
        if g.has("script") and ResourceLoader.exists(String(g["script"])):
                steps.append(String(g["script"]))
        steps.append(String(g.get("thumb", "")))
        for p in _game_assets(id):
                steps.append(p)
        if steps.is_empty():
                steps.append("wait")  # keep the flow honest even with nothing to load

        var t0 := Time.get_ticks_msec()
        # v0.2.4: the await rides BATCHES, not single files - the lane-dodger
        # grew into Space Dash and its asset folder jumped from 4 files to
        # ~50 real sprites; one pause per file made the loading screen take
        # seconds longer purely out of file COUNT. The progress bar still
        # breathes ~10 times, the batch size scales with the cargo.
        var every := maxi(1, int(ceil(steps.size() / 10.0)))
        for i in steps.size():
                var p := String(steps[i])
                if p != "wait" and ResourceLoader.exists(p):
                        load(p)
                if (i % every) != every - 1 and i != steps.size() - 1:
                        continue
                var done := float(i + 1) / float(steps.size())
                var elapsed := float(Time.get_ticks_msec() - t0) / 1000.0
                var show_frac := clampf(elapsed / MIN_SHOW, 0.0, 1.0)
                var prog := minf(done, show_frac * 0.55 + done * 0.45)
                fill.size.x = (bar_bg.size.x - 8.0) * prog
                pct.text = "%d%%" % int(round(prog * 100.0))
                var pause := 0.1 + randf() * 0.22
                if elapsed >= MIN_SHOW:
                        pause = 0.03
                await get_tree().create_timer(pause).timeout
        # guarantee the minimum showtime
        while float(Time.get_ticks_msec() - t0) / 1000.0 < MIN_SHOW:
                await get_tree().process_frame

        fill.size.x = bar_bg.size.x - 8.0
        pct.text = "100%"
        Jukebox.sfx("confirm", -6.0)
        await get_tree().create_timer(0.22).timeout
        var fout := create_tween()
        fout.tween_property(root, "modulate:a", 0.0, 0.3)
        await fout.finished
        queue_free()

## All textures belonging to this game (folder scan with fallback).
func _game_assets(id: String) -> Array:
        var out: Array = []
        var dir := "res://assets/games/%s" % id
        var da := DirAccess.open(dir)
        if da != null:
                da.list_dir_begin()
                var f := da.get_next()
                while f != "":
                        if not da.current_is_dir() and f.to_lower().ends_with(".png"):
                                out.append(dir + "/" + f)
                        f = da.get_next()
                da.list_dir_end()
        return out
