extends Node2D

signal toggled

const map_generate = preload("res://map_generate.gd")

onready var open_sprite = get_node("open")
onready var closed_sprite = get_node("closed")

var open = true setget set_open
var tile
var horizontal

func _ready():
	set_process_input(true)
	set_sprite()
	
func _input(event):
	if event.type == InputEvent.MOUSE_BUTTON and event.pressed:
		open = not open
		set_sprite()
		emit_signal("toggled")

func set_open(new_open):
	open = new_open
	set_sprite()

func set_sprite():
	if open_sprite:
		open_sprite.set_hidden(not open)
	if closed_sprite:
		closed_sprite.set_hidden(open)

func attachments():
	if horizontal:
		return [tile.add(map_generate.P.new(0, -1)),
		        tile.add(map_generate.P.new(0, 1))]
	else:
		return [tile.add(map_generate.P.new(-1, 0)),
		        tile.add(map_generate.P.new(1, 0))]