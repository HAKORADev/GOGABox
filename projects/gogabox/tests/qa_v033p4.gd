extends Node
## qa_v033p4 - the PATCH 4 Xvfb shot driver. Boots the REAL matcher for a
## chosen mode (QA_MODE env), lets the physics pour land, optionally plants
## the thumb pattern (QA_THUMB=1: a gem pattern + two REAL shader specials,
## no coin anywhere), holds for the x11grab window and quits.
##   QA_MODE=challenge QA_THUMB=1 godot --path . res://tests/qa_v033p4.tscn

var G: GogaGame

func _ready() -> void:
        Box.dev_set_cheat("all_owned", 1)
        var mode := OS.get_environment("QA_MODE")
        if mode.is_empty():
                mode = "challenge"
        G = load("res://game/games/matcher/matcher.gd").new()
        G.game_id = "matcher"
        G.mode = mode
        add_child(G)
        for i in 40:
                await get_tree().create_timer(0.25).timeout
                if G.pick_open:
                        break
        G._pick_close()
        G._start_mode(mode)
        # wait out the physics pour (busy gates it) - no race, no guesswork
        for i in 80:
                await get_tree().create_timer(0.25).timeout
                if G.grid.size() >= 8 and not G.busy and G.phase == "play" \
                                and not G.pick_open:
                        break
        # a grace beat: the settle flag flips late on some paths - let the
        # last bounces die before the grab
        await get_tree().create_timer(1.2).timeout
        if OS.get_environment("QA_THUMB") == "1":
                await _plant_thumb_pattern()
        # park the pointer OUT of the board (the thumb must be cursor-free)
        Input.warp_mouse(Vector2(6, 6))
        await get_tree().create_timer(0.6).timeout
        print("QA_BOARD board_o=%s cell_px=%s" % [G.board_o, G.cell_px])
        print("QA_READY %s" % mode)
        # the hold - the bash driver grabs the frames here
        await get_tree().create_timer(float(OS.get_environment("QA_HOLD")
                        if not OS.get_environment("QA_HOLD").is_empty() else "8.0")).timeout
        print("QA_DONE")
        get_tree().quit()


## the thumbnail board: a quiet two-tone weave + two REAL specials wearing
## the shader - no coin, no floating clutter (the owner's patch-4 verdict)
func _plant_thumb_pattern() -> void:
        # a diagonal weave with zero 3-runs
        var pattern := [
                [0, 1, 2, 3, 4, 0, 1, 2],
                [2, 3, 4, 0, 1, 2, 3, 4],
                [4, 0, 1, 2, 3, 4, 0, 1],
                [1, 2, 3, 4, 0, 1, 2, 3],
                [3, 4, 0, 1, 2, 3, 4, 0],
                [0, 1, 2, 3, 4, 0, 1, 2],
                [2, 3, 4, 0, 1, 2, 3, 4],
                [4, 0, 1, 2, 3, 4, 0, 1],
        ]
        for r in 8:
                for c in 8:
                        var cell: Dictionary = G.grid[r][c]
                        if cell.is_empty() or G._is_coin(cell) or G._is_item(cell):
                                continue
                        var col: int = pattern[r][c]
                        cell["color"] = col
                        cell["special"] = ""
                        cell["wing"] = false
                        if is_instance_valid(cell.get("node")):
                                (cell["node"] as Sprite2D).texture = G.tex_gem[col]
        # two REAL specials - the shader renders them for real on the shot
        G.grid[2][2]["special"] = "bomb"
        G._dress_special(2, 2)
        G.grid[2][5]["special"] = "hyper"
        G._dress_special(2, 5)
        G.grid[5][3]["special"] = "rowh"
        G._dress_special(5, 3)
