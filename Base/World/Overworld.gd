extends TileMap

enum CELL_TYPES {EMPTY = -1, ACTOR, OBJECT}

var children
var stale_children = false

func _ready():
	process_actor_spawn_conditions()
	stale_children = true


# Make sure to call this when necessary
# We don't want to be getting children everytime an actor tries to move.
func refresh_children()->void:
	children = get_children()


# Iterate through EVERY object in the overworld and find the right one
# Could probably be done better
func get_overworld_obj(coordinates)->Node2D:
	if stale_children:
		stale_children = false
		refresh_children()
	for node in children:
		# Protects against certain situations where an object is queued to be
		# freed
		if !is_instance_valid(node):
			stale_children = true
			continue
		else:
			if are_coinciding(node,coordinates):
				return node
	return null

func are_coinciding(node:Node2D,coords:Vector2):
	var node_pos:=world_to_map(node.position)
	#print(node.name +"@"+str(node_pos)+" ~ "+str(coords)+" ? "+str(node_pos == coords))
	return node_pos == coords

func request_interaction(requesting_object, direction:Vector2)->void:
	#print(requesting_object.name+" request interaction")
	#var cell_start = world_to_map(requesting_object.position)
	var cell_target = world_to_map(requesting_object.position) + direction
	var target_obj = get_overworld_obj(cell_target)
	if target_obj == requesting_object:
		return
	if target_obj:
		print(requesting_object.name+" interact with "+target_obj.name)
		requesting_object.interact_with(target_obj)
	#print("no one to interact with")


func request_move(requesting_object:Node2D, direction:Vector2)->Vector2:
	var cell_start = world_to_map(requesting_object.position)
	var cell_target = world_to_map(requesting_object.position) + direction
	var cell_target_type = get_cellv(cell_target)

	if cell_target_type == CELL_TYPES.EMPTY:
		var target_obj = get_overworld_obj(cell_target) as Node2D
		if target_obj:
			#print(requesting_object.name+" target "+str(direction)+": "
			#		+str(cell_target_type)+"/"+target_obj.name);
		
			match target_obj.obj_type: 
				CELL_TYPES.OBJECT:
					target_obj.do_what_this_object_does()
					return update_overworld_obj_position(requesting_object,
							cell_start, cell_target)
				CELL_TYPES.ACTOR:
					request_interaction(requesting_object,direction)
		else:
			#print(requesting_object.name+" see no target obj @"+str(direction));
			return update_overworld_obj_position(requesting_object,
					cell_start, cell_target)
	return Vector2.ZERO
	
func update_overworld_obj_position(_requesting_object, cell_start, cell_target)->Vector2:
	# The cell the moving object was in is now free
	set_cellv(cell_start, CELL_TYPES.EMPTY)

	# Divide by 2 because location 0,0 starts from the top left of the cell
	# and we want the object to be "in the middle" of the grid cell
	return map_to_world(cell_target) + cell_size / 2


# removes an object from children array. The object should queue_free itself,
# but we want the overworld to immediately know this cell is no longer occupied
func remove_from_active(obj)->void:
	children.erase(obj)


# By default design, all potential actors are on scene, and those that do not
# meet their conditions to be present are removed
func process_actor_spawn_conditions()->void:
	for obj in get_children():
		if !obj.spawn_condition():
			obj.call_deferred("free")
