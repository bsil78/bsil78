extends Node2D

#exposed values
export(NodePath) var animTree

#protected values
var state_machine:AnimationNodeStateMachinePlayback
var debug:=DEBUG.OFF

func _ready():
	var _animTree:AnimationTree=get_node(animTree)
	_animTree.active=false
	_animTree.active=true
	state_machine = _animTree["parameters/playback"]


func isanim(anim):
	return anim==state_machine.get_current_node()

func getanim()->String:
	return state_machine.get_current_node()

func trigger_anim(anim):
	if(debug):debug.push("triggered "+anim+" anim")
	if isanim(anim): return
	if(debug):debug.push(anim+" anim started")
	state_machine.travel(anim)


