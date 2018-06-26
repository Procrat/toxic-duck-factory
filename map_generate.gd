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
	
	func sub(other):
		return make_new(self.row - other.row, self.col - other.col)
	
	func invert():
		return make_new(-self.row, -self.col)

	func equals(other):
		return self.row == other.row and self.col == other.col
		
	static func make_new(x, y):
		return new(x, y)


class Rect:
	var row
	var col
	var height
	var width
	
	func _init(row, col, height, width):
		self.row = row
		self.col = col
		self.height = height
		self.width = width
	
	func start():
		return P.new(row, col)


class Base:
	var rect
	var safe_area
	var extensions
	var starting_points
	
	func _init(rect, safe_area, extensions, starting_points):
		self.rect = rect
		self.safe_area = safe_area
		self.extensions = extensions
		self.starting_points = starting_points


static func four_directions():
	return [P.new(0, 1), P.new(1, 0), P.new(0, -1), P.new(-1, 0)]


static func generate_map(height, width):
	var base_and_inner_map = generate_inner_map(height - 2, width - 2)
	var base = base_and_inner_map[0]
	var inner_map = base_and_inner_map[1]
	
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
	
	base.rect.row += 1
	base.rect.col += 1
	for cell in base.safe_area + base.extensions + base.starting_points:
		cell.row += 1
		cell.col += 1
	
	return [base, outer_map]


static func generate_inner_map(height, width):
	randomize()
	
	var map_ = array_2d(height, width, WALL)
	
	var base = construct_base(map_, height, width)

	var paths = []
	var i = 0

	for starting_point in base.starting_points:
		debug('Constructing path %d' % i)
		var length = random_int(1, width + height)
		var path = make_path(map_, starting_point, length, base)
		if path.size() > 0:
			paths.append(path)
			debug_map(map_)
		i += 1

	var n_extra_paths = 2 * (width + height)
	debug('Constructing %d extra paths' % n_extra_paths)

	for _ in range(n_extra_paths):
		debug('Constructing extra path %d' % i)
		debug(paths)
		var path = random_choice(paths)
		var starting_point = random_choice(path)
		var length = random_int(1, 2 * (width + height))
		var path = make_path(map_, starting_point, length, base)
		if path.size() > 0:
			paths.append(path)
			debug_map(map_)
		i += 1

	return [base, map_]


static func array_2d(height, width, fill):
	var array = []
	for _ in range(height):
		var row = []
		for _ in range(width):
			row.append(fill)
		array.append(row)
	return array


static func construct_base(map, height, width):
	var base_rect = Rect.new(int((height - 1) / 2), int((width - 1) / 2), 2, 2)
	
	var safe_area = []
	for drow in range(base_rect.height):
		for dcol in range(base_rect.width):
			var cell = base_rect.start().add(P.new(drow, dcol))
			safe_area.append(cell)
			set_content(map, cell, BASE)
	
	if DEBUG:
		print('base rect: %d, %d, %d, %d' % [base_rect.row, base_rect.col, base_rect.height, base_rect.width])
	
	var extensions = []
	var starting_points = []
	
	# left
	var extension = base_rect.start().add(P.new(random_int(0, base_rect.height), -1))
	var extension2 = extension.add(P.new(0, -1))
	make_floor(map, extension)
	make_floor(map, extension2)
	extensions.append(extension)
	starting_points.append(extension2)
	debug_point('left1', extension)
	debug_point('left2', extension2)
	# right
	var extension = base_rect.start().add(P.new(random_int(0, base_rect.height), base_rect.width))
	var extension2 = extension.add(P.new(0, 1))
	make_floor(map, extension)
	make_floor(map, extension2)
	extensions.append(extension)
	starting_points.append(extension2)
	debug_point('right1', extension)
	debug_point('right2', extension2)
	# up
	var extension = base_rect.start().add(P.new(-1, random_int(0, base_rect.width)))
	var extension2 = extension.add(P.new(-1, 0))
	make_floor(map, extension)
	make_floor(map, extension2)
	extensions.append(extension)
	starting_points.append(extension2)
	debug_point('up1', extension)
	debug_point('up2', extension2)
	# down
	var extension = base_rect.start().add(P.new(base_rect.height, random_int(0, base_rect.width)))
	var extension2 = extension.add(P.new(1, 0))
	make_floor(map, extension)
	make_floor(map, extension2)
	extensions.append(extension)
	starting_points.append(extension2)
	debug_point('down1', extension)
	debug_point('down2', extension2)
	
	return Base.new(base_rect, safe_area, extensions, starting_points)


static func make_path(map_, starting_point, length, base):
	debug_point('Making path of length %d from' % length, starting_point)

	var path = []
	var last_pos = starting_point
	for _ in range(length):
		var next_places = possible_next_places(map_, last_pos, base)
		if next_places.size() == 0:
			debug('No future for this path!')
			break
		var cell = random_choice(next_places)
		path.append(cell)
		make_floor(map_, cell)
		debug_point('adding to path', cell)
		debug_map(map_)
		last_pos = cell
	debug(path)
	return path


static func possible_next_places(map_, pos, base):
	var places = []
	for direction in four_directions():
		var possible_next_place = pos.add(direction)
		debug_point('checking next place', possible_next_place)
		
		if not is_within_boundaries(map_, possible_next_place):
			continue
		
		# Only one of these checks should be enough
		# but I don't want to risk it
		if is_floor(map_, possible_next_place):
			continue
		if contains_point(base.extensions, possible_next_place):
			continue

		if has_surrounding_floor(map_, possible_next_place, direction, base):
			continue

		debug('valid possibility found!')

		places.append(possible_next_place)
	return places


static func is_within_boundaries(map_, pos):
	return (0 <= pos.row and pos.row < map_.size() and
	        0 <= pos.col and pos.col < map_[0].size())


static func has_surrounding_floor(map_, pos, direction, base):
	for side in sides(pos, direction):
		debug_point('side', side)
		if not is_within_boundaries(map_, side):
			continue

		if is_floor(map_, side):
			return true

	var in_front = pos.add(direction)
	debug_point('in front', in_front)
	if (is_within_boundaries(map_, in_front) and
		is_floor(map_, in_front)):
		
		if contains_point(base.extensions, in_front):
			return true

		if randf() < LOOPING_PROBABILITY:
			debug('looping')
			return false

		return false

	for surrounding in diagonal_in_front(pos, direction):
		debug_point('directed surrounding', surrounding)

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
	return content == FLOOR or content == BASE


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


static func debug(arg):
	if DEBUG:
		print(arg)


static func debug_point(text, point):
	if DEBUG:
		print('%s: (%d, %d)' % [text, point.row, point.col])


static func random_int(from_inclusive, to_exclusive):
	if from_inclusive == to_exclusive:
		return from_inclusive
	return from_inclusive + (randi() % (to_exclusive - from_inclusive))


static func random_choice(arr):
	return arr[randi() % arr.size()]


static func contains_point(arr, point):
	for other in arr:
		if point.equals(other):
			return true
	return false


static func random_point(map):
	return P.new(randi() % map.size(), randi() % map[0].size())
