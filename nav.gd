extends Navigation2D

const map_generate = preload("map_generate.gd")

var map
var cell

func cell_size():
	assert(cell.size.x == cell.size.y)
	return cell.size.x
	
func tile2_to_world(row, col):
	return Vector2(col * cell.size.x - cell.pos.x,
	               row * cell.size.y - cell.pos.y)
	
func tile_to_world(tile_pos):
	return Vector2(tile_pos.x * cell.size.x - cell.pos.x,
	               tile_pos.y * cell.size.y - cell.pos.y)
	
func world_to_tile(world_pos):
	return Vector2(int(round((world_pos.x + cell.pos.x) / cell.size.x)),
	               int(round((world_pos.y + cell.pos.y) / cell.size.y)))
	
func is_accessible(tile_pos):
	return map[tile_pos.y][tile_pos.x] != map_generate.WALL
	# TODO when doors are implemented:
	# TODO calc closest_point for each. filter if != goal
	# TODO calc path for each. filter if size > 1