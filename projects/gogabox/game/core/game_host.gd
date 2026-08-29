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
        var fee := int(g["fee"])
        var free_play := fee > 0 and Box.coins() < Box.cheapest_owned_fee()
        if fee > 0 and not free_play:
                if not Box.spend(fee):
                        return false
                Box.add_spent(id, fee)
        var host: Node = load("res://game/core/host_node.gd").new()
        host.configure(g, router, fee, free_play)
        router.add_child(host)
        active_host = host
        return true

static func end_session() -> void:
        if active_host != null and is_instance_valid(active_host):
                active_host.queue_free()
        active_host = null
