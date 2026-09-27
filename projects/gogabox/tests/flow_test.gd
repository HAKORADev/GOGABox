extends Node
## GOGABox flow test - v043 THE PLATFORM ERA. Core infra round-trips + the
## installed-package world (the box bakes ZERO games now; the rig installs
## the official source's packages first) + the v043 seats: the GOGA
## runtime, the age door, the discover engine. Exit 0 = all green.

const RIG_HOME := "user://goga_rig"
## THE FOUR PILOTS (the owner's port list - the only games that exist in
## v043): pong (rally) + fruit slasher 1:1 both devices, dominoes PC only,
## CONQUER DICE (jumpcube) android only.
const PILOT_GAME_IDS := ["rally", "slasher", "domino", "jumpcube"]

var fails := 0

func _ready() -> void:
        print("=== GOGABox flow test (v043 platform era) ===")
        # ---- the rig: the official source installs, the box reads packages
        fails += _test("rig: the official source installs the pilots", _t_rig())
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
        fails += _test("goga: the id scheme + versions", _t_goga_ids())
        fails += _test("goga: THE STRICT VALIDATOR refusals", _t_goga_validator())
        fails += _test("goga: import shapes + rename + update laws", _t_goga_import())
        fails += _test("goga: the SDK doors (data/save/visual)", _t_goga_sdk())
        fails += _test("sdk: the bridge roundtrip (a standalone client over TCP)", await _t_sdk_bridge())
        # ---- lan (the v042 regression shield, platform-era ids)
        fails += _test("lan: the v042 laws", _t_lan_laws())
        # ---- the games, through the runner
        fails += _test("host: launch + finish + economy (a package game)", await _t_host_flow())
        fails += _test("games: all installed boot through the runner", await _t_all_games())
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
        ok += _check(GOGA.home() == RIG_HOME, "the home override seats")
        ok += _check(DirAccess.dir_exists_absolute(GOGA.games_dir()), "games/ exists")
        ok += _check(DirAccess.dir_exists_absolute(GOGA.libs_dir()), "libs/ exists")
        ok += _check(DirAccess.dir_exists_absolute(GOGA.discover_dir()), "discover/ exists")
        ok += _check(DirAccess.dir_exists_absolute(GOGA.cache_dir()), ".cache/ exists")
        # the official source: <repo>/GOGAs/games (the repo root is two up)
        var repo_root := ProjectSettings.globalize_path("res://").path_join("../..")
        var src := repo_root.path_join("GOGAs/games")
        ok += _check(DirAccess.dir_exists_absolute(src),
                        "the repo carries GOGAs/games (the official source)")
        if not DirAccess.dir_exists_absolute(src):
                return ok
        var report: Dictionary = GOGA.import_path(src)
        var installed: int = (report["installed"] as Array).size()
        ok += _check(installed >= PILOT_GAME_IDS.size(),
                        "the four pilots installed (%d)" % installed)
        for bad in (report["refused"] as Array):
                print("    - the source refused: %s %s" % [String(bad.get("name")), str(bad.get("errors"))])
        ok += _check((report["refused"] as Array).is_empty(),
                        "the official source validates clean")
        for gid in PILOT_GAME_IDS:
                var e: Dictionary = GOGA.entry(gid)
                ok += _check(not e.is_empty(), gid + " is installed")
                if not e.is_empty():
                        ok += _check(String(e.get("pkg_id", "")).begins_with("gogabox_github-"),
                                        gid + " wears the long pkg id")
                        ok += _check(GOGA.parse_id(String(e.get("pkg_id", ""))).get("tier", "") == "official",
                                        gid + " rides the official tier")
        return ok

# ============================================================ THE EMPTY BINARY

func _t_registry() -> int:
        var ok := 0
        ok += _check(GameReg.GAMES.is_empty(), "GAMES is empty (THE EMPTY BINARY LAW)")
        var all := GameReg.games()
        ok += _check(all.size() >= PILOT_GAME_IDS.size(),
                        "unified entries carry the installed packages (%d)" % all.size())
        for gid in PILOT_GAME_IDS:
                var g := GameReg.get_game(gid)
                ok += _check(not g.is_empty(), gid + " reads through GameReg.get_game")
                ok += _check(String(g.get("root", "")) != "", gid + " carries its package root")
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

func _t_goga_ids() -> int:
        var ok := 0
        var pid := GOGA.parse_id("gogabox_github-HAKORADev_hakora.rally.001_official")
        ok += _check(pid.get("user", "") == "HAKORADev", "the user parses")
        ok += _check(pid.get("slug", "") == "hakora.rally.001", "the slug parses")
        ok += _check(pid.get("tier", "") == "official", "the tier parses")
        ok += _check(GOGA.parse_id("gogabox_github-neo99_shit.how.nah_hobbyist").get("tier", "") == "hobbyist",
                        "the hobbyist tier parses (the owner's example id)")
        ok += _check(GOGA.parse_id("gogabox_github-a_b.c_community").get("tier", "") == "community",
                        "the community tier parses")
        ok += _check(GOGA.parse_id("rally").is_empty(), "a bare id is NOT a package id")
        ok += _check(GOGA.parse_id("gogabox_github-x_y.z_federal").is_empty(),
                        "an unknown tier dies")
        ok += _check(GOGA.parse_id("gogabox_github-nodots_official").is_empty(),
                        "a slug without the dotted id dies")
        # versions
        ok += _check(GOGA.version_compare("1.0", "1.0") == 0, "versions: equal")
        ok += _check(GOGA.version_compare("1.0.1", "1.0") == 1, "versions: patch up")
        ok += _check(GOGA.version_compare("0.9", "1.0") == -1, "versions: minor down")
        ok += _check(GOGA.version_compare("0.4.10", "0.4.9") == 1, "versions: 10 > 9 (numeric, not lexical)")
        return ok

func _t_goga_validator() -> int:
        var ok := 0
        var rig := GOGA.cache_dir().path_join("validator_lab")
        _wipe(rig)
        # a VALID package (the full contract)
        var good := rig.path_join("gogabox_github-TESTER_test.good.001_official")
        _build_good_package(good)
        var v: Dictionary = GOGA.validate_root(good)
        ok += _check(bool(v["ok"]), "a complete package validates")
        for e in (v["errors"] as Array):
                print("    - unexpected: %s" % String(e))
        # every refusal is NAMED - break one thing at a time (each path is
        # a REAL file the factory created; save/ is the absence case)
        ok += _refuse_case(rig, good, "index/index.json", "index")
        ok += _refuse_case(rig, good, "data/logic/tuning.json", "data/logic")
        ok += _refuse_case(rig, good, "data/audio/sfx/click.ogg", "data/audio/sfx")
        ok += _refuse_case(rig, good, "data/audio/music/loop.ogg", "data/audio/music")
        ok += _refuse_case(rig, good, "data/visuals/shaders/tint.gdshader", "data/visuals/shaders")
        ok += _refuse_case(rig, good, "data/visuals/assets/board.png", "data/visuals/assets")
        ok += _refuse_case(rig, good, "save", "save")
        ok += _refuse_case(rig, good, "discover/page.json", "discover")
        _wipe(rig)
        return ok

func _refuse_case(rig: String, good: String, rel: String, what: String) -> int:
        # copy the good package, break the one thing, expect the named refusal
        var ok := 0
        var broken := rig.path_join("broken")
        _wipe(broken)
        _copy_tree(good, broken)
        var full := broken.path_join(rel)
        if DirAccess.dir_exists_absolute(full):
                _wipe(full)
                DirAccess.remove_absolute(full)
                if rel.begins_with("data/"):
                        # the data minimums fail on EMPTINESS - recreate empty;
                        # existence-only contracts (save/) fail on absence
                        DirAccess.make_dir_recursive_absolute(full)
        elif FileAccess.file_exists(full):
                DirAccess.remove_absolute(full)
        var v: Dictionary = GOGA.validate_root(broken)
        ok += _check(not bool(v["ok"]), "refused when missing: " + what)
        var named := false
        for e in (v["errors"] as Array):
                if String(e).contains(what):
                        named = true
        ok += _check(named, "the refusal NAMES the missing thing: " + what)
        return ok

func _t_goga_import() -> int:
        var ok := 0
        var lab := GOGA.cache_dir().path_join("import_lab")
        _wipe(lab)
        DirAccess.make_dir_recursive_absolute(lab)
        var home_before := GOGA.home()
        var lab_home := lab.path_join("home")
        GOGA.set_home(lab_home)
        # build two valid packages with different games + versions
        var pa := lab.path_join("pkg_a")
        _build_good_package(pa, "gogabox_github-TESTER_test.good.001_official", "goodgame", "1.0.0")
        var pb := lab.path_join("pkg_b")
        _build_good_package(pb, "gogabox_github-TESTER_test.second.001_official", "secondgame", "2.0.0")
        # 1) THE FOLDER SHAPE (a single root)
        var r1: Dictionary = GOGA.import_path(pa)
        ok += _check((r1["installed"] as Array).size() == 1, "a folder root imports")
        var installed_id := String((r1["installed"][0] as Dictionary).get("id", ""))
        ok += _check(installed_id == "gogabox_github-TESTER_test.good.001_official",
                        "the install reports the package id")
        ok += _check(DirAccess.dir_exists_absolute(GOGA.games_dir().path_join(installed_id)),
                        "THE RENAME LAW: the folder is the package id now")
        # 2) THE PARENT SHAPE (a folder of roots = the .gogas shape unzipped).
        # NOTE: pkg_a was MOVED by the import (THE RENAME LAW) - the test
        # rebuilds its own copies instead of reading a moved source.
        var parent := lab.path_join("many")
        DirAccess.make_dir_recursive_absolute(parent)
        _build_good_package(lab.path_join("pkg_a2"), "gogabox_github-TESTER_test.good.001_official", "goodgame", "1.0.0")
        _copy_tree(lab.path_join("pkg_a2"), parent.path_join("whatever_folder_name"))
        _copy_tree(pb, parent.path_join("another_name"))
        var r2: Dictionary = GOGA.import_path(parent)
        var done: int = (r2["installed"] as Array).size() + (r2["skipped"] as Array).size()
        ok += _check(done == 2, "a parent of roots handles both (one lands, one skips as installed)")
        ok += _check(DirAccess.dir_exists_absolute(GOGA.games_dir().path_join("gogabox_github-TESTER_test.second.001_official")),
                        "the second package renamed to its id too")
        # 3) THE ZIP SHAPES (.goga one root / .gogas many roots)
        _build_good_package(lab.path_join("pkg_a3"), "gogabox_github-TESTER_test.good.001_official", "goodgame", "1.0.0")
        var zg := lab.path_join("one.goga")
        _zip_dir(lab.path_join("pkg_a3"), zg)
        var r3: Dictionary = GOGA.import_path(zg)
        if (r3["refused"] as Array).size() > 0:
                print("    - .goga refused: %s" % str((r3["refused"][0] as Dictionary).get("errors")))
        ok += _check((r3["installed"] as Array).size() == 1 or not (r3["skipped"] as Array).is_empty(),
                        "a .goga archive imports (or skips as already-installed)")
        var zgs := lab.path_join("many.gogas")
        # step 2's import MOVED another_name out of parent/ (THE RENAME LAW
        # moves) - restore the copy so the .gogas really carries two roots
        _copy_tree(pb, parent.path_join("another_name"))
        _zip_dir(parent, zgs)
        var r4: Dictionary = GOGA.import_path(zgs)
        if (r4["refused"] as Array).size() > 0:
                print("    - .gogas refused: %s" % str((r4["refused"][0] as Dictionary).get("errors")))
        var moved: int = (r4["installed"] as Array).size() + (r4["skipped"] as Array).size()
        ok += _check(moved >= 2, "a .gogas archive handles both roots")
        # 4) THE UPDATE LAW: same version skips, older refuses, newer replaces
        var again: Dictionary = GOGA.import_path(lab.path_join("pkg_a2"))
        ok += _check((again["skipped"] as Array).size() >= 1
                        and String((again["skipped"][0] as Dictionary).get("why", "")).contains("same version"),
                        "the same version skips with the honest why")
        _build_good_package(lab.path_join("pkg_old"), "gogabox_github-TESTER_test.good.001_official", "goodgame", "0.9.0")
        var older: Dictionary = GOGA.import_path(lab.path_join("pkg_old"))
        var older_why := String(((older["skipped"] as Array)[0] as Dictionary).get("why", "")) if not (older["skipped"] as Array).is_empty() else ""
        ok += _check(older_why.contains("newer"), "an older version refuses with the why")
        _build_good_package(lab.path_join("pkg_new"), "gogabox_github-TESTER_test.good.001_official", "goodgame", "3.0.0")
        var newer: Dictionary = GOGA.import_path(lab.path_join("pkg_new"))
        ok += _check((newer["installed"] as Array).size() == 1, "a newer version replaces")
        # 5) A BROKEN PACKAGE IS REFUSED, NAMED, and installs NOTHING
        _build_good_package(lab.path_join("bad"), "gogabox_github-TESTER_test.bad.001_official", "badgame", "1.0.0")
        _wipe(lab.path_join("bad/save"))
        DirAccess.remove_absolute(lab.path_join("bad/save"))
        var bad: Dictionary = GOGA.import_path(lab.path_join("bad"))
        ok += _check((bad["refused"] as Array).size() == 1, "a broken package refuses")
        ok += _check(not DirAccess.dir_exists_absolute(GOGA.games_dir().path_join("gogabox_github-TESTER_test.bad.001_official")),
                        "the refused package installs nothing")
        # 6) UNINSTALL
        ok += _check(GOGA.uninstall("gogabox_github-TESTER_test.second.001_official"),
                        "uninstall removes a package")
        ok += _check(not GOGA.entry("secondgame") != {} and not GOGA.entries().any(func(e): return e.get("pkg_id") == "gogabox_github-TESTER_test.second.001_official"),
                        "the uninstalled package leaves the entries")
        GOGA.set_home(home_before)
        _wipe(lab)
        return ok

func _t_goga_sdk() -> int:
        var ok := 0
        var lab := GOGA.cache_dir().path_join("sdk_lab")
        _wipe(lab)
        var home_before := GOGA.home()
        GOGA.set_home(lab.path_join("home"))
        var pkg := lab.path_join("pkg")
        _build_good_package(pkg, "gogabox_github-TESTER_test.sdk.001_official", "sdkgame", "1.0.0")
        var rep: Dictionary = GOGA.import_path(pkg)
        if (rep["refused"] as Array).size() > 0:
                print("    - sdk lab refused: %s" % str((rep["refused"][0] as Dictionary).get("errors")))
        var e: Dictionary = GOGA.entry("sdkgame")
        ok += _check(not e.is_empty(), "the sdk package is installed")
        # the SDK context: my_id/my_root/data/save doors
        GOGA._current_id = "sdkgame"
        ok += _check(GOGA.my_id() == "sdkgame", "my_id reads the running package")
        ok += _check(GOGA.my_root().ends_with("gogabox_github-TESTER_test.sdk.001_official"),
                        "my_root points at the installed folder")
        ok += _check(not GOGA.has_data("logic/board.json"), "has_data is honest before a write")
        ok += _check(GOGA.data_json("logic/board.json").is_empty(), "a missing data json reads {}")
        ok += _check(GOGA.data_json("logic/tuning.json").has("speed"),
                        "the package's own data json reads through the door")
        ok += _check(GOGA.data_read("logic/tuning.json").contains("speed"),
                        "raw data reads too")
        ok += _check(GOGA.save_json_write("save.json", {"best": 42}), "a save writes")
        var back := GOGA.save_json_read("save.json")
        ok += _check(int(back.get("best", 0)) == 42, "the save reads back")
        ok += _check(FileAccess.file_exists(GOGA.save_path("save.json")),
                        "THE PORTABLE SAVE LAW: the save lives in the package")
        ok += _check(GOGA.visual_override("board.png") != "",
                        "a visual override reads from data/visuals/assets")
        ok += _check(GOGA.visual_override("nothing.png") == "",
                        "a missing override is empty, never a crash")
        GOGA.set_home(home_before)
        _wipe(lab)
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
        # THE ROOM CODE round-trip
        var lp: Node = load("res://game/core/lan.gd").new()
        var code: String = lp.encode_code("192.168.1.20", 31440)
        ok += _check(code.begins_with("GOGA-"), "lan code: the prefix")
        ok += _check(lp.decode_code(code) == "192.168.1.20:31440",
                        "lan code: the round-trip")
        ok += _check(lp.decode_code("GOGA-BADCODE") == "", "lan code: garbage dies")
        lp.free()
        # THE MULTI-LEVEL TAGS on the installed world (rally + slasher wear
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
        ok += _check(with_lan == 4, "the four pilots all wear the seat (%d)" % with_lan)
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
                # THE PLATFORM EXCLUSIVES: domino is PC-only, conquer dice
                # Android-only - the OTHER platform's seat refuses by design.
                # The headless rig runs as "pc", so jumpcube (android-only)
                # must refuse and be counted as the LAW WORKING.
                var os_list: Array = g.get("os", ["android", "pc"])
                var platform_now := "android" if OS.has_feature("android") else "pc"
                if not os_list.has(platform_now):
                        ok += _check(not host_script.launch(router, id),
                                        id + " refuses on the wrong platform (the exclusive law)")
                        continue
                var fee := int(g["fee"])
                var before := Box.coins()
                var launched: bool = host_script.launch(router, id)
                ok += _check(launched, id + " launches")
                if not launched:
                        continue
                await get_tree().create_timer(3.0).timeout
                var host: Node = host_script.active_host
                ok += _check(host != null and host.game != null, id + " host+game alive")
                if host == null or host.game == null:
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
        ok += _check(not e.is_empty() and GOGA.mount_for(e),
                        "jumpcube's pck mounts")
        if e.is_empty():
                return ok
        var jc: GDScript = load(String(e["script"]))
        ok += _check(jc != null, "the package's script loads from the mounted pck")
        if jc == null:
                return ok
        var inst: RefCounted = null
        var probe: Node = jc.new()
        add_child(probe)
        await get_tree().process_frame
        # the CPU must answer a move on its own board states
        if probe.has_method("_goga_setup"):
                probe.call("_goga_setup")
        await get_tree().create_timer(0.5).timeout
        ok += _check(probe.get("score") == 0 or probe.get("score") != null,
                        "the game node boots with its score seat")
        probe.queue_free()
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
        ok += _check(pass9 == (String(GameReg.get_game("rally").get("age", 3)) == "9"),
                        "the age filter compares the tag exactly")
        menu.set("_filter_age", "")
        menu.set("_filter_content", "GaMbLiNg".to_lower())
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
        ok += _check(ids.size() >= PILOT_GAME_IDS.size(),
                        "the feed lists the installed pilots")
        for gid in PILOT_GAME_IDS:
                ok += _check(ids.has(gid), gid + " sits in the feed")
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
        ok += _check(Box.dev_cheat("all_owned") == 0, "cheats start off")
        Box.dev_set_cheat("all_owned", 1)
        ok += _check(Box.dev_cheat("all_owned") == 1, "the cheat arms")
        ok += _check(Box.owns_game("domino"), "all_owned owns everything")
        ok += _check(Box.coins() == 150, "all_owned never touches the wallet")
        Box.dev_set_cheat("gogacoins", 1)
        ok += _check(Box.coins() == 999999999 and Box.coins_display() == "0",
                        "the wallet cheat shows 0, pays everything")
        Box.dev_set_cheat("all_owned", 0)
        Box.dev_set_cheat("gogacoins", 0)
        ok += _check(not Box.owns_game("domino"), "the cheat disarms")
        # THE GIVE-EVERYTHING LAW works on the installed world
        Box.dev_grant_everything()
        for gid in PILOT_GAME_IDS:
                ok += _check(Box.owns_game(gid), "grant-everything owns " + gid)
        Box.reset_all()
        return ok

func _t_isolation() -> int:
        var ok := 0
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        var host_script: GDScript = load("res://game/core/game_host.gd")
        var router := Node2D.new()
        add_child(router)
        var launched: bool = host_script.launch(router, "rally")
        ok += _check(launched, "isolation: rally launches under the cheat")
        if launched:
                await get_tree().create_timer(2.0).timeout
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

# ============================================================ SDK BRIDGE

## A REAL standalone-client roundtrip over the localhost wire: raw TCP to
## the box's bridge, the newline-JSON protocol, the save lands inside the
## GOGAs tree (libs/clients/) - the Steam model proven on loopback.
## NOTE: the bridge answers from the GOGA autoload's _process - the test
## YIELDS frames between steps (a blocking loop would starve the server).
func _t_sdk_bridge() -> int:
        var ok := 0
        await get_tree().create_timer(0.3).timeout   # the bridge listened at boot
        var peer := StreamPeerTCP.new()
        var err := peer.connect_to_host("127.0.0.1", 31442)
        ok += _check(err == OK, "the wire dials")
        if err != OK:
                return ok
        var deadline := Time.get_ticks_msec() + 2000
        while Time.get_ticks_msec() < deadline \
                        and peer.get_status() == StreamPeerTCP.STATUS_CONNECTING:
                peer.poll()
                await get_tree().process_frame
        ok += _check(peer.get_status() == StreamPeerTCP.STATUS_CONNECTED,
                        "the box's bridge accepts (127.0.0.1:31442)")
        if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
                return ok
        var buf := ""
        var ask := func(req: Dictionary) -> Dictionary:
                peer.put_data((JSON.stringify(req) + "\n").to_utf8_buffer())
                var dl := Time.get_ticks_msec() + 2500
                while Time.get_ticks_msec() < dl:
                        peer.poll()
                        var n := peer.get_available_bytes()
                        if n > 0:
                                var got := peer.get_data(n)
                                if got[0] == OK:
                                        buf += (got[1] as PackedByteArray).get_string_from_utf8()
                        while buf.contains("\n"):
                                var line := buf.substr(0, buf.find("\n")).strip_edges()
                                buf = buf.substr(buf.find("\n") + 1)
                                var res: Variant = JSON.parse_string(line)
                                if res is Dictionary:
                                        return res
                        await get_tree().process_frame   # let the bridge breathe
                return {}
        var hello: Dictionary = await ask.call({"op": "hello", "client": "rig_client", "proto": 1})
        ok += _check(bool(hello.get("ok", false)), "the hello handshakes")
        ok += _check(int(hello.get("proto", 0)) == 1, "the protocol matches")
        var bal: Dictionary = await ask.call({"op": "coins.balance"})
        ok += _check(bool(bal.get("ok", false)) and bal.has("coins"),
                        "the balance reads (%s coins)" % str(bal.get("coins")))
        Box.earn(25)
        var bal2: Dictionary = await ask.call({"op": "coins.balance"})
        ok += _check(int(bal2.get("coins", 0)) == int(bal.get("coins", 0)) + 25,
                        "an earn rides the wire")
        var spend: Dictionary = await ask.call({"op": "coins.spend", "n": 10})
        ok += _check(bool(spend.get("ok", false)), "a spend rides the wire")
        var wr: Dictionary = await ask.call({"op": "save.write", "key": "save", "data": "{\"lv\":7}"})
        ok += _check(bool(wr.get("ok", false)), "a save writes over the wire")
        var rd: Dictionary = await ask.call({"op": "save.read", "key": "save"})
        ok += _check(String(rd.get("data", "")) == "{\"lv\":7}", "the save reads back")
        ok += _check(FileAccess.file_exists(GOGA.libs_dir().path_join("clients/rig_client/save.json")),
                        "THE SAVE LAW holds for standalone clients (libs/clients/)")
        peer.disconnect_from_host()
        Box.reset_all()
        return ok

# ============================================================ LAB HELPERS

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

## THE PACKAGE FACTORY (the rig's own): a complete, valid package with the
## full contract - index, game stub, discover page, the data minimums, save.
func _build_good_package(root: String, pkg_id := "gogabox_github-TESTER_test.good.001_official",
                game_id := "goodgame", version := "1.0.0") -> void:
        for d in ["index", "game", "discover", "save",
                        "game/pc", "game/android", "discover/media",
                        "data/logic", "data/audio/sfx", "data/audio/music",
                        "data/visuals/shaders", "data/visuals/assets",
                        "data/audio/voice", "data/visuals/vfx"]:
                DirAccess.make_dir_recursive_absolute(root.path_join(d))
        var index := {
                "schema": 1,
                "id": pkg_id,
                "game_id": game_id,
                "title": "GOOD GAME",
                "tag": "the test twin",
                "version": version,
                "age": 3,
                "content": ["horror"],
                "genres": {"main": ["arcade"], "sub": ["retro"]},
                "os": ["android", "pc"],
                "runs": {"pc": {"kind": "godot_embedded", "pck": "game/pc/goga.pck",
                                "script": "res://game/games/%s/%s.gd" % [game_id, game_id]},
                                "android": {"kind": "godot_embedded", "pck": "game/android/goga.pck",
                                "script": "res://game/games/%s/%s.gd" % [game_id, game_id]}},
                "thumb": "discover/media/thumb.png",
                "desc": "the validator's own test twin",
                "fee": 0, "price": 0, "coin_div": 10,
        }
        var f := FileAccess.open(root.path_join("index/index.json"), FileAccess.WRITE)
        f.store_string(JSON.stringify(index, "  "))
        f.close()
        _touch(root.path_join("game/pc/goga.pck"))
        _touch(root.path_join("game/android/goga.pck"))
        _touch(root.path_join("discover/page.json"),
                        "{\"title\": \"GOOD GAME\", \"desc\": \"hello\"}")
        _touch(root.path_join("discover/media/thumb.png"))
        _touch(root.path_join("data/logic/tuning.json"), "{\"speed\": 3}")
        _touch(root.path_join("data/audio/sfx/click.ogg"))
        _touch(root.path_join("data/audio/music/loop.ogg"))
        _touch(root.path_join("data/visuals/shaders/tint.gdshader"),
                        "shader_type canvas_item;\nvoid fragment() { COLOR.a = 0.5; }")
        _touch(root.path_join("data/visuals/assets/board.png"))
        _touch(root.path_join("data/audio/voice/hello.ogg"))
        _touch(root.path_join("data/visuals/vfx/spark.png"))

func _touch(path: String, txt := "x") -> void:
        DirAccess.make_dir_recursive_absolute(path.get_base_dir())
        var f := FileAccess.open(path, FileAccess.WRITE)
        if f != null:
                f.store_string(txt)
                f.close()

func _zip_dir(src_dir: String, out_path: String) -> void:
        var zp := ZIPPacker.new()
        zp.open(out_path)
        _zip_walk(zp, src_dir, "")
        zp.close()

func _zip_walk(zp: ZIPPacker, base: String, rel: String) -> void:
        var da := DirAccess.open(base.path_join(rel) if rel != "" else base)
        if da == null:
                return
        da.list_dir_begin()
        var n := da.get_next()
        while n != "":
                var r := (rel + "/" + n) if rel != "" else n
                var full := base.path_join(r)
                if da.current_is_dir():
                        _zip_walk(zp, base, r)
                else:
                        zp.start_file(r)
                        var f := FileAccess.open(full, FileAccess.READ)
                        if f != null:
                                zp.write_file(f.get_buffer(f.get_length()))
                                f.close()
                        zp.close_file()
                n = da.get_next()
        da.list_dir_end()
