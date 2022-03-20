extends Node2D

#exposed values
export(NodePath) var animTree
export(NodePath) var visual
export(PoolStringArray) var looping_anims:=[]
export(bool) var autostart:=true
export(String) var start_node:="start"

#protected values
var state_machine:AnimationNodeStateMachinePlayback
var debug:=DEBUG.ON
export(bool) var debug_mode:=false
var _visual:Node2D
var _animPlayer:AnimationPlayer
var _animTree:AnimationTree
var ensure_finish:=false
var stacked_anims=[]
var lock:=false
var root:AnimationNodeStateMachine

signal is_ready
		
func _ready():
	_animTree=get_node(animTree)
	root=(_animTree.tree_root) as AnimationNodeStateMachine
	state_machine = _animTree["parameters/playback"]
	_visual=get_node(visual)
	_animPlayer=get_node(_animTree.anim_player)
	if autostart: restart()
	emit_signal("is_ready")

func restart():
	_animTree.active=false
	_animTree.active=true
	if !root.get_start_node():
		if(debug and debug_mode):debug.push("%s starting animator" % owner_name())
		state_machine.start(start_node)
		
func _process(_delta):
	if !state_machine or is_one_shot_anim(getanim()):return
	if lock:return
	self.ensure_finish=false
	if !stacked_anims.empty():call_deferred("pop_anim")
		
func pop_anim():
	var animargs=stacked_anims.pop_front()
	if(debug and debug_mode):debug.push("%s pop anim : %s" % [ owner_name(),animargs[0] ])
	callv("trigger_anim",animargs)
		
func owner_name()->String:
	return get_parent().get_parent().name
	
func getanim()->String:
	if state_machine:
		return state_machine.get_current_node()
	else:
		return "[NOT READY]"
		
func trigger_anim(anim:String,enforce_same:bool=false,ensure_finish:bool=false)->bool:
	if !state_machine or getanim().empty():	return false
	var canlock=lock()
	if !canlock:
		if(debug and debug_mode): debug.push("%s cannot lock" % owner_name())
		stack(anim,enforce_same,ensure_finish)
		return !canlock
	var debug_vars=[owner_name(),anim]
	var current=getanim()
	if current==anim: 
		if !enforce_same: return unlocked()
		if(debug and debug_mode): debug.push("%s is enforcing same anim: %s" % [owner_name(),anim])
		if is_loop_anim(anim):return unlocked()
		if(debug and debug_mode): debug.push("%s is not a loop and should play" % [anim])
	if(debug and debug_mode):
		#if !current.empty():
		debug.push("%s currently playing anim : %s with ensure finish = %s" % [owner_name(),current,self.ensure_finish])
	if anim!=start_node:
		if !current.empty() and is_one_shot_anim(current):
			if self.ensure_finish:
				stack(anim,enforce_same,ensure_finish)
				return unlocked()
	if(debug and debug_mode):debug.push("%s now playing anim : %s" % debug_vars)
	self.ensure_finish=!is_loop_anim(anim) && ensure_finish
	state_machine.start(anim)
	if(getanim()!=anim):
		if anim!="start":yield(Utils.timer(0.05),"timeout")
		if(debug and debug_mode):debug.push("%s current anim : %s" % [owner_name(),getanim()])
	return unlocked()

func unlocked()->bool:
	lock=false
	return lock

func lock()->bool:
	if lock: return false
	lock=true
	return lock

func stack(anim:String,enforce_same:bool=false,ensure_finish:bool=false)->void:
	var debug_vars=[owner_name(),anim]
	if(debug and debug_mode):debug.push("%s want to stack anim : %s" % debug_vars)
	var last_stacked:Array
	if !stacked_anims.empty():last_stacked=stacked_anims.back()
	var last_stacked_anim:=""
	if last_stacked:last_stacked_anim=last_stacked[0]
	if ( !is_loop_anim(anim) or last_stacked_anim!=anim ):
		if (last_stacked_anim==anim and !enforce_same): 
			if(debug and debug_mode):debug.push("%s cannot stacking anim : %s" % debug_vars)
			return
		if(debug and debug_mode):debug.push("%s is stacking anim : %s" % debug_vars)
		stacked_anims.push_back([anim,enforce_same,ensure_finish])
		return
	if(debug and debug_mode):debug.push("%s has not stacked anim : %s" % debug_vars)

func get_visual()->Node2D:
	return _visual

func is_one_shot_anim(anim)->bool:
	return anim=="start" or ( !anim.empty() and !is_loop_anim(anim) )
	
func is_loop_anim(anim:String)->bool:
	for loop in looping_anims:
		if loop==anim:return true
	return false
	
func get_transitions_to_node(node:String)->Array:
	var result:=[]
	for idx in range(0,root.get_transition_count()):
		var to_node:=root.get_transition_to(idx)
		if to_node==node: result.push_back(root.get_transition(idx))
	return result
	
func get_transitions_from_node(node:String)->Array:
	var result:=[]
	for idx in range(0,root.get_transition_count()):
		var to_node:=root.get_transition_from(idx)
		if to_node==node: result.push_back(root.get_transition(idx))
	return result		

func get_transition_from_to(a:String,b:String)->AnimationNodeStateMachineTransition:
	var from:=get_transitions_from_node(a)
	var to:=get_transitions_to_node(b)
	for t in from:
		if to.has(t): return t
	return null
	
func rand_animation_track(anim:String,tracks:Dictionary)->void:
	Utils.rand_animation_track(_animPlayer,anim,tracks)
