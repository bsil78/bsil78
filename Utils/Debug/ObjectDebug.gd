extends Control

export(Font) var font

var message:=""
var objects:String=""
var mousepos:Vector2=Vector2.ZERO
export(bool) var hide_me:bool=true
var debug_obj:Object


func _ready():
	var parent:=get_parent()
	if parent is Node2D:
		debug_obj=parent as Node2D

func _process(_delta):
	visible=(GameData.world!=null and !hide_me and DEBUG.active and DEBUG.objects)
	if is_instance_valid(debug_obj):
		var text:=""
		if debug_obj.has_method("state_str"):
			text=debug_obj.state_str()
		else:
			text=("%s\nglobal pos:%s\ngrid pos:%s\n%s" % [
										debug_obj.name,
										debug_obj.global_position,
										GameFuncs.grid_pos(debug_obj.global_position),
										GameFuncs.dump(DEBUG.messages).replace(",",",\n\t")
										])
		$Label.text=text.c_unescape()
