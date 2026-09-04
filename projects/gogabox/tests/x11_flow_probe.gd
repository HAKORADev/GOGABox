extends Node
## X11 REAL-FLOW driver: boots the actual merge game through GameHost,
## opens the real are-you-sure confirm, prints window-space rects of the
## live buttons, then keeps printing the sheet STATE so the bash driver can
## watch what the X11 clicks actually did.

var game: GogaGame
var last := ""

func _ready() -> void:
        Box.dev_set_cheat("all_owned", 1)
        var ok := GameHost.launch(self, "merge")
        print("LAUNCH ok=", ok)
        if not ok:
                get_tree().quit(1)
                return
        for i in 30:
                await get_tree().create_timer(0.5).timeout
                if GameHost.active_host != null and GameHost.active_host.game != null:
                        break
        game = GameHost.active_host.game
        print("GAME ", game.game_id, " ok")
        game._options_open()
        await get_tree().create_timer(0.5).timeout
        _dump_buttons("OPTIONS")
        game._size_confirm("6", false)
        await get_tree().create_timer(0.5).timeout
        _dump_buttons("CONFIRM")

func _dump_buttons(tag: String) -> void:
        var st: Transform2D = game.get_viewport().get_screen_transform()
        _walk(game._overlay_root_ref(), tag, st)
        print("RESULT DUMPED ", tag)

func _walk(n: Node, tag: String, st: Transform2D) -> void:
        for c in n.get_children():
                if c is Button:
                        var b := c as Button
                        var gp: Vector2 = st * b.get_global_rect().position
                        var gs: Vector2 = b.get_global_rect().size * st.get_scale()
                        print("BTN %s '%s' win=(%d,%d %dx%d)" % [tag, b.text, int(gp.x), int(gp.y), int(gs.x), int(gs.y)])
                _walk(c, tag, st)

var _btns := 0
func _process(_d: float) -> void:
        if game == null:
                return
        var root: Control = game._overlay_root_ref()
        if root == null:
                return
        _btns = 0
        _count(root)
        var line := "STATE btns=%d paused=%s over=%s" % [_btns, str(get_tree().paused), str(game.over)]
        if line != last:
                last = line
                print(line)

func _count(n: Node) -> void:
        for c in n.get_children():
                if c is Button:
                        _btns += 1
                _count(c)
