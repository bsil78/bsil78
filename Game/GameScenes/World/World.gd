extends Node2D

func _ready():
	if GameData.current_level<1:
		printerr("Current level must be at least 1")
		Utils.quit(1)
	GameData.world=self
	init_level()
	place_players()
	GameData.players_slots={}
	GameData.players_saves.clear()
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
	for pname in GameData.players_names:
		var slot=GameData.players_slots[pname]
		if slot==null: continue
		var player_pos=$LevelPlaceholder.find_node("Position"+str(slot)+"*",true,false) as Position2D
		if player_pos==null: continue
		var player
		if GameData.players_saves.has(pname):player=GameData.players_saves[pname]
		elif GameData.players.has(pname): player=GameData.players[pname]
		if player==null:
			print_debug("Cannot get player {}".format([pname],"{}"))
			continue
		$PlayersPlaceholder.add_child(player)
		GameData.players[pname]=player
		player.position=player_pos.global_position
		GameFuncs.add_level_object(player)
		var pos_data:PoolStringArray=player_pos.name.split("_")
		if len(pos_data)>1:
			var dir=pos_data[1]
			var facing_dir:=facing_dir(dir)
			print_debug("Adjusting facing of {} to {} according to {}".format([player.name,facing_dir,player_pos.name],"{}"))
			player.adjust_facing(facing_dir,false)
			print_debug("Player flip_h is : {}".format([player.get_node("Animation/AnimatedSprite").flip_h],"{}"))
			player.on_level_entered()
			if len(pos_data)>2:
				var active:=(pos_data[2]=="ACTIVE")
				if active:GameData.current_player=player
		
	if not GameData.current_player:
		printerr("No active player in "+GameFuncs.level_as_string())
		if GameData.players.empty():
			print_debug("No player to activate !")
		else:
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
