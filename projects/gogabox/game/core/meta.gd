class_name Meta
extends RefCounted
## Modular game metadata vocabulary for GOGABox: main genres and sub genres.
## Mirrors HAKORADev/GameBox limits: a game carries up to 3 main
## categories and up to 3 sub categories; every list here is open - add an id
## and (optionally) an icon and the search filter + game pages pick it up
## automatically. Unknown ids degrade to text-only chips, never crash.

const MAIN_LIMIT := 3
const SUB_LIMIT := 3

# v043 THE AGE LADDER RETURNS (THE APP STORE QUESTION §7 archive, the
# owner's own tier texts, SIMPLIFIED per his v043 order: "the age system
# will be simplified, a game can be discovered, downloaded, owned and
# everything by people under the age, but the button 'play nn
# goga_coins_icon' in the pre-play will just gray-out and say you must be
# +nn"). Nothing is hidden, nothing is filtered OUT of discovery - the
# ladder touches ONLY the play button (Meta.age_allowed + the pre-play
# door). The tier names below are the archive's own legal descriptions,
# shortened to chip size; the full texts live in the archive file.
const AGES := {
        "3": {"label": "+3 EVERYONE"},
        "5": {"label": "+5 SIMPLE"},
        "7": {"label": "+7 MODERATE"},
        "9": {"label": "+9 LITTLE VIOLENCE"},
        "12": {"label": "+12 YOUNG TEENS"},
        "16": {"label": "+16 TEENS"},
        "18": {"label": "+18 MATURE"},
        "21": {"label": "+21 ADULT ONLY"},
}
## THE AGE CEILING LAW: a profile with NO age number set (LanProfile.age()
## == 0) opens games up to +12 - the archive's "young teens" band is the
## default audience until the player declares themselves older. Anything
## stricter (+16/+18/+21) wears the same gray-out + lock message.
const AGE_UNSET_CEILING := 12

## v043 THE CONTENT TAGS (the owner: "i guess we made them for horror,
## gambling, politics, porn, psycho, and many other content i mean, i
## forgot what every tag was ofc" - rebuilt from the archive's own tier
## texts: porn, gore, gambling, intense horror, political-sensitive,
## psychological-intense, nudity, illegal trading; politics + psycho are
## the owner's two named adds). A game's entry carries
## "content": ["horror", ...] - chips ride search + the pages.
const CONTENT := {
        "horror": {"label": "Horror"},
        "psycho": {"label": "Psychological"},
        "gore": {"label": "Gore"},
        "porn": {"label": "Porn"},
        "gambling": {"label": "Gambling"},
        "politics": {"label": "Politics"},
        "illegal_trading": {"label": "Illegal Trading"},
        "nudity": {"label": "Nudity"},
}

## v043 THE LOWERCASE LAW (the owner: "in-game genre/sub-genre tags should
## be case-insensitive i mean if someone wrote BOarD or boARd, all will
## lead to same genre/sub-genre in the gogabox"): every tag id - genre,
## sub, content - normalizes to lowercase at READ time. Data from any
## package, any hand, any case joins the same chip and the same filter.
static func normalize_tag(id: String) -> String:
        return id.strip_edges().to_lower()

## THE AGE DOOR (the whole simplified system in one function): can this
## profile press PLAY on a game tagged `game_age`?
##   - profile age set (LanProfile.age() > 0): the game plays when the
##     profile is at least as old as the tag.
##   - profile age UNSET (0): games up to +12 play (AGE_UNSET_CEILING),
##     the rest wear the same gray-out + "you must be +nn".
## NOTHING else reads this - discovery, search, download, import, buying
## and owning all work normally under any age (the owner's simplification).
static func age_allowed(game_age: int, profile_age: int) -> bool:
        var ga := maxi(3, game_age)
        if profile_age <= 0:
                return ga <= AGE_UNSET_CEILING
        return profile_age >= ga

static func age_label(id: String) -> String:
        if AGES.has(id):
                return String(AGES[id]["label"])
        return "+" + id

static func content_label(id: String) -> String:
        if CONTENT.has(id):
                return String(CONTENT[id]["label"])
        return normalize_tag(id).capitalize()

## v043 THE DUAL THUMB LAW: a baked game's thumb is a res:// resource; an
## installed package's thumb is a FILE on disk (GOGAs/games/<id>/...).
## Every thumb seat asks here and gets a texture either way. `root` joins
## a package's RELATIVE thumb path (the index points inside the package).
static var _thumb_cache := {}
static func thumb_texture(path: String, root := "") -> Texture2D:
        if path == "":
                return null
        if path.begins_with("res://"):
                return load(path) if ResourceLoader.exists(path) else null
        var full := path
        if not full.is_absolute_path():
                if root == "":
                        return null
                full = root.path_join(path)
        if _thumb_cache.has(full):
                return _thumb_cache[full]
        if not FileAccess.file_exists(full):
                return null
        var img := Image.load_from_file(full)
        if img == null:
                return null
        var tex := ImageTexture.create_from_image(img)
        _thumb_cache[full] = tex
        return tex

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

## All ids currently used by the unified entries (baked + installed; feeds
## the filter sheet; grows automatically as games adopt new genres).
## v043: every id rides THE LOWERCASE LAW on the way out.
static func used_genres() -> Array:
        var out := []
        for g in GameReg.games():
                for gid in (g.get("genres", {}).get("main", []) as Array):
                        var sid := normalize_tag(String(gid))
                        if sid != "" and not out.has(sid):
                                out.append(sid)
        return out

static func used_subs() -> Array:
        var out := []
        for g in GameReg.games():
                for sid in (g.get("genres", {}).get("sub", []) as Array):
                        var sid2 := normalize_tag(String(sid))
                        if sid2 != "" and not out.has(sid2):
                                out.append(sid2)
        return out

## v043 the content-tag census (the search CONTENT row feeds off this).
static func used_contents() -> Array:
        var out := []
        for g in GameReg.games():
                for cid in (g.get("content", []) as Array):
                        var sid := normalize_tag(String(cid))
                        if sid != "" and not out.has(sid):
                                out.append(sid)
        return out

## v043 THE SELF-LEARNING INDEX (the owner: "add a feature in the search
## engine of GOGABox to index games genres/sub-genres to detect unsupported
## keywords, when there is +10 games in the user library have same
## genre/sub-genre, then index it too"). `entries` = the unified entries,
## `owns` = Callable(id) -> bool (the user-library check). A tag NOT in the
## const tables that >= LEARN_THRESHOLD owned games share becomes a
## first-class filter chip. Returns the learned ids per kind; the caller
## persists them (Box meta) so the index survives restarts.
const LEARN_THRESHOLD := 10

static func learn_tags(entries: Array, owns: Callable) -> Dictionary:
        var tally := {"genre": {}, "sub": {}}
        for g in entries:
                var gid := String(g["id"])
                if not bool(owns.call(gid)):
                        continue
                var geo: Dictionary = g.get("genres", {})
                for kind in ["genre", "sub"]:
                        for raw in (geo.get("main" if kind == "genre" else "sub", []) as Array):
                                var sid := normalize_tag(String(raw))
                                if sid == "":
                                        continue
                                var table := GENRES if kind == "genre" else SUBS
                                if table.has(sid):
                                        continue   # a known tag - nothing to learn
                                if not tally[kind].has(sid):
                                        tally[kind][sid] = 0
                                tally[kind][sid] = int(tally[kind][sid]) + 1
        var out := {"genre": [], "sub": []}
        for kind in ["genre", "sub"]:
                for sid in tally[kind]:
                        if int(tally[kind][sid]) >= LEARN_THRESHOLD:
                                out[kind].append(sid)
                out[kind].sort()
        return out

