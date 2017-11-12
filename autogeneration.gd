extends Node

const map_generate = preload("map_generate.gd")
const wall = preload("game/wall.tscn")
const floor_ = preload("game/floor.tscn")
const duck_factory = preload("sprites/ducks/duck idle.tscn")

const WIDTH = 20
const HEIGHT = 15
const DUCKS = 8
const RANDOM_TRIES = 100

var CELL = floor_.instance().get_item_rect()

onready var nav = get_node("nav")

func _ready():
	generate_level()

func generate_level():
	var map = map_generate.generate_map(HEIGHT, WIDTH)
	nav.map = map
	nav.cell = CELL
	construct_map(map)
	
	var ducks = []
	for _ in range(DUCKS):
		var duck = duck_factory.instance()
		duck.set_pos(nav.tile_to_world(get_random_free_pos(map, ducks)))
		ducks.append(duck)
		nav.add_child(duck)

func construct_map(map):
	print('cell size:', CELL)
	var row_idx = 0
	for row in map:
		var col_idx = 0
		for cell_type in row:
			var cell = wall.instance() if cell_type == map_generate.WALL else floor_.instance()
			cell.set_pos(nav.tile2_to_world(row_idx, col_idx))
			nav.add_child(cell)
			col_idx += 1
		row_idx += 1
	
	# OS.set_window_size(Vector2(map[0].size() * CELL.size.x, map.size() * CELL.size.y))

func get_random_free_pos(map, existing_ducks):
	for _ in range(RANDOM_TRIES):
		var row = randi() % map.size()
		var col = randi() % map[row].size()
		var pos = Vector2(col, row)
		if map[row][col] != map_generate.WALL and not pos in existing_ducks:
			return pos
	return Vector2(-1, -1)