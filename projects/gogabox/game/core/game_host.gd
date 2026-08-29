class_name GameHost
extends RefCounted
## Launches a game and owns everything around a run: orientation switch,
## entry fee, run-end economy (coins, best/last, rewarded double, interstitial),
## and the game-over sheet. The menu calls GameHost.launch(...).

static var active_host: Node = null  # the live host node while a game runs

## Entry point: menu -> play. Returns false if the fee couldn't be paid.
static func launch(router: Node, id: String) -> bool:
        var g := GameReg.get_game(id)
        if g.is_empty() or g.get("coming_soon", false):
                return false
        if not Box.owns_game(id):
                return false
        if not Roadmap.window_ok(id):
                return false
        var fee := int(g["fee"])
        # anti-softlock, snake only: the starter game is ALWAYS playable.
        # Every other game requires real coins (adds value to the wallet).
        var free_play := id == "snake" and fee > 0 and Box.coins() < fee
        if fee > 0 and not free_play:
                if not Box.spend(fee):
                        return false
                Box.add_spent(id, fee)
        # GOGABatteries: charged games consume their pool + the box bank
        if not Box.consume_round_batteries(id):
                return false
        # The STAGE owns the session (hide the box, restore it after): the node
        # that answers on_game_entered/on_game_closed. v0.0.4 handed it the
        # menu, which has neither - the box stayed alive under the game (the
        # big L on device: menu visible around the board + every tap leaked).
        var stage := find_stage(router)
        if stage == null:
                stage = router          # tests / headless: plain node, no chrome
        var host: Node = load("res://game/core/host_node.gd").new()
        # host keeps the STAGE as its router: close must reach
        # stage.on_game_closed (restore the box), not an inner node that
        # happens to carry the same method name (the menu does - that
        # shadowing would leave the box hidden forever after a run).
        host.configure(g, stage, fee, free_play)
        stage.add_child(host)
        active_host = host
        if stage.has_method("on_game_entered"):
                stage.call("on_game_entered")
        return true

## Walk up to the session stage (main.gd). Capped + null-safe.
static func find_stage(node: Node) -> Node:
        var n := node
        var hops := 0
        while n != null and hops < 8:
                if n.has_method("on_game_entered"):
                        return n
                n = n.get_parent()
                hops += 1
        return null

static func end_session() -> void:
        if active_host != null and is_instance_valid(active_host):
                active_host.queue_free()
        active_host = null
