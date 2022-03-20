extends ColorRect

var pixel_size
var pixel_vect
var coffset
var vect_coffset
const one_offset=Vector2(1,1)
const two_offset=Vector2(2,2)
var map_elements:={}

func _ready():
	GameData.world.connect("ready",self,"_on_level_ready")
	GameFuncs.connect("players_switched",self,"update_minimap")

func _on_level_ready():
	var size=GameData.world.level.size
	pixel_size=int(128/size)
	var hw=2+(size+2)*pixel_size
	rect_size=Vector2(hw,hw)
	var xy=max(8,72-hw/2)
	rect_position=Vector2(xy,xy)
	pixel_vect=Vector2(pixel_size,pixel_size)
	coffset=pixel_size+1
	vect_coffset=Vector2(coffset,coffset)
	
func _draw():
	var players_pos:=[]
	var not_found_players:=GameData.players.keys()
	var players_grid_pos:={}
	for player in GameData.players:
		players_grid_pos[player]=GameFuncs.grid_pos(GameData.players[player].position)
	if !map_elements.empty():
		for elem in map_elements:
			var elem_pos=elem*pixel_size
			var pixel_color=map_elements[elem]
			draw_rect(Rect2(elem_pos+vect_coffset,pixel_vect),pixel_color,true)
			for player in not_found_players.duplicate():
				if players_grid_pos[player]==elem:
					players_pos.append(elem_pos)
					not_found_players.remove(not_found_players.find(player))
					
		for pos in players_pos: 	
			draw_rect(Rect2(pos+vect_coffset,pixel_vect),Color.aquamarine,false,1.0)
			draw_rect(Rect2(pos+vect_coffset-one_offset,pixel_vect+two_offset),Color.aliceblue,false,1.0)
			
		
func update_minimap():
	if GameData.current_player:
		map_elements=map_elements()
		if !map_elements.empty():
			show()
			update()
			return
	hide()

var static_elements:={}
var cached_zones:={}


func map_elements()->Dictionary:
	var elements:={}
	var level_maps=GameData.current_player.inventory().maps.get(GameData.current_level)
	if level_maps:
		for map in level_maps:
			var part_elements:Dictionary=elements_of_positions(map.name,map.parts())
			for pos in part_elements:
				elements[pos]=part_elements[pos]
	return elements

func elements_of_positions(zone_name:String,zones:Array)->Dictionary:
	var cachedz=cached_zones.get(zone_name)
	var myzones:Array=cachedz if cachedz else zones
	var dynzones:=myzones.duplicate()
	var static_elems:={} if !cachedz else static_elements[zone_name]
	var elements:={} if !cachedz else static_elems
	for pos in myzones:
		if !cachedz:
			if pos.x<0 or pos.x>=GameData.world.level.size or pos.y<0 or pos.y>=GameData.world.level.size:
				elements[pos]=walls_col	
				static_elems[pos]=walls_col	
				dynzones.remove(dynzones.find(pos))
				continue
			if GameData.world.level.innerwalls.get_cellv(pos)!=TileMap.INVALID_CELL: 
				elements[pos]=walls_col
				static_elems[pos]=walls_col	
				dynzones.remove(dynzones.find(pos))
				continue
		var pixels_pos=pos*GameData.cell_size+Vector2(GameData.cell_size/2,GameData.cell_size/2)
		elements[pos]=map_color_at(pixels_pos)
	if !cachedz:
		static_elements[zone_name]=static_elems
		cached_zones[zone_name]=dynzones
	return elements
	

export(Color) var coin_col
export(Color) var mobile_col
export(Color) var fix_col
export(Color) var bad_col

var filters:Dictionary={
		0 : {	GameEnums.OBJECT_TYPE.ITEM:	[ GameEnums.ITEMS.GOD_SIGN_GOOD ],
				GameEnums.OBJECT_TYPE.BLOCK:[ GameEnums.BLOCKS.GOD_SIGN_BLOCK_GOOD ] },
		1 : { 	GameEnums.OBJECT_TYPE.ACTOR: [	GameEnums.ACTORS.ANY_RUNNER,
												GameEnums.ACTORS.MOBILE_WALL ],
				GameEnums.OBJECT_TYPE.BLOCK: [	GameEnums.BLOCKS.FORCE_FIELD ] },
		2 : { 	GameEnums.OBJECT_TYPE.BLOCK: [	GameEnums.BLOCKS.FAKE_WALL,
												GameEnums.BLOCKS.EXIT, 
												GameEnums.BLOCKS.TELEPORTER ] },
		3 : {	GameEnums.OBJECT_TYPE.BLOCK: [ GameEnums.BLOCKS.GOD_SIGN_BLOCK_BAD ],
				GameEnums.OBJECT_TYPE.ITEM: [ GameEnums.ITEMS.GOD_SIGN_BAD ] }
	}
	


export(Color) var walls_col
export(Color) var bg_col
export(Color) var enemies_col

func map_color_at(pixels_pos):
	var colors:Dictionary={
		0:coin_col,
		1:mobile_col,
		2:fix_col,
		3:bad_col
	}
	var enemies:Array=GameData.world.level.matching_objects_at({ GameEnums.OBJECT_TYPE.ACTOR: [	GameEnums.ACTORS.ANY_ENEMY]},pixels_pos)
	if enemies and GameFuncs.grid_pos(enemies[0].position)==GameFuncs.grid_pos(pixels_pos): return enemies_col
	for idx in range(0,4):
		if GameData.world.level.matching_objects_at(filters[idx],pixels_pos): return colors[idx]
	if GameData.world.level.has_block_at(pixels_pos): return Color.orange
	if GameData.world.level.has_item_at(pixels_pos): return Color.pink
	return bg_col	
