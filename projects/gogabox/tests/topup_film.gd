extends Node
## v040-8 THE TOP-UP FILM - the wallet tap, the balance sheet, the vertical
## card picker, a game's exchange screen, the confirmation. Eyed before the
## owner has to see it.

var menu: Node2D
var shot_dir := "/tmp/topup_film"

func _wait(t: float) -> void:
        await get_tree().create_timer(t, true).timeout

func _shot(name: String) -> void:
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        img.save_png("%s/%s.png" % [shot_dir, name])
        print("[FILM] shot ", name)

func _run() -> void:
        DirAccess.make_dir_recursive_absolute(shot_dir)
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        Box.earn(1234)
        GameCoin.add("heavywar", 777)
        GameCoin.add("rockbreaker", 4321)
        get_window().size = Vector2i(1080, 1920)
        ScaleRule.apply(get_window())
        await _wait(0.3)
        menu = Node2D.new()
        menu.set_script(load("res://game/menu/menu.gd"))
        add_child(menu)
        menu.set("router", self)
        await _wait(0.8)
        await _shot("01_box")

        # THE WALLET TAP LAW: the balance sheet
        menu.call("_open_topup")
        await _wait(0.5)
        await _shot("02_balance")

        # the picker: vertical cards
        menu.call("_open_topup_picker")
        await _wait(0.5)
        await _shot("03_picker")

        # a game's exchange screen (rockbreaker)
        menu.call("_open_topup_game", "rockbreaker")
        await _wait(0.5)
        await _shot("04_exchange")

        # type an amount -> the live preview
        var field: LineEdit = menu._root.get_children()[-1].find_children(
                "*", "LineEdit", true, false)[0]
        field.text = "100"
        field.text_changed.emit("100")
        await _wait(0.4)
        await _shot("05_amount")

        # the confirmation
        menu.call("_topup_confirm", "rockbreaker", 100)
        await _wait(0.5)
        await _shot("06_confirm")

        # v040-12 THE CANCEL ROUND TRIP: CANCEL walks back to a rebuilt
        # exchange WITH the typed amount in the FIELD too (the old bug:
        # the preview kept the number, the field read 0)
        menu.call("_open_topup_game", "rockbreaker", 100)
        await _wait(0.5)
        await _shot("06b_cancel_roundtrip")

        # settle for real: the wallets move
        menu.call("_topup_settle", "rockbreaker", 100, 500)
        await _wait(0.6)
        await _shot("07_settled")
        print("[FILM] rockcoins after settle: ", GameCoin.balance("rockbreaker"))
        print("[FILM] coins after settle: ", Box.coins())
        print("[FILM] done")
        get_tree().quit()

func on_game_entered() -> void:
        pass

func on_game_closed() -> void:
        pass

func _ready() -> void:
        _run.call_deferred()
