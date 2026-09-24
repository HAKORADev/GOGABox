class_name Meta
extends RefCounted
## Modular game metadata vocabulary for GOGABox: main genres and sub genres.
## Mirrors HAKORADev/GameBox limits: a game carries up to 3 main
## categories and up to 3 sub categories; every list here is open - add an id
## and (optionally) an icon and the search filter + game pages pick it up
## automatically. Unknown ids degrade to text-only chips, never crash.

const MAIN_LIMIT := 3
const SUB_LIMIT := 3

## Main genres (id -> label + optional icon under assets/meta/).
const GENRES := {
        "arcade": {"label": "Arcade", "icon": "res://assets/meta/genre_arcade.png"},
        "action": {"label": "Action", "icon": "res://assets/meta/genre_action.png"},
        "puzzle": {"label": "Puzzle", "icon": "res://assets/meta/genre_puzzle.png"},
        "adventure": {"label": "Adventure", "icon": "res://assets/meta/genre_adventure.png"},
        "shooter": {"label": "Shooter", "icon": "res://assets/meta/genre_shooter.png"},
        "racing": {"label": "Racing", "icon": "res://assets/meta/genre_racing.png"},
        "kids": {"label": "Kids", "icon": "res://assets/meta/genre_kids.png"},
        "music": {"label": "Music", "icon": "res://assets/meta/genre_music.png"},
        "story": {"label": "Story", "icon": "res://assets/meta/genre_story.png"},
        "strategy": {"label": "Strategy", "icon": ""},
        "casual": {"label": "Casual", "icon": ""},
        "simulation": {"label": "Simulation", "icon": ""},
        "sports": {"label": "Sports", "icon": ""},
        "rpg": {"label": "RPG", "icon": ""},
        "sci-fi": {"label": "Sci-Fi", "icon": ""},
        "sandbox": {"label": "Sandbox", "icon": ""},
        "party": {"label": "Party", "icon": ""},
        "horror": {"label": "Horror", "icon": ""},
        "educational": {"label": "Educational", "icon": ""},
}

## Sub genres (subset of GameBox's SUB_CATEGORIES that GOGA games actually
## use; more can be added any time - label-only chips are fine).
const SUBS := {
        "retro": {"label": "Retro", "icon": "res://assets/meta/sub_retro.png"},
        "singleplayer": {"label": "Singleplayer", "icon": "res://assets/meta/sub_singleplayer.png"},
        "survival": {"label": "Survival", "icon": "res://assets/meta/sub_survival.png"},
        "competitive": {"label": "Competitive", "icon": "res://assets/meta/sub_competitive.png"},
        "hacknslash": {"label": "Hack'n'Slash", "icon": "res://assets/meta/sub_hacknslash.png"},
        "platformer": {"label": "Platformer", "icon": "res://assets/meta/sub_platformer.png"},
        "minimal": {"label": "Minimal", "icon": "res://assets/meta/sub_minimal.png"},
        "turnbased": {"label": "Turn-based", "icon": "res://assets/meta/sub_turnbased.png"},
        "rhythm": {"label": "Rhythm", "icon": ""},
        "tower-defense": {"label": "Tower Defense", "icon": ""},
        "procedural": {"label": "Procedural", "icon": ""},
        "pixel": {"label": "Pixel", "icon": ""},
}

# v0.3.4-3 THE PLATFORM LAW (the windows return): every game wears an os
# tag (the badge on all games; platform exclusives become possible later).
# v0.4.1: the tags wear ICONS (assets/meta/os_*.png) and return to every
# pre-play header (they lived in search + guide only).
const OS_TAGS := {
        "android": {"label": "PHONE", "icon": "res://assets/meta/os_android.png"},
        "pc": {"label": "PC", "icon": "res://assets/meta/os_pc.png"},
}

# v0.4.1 THE CONTROLS TAGS (the owner: "add controls tags that reflect the
# game controls with cool icons like hand finger for touch and keyboard and
# mouse for mouse+keyboard and gamepad for gamepad"). A registry entry
# carries "ctrl": a list of these ids; the honest fallback (no key) is
# touch + mouse+keys when PC control lines exist + gamepad when the game
# declares the seat ("gamepad": true). Same design language as the tags.
const CTRL_TAGS := {
        "touch": {"label": "TOUCH", "icon": "res://assets/meta/ctrl_touch.png"},
        "mkb": {"label": "MOUSE + KEYS", "icon": "res://assets/meta/ctrl_mkb.png"},
        "pad": {"label": "GAMEPAD", "icon": "res://assets/meta/ctrl_pad.png"},
}

## The control-scheme chips for one registry entry.
static func ctrl_list(g: Dictionary) -> Array:
        var out: Array = []
        if g.has("ctrl"):
                for c in g["ctrl"]:
                        out.append(String(c))
                return out
        out.append("touch")
        if not (g.get("controls_pc", []) as Array).is_empty():
                out.append("mkb")
        if bool(g.get("gamepad", false)):
                out.append("pad")
        return out

static func ctrl_label(id: String) -> String:
        if CTRL_TAGS.has(id):
                return String(CTRL_TAGS[id]["label"])
        return id.to_upper()

# v042 THE LAN TAGS (the multi-level vocabulary, the owner: "make sure LAN
# tagging/support is like, many different levels, one is phone only, one is
# PC only, one is both, one is 2P or 3P or 4P and one is a game that
# supports both platforms but LAN is for one platform only too"). A registry
# entry carries "lan": {"players": 2..4, "platforms": [...], "cross": bool};
# the derived chips below ride the search sheet, the pre-play tags and the
# PLAYERS badge (its own area - never a genre badge).
const LAN_TAGS := {
        "lan": {"label": "LAN"},
        "lan_phone": {"label": "LAN PHONE"},
        "lan_pc": {"label": "LAN PC"},
        "lan_cross": {"label": "LAN CROSS"},
        "lan_2p": {"label": "LAN 2P"},
        "lan_3p": {"label": "LAN 3P"},
        "lan_4p": {"label": "LAN 4P"},
}

## The derived LAN chips for one registry entry (empty = out of radar).
static func lan_list(g: Dictionary) -> Array:
        var lan: Dictionary = g.get("lan", {})
        if lan.is_empty():
                return []
        var out: Array = ["lan"]
        var plats: Array = lan.get("platforms", [])
        var cross := bool(lan.get("cross", false))
        if cross and plats.has("android") and plats.has("pc"):
                out.append("lan_cross")
        else:
                if plats.has("android"):
                        out.append("lan_phone")
                if plats.has("pc"):
                        out.append("lan_pc")
        var players := int(lan.get("players", 0))
        if players >= 2:
                out.append("lan_%dp" % mini(players, 4))
        return out

static func lan_label(id: String) -> String:
        if LAN_TAGS.has(id):
                return String(LAN_TAGS[id]["label"])
        return id.to_upper()

## The PLAYERS badge text (its own badge area on cards + the pre-play
## header): "PLAYERS 2-4" for a LAN game, "PLAYERS 1" never shows - a
## single-seat game is OUT OF RADAR (the LAN spec's own law).
static func players_badge(g: Dictionary) -> String:
        var lan: Dictionary = g.get("lan", {})
        if lan.is_empty():
                return ""
        var players := int(lan.get("players", 0))
        if players < 2:
                return ""
        return "PLAYERS 2-%d" % mini(players, 4)

static func genre_label(id: String) -> String:
        if GENRES.has(id):
                return String(GENRES[id]["label"])
        return id.capitalize()

static func sub_label(id: String) -> String:
        if SUBS.has(id):
                return String(SUBS[id]["label"])
        return id.capitalize()

static func os_label(id: String) -> String:
        if OS_TAGS.has(id):
                return String(OS_TAGS[id]["label"])
        return id.to_upper()

static func icon_for(kind: String, id: String) -> String:
        # kind: "genre" | "sub" | "os" | "ctrl"
        var table := {}
        match kind:
                "genre": table = GENRES
                "sub": table = SUBS
                "os": table = OS_TAGS
                "ctrl": table = CTRL_TAGS
        if table.has(id) and String(table[id].get("icon", "")) != "":
                return String(table[id]["icon"])
        return ""

## All ids currently used by registry games (feeds the filter sheet; grows
## automatically as games adopt new genres).
static func used_genres() -> Array:
        var out := []
        for g in GameReg.GAMES:
                for gid in (g.get("genres", {}).get("main", []) as Array):
                        if not out.has(String(gid)):
                                out.append(String(gid))
        return out

static func used_subs() -> Array:
        var out := []
        for g in GameReg.GAMES:
                for sid in (g.get("genres", {}).get("sub", []) as Array):
                        if not out.has(String(sid)):
                                out.append(String(sid))
        return out

