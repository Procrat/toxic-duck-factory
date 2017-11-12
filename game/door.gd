extends Node2D

signal toggled

onready var open_sprite = get_node("open")
onready var closed_sprite = get_node("closed")

var open = true setget set_open

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
