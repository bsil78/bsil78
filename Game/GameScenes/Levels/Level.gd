extends Node2D

export(int,10,40,1) var size:=40

export(NodePath) var innerwalls_path

var innerwalls:TileMap

var objects:={}
var grid_lock:=Mutex.new()
var exits:=[]
var teleporters:=[]


func _ready():
	innerwalls=get_node(innerwalls_path)
	$ContextOfLevels.fill(size)
	scan_objects()

func connect_exit(exit:Node2D):
	exit.connect("exit_fullfilled",self,"_on_exit_fullfilled")
	exits.append(exit)
	
func connect_teleporter(teleporter:Node2D):
	teleporter.connect("teleporter_activated",self,"_on_teleporter_actived")
	teleporters.append(teleporter)

func has_actor_at(at,object=null)->bool:
	return has_thing_at(at,object,GameEnums.OBJECT_TYPE.ACTOR)
	
func has_item_at(at,object=null)->bool:
	return has_thing_at(at,object,GameEnums.OBJECT_TYPE.ITEM)

func has_block_at(at,object=null)->bool:
	return has_thing_at(at,object,GameEnums.OBJECT_TYPE.BLOCK)

func has_thing_at(at,object,type_of_thing)->bool:
	var thing=objects_at(at).get(type_of_thing)
	if !thing: return false
	if !object: return true
	return object==thing

func _on_teleporter_actived(which_one,target,actor):
	print_debug("Teleporter %s activated by %s with target %s"%[which_one.teleporter_id,actor.name,target])
	for teleporter in teleporters:
		if teleporter.teleporter_id==target:
			teleporter.receive(which_one,actor)
			return
	print_debug("Target teleporter not found")
	which_one.throw_back(actor)

func _on_exit_fullfilled():
	# if one has not been fullfilled : cannot exit yet
	for exit in exits:
		if !exit.is_fullfilled():return
	# else : open all exits at once !
	for exit in exits:
		exit.open()

func lock_grid():
	while grid_lock.try_lock()==ERR_BUSY:
		DEBUG.push("Waiting for grid lock")
		yield(Utils.timer(0.1),"timeout")

func unlock_grid():
	grid_lock.unlock()
	
func scan_objects():
	lock_grid()
	objects.clear()
	add_scanned_objects(self)
	unlock_grid()
	
func add_scanned_objects(level_node:Node2D):
	for node in level_node.get_children():
		if((node as Node2D).name.match("*Layer")):
			add_scanned_objects(node)
		else:
			var type:int=GameFuncs.object_type_of(node)
			if ! type in [GameEnums.OBJECT_TYPE.UNKNOWN,GameEnums.OBJECT_TYPE.ACTOR]:
				add_object(node as Node2D)
				

func add_object(object:Node2D)->bool:
	return add_object_at(object,object.position)
		
func add_object_at(object:Node2D,pos:Vector2)->bool:
	var type:int=GameFuncs.object_type_of(object)
	if type==GameEnums.OBJECT_TYPE.UNKNOWN: 
		DEBUG.error("%s is of unknown type" % object.name)
		return false
	lock_grid()
	var grid_pos=GameFuncs.grid_pos(pos)
	var result=true
	var dic=objects.get(grid_pos)
	if !dic:
		objects[grid_pos]={type:object}
	elif !dic.has(type):
		dic[type]=object
	else:
		#DEBUG.error("%s has already object %s cannot add %s"%[grid_pos,(dic[type] as Node2D).name,object.name])
		result=false
	unlock_grid()
	return result
	
func dump_grid_pos_and_neighbors(pos:Vector2)->String:
	return GameFuncs.dump([
		sub_grid(pos,Vector2.ZERO),
		sub_grid(pos,Vector2.RIGHT),
		sub_grid(pos,Vector2.DOWN),
		sub_grid(pos,Vector2.LEFT),
		sub_grid(pos,Vector2.UP),
	])
	
	
func sub_grid(pos:Vector2,dir:Vector2)->Dictionary:
	var new_pos:=pos+dir
	var value=objects.get(new_pos)
	if !value:
		return {dir:{}}
	else:
		return {dir:value}
	
func remove_type_at(pos:Vector2,object_type:int=GameEnums.OBJECT_TYPE.UNKNOWN)->bool:
	lock_grid()
	var done:=false
	var grid_pos=GameFuncs.grid_pos(pos)
	var dic=objects.get(grid_pos)
	if dic and dic.has(object_type):
		done=dic.erase(object_type)
		if len(dic)==0:objects.erase(grid_pos)
	unlock_grid()
	return done
	
func remove_object_at(pos:Vector2,object)->bool:
	lock_grid()
	var done:=false
	var grid_pos=GameFuncs.grid_pos(pos)
	var dic=objects.get(grid_pos)
	if dic and dic.values().has(object):
		var key_to_erase=-1
		for key in dic:
			if dic[key]==object: key_to_erase=key
		done=(key_to_erase!=-1) and dic.erase(key_to_erase)
		if len(dic)==0:objects.erase(grid_pos)
	unlock_grid()
	return done	
	
func remove_object(object:Node2D)->bool:
	lock_grid()
	var remove_count:=0
	var new_dics:={}
	var to_remove:=[]
	for grid_pos in objects:
		var dic:Dictionary=objects[grid_pos] as Dictionary
		var new_dic:={}
		for key in dic:
			if object!=dic[key]: 
				new_dic[key]=dic[key]
			else:
				remove_count+=1
		if new_dic.empty():
			to_remove.push_back(grid_pos)
		else:
			new_dics[grid_pos]=new_dic
	for pos in new_dics:
		objects[pos]=new_dics[pos]
	for pos in to_remove:
		objects.erase(pos)
	#check
#	for grid_pos in objects:
#		var dic:Dictionary=objects[grid_pos] as Dictionary
#		for key in dic:
#			if object==dic[key]: printerr("Remove object failed")
#	print_debug("Removed %s of %s"%[remove_count,object.name])
	unlock_grid()
	return remove_count>0
	
func remaining_good_godsigns_items()->int:
	var remaining:=0
	for node in $ItemsLayer.get_children():
		if !node.has_method("is_item"):continue
		if node.is_item(GameEnums.ITEMS.GOD_SIGN_GOOD):remaining+=1
	return remaining

func remaining_good_godsigns_blocks()->int:
	var remaining:=0
	for node in $BlocksLayer.get_children():
		if !node.has_method("is_block"):continue
		if node.is_block(GameEnums.BLOCKS.GOD_SIGN_BLOCK_GOOD):remaining+=1
	return remaining

func items_node():
	return get_node("ItemsLayer")

func actors_node():
	return get_node("ActorsLayer")

func blocks_node():
	return get_node("BlocksLayer")
	
func objects_at(at:Vector2)->Dictionary:
	lock_grid()
	var grid_pos=GameFuncs.grid_pos(at)
	var found=objects.get(grid_pos)
	unlock_grid()
	return found if found!=null else {}

func matching_objects_at(matcher:Dictionary,at:Vector2)->Array:
	var all_objects:=objects_at(at)
	var matching:=[]
	for obj_type in matcher:
		var obj=all_objects.get(obj_type)
		if obj and GameFuncs.is_one(obj_type,obj,matcher[obj_type]): matching.append(obj)
	return matching


