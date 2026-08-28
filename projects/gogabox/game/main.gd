extends Node2D
## GOGABox bootstrap. The menu is the app; games are hosted on top of it.

const MenuScene := preload("res://game/menu/menu.gd")

func _ready() -> void:
	var menu := Node2D.new()
	menu.set_script(load("res://game/menu/menu.gd"))
	add_child(menu)
