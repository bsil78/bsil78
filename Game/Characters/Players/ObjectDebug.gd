extends Control

export(Font) var font

var message:=""

func _ready():
	visible=(DEBUG.active and DEBUG.objects)

func _process(_delta):
	var owner:=get_parent()
	var animator:=owner.get_node_or_null("Animator")
	var anim:=""
	if animator:anim=animator.getanim()
	$Label.text="global pos:{}\ngrid pos:{}\nanim:{},\n{}".format([
									owner.global_position,
									GameFuncs.grid_pos(owner.global_position),
									anim,
									message
								],"{}").c_unescape()

