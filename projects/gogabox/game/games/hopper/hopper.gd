extends GogaGame
## Snowy Tower — climb forever. Tap left/right half to hop that way, land on
## platforms as they scroll down; camera follows height. Slip = run over.

const GRAV := 2200.0
const JUMP_V := -900.0

var world: Node2D
var player: Sprite2D
var vy := 0.0
var vx := 0.0
var playing := true
var cam_y := 0.0
var highest := 0.0
var platforms: Array = []     # {node, x, y, w}
var spawn_y := 0.0
var hops := 0

var _plat_tex: Texture2D
var _snowball: Texture2D

func _goga_setup() -> void:
        tk.tapped.connect(_on_tap)
        _plat_tex = load("res://assets/games/hopper/platform.png")
        _snowball = load("res://assets/games/hopper/player.png")
        _build()
        set_hud_score_prefix("HEIGHT")
        set_score(0)

func _build() -> void:
        var vp := get_viewport_rect().size
        var bg := ColorRect.new()
        bg.color = Color("bfe3f5")
        bg.size = vp
        bg.z_index = -10
        bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(bg)  # static sky: does NOT scroll with the world
        world = Node2D.new()
        add_child(world)

        player = Sprite2D.new()
        player.texture = _snowball
        player.position = Vector2(vp.x / 2.0, vp.y - 220)
        world.add_child(player)

        # starting platform right under the player
        _spawn_platform(vp.x / 2.0, vp.y - 160, true)
        # prefill upward
        var next_y := vp.y - 260
        while next_y > cam_y - 200:
                _spawn_platform(randf_range(90, vp.x - 90), next_y)
                next_y -= randf_range(110, 165)

func _spawn_platform(x: float, y: float, wide := false) -> void:
        var s := Sprite2D.new()
        s.texture = _plat_tex
        var w := randf_range(190, 260) if not wide else 300.0
        s.scale = Vector2(w / 300.0, 1.0)
        s.position = Vector2(x, y)
        world.add_child(s)
        platforms.append({"node": s, "x": x, "y": y, "w": w})
        spawn_y = minf(spawn_y, y)

func _on_tap(pos: Vector2) -> void:
        if not playing:
                return
        var vp := get_viewport_rect().size
        var side := -1.0 if pos.x < vp.x / 2.0 else 1.0
        vy = JUMP_V
        vx = side * 330.0
        hops += 1
        achievement_count("hops", 1)
        Jukebox.sfx("hop", -6.0, 1.0 + randf() * 0.1)

func _goga_tick(delta: float) -> void:
        if not playing:
                return
        var vp := get_viewport_rect().size
        vy += GRAV * delta
        player.position.y += vy * delta
        player.position.x += vx * delta
        vx = lerpf(vx, 0.0, 2.2 * delta)
        player.position.x = clampf(player.position.x, 40, vp.x - 40)
        player.rotation += vx * delta * 0.004

        # land: only when falling
        if vy > 0:
                for p in platforms:
                        var top: float = float(p["y"]) - 22.0
                        if player.position.y >= top and player.position.y <= top + 26.0 + vy * delta \
                                        and absf(player.position.x - float(p["x"])) < float(p["w"]) / 2.0 + 16.0:
                                player.position.y = top
                                vy = 0
                                vx *= 0.5
                                Jukebox.sfx("land", -14.0)
                                break

        # camera follows player upward only
        var target_cam := minf(cam_y, player.position.y - vp.y * 0.55)
        cam_y = lerpf(cam_y, target_cam, 1.0 - pow(0.001, delta))
        world.position.y = -cam_y

        # height score (px climbed relative to start)
        var climbed := maxf(0.0, (vp.y - 220.0) - player.position.y + maxf(0.0, -cam_y))
        highest = maxf(highest, climbed)
        set_score(int(climbed))
        achievement_max("max_height", int(climbed))

        # spawn platforms above, cull below
        if spawn_y > cam_y - 100:
                spawn_y -= randf_range(110, 165)
                _spawn_platform(randf_range(90, vp.x - 90), spawn_y)
        for p in platforms.duplicate():
                if float(p["y"]) > cam_y + vp.y + 140:
                        platforms.erase(p)
                        (p["node"] as Sprite2D).queue_free()

        # fell off the bottom
        if player.position.y > cam_y + vp.y + 60:
                playing = false
                Jukebox.sfx("boom", -4.0)
                check_achievements()
                var tw := create_tween()
                tw.tween_property(world, "modulate", Color(0.7, 0.8, 1.0, 0.6), 0.3)
                tw.tween_callback(func(): finish_run(score))
