extends Node2D
export(String) var player = "playerscene.tscn"


func _ready():
	instantiate_player()


func instantiate_player():
	# This sets the player to appear at the correct area when loading into a new
	# zone
	var spawn_points = $"Non-InteractiveTerrain".get_children()
	var index = BaseData.zone_load_spawn_point

	# If we somehow don't have that spawn point, fall back to 0
	if not spawn_points[index]:
		index = 0


	# Spawn the player and add to scene
	var player_spawn = load(player).instance()
	$InteractiveTerrain.add_child(player_spawn)
	# Set player at the correct position (spawn point of zone)
	player_spawn.position = spawn_points[index].position
	# Make the player face the direction from last movement to create a
	# "seamless" feel
	if BaseData.zone_load_facing_direction:
		player_spawn.update_facing(BaseData.zone_load_facing_direction)
