extends Node2D

export(bool) var debug:=false
export(NodePath) var animTreePath
export(NodePath) var animSpritePath
var animTree:AnimationTree
var animSprite:AnimatedSprite
var state_machine:AnimationNodeStateMachinePlayback
var body:KinematicBody2D 

func _ready():
	body=get_parent() as KinematicBody2D
	assert(body!=null)
	animTree=get_node(animTreePath) as AnimationTree
	assert(animTree!=null)
	animSprite=get_node(animSpritePath) as AnimatedSprite
	assert(animSprite!=null)
	animTree.active=false
	animTree.active=true
	state_machine = animTree["parameters/playback"]


func isanim(anim):
	return anim==state_machine.get_current_node()

func trigger_anim(anim,func_name=null,func_arg0=null,func_arg1=null,func_arg2=null,func_arg3=null,func_arg4=null,func_arg5=null,func_arg6=null):
	if(debug):print("triggered "+anim)
	state_machine.travel(anim)
	if func_name:
		if func_arg0:
			var args=[func_arg0]
			if func_arg1:args.push_back(func_arg1)
			if func_arg2:args.push_back(func_arg2)
			if func_arg3:args.push_back(func_arg3)
			if func_arg4:args.push_back(func_arg4)
			if func_arg5:args.push_back(func_arg5)
			if func_arg6:args.push_back(func_arg6)
			body.callv(func_name,args)
		else:
			body.call(func_name)

func controlled_node():
	return body
