extends Node2D

export(int,10,40,1) var size:=40

var objects:={}
var grid_lock:=Mutex.new()
var exits:=[]


func _ready():
	$ContextOfLevels.fill(size)
	scan_objects()
	for node in $BlocksLayer.get_children():
		if !node.has_method("is_block"):continue
		if node.is_block(GameEnums.BLOCKS.EXIT):
			node.connect("exit_fullfilled",self,"check_exits")
			exits.append(node)


func check_exits():
	# if one has not been fullfilled : cannot exit yet
	for exit in exits:
		if !exit.is_fullfilled():return
	# else : open all exits at once !
	for exit in exits:
		exit.open()

func lock_grid():
	while grid_lock.try_lock()==ERR_BUSY:
		DEBUG.push("Waiting grid lock")
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
		if((node as Node2D).name.matchn("*layer*")):
			add_scanned_objects(node)
		else:
			var type:int=GameFuncs.object_type_of(node)
			if type!=GameEnums.OBJECT_TYPE.UNKNOWN:
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
	if objects.has(grid_pos):
		var dic:Dictionary=objects[grid_pos]
		if dic.has(type):
			#DEBUG.error("%s has already object %s cannot add %s"%[grid_pos,(dic[type] as Node2D).name,object.name])
			result=false
		else:
			dic[type]=object
	else:
		objects[grid_pos]={type:object}
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
	
func remove_object_at(pos:Vector2,object_type:int=GameEnums.OBJECT_TYPE.UNKNOWN)->bool:
	lock_grid()
	var done:=false
	var grid_pos=GameFuncs.grid_pos(pos)
	if objects.has(grid_pos):
		var dic:=(objects[grid_pos] as Dictionary)
		if dic.has(object_type):
			done=dic.erase(object_type)
			if len(dic)==0:objects.erase(grid_pos)
	unlock_grid()
	return done
	

#func ifmatch_remove_object(mask:String,object_type:int=GameEnums.OBJECT_TYPE.UNKNOWN)->Vector2:
#	var found_pos:Vector2
#	if object_type!=GameEnums.OBJECT_TYPE.UNKNOWN: 
#		lock_grid()
#		var pos_to_remove:Vector2
#		var done:=false
#		for grid_pos in objects:
#			var dic:Dictionary=objects[grid_pos] as Dictionary
#			var types_to_remove:=[]
#			if not dic.has(object_type):continue
#			var object:=dic[object_type] as Node2D
#			if object and object.name.matchn(mask):
#				done=dic.erase(object_type)
#				if len(dic)==0:pos_to_remove=grid_pos
#				found_pos=grid_pos as Vector2
#		if pos_to_remove:objects.erase(pos_to_remove)
#		unlock_grid()
#	return found_pos
	
func remove_object(object:Node2D)->bool:
	lock_grid()
	var new_dics:={}
	var to_remove:=[]
	for grid_pos in objects:
		var dic:Dictionary=objects[grid_pos] as Dictionary
		var new_dic:={}
		for key in dic:
			if object!=dic[key]: new_dic[key]=dic[key]
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
	unlock_grid()
	return true
	
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
	var found={}
	if objects.has(grid_pos):
		found=objects[grid_pos]
	unlock_grid()
	
	return found

func matching_object_at(mask:String,at:Vector2)->Node2D:
	var objects:=objects_at(at)
	for obj in objects.values():
		if obj.name.matchn(mask):
			return obj
	return null


