const DEBUG = false
const LOOPING_PROBABILITY = 0.1
const WALL = '█'
const FLOOR = ' '
const BASE = '░'


class P:
	var row = 0
	var col = 0
	
	func _init(row, col):
		self.row = int(row)
		self.col = int(col)

	func add(other):
		return make_new(self.row + other.row, self.col + other.col)

	func equals(other):
		return self.row == other.row and self.col == other.col
		
	static func make_new(x, y):
		return new(x, y)


static func four_directions():
	return [P.new(0, 1), P.new(1, 0), P.new(0, -1), P.new(-1, 0)]


static func generate_map(height, width):
	var inner_map = generate_inner_map(height - 2, width - 2)
	
	var wall_row = []
	for _ in range(width):
		wall_row.append(WALL)
	
	var outer_map = []
	outer_map.append(wall_row)
	for row in inner_map:
		row.push_front(WALL)
		row.push_back(WALL)
		outer_map.append(row)
	outer_map.append(wall_row)
	
	return outer_map

static func generate_inner_map(height, width):
	randomize()
	
	# TODO four starting points for now
	var starting_points = []
	for p in [P.new(0, 0), P.new(0, 1), P.new(1, 0), P.new(1, 1)]:
		starting_points.append(P.new((height - 1) / 2, (width - 1) / 2).add(p))

	var map_ = array_2d(height, width)
	for starting_point in starting_points:
		set_content(map_, starting_point, BASE)

	var paths = []
	var i = 0

	for starting_point in starting_points:
		debug('Constructing path %d' % i)
		var length = rand_range(1, width + height)
		var path = make_path(map_, starting_point, length)
		if path.size() > 0:
			paths.append(path)
			debug_map(map_)
		i += 1

	var n_extra_paths = 2 * (width + height)
	debug('Constructing %d extra paths' % n_extra_paths)

	for _ in range(n_extra_paths):
		debug('Constructing extra path %d' % i)
		debug(paths)
		var path = paths[randi() % paths.size()]
		var starting_point = path[randi() % path.size()]
		var length = rand_range(1, 2 * (width + height))
		var path = make_path(map_, starting_point, length)
		if path.size() > 0:
			paths.append(path)
			debug_map(map_)
		i += 1

	return map_


static func array_2d(height, width):
	var array = []
	for _ in range(height):
		var row = []
		for _ in range(width):
			row.append(WALL)
		array.append(row)
	return array


static func make_path(map_, starting_point, length):
	debug('Making path from %s of length %d' % [starting_point, length])

	var path = []
	var last_pos = starting_point
	for _ in range(length):
		var next_places = possible_next_places(map_, last_pos)
		if next_places.size() == 0:
			debug('No future for this path!')
			break
		var cell = next_places[randi() % next_places.size()]
		path.append(cell)
		make_floor(map_, cell)
		debug('adding %s to path' % cell)
		debug_map(map_)
		last_pos = cell
	debug(path)
	return path


static func possible_next_places(map_, pos):
	var places = []
	for direction in four_directions():
		var possible_next_place = pos.add(direction)
		debug('checking next place: %s' % possible_next_place)

		if not is_within_boundaries(map_, possible_next_place):
			continue

		# Should not be necessary anymore
		#  if is_floor(map_, possible_next_place):
		#	  continue

		if has_surrounding_floor(map_, possible_next_place, direction):
			continue

		debug('valid possibility found!')

		places.append(possible_next_place)
	return places


static func is_within_boundaries(map_, pos):
	return (0 <= pos.row and pos.row < map_.size() and
	        0 <= pos.col and pos.col < map_[0].size())


static func has_surrounding_floor(map_, pos, direction):
	for side in sides(pos, direction):
		debug('side: %s' % side)
		if not is_within_boundaries(map_, side):
			continue

		if is_floor(map_, side):
			return true

	var in_front = pos.add(direction)
	debug('in front: %s' % in_front)
	if (is_within_boundaries(map_, in_front) and
			is_floor(map_, in_front)):

		if randf() < LOOPING_PROBABILITY:
			debug('looping')
			return false

		return false

	for surrounding in diagonal_in_front(pos, direction):
		debug('directed surrounding: %s' % surrounding)

		if not is_within_boundaries(map_, surrounding):
			continue

		if is_floor(map_, surrounding):
			return true

	return false


static func sides(pos, direction):
	if direction.row == 0:
		return [pos.add(P.new(-1, 0)),
		        pos.add(P.new(1, 0))]
	else:
		return [pos.add(P.new(0, -1)),
		        pos.add(P.new(0, 1))]


static func diagonal_in_front(pos, direction):
	if direction.row == 0:
		return [pos.add(direction).add(P.new(-1, 0)),
		        pos.add(direction).add(P.new(1, 0))]
	else:
		return [pos.add(direction).add(P.new(0, -1)),
		        pos.add(direction).add(P.new(0, 1))]


static func is_floor(map_, point):
	var content = map_[point.row][point.col]
	return content in [FLOOR, BASE]


static func make_floor(map_, point):
	set_content(map_, point, FLOOR)


static func set_content(map_, point, value):
	map_[point.row][point.col] = value


static func print_map(map_):
	for row in map_:
		for char in row:
			printraw(char, char)
		print()


static func debug_map(map_):
	if DEBUG:
		for row in map_:
			for char in row:
				printraw(char, char)
			print()


static func debug(args):
	if DEBUG:
		print(args)
