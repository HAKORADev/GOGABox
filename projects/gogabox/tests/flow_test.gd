extends Node
## GOGABox flow test - v044 THE BOX, SIMPLIFIED. The game-folder world: the
## rig copies the repo's GOGAs/games folders into a fresh home (exactly what
## a player's artifact gives them), the whole battery runs against the 31
## installed games, and EVERY game boots through the runner - the crash
## gate is the battery, not a hope. Exit 0 = all green.

const RIG_HOME := "user://goga_rig"
## the v044 box ships 31 game folders (the full v042 generation, ported).
const GAME_COUNT := 31

var fails := 0

func _ready() -> void:
        print("=== GOGABox flow test (v044 the box, simplified) ===")
        # ---- the rig: the game folders arrive by copy, the box scans them
        fails += _test("rig: the game folders land in a fresh home", _t_rig())
        # ---- the empty-binary truth
        fails += _test("empty binary: zero baked games, unified entries", _t_registry())
        # ---- infra (the survivors, retargeted to installed games)
        fails += _test("store: wallet roundtrip", _t_wallet())
        fails += _test("store: favorites roundtrip", _t_favorites())
        fails += _test("store: unlocks + anti-softlock", _t_unlocks())
        fails += _test("store: stats/achievements/skins", _t_slots())
        fails += _test("store: time/spent/earned tracking", _t_accounting())
        fails += _test("batteries: pools, consumption, refill", _t_batteries())
        fails += _test("windows: hour math", _t_windows())
        fails += _test("wallet: daily limits 12AM reset", _t_daily())
        fails += _test("time: AM/PM + live unlock", _t_time_fmt())
        # ---- the v043 seats
        fails += _test("meta: v043 tables + lowercase law + self-learning", _t_meta())
        fails += _test("age: THE AGE DOOR truth table", _t_age_door())
        fails += _test("goga: THE FOLDER SCAN laws", _t_folder_scan())
        fails += _test("goga: the SDK doors (data/save/visual)", _t_goga_sdk())
        # ---- lan (the v042 regression shield, the local law)
        fails += _test("lan: the v042 laws (local only)", _t_lan_laws())
        # ---- the games, through the runner
        fails += _test("host: launch + finish + economy (a folder game)", await _t_host_flow())
        fails += _test("games: ALL %d boot through the runner" % GAME_COUNT, await _t_all_games())
        fails += _test("jumpcube: conquer dice CPU sanity (from its pck)", await _t_jumpcube_ai())
        # ---- the menu world
        fails += _test("menu: boots and lays out (zero baked + installed)", await _t_menu())
        fails += _test("menu: the search sheet filters (age/content/lowercase)", await _t_search_filters())
        fails += _test("roadmap: feed order + state machine (installed)", _t_roadmap())
        fails += _test("roadmap: GOGACharges meters", _t_charging())
        fails += _test("dev: switches, code arm, all_owned-only, sheet", await _t_dev_cheats())
        fails += _test("isolation: own-world launch (0-ads)", await _t_isolation())
        # ---- ui laws
        fails += _test("scroll: BoxScroll drag/tap", await _t_scroll())
        fails += _test("sheets: fit_sheet button safety", await _t_fitsheet())
        fails += _test("thumbs: the dual-thumb law", _t_thumb_laws())
        fails += _test("plugins: GDScript/native name parity", _t_plugin_names())
        print("RESULT: %s" % ("ALL TESTS PASSED" if fails == 0 else "%d FAILURES" % fails))
        get_tree().quit(0 if fails == 0 else 1)

func _test(name_: String, fn_result: int) -> int:
        print("  %s: %s" % ["PASS" if fn_result == 0 else "FAIL", name_])
        return fn_result

func _check(cond: bool, what: String) -> int:
        if not cond:
                print("    - FAIL: %s" % what)
                return 1
        return 0

# ============================================================ THE RIG

## The rig installs the repo's official source (GOGAs/games next to the
## project) into a controlled home, exactly like a player's first discover
## download would - the tests then run against REAL installed packages.
func _t_rig() -> int:
        var ok := 0
        GOGA.set_home(RIG_HOME)
        _wipe(RIG_HOME)
        GOGA.set_home(RIG_HOME)
        ok += _check(GOGA.home() == RIG_HOME, "the home override seats")
        ok += _check(DirAccess.dir_exists_absolute(GOGA.games_dir()), "games/ exists")
        # the repo's own GOGAs/games IS the shipping set - copy it in like
        # the artifact does (no importer, no validation: folders land as-is)
        var repo_root := ProjectSettings.globalize_path("res://").path_join("../..")
        var src := repo_root.path_join("GOGAs/games")
        ok += _check(DirAccess.dir_exists_absolute(src),
                        "the repo carries GOGAs/games (the shipping set)")
        if not DirAccess.dir_exists_absolute(src):
                return ok
        _copy_tree(src, GOGA.games_dir())
        GOGA.reload_entries()
        var entries: Array = GOGA.entries()
        ok += _check(entries.size() == GAME_COUNT,
                        "all %d game folders scanned (%d)" % [GAME_COUNT, entries.size()])
        for e in entries:
                var gid := String(e["id"])
                ok += _check(String(e.get("title", "")) != "", gid + " wears a title")
                ok += _check(String(e.get("kind", "")) == "godot_embedded",
                                gid + " is a godot game")
                ok += _check(FileAccess.file_exists(String(e["root"]).path_join("game.pck")),
                                gid + " carries its game.pck")
                ok += _check(String(e.get("script", "")).begins_with("res://"),
                                gid + " carries its entry script")
                ok += _check(FileAccess.file_exists(String(e["root"]).path_join("thumb.png")),
                                gid + " carries its thumb")
        return ok

# ============================================================ THE EMPTY BINARY

func _t_registry() -> int:
        var ok := 0
        ok += _check(GameReg.GAMES.is_empty(), "GAMES is empty (THE EMPTY BINARY LAW)")
        var all := GameReg.games()
        ok += _check(all.size() == GAME_COUNT,
                        "unified entries carry every installed game (%d)" % all.size())
        for e0 in all:
                var gid := String(e0["id"])
                var g := GameReg.get_game(gid)
                ok += _check(not g.is_empty(), gid + " reads through GameReg.get_game")
                ok += _check(String(g.get("root", "")) != "", gid + " carries its package root")
                # the script path exists on EVERY platform now (v044-1: the
                # whole shipping set runs everywhere - the phone-only/pc-only
                # tags were the v044 rig's test seats and are gone)
                var os_list: Array = g.get("os", ["android", "pc"])
                var platform_now := "android" if OS.has_feature("android") else "pc"
                ok += _check(os_list.has(platform_now),
                                gid + " runs on this platform (all-platform law)")
                ok += _check(String(g.get("script", "")).begins_with("res://"),
                                gid + " carries its pck script path")
                ok += _check(int(g.get("age", 0)) >= 3, gid + " wears an age tag")
        # a game id that exists nowhere reads empty (never crashes)
        ok += _check(GameReg.get_game("does_not_exist").is_empty(), "unknown id -> empty")
        return ok

# ============================================================ INFRA

func _t_wallet() -> int:
        Box.reset_all()
        var ok := _check(Box.coins() == 150, "start wallet 150")
        Box.earn(50)
        ok += _check(Box.coins() == 200, "earn +50")
        ok += _check(Box.spend(30), "spend ok")
        ok += _check(Box.coins() == 170, "balance 170")
        ok += _check(not Box.spend(999999), "over-spend refused")
        return ok

func _t_favorites() -> int:
        Box.reset_all()
        var ok := _check(not Box.is_favorite("rally"), "rally not favorited at start")
        Box.set_favorite("rally", true)
        ok += _check(Box.is_favorite("rally"), "heart adds rally to favorites")
        ok += _check(not Box.is_favorite("slasher"), "slasher untouched")
        Box.set_favorite("rally", false)
        ok += _check(not Box.is_favorite("rally"), "heart removes it again")
        Box.set_favorite("rally", true)
        Box.reset_game("rally")
        ok += _check(Box.is_favorite("rally"), "reset_game keeps the favorite")
        Box.reset_all()
        ok += _check(not Box.is_favorite("rally"), "reset_all clears favorites")
        return ok

func _t_unlocks() -> int:
        Box.reset_all()
        var ok := _check(not Box.owns_game("domino"), "domino not owned at start")
        ok += _check(not Box.unlock_game("domino", 1000), "a dry wallet cannot buy")
        Box.earn(1000)
        ok += _check(Box.unlock_game("domino", 1000), "the buy lands")
        ok += _check(Box.owns_game("domino") and Box.coins() == 150,
                        "owned + only the price left (150 start + 1000 - 1000)")
        return ok

func _t_slots() -> int:
        Box.reset_all()
        # v0.1.9 law: plays count at START; record_run keeps the score story
        Box.record_started("rally")
        Box.record_started("rally")
        Box.record_run("rally", 42)
        Box.record_run("rally", 17)
        var ok := _check(Box.stat("rally", "best") == 42, "best kept")
        ok += _check(Box.stat("rally", "last") == 17, "last updated")
        ok += _check(Box.stat("rally", "plays") == 2, "plays counted at START")
        ok += _check(Box.last_played_at("rally") > 0, "last_ts set")
        Box.bump_counter("rally", "goals", 10)
        Box.bump_counter("rally", "goals", 5)
        ok += _check(Box.counter("rally", "goals") == 15, "counters add")
        ok += _check(not Box.has_achievement("rally", "a1"), "ach unset")
        ok += _check(Box.grant_achievement("rally", "a1"), "first grant true")
        ok += _check(not Box.grant_achievement("rally", "a1"), "second grant false")
        ok += _check(Box.ach_count("rally") == 1, "ach_count tracks trophies")
        Box.reset_all()
        ok += _check(Box.stat("rally", "best") == 0, "reset_all wipes slots")
        return ok

func _t_accounting() -> int:
        Box.reset_all()
        var ok := _check(Box.spent_in("slasher") == 0, "spent starts 0")
        Box.add_spent("slasher", 10)
        ok += _check(Box.spent_in("slasher") == 10, "spent records")
        ok += _check(Box.earned_in("slasher") == 0, "earned starts 0")
        Box.add_earned("slasher", 7)
        ok += _check(Box.earned_in("slasher") == 7, "earned records")
        Box.reset_all()
        return ok

func _t_batteries() -> int:
        Box.reset_all()
        var ok := _check(Box.box_batteries() == 50, "box pool starts full (50)")
        ok += _check(Box.game_battery("domino").is_empty(), "domino plays without charges")
        var b := Box.game_battery("rally")
        ok += _check(not b.is_empty() and int(b["count"]) == 10 and int(b["per_round"]) == 2,
                        "rally pool 10, 2 per round (from its package index)")
        ok += _check(Box.consume_round_batteries("rally"), "round consumes 2")
        ok += _check(int(Box.game_battery("rally")["count"]) == 8, "pool 8 after round")
        ok += _check(Box.box_batteries() == 48, "box bank drained too (48)")
        Box.data["game_batteries"]["rally"]["count"] = 1
        ok += _check(not Box.consume_round_batteries("rally"), "no play at 1 battery")
        Box.data["game_batteries"]["rally"]["count"] = 10
        Box.set_box_batteries(1)
        ok += _check(not Box.consume_round_batteries("rally"), "no play when bank < cost")
        ok += _check(int(Box.game_battery("rally")["count"]) == 10, "pool untouched on fail")
        Box.set_box_batteries(30)
        Box.data["game_batteries"]["rally"]["count"] = 1
        var moved := Box.refill_game_from_box("rally")
        ok += _check(moved == 2 and int(Box.game_battery("rally")["count"]) == 3,
                        "refill moves one round (2), pool 1->3")
        Box.data["game_batteries"]["rally"]["count"] = 5
        Box.set_box_batteries(0)
        ok += _check(Box.refill_game_from_box("rally") == 0, "dry bank: nothing moves")
        Box.reset_all()
        return ok

func _t_windows() -> int:
        var ok := 0
        ok += _check(Roadmap._hour_in(3, 1, 8), "3h inside 1-8")
        ok += _check(not Roadmap._hour_in(12, 1, 8), "12h outside 1-8")
        ok += _check(Roadmap._hour_in(23, 22, 6), "23h inside overnight 22-6")
        ok += _check(Roadmap._hour_in(2, 22, 6), "2h inside overnight 22-6")
        ok += _check(not Roadmap._hour_in(9, 22, 6), "9h outside overnight 22-6")
        return ok

func _t_daily() -> int:
        Box.reset_all()
        var ok := _check(Box.daily_ok("domino"), "domino has no daily cap")
        var u := Box.daily_usage("rally")
        ok += _check(int(u["rounds_cap"]) == 6 and int(u["mins_cap"]) == 0,
                        "rally: 6 rounds/day (its index says so)")
        for i in 6:
                Box.record_started("rally")   # v0.1.9: rounds burn at START
        ok += _check(not Box.daily_ok("rally"), "6 rounds: rally is done for today")
        ok += _check(Roadmap.daily_text("rally") == "6/6 rounds",
                        "daily text live (%s)" % Roadmap.daily_text("rally"))
        # 12AM 00:00: the day key flips -> counters wipe on first read
        Box.data["games"]["rally"]["daily"]["day"] = "2000-01-01"
        ok += _check(Box.daily_ok("rally") and Box.daily_usage("rally")["rounds"] == 0,
                        "past midnight: the cap resets")
        # slasher: playtime-only cap (20 min)
        Box.add_time("slasher", 19.0 * 60.0)
        ok += _check(Box.daily_ok("slasher"), "19 of 20 min: still playable")
        Box.add_time("slasher", 61.0)
        ok += _check(not Box.daily_ok("slasher"), "20 min reached: locked")
        # the oracle + the launcher respect the cap
        Box.unlock_game("rally", 0)
        Box.earn(100)
        Box.data["games"]["rally"]["daily"]["rounds"] = 6
        ok += _check(not Roadmap.can_play_now("rally"), "can_play_now false while capped")
        var router := Node2D.new()
        add_child(router)
        ok += _check(not load("res://game/core/game_host.gd").launch(router, "rally"),
                        "launch REFUSES a daily-capped game")
        router.queue_free()
        Box.reset_all()
        return ok

func _t_time_fmt() -> int:
        var ok := 0
        ok += _check(Roadmap.fmt_hour(0) == "12 AM", "midnight reads 12 AM")
        ok += _check(Roadmap.fmt_hour(13) == "1 PM", "13 reads 1 PM")
        ok += _check(Roadmap.fmt_hour(12) == "12 PM", "noon reads 12 PM")
        return ok

# ============================================================ META v043

func _t_meta() -> int:
        var ok := 0
        # the unified entries respect the metadata limits
        for g in GameReg.games():
                var geo: Dictionary = g.get("genres", {})
                ok += _check((geo.get("main", []) as Array).size() <= Meta.MAIN_LIMIT,
                                String(g["id"]) + " main genres <= 3")
                ok += _check((geo.get("sub", []) as Array).size() <= Meta.SUB_LIMIT,
                                String(g["id"]) + " sub genres <= 3")
        # THE AGE LADDER (the archive's bands, 3..21)
        ok += _check(Meta.AGES.size() == 8, "the ladder wears 8 bands")
        for band in ["3", "5", "7", "9", "12", "16", "18", "21"]:
                ok += _check(Meta.AGES.has(band), "the ladder wears +" + band)
        ok += _check(Meta.age_label("9") == "+9 LITTLE VIOLENCE", "the tier label reads the archive's text")
        # THE CONTENT TAGS (the owner's list + the archive's taxonomy)
        for c in ["horror", "psycho", "gore", "porn", "gambling", "politics",
                        "illegal_trading", "nudity"]:
                ok += _check(Meta.CONTENT.has(c), "content tag: " + c)
        # THE LOWERCASE LAW
        ok += _check(Meta.normalize_tag("BOarD") == "board", "BOarD -> board")
        ok += _check(Meta.normalize_tag("boARd") == "board", "boARd -> board")
        ok += _check(Meta.normalize_tag("  Retro ") == "retro", "padding dies too")
        ok += _check(Meta.content_label("GaMbLiNg") == "Gambling",
                        "a mixed-case content id lands on the known label")
        # used_* read the INSTALLED world
        ok += _check(not Meta.used_genres().is_empty(), "genres used by installed games")
        ok += _check(not Meta.used_subs().is_empty(), "subs used by installed games")
        ok += _check(Meta.used_contents().size() >= 0, "content census reads")
        # v043 pass 3 THE CHIP LAW, the owner's own clarification: the
        # const tables ALWAYS show ("if we hardcoded 'porn' then it must
        # keep showing up"), an unknown tag indexes only at the census
        # ("if we did not made 'blowjob' but there is 10 blowjob-tagged
        # games, then make that tag appear") - and the census covers
        # CONTENT tags now, not only genres/subs.
        ok += _check(Meta.GENRES.size() >= 12 and Meta.SUBS.size() >= 8,
                        "the const tables always ride the rows (the hardcoded law)")
        ok += _check(Meta.CONTENT.size() >= 8,
                        "the content table always rides the rows (porn stays)")
        ok += _check(Meta.age_label("21") == "+21 ADULT ONLY",
                        "the age chip wears the word (+21 ADULT ONLY)")
        ok += _check(Meta.age_label("12") == "+12 YOUNG TEENS",
                        "the age chip wears the word (+12 YOUNG TEENS)")
        var mk_e := func(id: String, genre: String) -> Dictionary:
                return {"id": id, "genres": {"main": [genre], "sub": []},
                                "content": [genre]}
        var nine: Array = []
        for i in 9:
                nine.append(mk_e.call("g%d" % i, "blowjob"))
        var r9: Dictionary = Meta.learn_tags(nine, func(_id): return true)
        ok += _check((r9["genre"] as Array).is_empty() and (r9["content"] as Array).is_empty(),
                        "9 games sharing an unknown tag index NOTHING (below the census)")
        var ten: Array = nine.duplicate(true)
        ten.append(mk_e.call("g10", "blowjob"))
        var r10: Dictionary = Meta.learn_tags(ten, func(_id): return true)
        ok += _check((r10["genre"] as Array) == ["blowjob"],
                        "10 games sharing an unknown genre index it (the owner's own example)")
        ok += _check((r10["content"] as Array) == ["blowjob"],
                        "the content census learns unknown content tags too")
        # a KNOWN tag never needs learning (porn rides the table forever)
        var known: Array = []
        for i in 15:
                known.append(mk_e.call("k%d" % i, "porn"))
        var rk: Dictionary = Meta.learn_tags(known, func(_id): return true)
        ok += _check((rk["content"] as Array).is_empty(),
                        "a hardcoded tag is never 'learned' - it is always there")
        # the dual thumb: a res:// path stays a resource, junk is null
        ok += _check(Meta.thumb_texture("res://assets/thumbs/soon.png") != null,
                        "res thumbs still load")
        ok += _check(Meta.thumb_texture("res://assets/thumbs/does_not_exist.png") == null,
                        "a missing thumb is null, never a crash")
        return ok

# ============================================================ THE AGE DOOR

func _t_age_door() -> int:
        var ok := 0
        # THE PROFILE AGE LAW: unset (0) opens up to +12, the rest lock
        ok += _check(Meta.age_allowed(3, 0), "unset profile: +3 plays")
        ok += _check(Meta.age_allowed(12, 0), "unset profile: +12 plays (the ceiling)")
        ok += _check(not Meta.age_allowed(16, 0), "unset profile: +16 locks")
        ok += _check(not Meta.age_allowed(18, 0), "unset profile: +18 locks")
        ok += _check(not Meta.age_allowed(21, 0), "unset profile: +21 locks")
        # a set profile compares numbers
        ok += _check(Meta.age_allowed(9, 9), "age 9 plays +9")
        ok += _check(Meta.age_allowed(9, 21), "age 21 plays +9")
        ok += _check(not Meta.age_allowed(16, 9), "age 9 cannot play +16")
        ok += _check(Meta.age_allowed(21, 21), "age 21 plays +21")
        # garbage ages floor at +3
        ok += _check(Meta.age_allowed(0, 5), "a missing tag floors at +3")
        # the real profile door: 0 = unset
        ok += _check(LanProfile.age() >= 0, "the profile age door reads")
        return ok

# ============================================================ THE GOGA RUNTIME

## THE FOLDER SCAN LAWS (v044): the two-file contract and nothing more.
func _t_folder_scan() -> int:
        var ok := 0
        # 1) a folder without game.pck is invisible - not a game, not a refusal
        var lab := GOGA.games_dir().path_join("_rig_empty")
        _wipe(lab)
        DirAccess.make_dir_recursive_absolute(lab)
        GOGA.reload_entries()
        ok += _check(GOGA.entry("_rig_empty").is_empty(),
                        "a folder without game.pck is not a game")
        _wipe(lab)
        # 2) a folder with a pack but no manifest still plays - it wears its
        # folder name (THE NAME LAW: the folder is the id, the name file is
        # a courtesy)
        var lab2 := GOGA.games_dir().path_join("_rig_noname")
        _wipe(lab2)
        DirAccess.make_dir_recursive_absolute(lab2)
        _touch(lab2.path_join("game.pck"))
        GOGA.reload_entries()
        var e: Dictionary = GOGA.entry("_rig_noname")
        ok += _check(not e.is_empty(), "a pack-only folder still plays")
        ok += _check(String(e.get("title", "")) == "_RIG_NONAME",
                        "the folder name becomes the title when the file is gone")
        ok += _check((e.get("os", []) as Array).has("pc") and (e["os"] as Array).has("android"),
                        "the os default is both platforms")
        ok += _check(GOGA.uninstall("_rig_noname"), "uninstall removes a game folder")
        GOGA.reload_entries()
        # 3) the platform truth: an os list without this device flags
        #    no_run_for_platform. v044-1: the whole shipping set runs on
        #    BOTH platforms (the test tags were a v044 rig artifact) - the
        #    door itself is still proven with a lab folder wearing one os.
        var lab3 := GOGA.games_dir().path_join("_rig_oneos")
        _wipe(lab3)
        DirAccess.make_dir_recursive_absolute(lab3)
        _touch(lab3.path_join("game.pck"))
        var f3 := FileAccess.open(lab3.path_join("game.json"), FileAccess.WRITE)
        f3.store_string(JSON.stringify({"title": "ONE OS", "os": ["pc"]}))
        f3.close()
        GOGA.reload_entries()
        var oneos: Dictionary = GOGA.entry("_rig_oneos")
        var platform_now := "android" if OS.has_feature("android") else "pc"
        ok += _check(bool(oneos.get("no_run_for_platform", false)) == (platform_now != "pc"),
                        "a pc-only lab game flags the wrong platform")
        for g in GOGA.entries():
                ok += _check(not bool(g.get("no_run_for_platform", false)),
                                "the shipping set runs everywhere: " + String(g["id"]))
        ok += _check(GOGA.uninstall("_rig_oneos"), "the lab folder cleans up")
        GOGA.reload_entries()
        # 4) v044-1 THE SETTINGS FILE: box.json carries the mature fold + the
        #    dev-cheats master; a missing/broken file means the defaults.
        var sp := GOGA.home().path_join("box.json")
        DirAccess.remove_absolute(sp)
        GOGA.reload_settings()
        ok += _check(GOGA.hide_mature(), "the mature fold defaults ON")
        ok += _check(not GOGA.dev_cheats_enabled(), "the dev-cheats master defaults OFF")
        var fs := FileAccess.open(sp, FileAccess.WRITE)
        fs.store_string(JSON.stringify({"hide_mature": false, "dev_cheats": true}))
        fs.close()
        GOGA.reload_settings()
        ok += _check(not GOGA.hide_mature(), "the file flips the mature fold off")
        ok += _check(GOGA.dev_cheats_enabled(), "the file arms the dev-cheats master")
        DirAccess.remove_absolute(sp)
        GOGA.reload_settings()
        return ok

func _t_goga_sdk() -> int:
        var ok := 0
        # the SDK doors ride the REAL installed games: the context is the
        # current game id, the paths point inside its folder
        GOGA._current_id = "rally"
        ok += _check(GOGA.my_id() == "rally", "my_id reads the running game")
        ok += _check(GOGA.my_root().ends_with("/games/rally"),
                        "my_root points at the game folder")
        ok += _check(not GOGA.has_data("logic/board.json"), "has_data is honest before a write")
        ok += _check(GOGA.data_json("logic/board.json").is_empty(), "a missing data json reads {}")
        ok += _check(GOGA.data_read("logic/board.json") == "", "a missing data read is empty")
        ok += _check(GOGA.visual_override("board.png") == "",
                        "a missing override is empty, never a crash")
        # the save door seats save/ INSIDE the game folder, creating it
        ok += _check(GOGA.save_json_write("save.json", {"best": 42}), "a save writes")
        var back := GOGA.save_json_read("save.json")
        ok += _check(int(back.get("best", 0)) == 42, "the save reads back")
        ok += _check(FileAccess.file_exists(GOGA.save_path("save.json")),
                        "THE PORTABLE SAVE DOOR: the save lives in the game folder")
        # clean the lab save out of the shipped folder
        DirAccess.remove_absolute(GOGA.save_path("save.json"))
        GOGA._current_id = ""
        return ok

# ============================================================ LAN (the shield)

func _t_lan_laws() -> int:
        var ok := 0
        # THE NAME LAW r2 (EN letters + DIGITS, 1 char min, no emoji, max 20)
        ok += _check(LanProfile.sanitize_name("osama bin-ladin") == "osama bin-ladin",
                        "lan name: the owner's example survives")
        ok += _check(LanProfile.sanitize_name("neo99") == "neo99",
                        "lan name: digits survive (r2)")
        ok += _check(LanProfile.name_ok("9"),
                        "lan name: 1 char is a name (r2)")
        ok += _check(not LanProfile.name_ok("   "),
                        "lan name: space-only is no name (r2)")
        ok += _check(LanProfile.sanitize_name("neo" + char(0x1F600) + "bad") == "neobad",
                        "lan name: emoji die")
        ok += _check(LanProfile.sanitize_name("ABCDEFGHIJKLMNOPQRSTU").length() == 20,
                        "lan name: max 20")
        # THE MULTI-LEVEL TAGS on the installed world (the archive's own
        # lan vocabulary: 12 games wear the seat)
        # the cross-platform 2P seat; the packages say so, not the binary)
        var with_lan := 0
        for g in GameReg.games():
                if g.has("lan"):
                        with_lan += 1
                        var lan: Dictionary = g["lan"]
                        ok += _check(int(lan.get("players", 0)) >= 2
                                        and int(lan.get("players", 0)) <= 4,
                                        String(g["id"]) + " lan players 2..4")
                        ok += _check(not (lan.get("platforms", []) as Array).is_empty(),
                                        String(g["id"]) + " lan platforms")
        ok += _check(with_lan == 12, "the lan games all wear the seat (%d)" % with_lan)
        ok += _check(Meta.lan_list(GameReg.get_game("rally")).has("lan_cross"),
                        "rally derives the cross chip")
        ok += _check(Meta.lan_list(GameReg.get_game("rally")).has("lan_2p"),
                        "rally derives the 2P chip")
        return ok

# ============================================================ THE GAMES (through the runner)

func _t_host_flow() -> int:
        Box.reset_all()
        var ok := 0
        var router := Node2D.new()
        add_child(router)
        var host_script: GDScript = load("res://game/core/game_host.gd")
        # rally costs 8 coins; own it free and check the PACKAGE mount path
        Box.unlock_game("rally", 0)
        var launched: bool = host_script.launch(router, "rally")
        ok += _check(launched, "rally launches THROUGH its package pck")
        if not launched:
                Box.reset_all()
                return ok
        await get_tree().create_timer(3.0).timeout   # universal loading screen
        var host: Node = host_script.active_host
        ok += _check(host != null and host.game != null, "host + game alive (from the pck)")
        if host != null and host.game != null:
                host.game.set_score(37)
                host.game.add_run_coins(5)
                host.game.finish_run(37)
                await get_tree().create_timer(2.2).timeout
                ok += _check(Box.stat("rally", "best") == 37, "run recorded (best 37)")
                ok += _check(Box.stat("rally", "plays") >= 1, "plays recorded")
                host._quit_to_menu()
                await get_tree().process_frame
        ok += _check(host_script.active_host == null, "host session ended")
        Box.reset_all()
        return ok

func _t_all_games() -> int:
        var ok := 0
        var host_script: GDScript = load("res://game/core/game_host.gd")
        Box.reset_all()
        Box.earn(100000)
        Box.set_box_batteries(Box.box_battery_cap())
        for g in GameReg.playable():
                if not Box.owns_game(String(g["id"])):
                        Box.unlock_game(String(g["id"]), 0)
        var router := Node2D.new()
        add_child(router)
        for g in GameReg.playable():
                var id := String(g["id"])
                if not Roadmap.window_ok(id):
                        ok += _check(Roadmap.window_text(id) != "",
                                        id + " window-gated right now (boot skipped by design)")
                        continue
                # THE PLATFORM TRUTH: one pack runs anywhere - the MENU's
                # PHONE ONLY / PC ONLY button is the gate (the entry flags
                # no_run_for_platform), so the launcher itself never has to
                # refuse. The rig asserts the flag, not a mount refusal.
                var os_list: Array = g.get("os", ["android", "pc"])
                var platform_now := "android" if OS.has_feature("android") else "pc"
                if not os_list.has(platform_now):
                        ok += _check(bool(g.get("no_run_for_platform", false)),
                                        id + " flags the wrong platform (the menu gate)")
                        continue
                var fee := int(g["fee"])
                var before := Box.coins()
                var launched: bool = host_script.launch(router, id)
                ok += _check(launched, id + " launches")
                if not launched:
                        continue
                await get_tree().create_timer(3.0).timeout
                var host: Node = host_script.active_host
                ok += _check(host != null and host.game != null,
                                id + " host + game alive")
                if host == null:
                        continue
                ok += _check(Box.coins() == before - fee,
                                id + " fee charged (%d -> %d)" % [before, Box.coins()])
                host.game.set_score(20)
                host.game.finish_run(20)
                await get_tree().create_timer(1.0).timeout
                ok += _check(Box.stat(id, "plays") >= 1, id + " play recorded")
                host._quit_to_menu()
                await get_tree().process_frame
        Box.reset_all()
        return ok

## The jumpcube CPU brain, now running FROM ITS PACKAGE PCK (the port's
## 1:1 proof: the same brain, served by the runner).
func _t_jumpcube_ai() -> int:
        var ok := 0
        var e: Dictionary = GOGA.entry("jumpcube")
        ok += _check(not e.is_empty(), "jumpcube is installed")
        if e.is_empty():
                return ok
        # v044 THE PLATFORM TRUTH + v044-1: one pack runs anywhere - the
        # shipping set is all-platform now, so the pack mounts and the CPU
        # brain answers on every rig (the game is a full citizen of any box).
        var platform_now := "android" if OS.has_feature("android") else "pc"
        var os_list: Array = e.get("os", ["android", "pc"])
        ok += _check(os_list.has(platform_now),
                        "jumpcube runs on this platform (all-platform law)")
        ok += _check(GOGA.mount_for(e), "jumpcube's pck mounts (platform-blind)")
        var jc: GDScript = load(String(e["script"]))
        ok += _check(jc != null, "the pack's script loads from the mounted pck")
        if jc == null:
                return ok
        var probe: Node = jc.new()
        add_child(probe)
        await get_tree().process_frame
        if probe.has_method("_goga_setup"):
                probe.call("_goga_setup")
        await get_tree().create_timer(0.5).timeout
        ok += _check(probe.get("score") == 0 or probe.get("score") != null,
                        "the game node boots with its score seat")
        probe.queue_free()
        # the raw probe skips the host's lifecycle (the quit door owns the
        # un-pause in the real box) - a story sheet left the tree paused
        get_tree().paused = false
        Box.reset_all()
        return ok

# ============================================================ THE MENU WORLD

func _t_menu() -> int:
        var ok := 0
        var menu: Node = load("res://game/menu/menu.gd").new()
        add_child(menu)
        await get_tree().create_timer(2.0).timeout
        ok += _check(menu.get("_grid") != null, "the menu builds its grid")
        ok += _check(is_instance_valid(menu), "the menu survives zero baked games")
        menu.queue_free()
        await get_tree().process_frame
        return ok

## THE SEARCH SHEET (v043): the sheet opens on the installed world; the
## AGE + CONTENT + SUB GENRES rows seat; filters pass the lowercase law.
func _t_search_filters() -> int:
        var ok := 0
        var menu: Node = load("res://game/menu/menu.gd").new()
        add_child(menu)
        await get_tree().create_timer(1.5).timeout
        # the filter oracle wears the v043 rows
        menu.set("_filter_age", "9")
        menu.set("_filter_content", "")
        var pass9: bool = menu._passes_filters(GameReg.get_game("rally"))
        ok += _check(pass9 == (str(GameReg.get_game("rally").get("age", 3)) == "9"),
                        "the age filter compares the tag exactly")
        menu.set("_filter_age", "")
        menu.set("_filter_content", "")
        menu.set("_filter_genre", "")
        # the lowercase law on the genre filter: BOarD == board
        menu.set("_filter_genre", "BOarD")
        var fake := {"id": "x", "genres": {"main": ["BoArD"], "sub": []}}
        ok += _check(menu._passes_filters(fake), "BOarD filter finds BoArD data")
        menu.set("_filter_genre", "board")
        ok += _check(menu._passes_filters(fake), "board filter finds BoArD data")
        menu.queue_free()
        await get_tree().process_frame
        return ok

func _t_roadmap() -> int:
        var ok := 0
        # the feed carries every playable installed game in install order
        var ids: Array = []
        for g in GameReg.playable():
                ids.append(String(g["id"]))
        ok += _check(ids.size() == GAME_COUNT,
                        "the feed lists every installed game (%d)" % ids.size())
        # reveal states never crash on an unknown id
        ok += _check(Roadmap.state("does_not_exist") != "", "state() answers for unknown ids")
        return ok

func _t_charging() -> int:
        var ok := 0
        Box.reset_all()
        # rally has no charge_unlock; the meter door answers 0 honestly
        ok += _check(Box.charges_in("rally") == 0, "no meter by default")
        ok += _check(Box.give_charges("rally", 5) == 0, "pouring into no meter moves 0")
        Box.reset_all()
        return ok

func _t_dev_cheats() -> int:
        var ok := 0
        Box.reset_all()
        # v044-1 THE MASTER SWITCH: box.json "dev_cheats" (default FALSE)
        # gates the whole sheet - master off, even a SAVED cheat reads 0.
        GOGA._settings["dev_cheats"] = false
        Box.dev_set_cheat("all_owned", 1)
        ok += _check(Box.dev_cheat("all_owned") == 0, "the master kills a saved cheat")
        GOGA._settings["dev_cheats"] = true
        ok += _check(Box.dev_cheat("all_owned") == 1, "the master arms the sheet")
        ok += _check(Box.owns_game("domino"), "all_owned owns everything")
        ok += _check(Box.coins() == 150, "all_owned never touches the wallet")
        Box.dev_set_cheat("gogacoins", 1)
        ok += _check(Box.coins() == 999999999 and Box.coins_display() == "0",
                        "the wallet cheat shows 0, pays everything")
        Box.dev_set_cheat("all_owned", 0)
        Box.dev_set_cheat("gogacoins", 0)
        ok += _check(not Box.owns_game("domino"), "the cheat disarms")
        # the master gates EVERY cheat read - flip it back off and the
        # armed gogacoins above goes inert instantly
        Box.dev_set_cheat("gogacoins", 1)
        GOGA._settings["dev_cheats"] = false
        ok += _check(Box.coins() == 150, "master off: the armed cheat is inert")
        GOGA._settings["dev_cheats"] = true
        # THE GIVE-EVERYTHING LAW works on the installed world
        Box.dev_grant_everything()
        for e in GOGA.entries():
                ok += _check(Box.owns_game(String(e["id"])),
                                "grant-everything owns " + String(e["id"]))
        GOGA._settings.erase("dev_cheats")   # back to the file truth
        Box.reset_all()
        return ok

func _t_isolation() -> int:
        var ok := 0
        Box.reset_all()
        # v044-1: this section arms cheats itself - the master rides on
        GOGA._settings["dev_cheats"] = true
        Box.dev_set_cheat("all_owned", 1)
        var host_script: GDScript = load("res://game/core/game_host.gd")
        var router := Node2D.new()
        add_child(router)
        var launched: bool = host_script.launch(router, "rally")
        ok += _check(launched, "isolation: rally launches under the cheat")
        if launched:
                # late in the battery ~30 packs ride the mount table - the
                # boot breathes slower; give it a generous window
                for i in 12:
                        await get_tree().create_timer(1.0).timeout
                        var h0: Node = host_script.active_host
                        var kids := 0
                        var has_loader := false
                        if h0 != null:
                                kids = h0.get_child_count()
                                for c in h0.get_children():
                                        if c is CanvasLayer and (c as CanvasLayer).layer == 30:
                                                has_loader = true
                        print("ISO t=%d host=%s game=%s open=%s kids=%d loader=%s" % [i,
                                h0 != null,
                                (h0 != null and h0.game != null),
                                (h0 != null and bool(h0.get("_session_open"))),
                                kids, has_loader])
                        if h0 != null and h0.game != null:
                                break
                var host: Node = host_script.active_host
                ok += _check(host != null and host.game != null, "the game node boots")
                if host != null:
                        var fee_paid := int(host.get("fee"))
                        ok += _check(fee_paid == 0, "the cheat launches FREE")
                        Box.spend(25)   # a wallet hit mid-run must not leak into the game
                        host._quit_to_menu()
                        await get_tree().process_frame
        Box.dev_set_cheat("all_owned", 0)
        Box.reset_all()
        return ok

# ============================================================ UI LAWS

func _t_scroll() -> int:
        var ok := 0
        var scroll := BoxScroll.new()
        scroll.custom_minimum_size = Vector2(600, 800)
        add_child(scroll)
        var v := VBoxContainer.new()
        for i in 30:
                var l := Label.new()
                l.text = "row %d" % i
                l.custom_minimum_size = Vector2(500, 40)
                v.add_child(l)
        scroll.add_child(v)
        await get_tree().process_frame
        ok += _check(scroll.get_v_scroll_bar().max_value > 0, "the scroll measures its content")
        scroll.queue_free()
        await get_tree().process_frame
        return ok

func _t_fitsheet() -> int:
        var ok := 0
        # fit_sheet wraps the body of a REAL sheet: the vb must sit inside
        # panel > cc > root (the _sheet_base shape) - seat it exactly so,
        # and the root needs a REAL size so the avail math can decide
        var root := Control.new()
        root.custom_minimum_size = Vector2(800, 1000)
        root.size = Vector2(800, 1000)
        add_child(root)
        var cc := CenterContainer.new()
        root.add_child(cc)
        var pc := PanelContainer.new()
        cc.add_child(pc)
        var vb := VBoxContainer.new()
        pc.add_child(vb)
        for i in 24:
                var b := Arc.button("ROW %d WITH A REALLY LONG TEXT LINE TO WRAP AROUND" % i,
                                Vector2(540, 64), 22, Arc.ACCENT)
                vb.add_child(b)
        Arc.fit_sheet(vb)
        await get_tree().process_frame
        await get_tree().process_frame
        # fit_sheet's wrap law: a BoxScroll joins the vb's children and the
        # rows move INSIDE it - vb itself never re-parents
        var wrapped: BoxScroll = null
        for c in vb.get_children():
                if c is BoxScroll:
                        wrapped = c
        ok += _check(wrapped != null, "a tall body wraps into a BoxScroll")
        if wrapped != null:
                ok += _check((wrapped.get_child(0) as Node).get_child_count() > 0,
                                "the rows moved inside the wrap")
        root.queue_free()
        await get_tree().process_frame
        return ok

func _t_thumb_laws() -> int:
        var ok := 0
        # the dual-thumb law through Meta (res + disk + junk)
        ok += _check(Meta.thumb_texture("") == null, "empty thumb -> null")
        ok += _check(Meta.thumb_texture("res://assets/thumbs/soon.png") != null, "res thumb loads")
        ok += _check(Meta.thumb_texture("/definitely/not/a/file.png") == null, "disk junk -> null")
        return ok

func _t_plugin_names() -> int:
        var ok := 0
        # the notify bridge stays the one plugin seat: the autoload script
        # loads and the singleton answers (the android side lives in
        # plugins/notify - materialized into addons/ at build time)
        ok += _check(ResourceLoader.exists("res://addons/notify/notify.gd"),
                        "the notify bridge script exists")
        ok += _check(Notify != null and Notify.has_method("schedule"),
                        "the notify singleton answers")
        return ok



func _touch(path: String, txt := "x") -> void:
        DirAccess.make_dir_recursive_absolute(path.get_base_dir())
        var f := FileAccess.open(path, FileAccess.WRITE)
        if f != null:
                f.store_string(txt)
                f.close()

func _wipe(path: String) -> void:
        if DirAccess.dir_exists_absolute(path):
                var da := DirAccess.open(path)
                if da != null:
                        da.list_dir_begin()
                        var n := da.get_next()
                        while n != "":
                                var full := path.path_join(n)
                                if da.current_is_dir():
                                        _wipe(full)
                                else:
                                        da.remove(n)
                                n = da.get_next()
                        da.list_dir_end()
                DirAccess.remove_absolute(path)

func _copy_tree(src: String, dst: String) -> void:
        DirAccess.make_dir_recursive_absolute(dst)
        var da := DirAccess.open(src)
        if da == null:
                return
        da.list_dir_begin()
        var n := da.get_next()
        while n != "":
                var s := src.path_join(n)
                var d := dst.path_join(n)
                if da.current_is_dir():
                        _copy_tree(s, d)
                else:
                        da.copy(s, d)
                n = da.get_next()
        da.list_dir_end()
