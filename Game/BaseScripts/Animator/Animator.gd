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
var current_anim:String=""

var state2anim_dict:={}
var anim2state_dict:={}

signal is_ready
		
func _ready():
	_animTree=get_node(animTree)
	root=(_animTree.tree_root) as AnimationNodeStateMachine
	state_machine = _animTree["parameters/playback"]
	_visual=get_node(visual)
	_animPlayer= (get_node(_animTree.anim_player) as AnimationPlayer)
	_animPlayer.connect("animation_finished",self,"anim_finished")
	_animPlayer.connect("animation_changed",self,"anim_changed")
	catalogAnims()
	if autostart: restart()
	emit_signal("is_ready")


func catalogAnims():
	pass

func anim_finished():
	self.ensure_finish=false
	self.current_anim=""
	
func anim_changed():
	if(debug and debug_mode):debug.push("%s changed anim to %s" % [owner_name(),getanim()])
	current_anim=getanim()

func restart():
	_animTree.active=false
	_animTree.active=true
	if !root.get_start_node():
		if(debug and debug_mode):debug.push("%s starting animator" % owner_name())
		state_machine.start(start_node)
		current_anim=start_node
		
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
	self.current_anim=anim
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
			if(debug and debug_mode):debug.push("%s cannot stackg anim : %s" % debug_vars)
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

func get_node_from_anim(anim:String)->String:
	var result:=""
	for idx in range(0,root.get_transition_count()):
		var to_node:=root.get_transition_to(idx)
		var node:=root.get_node(to_node)
		var matching_node:=dig_into_for_anim(node,anim)
		if matching_node:
			result=matching_node.get_caption()
	return result

func dig_into_for_anim(node:AnimationNode,anim:String)->AnimationNode:
	if node.get_caption()==anim: return node
	if node is AnimationNodeAnimation:
		if (node as AnimationNodeAnimation).animation==anim:
			return node
		else:
			return null
	if node is AnimationNodeStateMachine:
		var smNodes:=list_nodes(node)
		for child in smNodes:
			var child_as_node:AnimationNode=node.get_node(child)
			var matching_node:=dig_into_for_anim(child_as_node,anim)
			if matching_node: return matching_node
	if node is AnimationNodeBlendTree:
		for child in node.get_child_nodes():
			var matching_node:=dig_into_for_anim(child,anim)
			if matching_node: return matching_node
	return null

static func list_nodes(aSM:AnimationNodeStateMachine)->Array:
	var res:=[]
	for idx in range(0,aSM.get_transition_count()):
		var to_node:=aSM.get_transition_to(idx)
		var from_node:=aSM.get_transition_from(idx)
		if not to_node in res: res.append(to_node)
		if not from_node in res: res.append(from_node)
	return res	
		
static func sm_get_transitions_to_node(aSM:AnimationNodeStateMachine, node:String)->Array:
	var result:=[]
	for idx in range(0,aSM.get_transition_count()):
		var to_node:=aSM.get_transition_to(idx)
		if to_node==node: result.push_back(aSM.get_transition(idx))
	return result

	
static func sm_get_transitions_from_node(aSM:AnimationNodeStateMachine,node:String)->Array:
	var result:=[]
	for idx in range(0,aSM.get_transition_count()):
		var from_node:=aSM.get_transition_from(idx)
		if from_node==node: result.push_back(aSM.get_transition(idx))
	return result		

func get_transition_from_to(a:String,b:String)->AnimationNodeStateMachineTransition:
	return sm_get_transition_from_to(root,a,b)

static func sm_get_transition_from_to(aSM:AnimationNodeStateMachine,a:String,b:String)->AnimationNodeStateMachineTransition:
	var from:=sm_get_transitions_from_node(aSM,a)
	var to:=sm_get_transitions_to_node(aSM,b)
	for t in from:
		if to.has(t): return t
	return null
	
func rand_animation_track(anim:String,tracks:Dictionary)->void:
	Utils.rand_animation_track(_animPlayer,anim,tracks)
