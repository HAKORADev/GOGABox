extends Node
## qa_v038p3 - the v0.3.8-3 rigs: THE SHIELD TRUTH, THE ROSTER FACES, THE
## DEAL THEATER, THE PIP TRUTH, THE FIT LAW, THE GOALS SEAT - all watched.
## Rigs (QA_RIG env):
##  shield   - a TRI-SHIELD mid-fight: the shatter orbit + the layer shell
##             (some areas chewed to lower levels, one window open)
##  prism    - THE PRISM MATRIARCH: the full 5-layer shell + 2 shards
##  allies   - all SIX allies deployed around the potato (the roster faces)
##  deal     - DOMINO mid-deal: tiles in flight from the yard to both fans
##  domino   - DOMINO mid-game: a full snake, the goals stack above the
##             rail, the CPU label between fan and felt, a 6-6 in the hand
##  pips     - DOMINO pip truth: every value 0-6 drawn both orientations
##  contact  - COSMIC SPUD contact: a chunk pressed on the rim (the ram)
##  hud      - COSMIC SPUD HUD: the XP bar + the SKILL POINTS meter under it
##
##  QA_RIG=<rig> xvfb-run -a godot --path . res://tests/qa_v038p3.tscn

var frames := 0
var rig_id := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var rig := OS.get_environment("QA_RIG")
	if rig.is_empty():
		rig = "shield"
	rig_id = rig
	DirAccess.make_dir_recursive_absolute("/tmp/qa_v038p3")
	match rig_id:
		"shield", "allies", "contact", "hud", "prism":
			await _cs_rig(rig_id)
		"deal", "domino", "pips":
			await _dom_rig(rig_id)
	print("[qa_v038p3] rig %s done: %d frames" % [rig_id, frames])
	get_tree().quit(0)

func _settle(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _snap(tag: String) -> void:
	await _settle(3)
	var img := get_viewport().get_texture().get_image()
	var path := "/tmp/qa_v038p3/%s_%s_%03d.png" % [tag, rig_id, frames]
	img.save_png(path)
	frames += 1

# ------------------------------------------------------------- cosmic spud
func _cs_rig(rig: String) -> void:
	var G: GogaGame = load("res://game/games/cosmic_spud/cosmic_spud.gd").new()
	G.game_id = "cosmic_spud"
	add_child(G)
	for i in 40:
		await get_tree().process_frame
	var meta: CSMeta = G.meta
	meta.d["coins"] = 2600
	meta.d["kills"] = 340
	meta.save()
	G._cc_pull()
	# start a real run so the world + the HUD exist
	G._start_run()
	await _settle(30)
	match rig:
		"shield":
			# one tri-shield with a chewed shell: area 0 at lv1, area 1
			# windowed, the rest alive
			G.enemies.clear()
			var t: Dictionary = G._spawn_enemy("trishield",
					G.p_pos + Vector2(240, -40))
			var outer: Dictionary = t["shield"]["layers"][0]
			(outer["areas"] as Array)[0]["hp"] = 0.4
			(outer["areas"] as Array)[1]["hp"] = 0.0
			(outer["areas"] as Array)[2]["hp"] = 2.0
			await _settle(12)
			await _snap("shield_a")
			await _settle(30)
			await _snap("shield_b")
		"prism":
			G.enemies.clear()
			G.run_wave = 20
			G._spawn_boss(20)
			var pb: Dictionary = G.enemies[0]
			var layers: Array = pb["shield"]["layers"]
			# chew the outer layer: two windows + a mid level
			(layers[0]["areas"] as Array)[0]["hp"] = 0.0
			(layers[0]["areas"] as Array)[1]["hp"] = 2.0
			(layers[1]["areas"] as Array)[2]["hp"] = 1.0
			await _settle(12)
			await _snap("prism_a")
			await _settle(40)
			await _snap("prism_b")
		"allies":
			G.enemies.clear()
			for aid in ["drone", "turret", "guard", "medic", "bomber", "scout"]:
				G._deploy_ally(aid, 1)
			await _settle(20)
			await _snap("allies_a")
			# a couple of enemies so the crew works
			G._spawn_enemy("blab", G.p_pos + Vector2(260, -60))
			G._spawn_enemy("sprinter", G.p_pos + Vector2(-240, 80))
			await _settle(40)
			await _snap("allies_b")
		"contact":
			G.enemies.clear()
			G.p_iframe = 0.0
			G._spawn_enemy("chunk", G.p_pos + Vector2(26, 0))
			G._tick_enemies(0.016)
			await _settle(4)
			await _snap("contact_a")
			await _settle(20)
			await _snap("contact_b")
		"hud":
			await _settle(10)
			await _snap("hud_a")
			G.run_kills = 62
			G._refresh_hud()
			await _settle(30)
			await _snap("hud_b")

# ----------------------------------------------------------------- domino
func _dom_rig(rig: String) -> void:
	var G: GogaGame = load("res://game/games/domino/domino.gd").new()
	G.game_id = "domino"
	add_child(G)
	for i in 40:
		await get_tree().process_frame
	match rig:
		"deal":
			# restart into the deal and catch the flights mid-air
			G._new_round()
			G.state = "deal"
			await _settle(10)
			await _snap("deal_early")
			await _settle(14)
			await _snap("deal_mid")
			await _settle(40)
			await _snap("deal_late")
			await _settle(60)
			await _snap("deal_done")
		"domino":
			# a real mid-game snake: play a deterministic chain
			G._new_round()
			G.state = "deal"
			for i in 28:
				await get_tree().process_frame
			await _settle(120)   # let the deal land
			var chain: Array = [[6, 6], [6, 4], [4, 4], [4, 2], [2, 3],
					[3, 5], [5, 5], [5, 0], [0, 1]]
			G.chain.clear()
			for c in chain:
				G.chain.append({"a": c[0], "b": c[1], "fl": false,
						"who": 1, "landed": true})
			G.hand_p = [[6, 6], [5, 2], [4, 1]]
			G._relayout()
			await _settle(10)
			await _snap("domino_a")
		"pips":
			G._new_round()
			G.state = "deal"
			for i in 10:
				await get_tree().process_frame
			await _settle(130)
			# the pip truth: both orientations, every value - drawn as a
			# chain of doubles and a run of mixed tiles
			G.chain.clear()
			for v in 7:
				G.chain.append({"a": v, "b": v, "fl": false, "who": 1,
						"landed": true})   # the doubles: vertical
			G._relayout()
			await _settle(8)
			await _snap("pips_doubles")
			G.chain.clear()
			for v in 7:
				var other: int = (v + 3) % 7
				G.chain.append({"a": v, "b": other, "fl": false, "who": 1,
						"landed": true})   # mixed: horizontal
			G._relayout()
			await _settle(8)
			await _snap("pips_mixed")
