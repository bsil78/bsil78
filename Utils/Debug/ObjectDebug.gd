extends Control

export(Font) var font

var message:=""
export(bool) var hide_me:bool=true

func _ready():
	visible=(!hide_me and DEBUG.active and DEBUG.objects)

func _process(_delta):
	var owner:=get_parent()
	var animator:=owner.find_node("Animator",true,false)
	var anim:=""
	if animator:anim=animator.getanim()
	$Label.text=("%s\nglobal pos:%s\ngrid pos:%s\nanim:%s,\n%s" % [
									owner.name,
									owner.global_position,
									GameFuncs.grid_pos(owner.global_position),
									anim,
									message
								]).c_unescape()

