extends Node

const map_generate = preload("map_generate.gd")
const wall = preload("game/wall.tscn")
const floor_ = preload("game/floor.tscn")
const safe_area = preload("game/safe_area.tscn")
const duck_factory = preload("sprites/ducks/duck idle.tscn")
const door_factory = preload("game/door.tscn")

const WIDTH = 20
const HEIGHT = 15
const DUCKS = 8
const EXTRA_DOORS = 15
const RANDOM_TRIES = 100

var CELL = floor_.instance().get_item_rect()

onready var nav = get_node("nav")

func _ready():
	generate_level()

func generate_level():
	var base_and_map = map_generate.generate_map(HEIGHT, WIDTH)
	var base = base_and_map[0]
	var map = base_and_map[1]
	nav.map = map
	nav.cell = CELL
	construct_map(map)
	
	nav.door_map = place_doors(map, base)
	
	place_ducks(map)

func construct_map(map):
	print('cell size:', CELL)
	var row_idx = 0
	for row in map:
		var col_idx = 0
		for cell_type in row:
			var cell = construct_cell(cell_type)
			cell.set_pos(nav.tile2_to_world(row_idx, col_idx))
			nav.add_child(cell)
			col_idx += 1
		row_idx += 1
	
	# OS.set_window_size(Vector2(map[0].size() * CELL.size.x, map.size() * CELL.size.y))

func construct_cell(cell_type):
	if cell_type == map_generate.WALL:
		return wall.instance()
	elif cell_type == map_generate.FLOOR:
		return floor_.instance()
	elif cell_type == map_generate.BASE:
		return safe_area.instance()

func place_ducks(map):
	var ducks = []
	for _ in range(DUCKS):
		var duck = duck_factory.instance()
		duck.set_pos(nav.tile_to_world(get_random_free_pos(map, ducks)))
		ducks.append(duck)
		nav.add_child(duck)

func get_random_free_pos(map, existing_ducks):
	for _ in range(RANDOM_TRIES):
		var row = randi() % map.size()
		var col = randi() % map[row].size()
		var pos = map_generate.P.new(row, col)
		if map[row][col] != map_generate.WALL and not pos in existing_ducks:
			return pos
	return map_generate.P.new(-1, -1)

func place_doors(map, base):
	var doors = []
	
	# Doors around base
	for cell in base.extensions:
		var rotated = (map[cell.row][cell.col - 1] != map_generate.WALL or
		               map[cell.row][cell.col + 1] != map_generate.WALL)
		doors.append([cell, rotated])
	
	# Doors in random places
	for _ in range(EXTRA_DOORS):
		var door = pick_random_cell_for_door(map, doors)
		doors.append(door)
	
	var door_map = map_generate.array_2d(map.size(), map[0].size(), null)
	
	for door_config in doors:
		var pos = door_config[0]
		var rotated = door_config[1]
		var door = door_factory.instance()
		door.set_pos(nav.tile_to_world(pos))
		door.open = randf() < 0.5
		door.set_rot(PI / 2 if rotated else 0)
		nav.add_child(door)
		door_map[pos.row][pos.col] = door
	
	return door_map

func pick_random_cell_for_door(map, doors):
	for _ in range(RANDOM_TRIES):
		var cell = map_generate.random_point(map)
		if map_generate.is_floor(map, cell) and not doors_contains(doors, cell):
			# If there are walls to the left and right for attaching a door
			if (not map_generate.is_floor(map, cell.add(map_generate.P.new(0, -1))) and
			    not map_generate.is_floor(map, cell.add(map_generate.P.new(0, 1)))):
				# But no third wall (above or below)
				if (map_generate.is_floor(map, cell.add(map_generate.P.new(-1, 0))) and
				    map_generate.is_floor(map, cell.add(map_generate.P.new(1, 0)))):
					return [cell, false]
			# If there are walls above and below for attaching a door
			elif (not map_generate.is_floor(map, cell.add(map_generate.P.new(-1, 0))) and
			      not map_generate.is_floor(map, cell.add(map_generate.P.new(1, 0)))):
				# But no third wall
				if (map_generate.is_floor(map, cell.add(map_generate.P.new(0, -1))) and
				    map_generate.is_floor(map, cell.add(map_generate.P.new(0, 1)))):
					return [cell, true]

func doors_contains(doors, cell):
	for door in doors:
		if cell.equals(door[0]):
			return true
	return false