class_name RBMeta
extends RefCounted
## ROCK BREAKER's top-up adapter (v040-8) - the two static calls the box's
## GameCoin reads/writes (declared in the registry: rockbreaker's currency
## = ROCKCOINS, 1 GOGACoin = 5 rockCoins). The wallet is the game's own
## rb progress store - a top-up lands exactly where the run banks.

const GAME := "rockbreaker"

static func _wallet() -> Dictionary:
        var md: Dictionary = Box.get_progress(GAME, "rb", {})
        for k in ["rockcoins", "total_rockcoins"]:
                if not (md is Dictionary) or not md.has(k):
                        md[k] = 0
        return md

## THE UPGRADE LAW reads the same wallet: the static shelf prices the
## probes use (the game script owns the same consts - mirrored here so
## the adapter never loads the scene).
static func coin_balance() -> int:
        return int(_wallet().get("rockcoins", 0))

static func coin_add(n: int) -> void:
        if n <= 0:
                return
        var md := _wallet()
        md["rockcoins"] = int(md.get("rockcoins", 0)) + n
        md["total_rockcoins"] = int(md.get("total_rockcoins", 0)) + n
        Box.set_progress(GAME, "rb", md)
