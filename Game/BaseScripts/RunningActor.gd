extends "res://Game/BaseScripts/Actor.gd"

var last_pushdir:=Vector2.UP
var pushdir:=Vector2.ZERO

export(bool) var one_step_only:=false
export(bool) var always_running:=false
export(bool) var walk_on_push:=true
export(String,"Up","Right","Down","Left") var initial_dir:String="Up"

var push_hardness:=10
var push_reset_timer:Timer=Timer.new()
var push_effort:=0

func _ready():
	for dir in GameEnums.DIRS_MAP:
		if GameEnums.DIRS_MAP[dir]==initial_dir:
			last_pushdir=dir
			break
	if always_running: 
		speedup()
	push_reset_timer.name="push_reset_timer"
	push_reset_timer.one_shot=true
	push_reset_timer.connect("timeout",self,"reset_push")
	add_child(push_reset_timer)

func push_to(who:Node2D,pdir:Vector2)->bool:
	push_reset_timer.stop()
	if was_stopped(next_pos(pdir)): return false
	if (pushdir!=Vector2.ZERO and pushdir!=pdir):reset_push()
	push_effort+=1
	print("push effort on %s is now %s"%[name,push_effort])
	pushdir=pdir
	if push_effort<push_hardness: 
		pushdir=pdir
		push_reset_timer.start(0.2)
		return false 	
	on_pushed()
	return true
	
func reset_push():
	print("push reset on %s"%name)
	pushdir=Vector2.ZERO
	push_effort=0

func on_moved(_from,_to):
	if one_step_only:
		idle()
	elif last_pushdir!=Vector2.ZERO:	
		pushdir=last_pushdir
		on_pushed()

func on_moving(from:Vector2,to:Vector2):
	if global_position.distance_to(to)<(cell_size-2):
		if GameData.world.level.objects_at(from).has(GameEnums.OBJECT_TYPE.ACTOR):
			if GameData.world.level.objects_at(from)[GameEnums.OBJECT_TYPE.ACTOR]==self:
				var _done=GameData.world.level.remove_object_at(from,GameEnums.OBJECT_TYPE.ACTOR) # remove self blocking old cell
				if !_done: printerr("Cannot remove Actor from game map at %s\n%d" % [from, GameFuncs.dump(GameData.world.level.objects)])

func on_move(from,to)->bool:
	var move_ok=.on_move(from,to)
	if move_ok:play_move_anim(current_dir)
	return move_ok
	
func on_pushed():
	if walk_on_push: speeddown()
	goto(position,pushdir)
	last_pushdir=pushdir
	reset_push()

func play_move_anim(dir:Vector2,forced:bool=true):
	match dir:
		Vector2.RIGHT:
			_animator.trigger_anim("GoingRight",forced)
		Vector2.UP:
			_animator.trigger_anim("GoingUp",forced)
		Vector2.DOWN:
			_animator.trigger_anim("GoingDown",forced)
		Vector2.LEFT:
			_animator.trigger_anim("GoingLeft",forced)
		_:
			printerr("Cannot manage dir {}".format([current_dir],"{}"))

func is_actor(actor:int=-1):
	return ( .is_actor(actor) or GameEnums.ACTORS.ANY_RUNNER==actor )

func capabilities()->Array:
	var capas=.capabilities()
	capas.remove(GameEnums.CAPABILITIES.HIT)
	capas.append(GameEnums.CAPABILITIES.PUSH)
	return capas
