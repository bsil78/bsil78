extends Node2D

#exposed values
export(NodePath) var animTree
export(NodePath) var visual
export(NodePath) var animPlayer

#protected values
var state_machine:AnimationNodeStateMachinePlayback
var debug:=DEBUG.OFF
var _visual:Node2D
var _animPlayer:AnimationPlayer

func _ready():
	var _animTree:AnimationTree=get_node(animTree)
	_animTree.active=false
	_animTree.active=true
	state_machine = _animTree["parameters/playback"]
	_visual=get_node(visual)
	_animPlayer=get_node(animPlayer)

func isanim(anim):
	return anim==state_machine.get_current_node()

func getanim()->String:
	return state_machine.get_current_node()

func trigger_anim(anim):
	if(debug):debug.push("triggered "+anim+" anim")
	if isanim(anim): return
	if(debug):debug.push(anim+" anim started")
	state_machine.travel(anim)

func get_visual()->Node2D:
	return _visual
	
func rand_animation_track(anim:String,tracks:Dictionary):
	Utils.rand_animation_track(_animPlayer,anim,tracks)
