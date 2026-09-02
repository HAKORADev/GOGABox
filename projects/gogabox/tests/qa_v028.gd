extends Node
## qa_v028 - the v0.2.8 visual QA (the owner's rule: LOOK before shipping).
## 2048: the warm CLASSIC paper (the blue is gone), the coin cell AND its
## ERASE after the take, the sea water CALM when still vs TILTED on a real
## slide, the OPTIONS sheet, the 6x6 board. XO: the sketch page (board,
## widget, notes), a live game with X/O pops, the winning strike, the coin
## race. Run under Xvfb:
##   DISPLAY=:99 godot --path . res://tests/qa_v028.tscn

const OUT := "/home/z/my-project/download/qa_v028/"

func _shot(path: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        img.save_png(path)
        print("[qa] ", path)

func _run() -> void:
        DirAccess.make_dir_recursive_absolute(OUT)
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)

        # ================= the 2048 =================
        var m: GogaGame = load("res://game/games/merge/merge2048.gd").new()
        m.game_id = "merge"
        add_child(m)
        await get_tree().create_timer(0.8).timeout

        # 1. the CLASSIC WARM PAPER (the owner: the blue was a mistake)
        await _shot(OUT + "01_merge_classic_warm_paper.png")

        # 2. the coin cell + its ERASE after the take
        var empty := Vector2i(-1, -1)
        for x in 4:
                for y in 4:
                        if int(m.board[x][y]) == 0:
                                empty = Vector2i(x, y)
                                break
        if empty.x >= 0:
                m.coin_cell = empty
                m.coin_t = 0.6
                await get_tree().create_timer(0.25).timeout
                await _shot(OUT + "02_merge_coin_on_board.png")
                # TAKE it, then LOOK: the coin must be GONE (the v0.2.7
                # stale-paint bug kept it hanging until the next coin)
                m._take_coin_cell()
                await get_tree().create_timer(0.12).timeout
                await _shot(OUT + "03_merge_coin_erased_after_take.png")
                _check(m.coin_cell.x < 0, "qa: the coin cell emptied on the take")

        # 3. the SEA water: CALM when still...
        Box.equip_item("merge", "theme", "sea")
        m._apply_theme()
        await get_tree().create_timer(0.8).timeout
        await _shot(OUT + "04_merge_sea_still_calm.png")
        # ...and TILTED only on a real slide
        m._on_swipe(Vector2i(-1, 0), Vector2.ZERO)
        await get_tree().create_timer(0.055).timeout
        await _shot(OUT + "05_merge_sea_slide_tilt.png")
        await get_tree().create_timer(0.6).timeout

        # 4. the OPTIONS sheet (the board sizes)
        Box.equip_item("merge", "theme", "classic")
        m._apply_theme()
        m._options_open()
        await get_tree().create_timer(0.35).timeout
        await _shot(OUT + "06_merge_options_sizes.png")
        m._options_close()

        # 5. the 6x6 board (bigger, centered, fresh)
        m._apply_size("6")
        await get_tree().create_timer(0.4).timeout
        await _shot(OUT + "07_merge_six_by_six.png")
        m._apply_size("4")
        m.queue_free()

        # ================= XO =================
        var x: GogaGame = load("res://game/games/xo/xo.gd").new()
        x.game_id = "xo"
        add_child(x)
        await get_tree().create_timer(0.5).timeout

        # 6. the fresh sketch page (board + widget + notes)
        await _shot(OUT + "08_xo_fresh_board.png")

        # 7. a live game: X and O strokes popped in
        x.board = [1, 0, 0, 0, 2, 0, 0, 0, 0]
        x._place(0, x.X)
        await get_tree().create_timer(0.15).timeout
        x._place(4, x.O)
        await get_tree().create_timer(0.1).timeout
        x._place(3, x.X)
        await get_tree().create_timer(0.12).timeout
        await _shot(OUT + "09_xo_marks_mid_game.png")

        # 8. the coin round (the coin waits in a cell)
        x.done_rounds = 3
        x._new_round()
        if x.coin_cell >= 0:
                await get_tree().create_timer(0.3).timeout
                await _shot(OUT + "10_xo_coin_on_board.png")

        # 9. the winning strike + the verdict
        x.board = [1, 1, 0, 2, 2, 0, 0, 0, 0]
        x.turn = x.X
        x.state = "play"
        x._tap_cell(2)
        await get_tree().create_timer(0.4).timeout
        await _shot(OUT + "11_xo_win_strike.png")

        # 10. the CPU thinking banner (a profile name + dots)
        await get_tree().create_timer(1.6).timeout
        await _shot(OUT + "12_xo_cpu_turn.png")

        print("[qa] done")
        get_tree().quit(0)

var _fails := 0
func _check(cond: bool, msg: String) -> void:
        print(("  [qa-PASS] " if cond else "  [qa-FAIL] ") + msg)
        if not cond:
                _fails += 1

func _ready() -> void:
        _run.call_deferred()
