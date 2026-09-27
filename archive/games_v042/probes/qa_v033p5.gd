extends Node
## qa_v033p5 - the PATCH 5 Xvfb shot driver. Boots the REAL matcher, plants
## ALL FOUR shader specials (the row + column sweeper gems wear their
## TRADED bodies - the owner's swap), fires a real banner (the purple/pink
## text-only pop-up skin), and holds for the grab. QA_MODE env picks the
## mode (default challenge); QA_BANNER=0 skips the banner; QA_THUMB=1 rigs
## the thumbnail pattern instead.
##   DISPLAY=:95 godot --path . res://tests/qa_v033p5.tscn

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
        # wait out the physics pour - no race, no guesswork
        for i in 80:
                await get_tree().create_timer(0.25).timeout
                if G.grid.size() >= 8 and not G.busy and G.phase == "play" \
                                and not G.pick_open:
                        break
        await get_tree().create_timer(1.0).timeout
        if OS.get_environment("QA_THUMB") == "1":
                await _plant_thumb_pattern()
        else:
                _plant_specials()
        if OS.get_environment("QA_BANNER") != "0":
                G._banner("ROUND CLEAR - THE POP-UP SPEAKS!", true)
        # park the pointer OUT of the board
        Input.warp_mouse(Vector2(6, 6))
        await get_tree().create_timer(0.6).timeout
        print("QA_BOARD board_o=%s cell_px=%s" % [G.board_o, G.cell_px])
        print("QA_READY %s" % mode)
        # the self-shot: no x11grab races - the viewport saves itself.
        # the banner fires HERE so the shot catches it mid-speech
        if not OS.get_environment("QA_SHOT").is_empty():
                if OS.get_environment("QA_BANNER") != "0":
                        G._banner("ROUND CLEAR - THE POP-UP SPEAKS!", true)
                await get_tree().create_timer(0.5).timeout
                var img := get_viewport().get_texture().get_image()
                img.save_png(OS.get_environment("QA_SHOT"))
                print("QA_SHOT_SAVED ", OS.get_environment("QA_SHOT"))
                print("QA_DONE")
                get_tree().quit()
                return
        await get_tree().create_timer(float(OS.get_environment("QA_HOLD")
                        if not OS.get_environment("QA_HOLD").is_empty() else "8.0")).timeout
        print("QA_DONE")
        get_tree().quit()


func _plant_specials() -> void:
        # the four shader kinds, spread on the board: 1 bomb, 2 ROW sweeper
        # (traded body), 3 COLUMN sweeper (traded body), 4 remover
        G.grid[2][2]["special"] = "bomb"
        G._dress_special(2, 2)
        G.grid[2][5]["special"] = "hyper"
        G._dress_special(2, 5)
        G.grid[5][2]["special"] = "rowh"
        G._dress_special(5, 2)
        G.grid[5][5]["special"] = "colv"
        G._dress_special(5, 5)


## the thumbnail board: the quiet weave + real shader specials - no coin,
## no floating clutter (the owner's in-game-shot law)
func _plant_thumb_pattern() -> void:
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
        G.grid[2][2]["special"] = "bomb"
        G._dress_special(2, 2)
        G.grid[2][5]["special"] = "hyper"
        G._dress_special(2, 5)
        G.grid[5][3]["special"] = "rowh"
        G._dress_special(5, 3)
