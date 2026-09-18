class_name MBMeta
extends RefCounted
## MARBLE POPPER - the persistent ledger. Lives inside the box save under
## games.marble.progress.mb - one dictionary saved through Box.set_progress
## (the box save law, the PDMeta pattern).

const KEY := "mb"

var d := {}

static func load_meta() -> MBMeta:
        var m := MBMeta.new()
        m.d = Box.get_progress("marble", KEY, {})
        m._heal()
        return m

func _heal() -> void:
        var base := {
                "lives": 3,               # the owner's law: 3 lives
                "cleared": {},            # level id -> true
                "unlock": 1,              # the highest playable level number (1-based)
                "best": {},               # level id -> best level score
                "stars": {},              # level id -> 0..3
                "levels_done": 0,         # cleared count THIS run of the ladder
                "life_marks": 0,          # how many +1 life bonuses were granted
                "free_play": false,       # true after the 100th clear (the lives system dies)
                "combo_best": 0,
                "coins_taken": 0,         # chain GOGACoins lifetime
                "challenges_won": 0,
                "challenge_best": {},     # level id -> best challenge wave
                "seen_story": false,
        }
        for k in base:
                if not d.has(k):
                        d[k] = base[k]

func save() -> void:
        Box.set_progress("marble", KEY, d)

# ------------------------------------------------------------------ lives
func lives() -> int:
        return int(d["lives"])

func lose_life() -> bool:
        if bool(d["free_play"]):
                return false          # the lives system is dead in free play
        d["lives"] = maxi(0, int(d["lives"]) - 1)
        save()
        return true

func grant_life() -> void:
        d["lives"] = mini(9, int(d["lives"]) + 1)
        save()

## THE ALL-LOST LAW: every life gone -> the game restarts from the first level
func wiped_out() -> bool:
        return not bool(d["free_play"]) and int(d["lives"]) <= 0

func reset_ladder() -> void:
        d["cleared"] = {}
        d["unlock"] = 1
        d["levels_done"] = 0
        d["life_marks"] = 0
        d["lives"] = 3
        save()

# ------------------------------------------------------------------ clearing
func is_cleared(idx: int) -> bool:      # idx is 1-based level number
        return bool((d["cleared"] as Dictionary).get("m%02d" % idx, false))

func is_unlocked(idx: int) -> bool:
        return idx <= int(d["unlock"])

func record_clear(idx: int, level_score: int, stars: int) -> bool:
        ## returns true when this clear was NEW (first time)
        var id := "m%02d" % idx
        var was := bool((d["cleared"] as Dictionary).get(id, false))
        (d["cleared"] as Dictionary)[id] = true
        var best: Dictionary = d["best"]
        best[id] = maxi(int(best.get(id, 0)), level_score)
        var st: Dictionary = d["stars"]
        st[id] = maxi(int(st.get(id, 0)), stars)
        if idx >= int(d["unlock"]):
                d["unlock"] = mini(MarbleData.LEVELS_TOTAL, idx + 1)
        if not was:
                d["levels_done"] = int(d["levels_done"]) + 1
        save()
        return not was

func done_count() -> int:
        var n := 0
        for k in d["cleared"]:
                if bool((d["cleared"] as Dictionary)[k]):
                        n += 1
        return n

func all_cleared() -> bool:
        return done_count() >= MarbleData.LEVELS_TOTAL

## THE EXTRA LIFE LAW: +1 life owned after each 10 levels
func check_life_bonus() -> bool:
        var marks := int(d["levels_done"]) / 10
        if marks > int(d["life_marks"]):
                d["life_marks"] = marks
                grant_life()
                return true
        return false

func complete_all() -> void:
        if not bool(d["free_play"]):
                d["free_play"] = true
                save()

# ------------------------------------------------------------------ records
func best_for(idx: int) -> int:
        return int((d["best"] as Dictionary).get("m%02d" % idx, 0))

func stars_for(idx: int) -> int:
        return int((d["stars"] as Dictionary).get("m%02d" % idx, 0))

func combo_best() -> int:
        return int(d["combo_best"])

func record_combo(c: int) -> void:
        if c > int(d["combo_best"]):
                d["combo_best"] = c
                Box.max_counter("marble", "combo_best", c)
        save()

func record_coin() -> void:
        d["coins_taken"] = int(d["coins_taken"]) + 1
        Box.bump_counter("marble", "coins_taken", 1)
        save()

func record_challenge_wave(idx: int, wave: int, won: bool) -> void:
        var cb: Dictionary = d["challenge_best"]
        cb["m%02d" % idx] = maxi(int(cb.get("m%02d" % idx, 0)), wave)
        if won:
                d["challenges_won"] = int(d["challenges_won"]) + 1
                Box.bump_counter("marble", "challenges_won", 1)
        save()

func challenge_best_for(idx: int) -> int:
        return int((d["challenge_best"] as Dictionary).get("m%02d" % idx, 0))

func mark_story() -> void:
        d["seen_story"] = true
        save()
