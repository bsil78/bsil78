extends Panel

export(Font) var aFont
export(Vector2) var offset:=Vector2(128,128)

var debug:=DEBUG
var mousepos:Vector2
var idx:=0

func _draw():
	if(DEBUG.panel):
		var i:=0
		for msg in DEBUG.messages:
			draw_string(aFont,Vector2(0,(1+i)*16),str(msg),Color(1,1,1,1))
			i+=1

			
func _process(_delta):
	if(DEBUG.panel): update()
	if mousepos:
		if $ObjectDebug.debug_obj:
			$ObjectDebug.rect_position=mousepos+Vector2(-16,-32)
		else:
			$ObjectDebug.rect_position=mousepos
func _physics_process(_delta):
	if GameData.world and mousepos and GameData.current_player and GameData.current_player.is_inside_tree():
		var camera:Camera2D = GameData.current_player.get_camera()
		var gamepos=mousepos-camera.get_viewport_transform().origin
		var grid_pos=GameFuncs.grid_pos(gamepos)
#		var space_state:Physics2DDirectSpaceState = GameData.world.get_world_2d().direct_space_state
#		var shape=Physics2DShapeQueryParameters.new()
#		shape.exclude=[self,$ObjectDebug,$ObjectDebug/Label]
#		shape.transform=Transform2D(0,gamepos)
#		shape.margin=0.0
#		var circle=CircleShape2D.new()
#		circle.radius=1.0
#		shape.set_shape(circle)
#		var result:Array = space_state.intersect_shape(shape,10)
#		var objects=[]
#		for item in result:
#			if item.collider.name.matchn("*wall*"):continue
#			objects.append(item)
		
		var objects=GameData.world.level.objects.get(grid_pos,{}).values()
		if !objects.empty():
			$ObjectDebug.objects=GameFuncs.dump(objects)
#			$ObjectDebug.debug_obj=objects[idx%objects.size()].collider as Node2D
			$ObjectDebug.debug_obj=objects[idx%objects.size()]
		else:
			$ObjectDebug/Label.text=("%s\n%s"%[gamepos,GameFuncs.grid_pos(gamepos)]).c_unescape()
			$ObjectDebug.objects=""
			$ObjectDebug.debug_obj=null	
		
func _input(event):
	if event is InputEventMouseMotion:
		var mouse:InputEventMouseMotion=event as InputEventMouseMotion
		mousepos=mouse.position
		$ObjectDebug.mousepos=mousepos
	if event is InputEventKey:
		var key:InputEventKey=event as InputEventKey
		if key.scancode==KEY_KP_ADD:
			idx+=1
		if key.scancode==KEY_KP_SUBTRACT:
			idx=max(idx-1,0)
