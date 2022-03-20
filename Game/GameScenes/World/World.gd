extends Node2D

var level:Node2D

func _ready():
	if GameData.current_level<1:
		printerr("Current level must be at least 1")
		Utils.quit(1)
	GameData.world=self
	init_level()
	place_players()
	GameData.players_slots={}
	GameData.players_saves.clear()

func init_level():
	var level_path="res://Game/GameScenes/Levels/Level%s.tscn" % GameData.current_level
	var level_scene:=load(level_path) as PackedScene
	if level_scene:
		level=level_scene.instance()
		$LevelPlaceholder.add_child(level)
	else:
		printerr("%s cannot be loaded at %s " % [GameFuncs.level_as_string(),level_path])

func remove_all_actors():
	for dic in level.objects.values():
		if dic.has(GameEnums.OBJECT_TYPE.ACTOR):
			dic[GameEnums.OBJECT_TYPE.ACTOR].remove_from_world()
	yield(Utils.timer(0.5),"timeout")
	
func detroy_object(object:Node2D):
	level.remove_object(object)
	object.get_parent().remove_child(object)
	object.queue_free()
		
func place_players():
	if GameData.players_slots.empty(): 
		GameData.transition_state=GameEnums.TRANSITION_STATUS.MENU
		GameFuncs.transition() 
	for pname in GameData.players_names:
		if GameData.players_slots.has(pname):
			var slot=GameData.players_slots[pname]
			if slot==null: continue
			var player_pos=$LevelPlaceholder.find_node("Position%s*" % slot,true,false) as Position2D
			if player_pos==null: continue
			var player
			if GameData.players_saves.has(pname):player=GameData.players_saves[pname]
			elif GameData.players.has(pname): player=GameData.players[pname]
			if player==null:
				print_debug("Cannot get player %s" % pname)
				continue
			$PlayersPlaceholder.add_child(player)
			GameData.players[pname]=player
			player.position=player_pos.global_position
			GameData.world.level.add_object(player)
			var pos_data:PoolStringArray=player_pos.name.split("_")
			if len(pos_data)>1:
				var dir=pos_data[1]
				var facing_dir:=facing_dir(dir)
				#print_debug("Adjusting facing of {} to {} according to {}".format([player.name,facing_dir,player_pos.name],"{}"))
				player.adjust_facing(facing_dir,false)
				#print_debug("Player flip_h is : {}".format([player.get_node("Animation/AnimatedSprite").flip_h],"{}"))
				player.on_entering_level()
				if len(pos_data)>2:
					var active:=(pos_data[2]=="ACTIVE")
					if active:GameData.current_player=player
		
	if not GameData.current_player:
		printerr("No active player in %s" % GameFuncs.level_as_string())
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
	printerr("Unknown facing dir : %s for %s" % [facing,GameFuncs.level_as_string()])
	return Vector2.RIGHT	
