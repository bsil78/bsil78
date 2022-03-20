extends Node2D

#exposed values
export(NodePath) var animTree
export(NodePath) var visual
export(NodePath) var animPlayer

#protected values
var state_machine:AnimationNodeStateMachinePlayback
var debug:=DEBUG.ON
export(bool) var debug_mode:=false
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
	if state_machine:
		return anim==state_machine.get_current_node()
	else:
		return false
		
func getanim()->String:
	return state_machine.get_current_node()

func trigger_anim(anim:String,enforce:bool=false):
	var debug_vars=[get_parent().get_parent().name,anim]
	if(debug and debug_mode):debug.push("{} triggered {} anim",debug_vars)
	if !enforce and isanim(anim): return
	if(debug and debug_mode):debug.push("{} {} anim starting",debug_vars)
	state_machine.start(anim)

func get_visual()->Node2D:
	return _visual
	
func rand_animation_track(anim:String,tracks:Dictionary):
	Utils.rand_animation_track(_animPlayer,anim,tracks)
