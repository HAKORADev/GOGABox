class_name GameReg
extends RefCounted
## The game list. Adding a game = add one entry here + a <id>.gd in
## game/games/<id>/<id>.gd (each game = its own folder = its own room)
## + a thumbnail assets/thumbs/<id>.png. Nothing else.
##
## Metadata carried per game (consumed by the help screen + search filters):
##   desc     one-liner shown in the ?-guide list
##   controls how to play lines (guide sheet)
##   genres   {"main": [<=3], "sub": [<=3]}   (GameBox-compatible limits)
##   charges  {"per_round": n, "capacity": n, "regen_minutes": m}  GOGABatteries (omit = free play)
##   os       ["android", "pc"] - the platforms the game runs on (THE
##            PLATFORM LAW; default both when omitted)
##   controls_pc  PC keyboard/mouse control lines (guide sheet, CONTROLS - PC)
##   hours    {"from": h, "to": h}  playable only inside the window (local time)
##   blocked_hours {"from": h, "to": h}     NOT playable inside the window
##   reveal   {"kind": "chain"|"orders"|"inbox"|"real"|"direct", ...}
##
## v0.1.5 THE SHARED UNLOCK VOCABULARY (the owner's "make it a GOGABox
## shared system" rule): EVERY way a game gets owned / played is a
## declarative registry key - a future game picks a COMBINATION, the box
## code reads the keys and never learns a new game by name. Nothing here
## replaced an older path; each version ADDED a key:
##   price + shop        buy with GOGACoins (the original path)
##   reveal.*             how the tile appears (chain/orders/inbox/real/direct)
##   reveal.needs_games  must own N games before the buy resolves
##   charge_unlock       GOGACharges meter to pour in (100/200 tiers) pre-buy
##   entry.partial_pay   thin wallet pays min(fee, ALL coins) at entry/retry
##   hours/blocked_hours time-of-day windows (live "unlocks at nn AM/PM")
##   daily_rounds / daily_minutes  per-day caps, 12AM 00:00 lazy reset
##   charges             per-game GOGABattery pool (per_round/capacity/regen)
##   lan (v042)          {"players": 2..4, "platforms": [...], "cross": bool}
##                       THE LAN SEAT - the multi-level multiplayer tag.
##                       players = the session seat ceiling; platforms =
##                       which devices may sit; cross = mixed phone+PC
##                       sessions. Omit = OUT OF RADAR (single-player, the
##                       LAN system pretends the game does not exist).
##                       Meta.lan_list(g) derives the chips (lan / lan_phone
##                       / lan_pc / lan_cross / lan_2p..4p).
##   age (v043)          int 3..21 - THE AGE LADDER tag (Meta.AGES); the
##                       pre-play play button is the ONLY reader
##   content (v043)      ["horror", "gambling", ...] - Meta.CONTENT tags
##
## v043 THE EMPTY BINARY LAW (the owner: "make the GOGAs/ folder now and
## remove all games from the main binary and make GOGABox itself an app by
## itself like engine"): GAMES is EMPTY - the box bakes zero games. Every
## game arrives as an installed GOGA package whose index/manifest speaks
## this same vocabulary, and the whole box reads games through
## GameReg.games() (baked + installed). The full v042 generation lives
## whole in archive/games_v042/ (scripts + assets + thumbs + the exact
## registry entries as the revival seed).

const GAMES := []

## v043 THE UNIFIED ENTRIES LAW: the box's own list (GAMES, empty since
## the platform split) merged with every INSTALLED GOGA package's index
## entry. The whole box reads games through THIS door - menu, search,
## pre-play, store, roadmap - so a package game behaves exactly like a
## baked one ever did. Soft dep: the GOGA runtime may not exist yet
## (boot order / bare tests); a missing runtime = baked only.
static func games() -> Array:
        var out := [] + GAMES
        if Engine.has_singleton("GOGA"):
                var rt: Object = Engine.get_singleton("GOGA")
                out.append_array(rt.entries())
        elif Engine.get_main_loop() != null:
                var root := (Engine.get_main_loop() as SceneTree).root
                if root != null and root.has_node("GOGA"):
                        out.append_array((root.get_node("GOGA") as Object).call("entries"))
        return out

static func get_game(id: String) -> Dictionary:
        for g in games():
                if String(g["id"]) == id:
                        return g
        return {}

static func playable() -> Array:
        var out := []
        for g in games():
                if g.get("coming_soon", false):
                        continue
                out.append(g)
        return out

static func workshop() -> Array:
        var out := []
        for g in GAMES:
                if not g.get("coming_soon", false):
                        continue
                out.append(g)
        return out

static func playable_index(id: String) -> int:
        var i := 0
        for g in playable():
                if String(g["id"]) == id:
                        return i
                i += 1
        return -1
