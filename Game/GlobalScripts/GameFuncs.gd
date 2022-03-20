extends Node

var music=preload("res://Game/Effects/Music.tscn")
var players_locker:Object=null

func _ready():
	CommonUI.add_child(music.instance())

func _process(_delta):
	if Input.action_press("ui_quit"):
		Utils.quit(0)
	

func load_next_level():
	GameData.transition_state=GameEnums.TRANSITION_STATUS.LEVEL_UP
	GameData.current_level=GameData.current_level+1
	transition()

func init_new_game():
	GameData.current_player=null	
	GameData.players={}
	GameData.level_objects={}
	GameData.players_slots={"PlayerOne":1,"PlayerTwo":2}
	GameData.players_saves={}
	for name in GameData.players_names:
		instanciate_player(name)
	GameData.transition_state=GameEnums.TRANSITION_STATUS.LEVEL_UP
	GameData.current_level=GameData.startLevel
	transition()

func lock_grid():
	while GameData.grid_lock.try_lock()==ERR_BUSY:
		DEBUG.push("Waiting grid lock")
		yield(Utils.timer(0.1),"timeout")

func unlock_grid():
	GameData.grid_lock.unlock()
	
func scan_level_objects(level_node:Node2D):
	lock_grid()
	GameData.level_objects.clear()
	add_scanned_objects_to_level(level_node)
	unlock_grid()
	return true
	
func add_scanned_objects_to_level(level_node:Node2D):
	for node in level_node.get_children():
		if((node as Node2D).name.matchn("*layer*")):
			add_scanned_objects_to_level(node)
		else:
			var type:int=object_type_of(node)
			if type!=GameEnums.OBJECT_TYPE.UNKNOWN:
				add_level_object(node as Node2D)
				
func dump(objects:Dictionary)->String:
	var dic:={}
	for key in objects:
		var value
		if is_instance_valid(objects[key]):
			if objects[key] is Node2D:
				value=(objects[key] as Node2D).name
			elif objects[key] is Dictionary:
				value=dump(objects[key])
			else:
				value=str(objects[key])
		else:
			value="]freed["
		if key is String:
			dic[key]=value
		else:
			dic[str(key)]=value
	return str(dic)


func rotr(dir:Vector2):
	return dir.rotated(PI/2)		
	
func rotl(dir:Vector2):
	return dir.rotated(PI/-2)		

func add_level_object(object:Node2D)->bool:
	var type:int=object_type_of(object)
	if type==GameEnums.OBJECT_TYPE.UNKNOWN: 
		DEBUG.error("{} is of unknown type",[object.name])
		return false
	return add_level_object_at(object,object.position)
		
func add_level_object_at(object:Node2D,pos:Vector2)->bool:
	var type:int=object_type_of(object)
	if type==GameEnums.OBJECT_TYPE.UNKNOWN: return false
	lock_grid()
	var grid_pos=grid_pos(pos)
	var result=true
	if GameData.level_objects.has(grid_pos):
		var dic:Dictionary=GameData.level_objects[grid_pos]
		if dic.has(type):
			DEBUG.error("{} has already object {} cannot add {}",[grid_pos,(dic[type] as Node2D).name,object.name])
			result=false
		else:
			dic[type]=object
	else:
		GameData.level_objects[grid_pos]={type:object}
	unlock_grid()
	return result
	
func remove_level_object_at(pos:Vector2,object_type:int=GameEnums.OBJECT_TYPE.UNKNOWN)->bool:
	lock_grid()
	var done:=false
	var grid_pos=grid_pos(pos)
	if GameData.level_objects.has(grid_pos):
		var dic:=(GameData.level_objects[grid_pos] as Dictionary)
		if dic.has(object_type):
			done=dic.erase(object_type)
			if len(dic)==0:GameData.level_objects.erase(grid_pos)
	unlock_grid()
	return done

func object_type_of(obj:Node2D):
	if is_block(obj): return GameEnums.OBJECT_TYPE.BLOCK
	if is_actor(obj): return GameEnums.OBJECT_TYPE.ACTOR
	if is_item(obj): return GameEnums.OBJECT_TYPE.ITEM
	return GameEnums.OBJECT_TYPE.UNKNOWN

func is_block(obj:Node2D):
	
	for block in GameEnums.BLOCKS_MAP.values():
		if obj.name.matchn(block): return true

func is_actor(obj:Node2D):
	
	for actor in GameEnums.ACTORS_MAP.values():
		if obj.name.matchn(actor): return true

func is_item(obj:Node2D):
	for item in GameEnums.ITEMS_MAP.values():
		if obj.name.matchn(item): return true

func ifmatch_remove_level_object(mask:String,object_type:int=GameEnums.OBJECT_TYPE.UNKNOWN)->Vector2:
	var found_pos:Vector2
	if object_type!=GameEnums.OBJECT_TYPE.UNKNOWN: 
		lock_grid()
		var pos_to_remove:Vector2
		var done:=false
		for grid_pos in GameData.level_objects:
			var dic:Dictionary=GameData.level_objects[grid_pos] as Dictionary
			var types_to_remove:=[]
			if not dic.has(object_type):continue
			var object:=dic[object_type] as Node2D
			if object and object.name.matchn(mask):
				done=dic.erase(object_type)
				if len(dic)==0:pos_to_remove=grid_pos
				found_pos=grid_pos as Vector2
		if pos_to_remove:GameData.level_objects.erase(pos_to_remove)
		unlock_grid()
	return found_pos
	
func remove_level_object(object:Node2D)->Array:
	var found_pos:=[]
	var pos_to_remove:=[]
	lock_grid()
	var done:=true
	for grid_pos in GameData.level_objects:
		var dic:Dictionary=GameData.level_objects[grid_pos] as Dictionary
		var types_to_remove:=[]
		for key in dic:
			if object==dic[key]:
				types_to_remove.push_back(key)
				if len(dic)==0:pos_to_remove.push_back(grid_pos)
				found_pos.push_back(grid_pos as Vector2)
		done=true
		for key in types_to_remove:
			done=done and dic.erase(key)
	for pos in pos_to_remove:
		GameData.level_objects.erase(pos)
	unlock_grid()
	return found_pos		

func are_in_hit_distance(obj1,obj2)->bool:
	return (obj1 as Node2D).global_position.distance_to((obj1 as Node2D).global_position)<GameData.MAX_HIT_DISTANCE
	
func level_objects(at:Vector2)->Dictionary:
	lock_grid()
	var grid_pos=grid_pos(at)
	var objects={}
	if GameData.level_objects.has(grid_pos):
		 objects=GameData.level_objects[grid_pos]
	unlock_grid()
	return objects

func matching_level_object(mask:String,at:Vector2)->Node2D:
	var objects:=level_objects(at)
	for obj in objects.values():
		if obj.name.matchn(mask):
			return obj
	return null
		

func grid_pos(position:Vector2)->Vector2:
	return Vector2(int(position.x/GameData.grid_size),int(position.y/GameData.grid_size))
		
func transition():
	GameData.current_player=null
	CommonUI.fade_transition_scene("res://Game/GUIComponents/Transition/Transition.tscn")

func instanciate_player(pname:String):
	var player_scene=load("res://Game/Actors/Players/PlayerOne.tscn") as PackedScene
	#var player_scene=load("res://Game/Characters/Players/"+pname+".tscn") as PackedScene
	var player=player_scene.instance()
	player.name=pname
	GameData.players[pname]=player

func change_active_player()->bool:
	DEBUG.push("Switching players")
	var next_player
	for pname in GameData.players:
		if GameData.current_player and pname==GameData.current_player.name:continue
		next_player=GameData.players[pname]
		break
	var changed:=false
	if next_player:
		DEBUG.push("Next player : {}".format([next_player.name],"{}"))
		GameData.current_player.desactivate()
		GameData.current_player=next_player
		next_player.activate()
		changed=true
	return changed
	
func remove_from_world(object):
	remove_level_object(object)
	object.get_parent().remove_child(object)
	object.queue_free()


func exit_player(player:Node2D,exit_name:String):
	DEBUG.push("{} took {}",[player.name,exit_name])
	if !exit_name.begins_with("Exit"):
		printerr("Not an exit !")
		return
	var slotval=exit_name
	slotval.erase(0,len("Exit"))
	var slot:=int(slotval)
	GameData.world.set_process(false)
	GameData.players_slots[player.name]=slot
	if GameData.current_player==player:change_active_player()
	GameData.players_saves[player.name]=player
	if GameData.players.size()==1:
		end_world_and_current_player()
		GameData.current_level+=1
		GameData.transition_state=GameEnums.TRANSITION_STATUS.LEVEL_UP
		transition()
	else:
		player.remove_from_world()
		GameData.world.set_process(true)
		
func end_world_and_current_player():
	var player=GameData.current_player
	if GameData.world:
		take_over_playercam(player)
		GameData.world.set_process(false)
		GameData.world.set_physics_process(false)
		GameData.world=null
	player.remove_from_world()

func player_died(player:Node2D):
	var tired:bool=(player.life_points<=0)
	GameData.world.set_process(false)
	if GameData.players.size()==1:
		end_world_and_current_player()
		if tired:
			GameData.transition_state=GameEnums.TRANSITION_STATUS.DEAD_TIRED
		else:
			GameData.transition_state=GameEnums.TRANSITION_STATUS.DEAD_HUNGRY
		Utils.timer(1.0).connect("timeout",self,"transition")
	else:
		take_over_playercam(player)
		player.remove_from_world()
		Utils.timer(1.0).connect("timeout",self,"change_active_player")
		
	
	
func take_over_playercam(player:Node2D):
	if !GameData.world: return
	print_debug("World camera is taking player camera over")
	var worldcam:=(GameData.world.get_node(NodePath("Camera2D")) as Camera2D)
	var playercam:=(player.get_node(NodePath("Camera2D")) as Camera2D)
	worldcam.position=playercam.global_position
	worldcam.make_current()

func spawn(spawn_point:Vector2, subject:PackedScene, spawn_placeholder:Node, direction:Vector2=Vector2.ZERO):
	var node:Node2D=subject.instance()
	spawn_placeholder.add_child(node)
	node.position=node.to_local(spawn_point)
	if node.has_method("adjust_facing"):
		node.adjust_facing(direction)

func level_as_string():
	return "Level "+str(GameData.current_level)

	
