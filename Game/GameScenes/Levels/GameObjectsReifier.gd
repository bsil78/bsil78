extends Node2D

var _tilemap:TileMap

func instantiate_objects(dic:Dictionary,size:int):
# warning-ignore:integer_division
	var half:=GameData.cell_size/2
	for x in range(0,size):
		for y in range(0,size):
			var cell=tilemap().get_cell(x,y)
			if cell==-1:continue
			var tile_name=tilemap().tile_set.tile_get_name(cell)
			var grid_pos=Vector2(x,y)
			var obj:Node2D=instance(dic,tile_name,grid_pos)
			if obj:
				add_child(obj)
				obj.position=grid_pos*GameData.cell_size+Vector2(half,half)
				GameFuncs.manage_debug_of(obj)
	tilemap().queue_free()

func tilemap()->TileMap:
	if !_tilemap:
		_tilemap=find_node("*TileMap",true,true) as TileMap
		assert(_tilemap!=null)
	return _tilemap

func has_property(name:String,obj:Object)->bool:
	var props:Array=obj.get_property_list()
	for prop in props:
		if prop.name==name: return true
	return false
	
func tilemap_params(key:int)->Array:
	return tilemap().params.get(key) as Array
	
func instantiate_object(_id,_args,_grid_pos)->Node2D:
	return null	
			
func instance(dic,tile_name,grid_pos)->Node2D:
	var args:=extract_obj_params(dic,tile_name)
	if !args.empty():
		var id:int=args.pop_front()
		return instantiate_object(id,args,grid_pos)
	else:
		print_debug("Cannot instantiate %s"%tile_name)
		return null
			
func extract_obj_params(dic:Dictionary,tile_name:String)->Array:
	for id in dic:
		var pattern=dic[id]
		var regexp:RegEx=RegEx.new()
		regexp.compile(pattern)
		var matchs:RegExMatch=regexp.search(tile_name)
		if matchs:
			var args=matchs.strings
			args.pop_front()
			args.push_front(id)
			return args
	return []
