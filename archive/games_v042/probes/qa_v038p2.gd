extends Node
## qa_v038p2 - the v0.3.8-2 rigs: COSMIC SPUD'S DEEP ROOTS, watched.
## Rigs (QA_RIG env):
##  door     - the boot door: the six starts on the raw-touch shelf + the
##             new STATS button in the action row
##  shop     - THE SHOP's universal list (GOGACoins shelves on a BoxScroll)
##  armory   - the armory ALLIES tab: a drone owned at LV 2 wearing the
##             RAISE row with its pips + the next-level line
##  stats    - THE STAT TRACKS: 3 tracks owned mid-way, the pips + the
##             next-level green lines + the BUY ladder prices
##  skills   - THE SKILLS with ghost_round raised to L2 (RAISE button + pips)
##  market   - the wave market mid-break: the purse header + the shelves
##
##  QA_RIG=<rig> xvfb-run -a godot --path . res://tests/qa_v038p2.tscn

var frames := 0
var rig_id := ""

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        var rig := OS.get_environment("QA_RIG")
        if rig.is_empty():
                rig = "door"
        rig_id = rig
        DirAccess.make_dir_recursive_absolute("/tmp/qa_v038p2")
        var G: GogaGame = load("res://game/games/cosmic_spud/cosmic_spud.gd").new()
        G.game_id = "cosmic_spud"
        add_child(G)
        for i in 40:
                await get_tree().process_frame
        var meta: CSMeta = G.meta
        # a lived-in save: coins, a raise, owned tracks, a raised skill
        meta.d["coins"] = 4200
        meta.d["kills"] = 640
        meta.d["stat_pts"] = 7
        meta.d["stat_tracks"] = {"dmg": 2, "hp": 1, "luck": 3}
        meta.d["skills"] = {"ghost_round": 2, "golden_gut": 1}
        meta.d["owned_allies"] = ["drone", "medic"]
        meta.d["ally_lv"] = {"drone": 2, "medic": 1}
        meta.save()
        G._cc_pull()
        match rig:
                "door":
                        await _door(G)
                "shop":
                        await _shop(G)
                "armory":
                        await _armory(G)
                "stats":
                        await _stats(G)
                "skills":
                        await _skills(G)
                "market":
                        await _market(G)
        print("[qa_v038p2] rig %s done: %d frames" % [rig_id, frames])
        get_tree().quit(0)

func _settle(n: int) -> void:
        for i in n:
                await get_tree().process_frame

func _snap(tag: String) -> void:
        await _settle(3)
        var img := get_viewport().get_texture().get_image()
        var path := "/tmp/qa_v038p2/%s_%s_%03d.png" % [tag, rig_id, frames]
        img.save_png(path)
        frames += 1

func _door(G: GogaGame) -> void:
        await _settle(20)
        await _snap("door")
        # the scroll truth ON CAMERA: drag the shelf from a start card
        G._shop_open()
        await _settle(10)
        await _snap("door_shop")

func _shop(G: GogaGame) -> void:
        G._shop_open()
        await _settle(15)
        await _snap("shop")

func _armory(G: GogaGame) -> void:
        G._armory_tab = "allies"
        G._armory_open()
        await _settle(15)
        await _snap("armory")

func _stats(G: GogaGame) -> void:
        G.phase = "boot"
        G._stats_menu_open()
        await _settle(15)
        await _snap("stats")

func _skills(G: GogaGame) -> void:
        G.phase = "boot"
        G._skills_menu_open()
        await _settle(15)
        await _snap("skills")

func _market(G: GogaGame) -> void:
        G._start_run()
        await _settle(10)
        G.phase = "break"
        G.run_wave = 4
        G._roll_shop_offers()
        G._market_open()
        await _settle(15)
        await _snap("market")
