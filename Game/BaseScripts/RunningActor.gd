extends "res://Game/BaseScripts/Actor.gd"

var pushdir:=Vector2.UP

export(bool) var one_step_only:=false
export(bool) var always_running:=false
export(bool) var walk_on_push:=true

func _ready():
	if always_running: 
		speedup()

func push_to(pdir:Vector2):
	if is_something(next_pos(pdir)): return false
	if pushdir!=pdir:
		pushdir=pdir
		return false
	on_pushed()
	return true
	
func on_moved(from,to):
	if one_step_only:
		idle()
	elif pushdir!=Vector2.ZERO:	
		push_to(pushdir)

func on_moving(from:Vector2,to:Vector2):
	if global_position.distance_to(to)<(grid_size-2):
		if GameFuncs.level_objects(from).has(GameEnums.OBJECT_TYPE.ACTOR):
			if GameFuncs.level_objects(from)[GameEnums.OBJECT_TYPE.ACTOR]==self:
				var _done=GameFuncs.remove_level_object_at(from,GameEnums.OBJECT_TYPE.ACTOR) # remove self blocking old cell
				if !_done: printerr("Cannot remove Actor from game map at %s\n%d" % [from, GameFuncs.dump(GameData.level_objects)])
				
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
