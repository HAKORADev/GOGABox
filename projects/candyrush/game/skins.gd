class_name Skins
extends RefCounted
## Skin catalog: sprite sets, backgrounds, palette accents, prices.
## Every skin uses 5 base pieces (indices 0..4). Specials render via real
## sprite variants when the skin provides them, else code-drawn overlays
## (see piece.gd). Colors drive the whole UI (buttons, HUD, board frame).

const SPRITES := "res://assets/sprites/"

const SKINS := [
        {
                "id": "candy", "name": "Candy Shop", "price": 0,
                "dir": "candy", "prefix": "base_", "size": 100,
                "striped": true,      # real striped_h_i / striped_v_i sprites exist
                "wrapped": "wrapped.png", "colorbomb": "colorbomb.png",
                "bg": SPRITES + "bg_candy.png",
                "panel": Color("ffffffe6"), "frame": Color("f8a5c2"), "accent": Color("ff6fa5"),
                "board_cell": Color("7a4a3a55"), "text": Color("5a2a3a"), "dark": false,
                "tints": [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE],
        },
        {
                "id": "gems", "name": "Gem Vault", "price": 400,
                "dir": "gems", "prefix": "gem_", "size": 100,
                "striped": false, "wrapped": "", "colorbomb": "",
                "bg": SPRITES + "bg_gems.png",
                "panel": Color("f4f0ffee"), "frame": Color("8f7ff0"), "accent": Color("6a4fe8"),
                "board_cell": Color("3a2a6a55"), "text": Color("2d2050"), "dark": false,
                "tints": [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE],
        },
        {
                "id": "fruits", "name": "Retro Fruits", "price": 900,
                "dir": "fruits", "prefix": "fruit_", "size": 128,
                "striped": false, "wrapped": "", "colorbomb": "",
                "bg": SPRITES + "bg_fruits.png",
                "panel": Color("fff8ecee"), "frame": Color("f0b060"), "accent": Color("e07820"),
                "board_cell": Color("6a4a2a55"), "text": Color("5a3a18"), "dark": false,
                "tints": [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE],
        },
        {
                "id": "neon", "name": "Neon Arcade", "price": 1500,
                "dir": "neon", "prefix": "base_", "size": 100,
                "striped": false, "wrapped": "wrapped.png", "colorbomb": "colorbomb.png",
                "bg": SPRITES + "bg_neon.png",
                "panel": Color("191430e6"), "frame": Color("00e5ff"), "accent": Color("ff2ea6"),
                "board_cell": Color("00e5ff22"), "text": Color("e8f6ff"), "dark": true,
                "tints": [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE],
        },
]

static func get_skin(id: String) -> Dictionary:
        for s in SKINS:
                if s["id"] == id:
                        return s
        return SKINS[0]

static func base_texture(skin: Dictionary, type: int) -> Texture2D:
        var path := SPRITES + String(skin["dir"]) + "/" + String(skin["prefix"]) + str(type) + ".png"
        return load(path)

static func striped_texture(skin: Dictionary, type: int, horizontal: bool) -> Texture2D:
        if not bool(skin["striped"]):
                return null
        var fname := ("striped_h_" if horizontal else "striped_v_") + str(type) + ".png"
        var path := SPRITES + String(skin["dir"]) + "/" + fname
        return load(path) if ResourceLoader.exists(path) else null

static func wrapped_texture(skin: Dictionary) -> Texture2D:
        if String(skin["wrapped"]).is_empty():
                return null
        return load(SPRITES + String(skin["dir"]) + "/" + String(skin["wrapped"]))

static func colorbomb_texture(skin: Dictionary) -> Texture2D:
        if String(skin["colorbomb"]).is_empty():
                return null
        return load(SPRITES + String(skin["dir"]) + "/" + String(skin["colorbomb"]))

static func background(skin: Dictionary) -> Texture2D:
        return load(String(skin["bg"]))
