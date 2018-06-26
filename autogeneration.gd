extends Node

const map_generate = preload("map_generate.gd")
const wall = preload("game/blank tile.tscn")
const floor_ = preload("game/floor.tscn")
const safe_area = preload("game/safe_area.tscn")
const duck_factory = preload("sprites/ducks/duck idle.tscn")
const door_factory = preload("game/door.tscn")
const button_factory = preload("game/push it baby.tscn")
const wire_factory = preload("game/wire door left on.tscn")

const WIDTH = 20
const HEIGHT = 15
const DUCKS = 8
const EXTRA_DOORS = 15
const BUTTONS = 1
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
	
	var door_config = place_doors(map, base)
	var doors = door_config[0]
	nav.door_map = door_config[1]
	
	place_wires(map, doors)
	
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
	var door_poss = []
	
	# Doors around base
	for cell in base.extensions:
		var vertical = (map[cell.row][cell.col - 1] != map_generate.WALL or
		                map[cell.row][cell.col + 1] != map_generate.WALL)
		door_poss.append([cell, vertical])
	
	# Doors in random places
	for _ in range(EXTRA_DOORS):
		var door = pick_random_cell_for_door(map, door_poss)
		door_poss.append(door)
	
	var door_map = map_generate.array_2d(map.size(), map[0].size(), null)
	var doors = []
	for door_config in door_poss:
		var pos = door_config[0]
		var vertical = door_config[1]
		var door = door_factory.instance()
		door.set_pos(nav.tile_to_world(pos))
		door.set_rot(PI / 2 if vertical else 0)
		door.open = randf() < 0.5
		door.tile = pos
		door.horizontal = not vertical
		nav.add_child(door)
		door_map[pos.row][pos.col] = door
		doors.append(door)
	
	return [doors, door_map]

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


func place_wires(map, all_doors):
	var astar = construct_astar(map)
	for _ in range(BUTTONS):
		var connections = map_generate.random_int(2, 4)
		var connection_config = find_connected_doors(all_doors, connections, astar)
		var longest_path = connection_config[0]
		var other_doors = connection_config[1]
		var midway = longest_path[int(longest_path.size() / 2)]
		
		place_wires_along_path(longest_path)
		for door in other_doors:
			var path = find_path(astar, door.tile, midway)
			place_wires_along_path(path)
		
		var button = button_factory.instance()
		button.set_pos(nav.tile_to_world(midway))
		nav.add_child(button)

func construct_astar(map):
	var astar = AStar.new()
	
	for row in range(map.size()):
		for col in range(map[0].size()):
			if map[row][col] != map_generate.WALL:
				continue
				
			var id = tile2_to_astar_id(row, col)
			astar.add_point(id, vec2to3(nav.tile2_to_world(row, col)))
			
			if row > 0 and map[row - 1][col] == map_generate.WALL:
				astar.connect_points(id, tile2_to_astar_id(row - 1, col))
			if col > 0 and map[row][col - 1] == map_generate.WALL:
				astar.connect_points(id, tile2_to_astar_id(row, col - 1))
	
	return astar

func tile_to_astar_id(pos):
	return tile2_to_astar_id(pos.row, pos.col)

func tile2_to_astar_id(row, col):
	return row * WIDTH + col

func astar_id_to_tile(id):
	return map_generate.P.new(int(id / WIDTH), id % WIDTH)

func vec2to3(vec2):
	return Vector3(vec2.x, vec2.y, 0)

func vec3to2(vec3):
	return Vector2(vec3.x, vec3.y)

func find_connected_doors(all_doors, amount, astar):
	# for door in all_doors:
	# 	print(door, ": ", s(door.tile))
	
	# Returns longest path and other doors not contained in ends of path
	for door in all_doors:
		var config = find_connected_doors_recursive(all_doors, amount - 1, astar, [door], [])
		if config == null:
			continue
		
		print('--> connected doors found longest=', config[0], ' doors=', config[1])
		var longest_path = config[0]
		var chosen_doors = config[1]
		
		var filtered_doors = []
		for door in chosen_doors:
			if not door.tile.equals(longest_path[0]) and not door.tile.equals(longest_path[-1]):
				filtered_doors.append(door)
		
		return [longest_path, filtered_doors]
	
	return null

func s(point):
	return '%d,%d' % [point.row, point.col]

func find_connected_doors_recursive(all_doors, amount, astar, chosen_doors, longest_path):
	# print('recursing with ', amount, ' to go doors=', chosen_doors, ' longest=', longest_path)
	if amount <= 0:
		# print('Connection found! returning', [longest_path, chosen_doors])
		return [longest_path, chosen_doors]
	
	for door in all_doors:
		if door in chosen_doors:
			continue
		
		var locally_longest_path = is_fully_connected(door, chosen_doors, astar, longest_path)
		if locally_longest_path == null:
			continue
		
		var config = find_connected_doors_recursive(all_doors, amount - 1, astar, chosen_doors + [door], longest_path)
		if config == null:
			continue
		
		var longest_path = config[0]
		if locally_longest_path.size() > longest_path.size():
			# print('setting longest to: ', locally_longest_path)
			longest_path = locally_longest_path
		return [longest_path, config[1]]
	
	return null

func is_fully_connected(door, other_doors, astar, longest_path):
	for other_door in other_doors:
		var path = find_shortest_path_between_doors(astar, door, other_door)
		if path == null:
			return null
		if path.size() > longest_path.size():
			longest_path = path
	return longest_path

func find_shortest_path_between_doors(astar, door1, door2):
	var shortest_path = null
	for attachment1 in door1.attachments():
		for attachment2 in door2.attachments():
			var path = find_path(astar, attachment1, attachment2)
			if path.size() > 0:
				if shortest_path == null or path.size() < shortest_path.size():
					shortest_path = path
	return shortest_path

func find_path(astar, from_pos, to_pos):
	var pos_path = []
	var id_path = astar.get_id_path(tile_to_astar_id(from_pos), tile_to_astar_id(to_pos))
	for id in id_path:
		pos_path.append(astar_id_to_tile(id))
	return pos_path

func place_wires_along_path(path):
	for pos in path:
		var wire = wire_factory.instance()
		wire.set_pos(nav.tile_to_world(pos))
		print('placing wire on ', pos.row, ',', pos.col, ' = ', wire.get_pos())
		nav.add_child(wire)
	pass
