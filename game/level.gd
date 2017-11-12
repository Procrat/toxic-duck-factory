extends Node

func _ready():
	get_node("door").connect("toggled", self, "update_duck_paths")

func update_duck_paths():
	get_tree().call_group(0, "ducks", "update_path")
