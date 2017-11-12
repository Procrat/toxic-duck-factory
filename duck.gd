extends KinematicBody2D

const SPEED_IN_CELLS = 1

onready var nav = get_parent()
onready var speed = nav.cell_size() * SPEED_IN_CELLS

var previous_direction;
var goal;

func _ready():
	update_goal()
	set_fixed_process(true)

func _fixed_process(delta):
	var current_pos = get_pos()
	var direction = goal - current_pos
	var advancement = direction.clamped(speed * delta)
	var new_pos = current_pos + advancement
	if new_pos != current_pos:
		set_pos(new_pos)
	else:
		update_goal()
#
func update_goal():
	var current_pos = get_pos()
	var current_tile = nav.world_to_tile(get_pos())
	
	var possible_directions = []
	var possible_goals = []

	for direction in [Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0)]:
		if previous_direction != null and direction == -previous_direction:
			continue
		
		var possible_goal = current_tile + direction
		
		if not nav.is_accessible(possible_goal):
			continue
		
		possible_directions.append(direction)
		possible_goals.append(possible_goal)
		
	print('After all filtering:', possible_goals)
	
	var new_goal
	
	if possible_directions.size() > 0:
		var choice = randi() % possible_goals.size()
		previous_direction = possible_directions[choice]
		new_goal = possible_goals[choice]
	else:
		# Dead end! Let's try to go back then...
		new_goal = current_tile - previous_direction
		if nav.is_accessible(new_goal):
			previous_direction = -previous_direction
		else:
			# Oh noes! There's nowhere to go! Let's stay where we are
			goal = current_tile
			
	goal = nav.tile_to_world(new_goal)
