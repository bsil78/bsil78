extends Node2D

func _ready():
	if GameData.current_level<1:
		print("Current level must be at least 1")
		Utils.quit(1)
	GameData.world=self
	init_level()
	place_players()
	$MaskLayer/FixedMask.visible=true

func init_level():
	var level_path="res://Game/GameScenes/Levels/Level"+str(GameData.current_level)+".tscn"
	var level:=load(level_path) as PackedScene
	if level:
		var level_node:=level.instance()
		$LevelPlaceholder.add_child(level_node)
		GameFuncs.scan_level_objects(level_node)
	else:
		printerr(GameFuncs.level_as_string()+" cannot be loaded at "+level_path)
		
	
func place_players():
	for name in GameData.players:
		var player=GameData.players[name]
		$PlayersPlaceholder.add_child(player)
		var slot:int=GameData.players_slots[name]
		if slot:
			var player_pos:=$LevelPlaceholder.find_node("Position"+str(slot)+"*",true,false) as Position2D
			assert(player_pos!=null)
			player.position=player_pos.global_position
			GameFuncs.add_level_object(player)
			var pos_data:PoolStringArray=player_pos.name.split("_")
			if len(pos_data)>1:
				var dir=pos_data[1]
				var facing_dir:=facing_dir(dir)
				player.adjust_facing(facing_dir)
				if len(pos_data)>2:
					var active:=(pos_data[2]=="ACTIVE")
					if active:
						GameData.current_player=player
	if not GameData.current_player:
		printerr("No active player in "+GameFuncs.level_as_string())
		GameData.current_player=GameData.players[GameData.players.keys()[0]]
	GameData.current_player.activate()
	
func facing_dir(facing:String)->Vector2:
	match(facing):
		"Right":
			return Vector2.RIGHT			
		"Left":
			return Vector2.LEFT	
		"Up":
			return Vector2.UP	
		"Down":
			return Vector2.DOWN
	printerr("Unknown facing dir : "+facing+" for "+GameFuncs.level_as_string())
	return Vector2.RIGHT	
