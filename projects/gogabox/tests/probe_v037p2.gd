extends Node
## probe_v037p2 - the v0.3.7-2 law battery: THE WORLD AUDIT (every geometry
## pattern, rated: no orbit ever inside a block/hazard, no structure
## intersections), THE SAME-PHYSICS LAW (the geoquare tumbles exactly like
## the normal square - the flip law is dead), THE FLAT WAIT LAW (the
## tap-anywhere world is flat forever + the calm re-stamp), and THE FEED
## RESTORE (the old reveal map, no age keys, no GOGAds). Exit 0 = all green.

var checks := 0
var fails := 0

func ck(cond: bool, what: String) -> void:
        checks += 1
        if cond:
                print("[PASS] ", what)
        else:
                fails += 1
                print("[FAIL] ", what)

func _run() -> void:
        print("=== probe_v037p2 ===")
        await _world_audit()
        await _random_world_audit()
        await _same_physics()
        await _flat_wait()
        _feed_restore()
        print("RESULT: %d checks, %d failures" % [checks, fails])
        get_tree().quit(1 if fails > 0 else 0)

# ============================================================ THE WORLD AUDIT
# The owner: "there is a situation where the world make an orbit directly
# literally overlapped in a block - test the world and see every single
# pattern to rate it". Design-px rect math (from the code): a block/pusher
# spans [x - C/2, x + C/2] x [y0, y1]; the orbit sprite is 128px * 0.5 = 64
# wide (r 32) with the 58 collect ring; spike3 is a 116x48 box; spike r34;
# saw r38. THE LAW: an orbit's visual disk (+ 8px margin) never touches a
# solid or a hazard; two solids never intersect (2px seam tolerance).

const C := 84.0
const ORB_R := 40.0            # 32 visual + 8 margin
const SEAM := 2.0

var G: GogaGame
var flip_vars_dead := false
var flip_funcs_dead := false

func _boot_geom(do_reset := true) -> void:
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        Box.bump_counter("geometry", "geoquare_lore", 1)   # the lore stays quiet
        get_window().size = Vector2i(1920, 1080)
        G = load("res://game/games/geometry/geometry.gd").new()
        G.game_id = "geometry"
        process_mode = Node.PROCESS_MODE_ALWAYS
        add_child(G)
        await get_tree().create_timer(0.8).timeout
        if do_reset:
                # the probe contract: reseed + PREFILL (the audit trials snapshot
                # the array sizes AFTER this, so the prefill is never counted)
                G.probe_reset(20260909)

func _circle_hits_rect(px: float, py: float, r: float, rc: Rect2) -> bool:
        var cx: float = clampf(px, rc.position.x, rc.end.x)
        var cy: float = clampf(py, rc.position.y, rc.end.y)
        return Vector2(cx - px, cy - py).length() < r

func _audit_slice(push: Array, orbi: Array, haz: Array, tag: String) -> int:
        var bad := 0
        var rects: Array = []
        for p in push:
                var x: float = float(p["x"])
                rects.append(Rect2(x - C * 0.5, float(p["y0"]), C, float(p["y1"]) - float(p["y0"])))
        for o in orbi:
                var ox: float = float(o["x"])
                var oy: float = float(o["y"])
                for rc in rects:
                        if _circle_hits_rect(ox, oy, ORB_R, rc):
                                bad += 1
                                print("    [OVERLAP] %s: orbit (%.0f, %.0f) inside block %s"
                                                % [tag, ox, oy, rc])
                for h in haz:
                        var hx: float = float(h["x"])
                        var hy: float = float(h["y"])
                        var hw: float = float(h.get("hw", 0.0))
                        if hw > 0.0:
                                # spike3: an axis box
                                var hb := Rect2(hx - hw, hy - float(h["hh"]), hw * 2.0, float(h["hh"]) * 2.0)
                                if _circle_hits_rect(ox, oy, ORB_R, hb):
                                        bad += 1
                                        print("    [OVERLAP] %s: orbit (%.0f, %.0f) inside hazard %s" % [tag, ox, oy, h["kind"]])
                        else:
                                var rr: float = float(h["r"]) + ORB_R
                                if Vector2(hx - ox, hy - oy).length() < rr:
                                        bad += 1
                                        print("    [OVERLAP] %s: orbit (%.0f, %.0f) inside hazard %s" % [tag, ox, oy, h["kind"]])
        # solid vs solid
        for i in rects.size():
                for j in range(i + 1, rects.size()):
                        var a: Rect2 = rects[i]
                        var b: Rect2 = rects[j]
                        var inter := a.intersection(b)
                        if inter.size.x > SEAM and inter.size.y > SEAM:
                                bad += 1
                                print("    [STRUCT] %s: blocks intersect %s vs %s" % [tag, a, b])
        # orbit vs orbit stacking (two rings on the same spot read as junk)
        for i in orbi.size():
                for j in range(i + 1, orbi.size()):
                        var d: float = Vector2(float(orbi[i]["x"]) - float(orbi[j]["x"]),
                                        float(orbi[i]["y"]) - float(orbi[j]["y"])).length()
                        if d < ORB_R:
                                bad += 1
                                print("    [STACK] %s: orbits %.0f apart" % [tag, d])
        return bad

func _truncate(n_push: int, n_orb: int, n_haz: int, n_g: int, n_r: int, n_l: int) -> void:
        while G.pushers.size() > n_push:
                var p: Dictionary = G.pushers.pop_back()
                if p.get("spr") != null and is_instance_valid(p["spr"]):
                        p["spr"].queue_free()
        while G.orbits.size() > n_orb:
                var o: Dictionary = G.orbits.pop_back()
                if o.get("spr") != null and is_instance_valid(o["spr"]):
                        o["spr"].queue_free()
        while G.hazards.size() > n_haz:
                var h: Dictionary = G.hazards.pop_back()
                if h.get("spr") != null and is_instance_valid(h["spr"]):
                        h["spr"].queue_free()
        while G.gsegs.size() > n_g:
                var s: Dictionary = G.gsegs.pop_back()
                if s.get("spr") != null and is_instance_valid(s["spr"]):
                        s["spr"].queue_free()
        while G.rsegs.size() > n_r:
                var s: Dictionary = G.rsegs.pop_back()
                if s.get("spr") != null and is_instance_valid(s["spr"]):
                        s["spr"].queue_free()
        while G.lines.size() > n_l:
                var s: Dictionary = G.lines.pop_back()
                if s.get("spr") != null and is_instance_valid(s["spr"]):
                        s["spr"].queue_free()

## One pattern trial: generate at the cursor, audit the slice, wipe it.
func _trial(fn: String, lvl: int, mech: String, seed_v: int) -> int:
        G.probe_reset(seed_v)
        G.speed_level = lvl
        G.mechanic = mech
        G.player["g"] = -1 if mech == "flip" else 1
        var n_push: int = G.pushers.size()
        var n_orb: int = G.orbits.size()
        var n_haz: int = G.hazards.size()
        var n_g: int = G.gsegs.size()
        var n_r: int = G.rsegs.size()
        var n_l: int = G.lines.size()
        var w: float = G.call(fn, 4000.0)
        if w <= 0.0:
                print("    [DEAD] %s returned width %.1f" % [fn, w])
                return 1
        var bad := _audit_slice(G.pushers.slice(n_push), G.orbits.slice(n_orb),
                        G.hazards.slice(n_haz), "%s L%d" % [fn.trim_prefix("_chunk_").trim_prefix("_gen_"), lvl])
        _truncate(n_push, n_orb, n_haz, n_g, n_r, n_l)
        return bad

func _world_audit() -> void:
        await _boot_geom()
        var patterns: Array = []
        for p in ["_chunk_flat", "_chunk_pit", "_chunk_push", "_chunk_spikes",
                        "_chunk_deck", "_chunk_stairs", "_chunk_garden", "_chunk_pyramid",
                        "_chunk_descent", "_chunk_down", "_chunk_mixed", "_chunk_gate",
                        "_chunk_valley", "_chunk_wave", "_chunk_islands", "_chunk_highway",
                        "_chunk_towers", "_chunk_twin", "_chunk_bridge", "_chunk_ladder",
                        "_chunk_weave", "_chunk_floaters", "_chunk_saw", "_chunk_roof",
                        "_chunk_roof_stairs", "_chunk_roof_yard", "_gen_calm"]:
                patterns.append(p)
        var trials := 0
        var total_bad := 0
        var per_pattern := {}
        for fn in patterns:
                var bad := 0
                for t in 10:
                        # spread the trials over levels 0..5, both sides of the gravity
                        var lvl := t % 6
                        var mech := "normal" if t % 2 == 0 else "flip"
                        bad += _trial(fn, lvl, mech, 20260909 + t * 77)
                        trials += 1
                per_pattern[fn] = bad
                total_bad += bad
        ck(total_bad == 0,
                        "THE WORLD AUDIT: all %d patterns PASS (%d trials, %d violations)"
                        % [patterns.size(), trials, total_bad])
        for fn in patterns:
                var bad: int = per_pattern[fn]
                if bad > 0:
                        print("    [RATING] %s: FAIL (%d)" % [fn, bad])
        G.queue_free()
        await get_tree().process_frame

## The REAL pool path: 300 chunks through _gen_chunk itself - the mix the
## player actually meets, plus the cross-chunk seam check.
func _random_world_audit() -> void:
        await _boot_geom()
        G.probe_reset(424242)
        var bad := 0
        var n_push: int = G.pushers.size()
        var n_orb: int = G.orbits.size()
        var n_haz: int = G.hazards.size()
        var n_g: int = G.gsegs.size()
        var n_r: int = G.rsegs.size()
        var n_l: int = G.lines.size()
        var prev_rects: Array = []
        var cursor := 4000.0
        for i in 300:
                G.speed_level = i % 6
                G.mechanic = "flip" if (i / 50) % 2 == 1 else "normal"
                G.player["g"] = -1 if G.mechanic == "flip" else 1
                var b_push: int = G.pushers.size()
                var b_orb: int = G.orbits.size()
                var b_haz: int = G.hazards.size()
                var w: float = G._gen_chunk(cursor)
                var push: Array = G.pushers.slice(b_push)
                # cross-chunk: this chunk's solids vs the previous chunk's solids
                var rects: Array = []
                for p in push:
                        var x: float = float(p["x"])
                        rects.append(Rect2(x - C * 0.5, float(p["y0"]), C, float(p["y1"]) - float(p["y0"])))
                for a in rects:
                        for b in prev_rects:
                                var inter: Rect2 = a.intersection(b)
                                if inter.size.x > SEAM and inter.size.y > SEAM:
                                        bad += 1
                                        print("    [CROSS] chunk %d: structure crosses the seam" % i)
                prev_rects = rects
                bad += _audit_slice(push, G.orbits.slice(b_orb), G.hazards.slice(b_haz),
                                "pool@%d" % i)
                cursor += w
        # one full wipe at the end
        G.probe_reset(424243)
        ck(bad == 0, "THE POOL AUDIT: 300 generated chunks PASS (%d violations)" % bad)
        G.queue_free()
        await get_tree().process_frame

# ========================================================= THE SAME PHYSICS
## The geoquare (the GEOMETRIC square) must tick-for-tick MATCH the normal
## square's tumble on the flat start ledge - one law, one physics, two
## skins. Each walk runs on a FRESH boot (no carry-over state), the style
## pre-equipped so the boot itself wears it.
func _walk_rot(geo: bool) -> Array:
        Box.reset_all()
        Box.dev_set_cheat("gogacoins", 0)
        Box.earn(20000)
        if not Box.skin_owned("hopper", "square"):
                Box.buy_skin("hopper", "square", 0)
        Box.equip_skin("hopper", "square")
        if geo:
                if not Box.item_owned("hopper", "style", "geometric"):
                        Box.buy_item("hopper", "style", "geometric", 0)
                Box.equip_item("hopper", "style", "geometric")
        get_window().size = Vector2i(1080, 1920)
        var H: GogaGame = load("res://game/games/hopper/hopper.gd").new()
        H.game_id = "hopper"
        process_mode = Node.PROCESS_MODE_ALWAYS
        add_child(H)
        await get_tree().process_frame
        await get_tree().process_frame
        H.char_id = "square"
        H.phase = "run"
        # the flip law must be GONE from the script entirely (no vars, no funcs)
        flip_vars_dead = H.get("flip_phase") == null and H.get("flip_base") == null
        flip_funcs_dead = not H.has_method("_update_flip") and not H.has_method("_cube_body")
        var rot: Array = []
        for i in 30:
                H._set_axis(120.0 * H.U)
                H._goga_tick(1.0 / 60.0)
                rot.append(H.tumble_rot)
        H._set_axis(0.0)
        H.queue_free()
        await get_tree().process_frame
        await get_tree().process_frame
        return rot

func _same_physics() -> void:
        var rot_a: Array = await _walk_rot(false)
        var rot_b: Array = await _walk_rot(true)
        ck(flip_vars_dead and flip_funcs_dead,
                        "THE FLIP LAW IS DEAD: no flip vars/functions on the tower")
        var same := rot_a.size() == rot_b.size()
        if same:
                for i in rot_a.size():
                        if absf(float(rot_a[i]) - float(rot_b[i])) > 0.0001:
                                same = false
                                print("    [PHYSICS] tick %d differs: %.5f vs %.5f" % [i, rot_a[i], rot_b[i]])
                                break
        ck(same, "THE SAME-PHYSICS LAW: the geoquare's rotation matches the normal square tick for tick")
        ck(float(rot_b[rot_b.size() - 1]) > 0.15,
                        "THE SAME-PHYSICS LAW: the walk really tumbles (rot %.2f after 30 ticks)"
                                % float(rot_b[rot_b.size() - 1]))

# =========================================================== THE FLAT WAIT
func _flat_wait() -> void:
        await _boot_geom(false)   # NO probe_reset - the live setup path only
        ck(G.orbits.is_empty() and G.hazards.is_empty() and G.pushers.is_empty()
                        and G.lines.is_empty(),
                        "THE FLAT WAIT LAW: the setup prefills NOTHING (no orbits/hazards/blocks/lines)")
        # let the ready gate breathe for a long simulated wait (the live tree
        # ticks the ready phase) - the world must stay flat
        for i in 120:
                await get_tree().process_frame
        ck(G.orbits.is_empty() and G.hazards.is_empty() and G.pushers.is_empty()
                        and G.lines.is_empty(),
                        "THE FLAT WAIT LAW: a long wait builds NOTHING but flat ground + roof")
        # the flat feed covers the horizon (no void ahead)
        var horizon: float = G.world_x + G._vp().x / G.us
        var covered := false
        for s in G.gsegs:
                if float(s["x0"]) <= horizon and float(s["x1"]) >= horizon:
                        covered = true
        ck(covered, "THE FLAT WAIT LAW: the ground reaches past the screen edge")
        # the start re-stamps the 6s calm runway from wherever the wait ended
        G._ready_start()
        ck(absf(G.calm_until - (G.world_x + G.BASE_SPEED * 6.0)) < 0.5,
                        "THE CALM RE-STAMP: the 6s runway is measured from the wait's end")
        G.queue_free()
        await get_tree().process_frame

# ========================================================== THE FEED RESTORE
func _feed_restore() -> void:
        Box.reset_all()
        # the old reveal map: chains are chains
        for gid in ["lanes", "slasher", "merge", "dario", "xo", "invaders"]:
                ck(String(GameReg.get_game(gid).get("reveal", {}).get("kind", "")) == "chain",
                                "THE FEED RESTORE: %s is a plain chain again" % gid)
        # the direct reveals + the honest meters
        var m: Dictionary = GameReg.get_game("matcher")
        ck(int(m.get("charge_unlock", 0)) == 100
                        and String(m.get("reveal", {}).get("kind", "")) == "direct",
                        "THE FEED RESTORE: matcher = direct + the 100 meter")
        var ps: Dictionary = GameReg.get_game("pop_siege")
        ck(int(ps.get("charge_unlock", 0)) == 100, "THE FEED RESTORE: pop siege meter 100")
        var cs: Dictionary = GameReg.get_game("cosmic_spud")
        ck(int(cs.get("charge_unlock", 0)) == 200
                        and String(cs.get("reveal", {}).get("kind", "")) == "direct",
                        "THE FEED RESTORE: cosmic spud = direct + the 200 meter")
        for gid in ["geometry", "maze"]:
                var g: Dictionary = GameReg.get_game(gid)
                ck(int(g.get("reveal", {}).get("appear_after", -1)) == 0,
                                "THE FEED RESTORE: %s reveals direct from the start" % gid)
        # no age keys anywhere, no gogads anywhere
        var age_free := true
        var ads_free := true
        for g in GameReg.GAMES:
                if g.has("age"):
                        age_free = false
                if g.has("gogads"):
                        ads_free = false
        ck(age_free, "THE AGE EXTINCTION: the registry carries no age keys")
        ck(ads_free, "THE GOGADS NUKE: the registry carries no ad breaks")
        # v0.3.8: domino + chess graduate from the SOON row - 16 playable,
        # 3 teasers still waiting (fourline / bovo / dots)
        ck(GameReg.playable().size() == 16, "THE SHELF: 16 playable games")
        ck(GameReg.workshop().size() == 3, "THE SHELF: 3 SOON teasers wait")
        ck(get_node_or_null("/root/GOGAds") == null, "THE GOGADS NUKE: the autoload is gone")

func _ready() -> void:
        _run.call_deferred()
