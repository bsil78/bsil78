extends "res://Game/BaseScripts/Actor.gd"

var pushdir:=Vector2.UP

export(bool) var one_step_only:=false
export(bool) var always_running:=false
export(bool) var walk_on_push:=true
export(String,"Up","Right","Down","Left") var initial_dir:String="Up"

func _ready():
	for dir in GameEnums.DIRS_MAP:
		if GameEnums.DIRS_MAP[dir]==initial_dir:
			pushdir=dir
			break
	if always_running: 
		speedup()

func push_to(who:Node2D,pdir:Vector2)->bool:
	if is_something(next_pos(pdir)): return false
	if pushdir!=pdir:
		pushdir=pdir
		return false
	on_pushed()
	return true
	
func on_moved(_from,_to):
	if one_step_only:
		idle()
	elif pushdir!=Vector2.ZERO:	
		push_to(self,pushdir)

func on_moving(from:Vector2,to:Vector2):
	if global_position.distance_to(to)<(cell_size-2):
		if GameData.world.level.objects_at(from).has(GameEnums.OBJECT_TYPE.ACTOR):
			if GameData.world.level.objects_at(from)[GameEnums.OBJECT_TYPE.ACTOR]==self:
				var _done=GameData.world.level.remove_object_at(from,GameEnums.OBJECT_TYPE.ACTOR) # remove self blocking old cell
				if !_done: printerr("Cannot remove Actor from game map at %s\n%d" % [from, GameFuncs.dump(GameData.world.level.objects)])
				
func on_collision(objects:Dictionary)->bool:
	var collide=objects.has(GameEnums.OBJECT_TYPE.ACTOR) or objects.has(GameEnums.OBJECT_TYPE.BLOCK)
	return collide

func on_move(from,to):
	.on_move(from,to)
	play_move_anim(current_dir)
	
func on_pushed():
	if walk_on_push: speeddown()
	goto(pushdir)

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
