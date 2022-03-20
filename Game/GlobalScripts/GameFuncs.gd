extends Node

var music=preload("res://Game/Effects/Music.tscn")
var players_locker:Object=null
var switch_of_player_disabled:=false
var spawned_count:=0
var music_node

signal players_switched

func _ready():
	music_node=music.instance()
	CommonUI.add_child(music_node)

func _process(_delta):
	if Input.action_press("ui_quit"):
		Utils.quit_from(self)
	
func load_next_level():
	GameData.transition_state=GameEnums.TRANSITION_STATUS.LEVEL_UP
	GameData.current_level=GameData.current_level+1
	transition()

func manage_debug_of(obj):
	if !DEBUG.active:return
	var debug_nodes:Array=get_tree().get_nodes_in_group("DebugPointer")
	for child in debug_nodes:
		if GameFuncs.grid_pos(child.position)==GameFuncs.grid_pos(obj.position):
			obj.debug=true
				
func init_new_game():
	findout_levels_config()
	GameData.current_player=null	
	GameData.players={}
	GameData.players_slots={"PlayerOne":1,"PlayerTwo":2}
	GameData.players_saves={}
	for pname in GameData.players_names:
		GameData.players[pname]=instanciate_player(pname)
	GameData.transition_state=GameEnums.TRANSITION_STATUS.LEVEL_UP
	GameData.current_level=GameData.startLevel
	transition()

func findout_levels_config():
	var l:=1
	if !DEBUG.debuglevel:
		l=0
		var dir = Directory.new()
		if dir.open("res://Game/GameScenes/Levels/") == OK:
			dir.list_dir_begin()
			var file_name:String= "ANY_FILE"
			while file_name != "":
				file_name= dir.get_next()
				if !dir.current_is_dir():
					if file_name.matchn("Level*"):
						var id=int(file_name.trim_prefix("Level"))
						if id>l: l=id
		else:
			printerr("An error occurred when trying to access the levels path.")
	DEBUG.push("Max level is : %s"%l)
	GameData.max_levels=l

func object_type_of(obj:Node2D):
	if is_block(obj): return GameEnums.OBJECT_TYPE.BLOCK
	if is_actor(obj): return GameEnums.OBJECT_TYPE.ACTOR
	if is_item(obj): return GameEnums.OBJECT_TYPE.ITEM
	return GameEnums.OBJECT_TYPE.UNKNOWN

func is_one(obj_type:int,obj:Node2D,types:Array=[])->bool:
	match obj_type:
		GameEnums.OBJECT_TYPE.ACTOR:
			return GameFuncs.is_actor(obj,types)
		GameEnums.OBJECT_TYPE.ITEM:
			return GameFuncs.is_item(obj,types)
		GameEnums.OBJECT_TYPE.BLOCK:
			return GameFuncs.is_block(obj,types)
		_:
			return false

func is_block(obj:Node2D,types:Array=[])->bool:
	if obj.has_method("is_block"):
		if types.empty(): return obj.is_block()
		for type in types:
			if obj.is_block(type): return true
	return false

func is_actor(obj:Node2D,types:Array=[])->bool:
	if obj.has_method("is_actor"):
		if types.empty(): return obj.is_actor()
		for type in types:
			if obj.is_actor(type): return true
	return false

func is_item(obj:Node2D,types:Array=[])->bool:
	if obj.has_method("is_item"):
		if types.empty(): return obj.is_item()
		for type in types:
			if obj.is_item(type): return true
	return false

func are_in_hit_distance(obj1,obj2)->bool:
	return (obj1 as Node2D).position.distance_to((obj2 as Node2D).position)<GameData.MAX_HIT_DISTANCE


func grid_pos(position:Vector2)->Vector2:
	return Vector2(floor(position.x/GameData.cell_size),floor(position.y/GameData.cell_size))
		
func transition():
	GameData.current_player=null
	CommonUI.fade_transition_scene("res://Game/GUIComponents/Transition/Transition.tscn")

func instanciate_player(pname:String)->Node2D:
	var player_scene=load("res://Game/Actors/Players/PlayerOne.tscn") as PackedScene
	#var player_scene=load("res://Game/Characters/Players/"+pname+".tscn") as PackedScene
	var player=player_scene.instance()
	player.name=pname
	return player

func change_active_player()->bool:
	if switch_of_player_disabled:return false
	DEBUG.push("Switching players")
	var next_player
	for pname in GameData.players:
		if GameData.current_player and pname==GameData.current_player.name:continue
		next_player=GameData.players[pname]
		break
	var changed:=false
	if next_player:
		DEBUG.push("Next player : %s"%next_player.name)
		if GameData.current_player: GameData.current_player.desactivate()
		GameData.current_player=next_player
		next_player.activate()
		changed=true
	if changed: emit_signal("players_switched")
	return changed

func exit_player(player:Node2D,exit_name:String):	
	DEBUG.push("%s took %s" % [player.name,exit_name])
	if !exit_name.matchn("*exit*"):
		printerr("%s is not an exit !" % exit_name)
		return
	switch_of_player_disabled=true
	var slotval=exit_name
	slotval.erase(0,len("Exit"))
	var slot:=clamp(int(slotval),1,2)
	#GameData.world.set_process(false)
	#GameData.world.set_physics_process(false)
	GameData.players_slots[player.name]=slot
	GameData.players_saves[player.name]=player
	if GameData.players.size()==1:
		if GameData.current_level==GameData.max_levels:
			GameData.transition_state=GameEnums.TRANSITION_STATUS.WIN_GAME
		else:
			GameData.transition_state=GameEnums.TRANSITION_STATUS.LEVEL_UP
		take_over_playercam(player)
		player.remove_from_world()
# warning-ignore:return_value_discarded
		Utils.timer(1.0).connect("timeout",self,"end_world",[true])
	else:
		take_over_playercam(player)
		player.remove_from_world()
		#GameData.world.set_process(true)
		#GameData.world.set_physics_process(true)
		switch_of_player_disabled=false
		Utils.timer(1.0).connect("timeout",self,"change_active_player")
		
		
func end_world(with_change_level:bool=false):
	GameData.current_player=null
	#GameData.world.set_process(false)
	#GameData.world.set_physics_process(false)
	GameData.world.remove_all_actors()
	var still_active:=true
	while(still_active):
		still_active=false
		print("waiting for cleanup")
		yield(Utils.timer(0.1),"timeout")
		for p in GameData.players_saves.values():
			var processing=(p as Node2D).is_physics_processing()
			still_active=still_active or processing
			if processing:
				DEBUG.push("%s still processing..." % p.name) 
				p.freeze()
	GameData.world=null
	if with_change_level:GameData.current_level+=1
	switch_of_player_disabled=false
	transition()

func player_died(player:Node2D):
	switch_of_player_disabled=true
	DEBUG.push("%s died" % player.name)
	var tired:bool=(player.life_points<=0)
	GameData.world.set_process(false)
	if GameData.players.size()==1:
		if tired:
			GameData.transition_state=GameEnums.TRANSITION_STATUS.DEAD_TIRED
		else:
			GameData.transition_state=GameEnums.TRANSITION_STATUS.DEAD_HUNGRY
		take_over_playercam(player)
		player.remove_from_world()
		Utils.timer(1.0).connect("timeout",self,"end_world",[false])
	else:
		take_over_playercam(player)
		player.remove_from_world()
		switch_of_player_disabled=false
		Utils.timer(1.0).connect("timeout",self,"change_active_player")
		
func dump(objects)->String:
	if objects is Dictionary:
		return dump_dic(objects)
	if objects is Array:
		return dump_array(objects)
	if (objects is KinematicBody2D or 
		objects is Sprite or
		objects is Node2D):
		return objects.name
	return str(objects)
			
func dump_array(objects:Array)->String:
	var res:=""
	for item in objects:
		res=res+dump(item)+",\n"
	return res
			
func dump_dic(objects:Dictionary)->String:
	var dic:={}
	for key in objects:
		dic[dump(key)]=dump(objects[key])
	return str(dic)


func rotr(dir:Vector2):
	return dir.rotated(PI/2)		
	
func rotl(dir:Vector2):
	return dir.rotated(PI/-2)		
	
	
func take_over_playercam(player:Node2D):
	if !GameData.world or GameData.current_player!=player: return
	DEBUG.push("World camera is taking %s camera over"%player.name)
	var worldcam:=(GameData.world.get_node(NodePath("Camera2D")) as Camera2D)
	var playercam:=(player.get_node(NodePath("Camera2D")) as Camera2D)
	worldcam.limit_bottom=playercam.limit_bottom
	worldcam.limit_top=playercam.limit_top
	worldcam.limit_left=playercam.limit_left
	worldcam.limit_right=playercam.limit_right
	worldcam.position=playercam.global_position
	worldcam.make_current()
	
func spawn(spawn_point:Vector2, subject:PackedScene, spawn_placeholder:Node, direction:Vector2=Vector2.ZERO)->Node2D:
	var node:Node2D=subject.instance()
	spawned_count+=1
	node.name="%s-SP[%s]"%[node.name,spawned_count]
	spawn_placeholder.add_child(node)
	node.position=node.to_local(spawn_point)
	if node.has_method("adjust_facing"):
		node.adjust_facing(direction)
	return node

func level_as_string():
	return "Level %s" % GameData.current_level

	
