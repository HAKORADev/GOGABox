class_name Meta
extends RefCounted
## Modular game metadata vocabulary for GOGABox: main genres, sub genres and
## age ratings. Mirrors HAKORADev/GameBox limits: a game carries up to 3 main
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

## Age ratings (NOT the GameBox 1-5 star rating - owner said no star system).
const AGES := {
	"everyone": {"label": "EVERYONE", "icon": "res://assets/meta/age_everyone.png"},
	"kids": {"label": "KIDS 8+", "icon": "res://assets/meta/age_kids.png"},
	"teens": {"label": "TEENS 12+", "icon": "res://assets/meta/age_teens.png"},
}

static func genre_label(id: String) -> String:
	if GENRES.has(id):
		return String(GENRES[id]["label"])
	return id.capitalize()

static func sub_label(id: String) -> String:
	if SUBS.has(id):
		return String(SUBS[id]["label"])
	return id.capitalize()

static func age_label(id: String) -> String:
	if AGES.has(id):
		return String(AGES[id]["label"])
	return id.to_upper()

static func icon_for(kind: String, id: String) -> String:
	# kind: "genre" | "sub" | "age"
	var table := {}
	match kind:
		"genre": table = GENRES
		"sub": table = SUBS
		"age": table = AGES
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

static func used_ages() -> Array:
	var out := []
	for g in GameReg.GAMES:
		var a := String(g.get("age", "everyone"))
		if not out.has(a):
			out.append(a)
	return out
