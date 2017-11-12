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
	return Vector2(tile_pos.col * cell.size.x - cell.pos.x,
	               tile_pos.row * cell.size.y - cell.pos.y)
	
func world_to_tile(world_pos):
	return map_generate.P.new(int(round((world_pos.y + cell.pos.y) / cell.size.y)),
	                          int(round((world_pos.x + cell.pos.x) / cell.size.x)))
	
func is_accessible(tile_pos):
	return map[tile_pos.row][tile_pos.col] != map_generate.WALL
	# TODO when doors are implemented:
	# TODO calc closest_point for each. filter if != goal
	# TODO calc path for each. filter if size > 1