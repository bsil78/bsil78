extends Actor
class_name RunningActor

var pushdir

export(bool) var one_step_only:=false
export(bool) var always_running:=false
export(bool) var walk_on_push:=true
export(String,"Up","Right","Down","Left") var initial_dir:String="Up"

func _ready():
	for dir in GameEnums.DIRS_MAP:
		if GameEnums.DIRS_MAP[dir]==initial_dir:
			pushdir=CLASS.stic("Dir2D","from_Vector2",[dir])
			break
	if always_running: 
		speedup()

#who:Actor,pdir:Dir2D
func push_to(who:Actor,pdir)->bool:
	CLASS.check(who,"Actor")
	CLASS.check(pdir,"Dir2D")
	if was_stopped(grid_pos().step(pdir)): return false
	if !pushdir.equals(pdir):
		pushdir=pdir
		return false
	on_pushed()
	return true
	
#from:GridPos,to:GridPos
func on_moved(from,to):
	CLASS.check(from,"GridPos")
	CLASS.check(to,"GridPos")
	if one_step_only:
		idle()
	elif !pushdir.isNone():	
		push_to(self,pushdir)

#from:GridPos,to:GridPos
func on_moving(from,to):
	CLASS.check(from,"GridPos")
	CLASS.check(to,"GridPos")
	if global_position.distance_to(to.as_Vector2())<(cell_size-2):
		if GameData.world.level.objects_at(from).has(GameEnums.OBJECT_TYPE.ACTOR):
			if GameData.world.level.objects_at(from)[GameEnums.OBJECT_TYPE.ACTOR]==self:
				var _done=GameData.world.level.remove_object_at(from,GameEnums.OBJECT_TYPE.ACTOR) # remove self blocking old cell
				if !_done: printerr("Cannot remove Actor from game map at %s\n%d" % [from, GameFuncs.dump(GameData.world.level.objects)])
				
func on_collision(objects:Dictionary)->bool:
	var collide=objects.has(GameEnums.OBJECT_TYPE.ACTOR) or objects.has(GameEnums.OBJECT_TYPE.BLOCK)
	return collide

#from:GridPos,to:GridPos
func on_move(from,to)->bool:
	var move_ok=.on_move(from,to)
	if move_ok:play_move_anim(current_dir)
	return move_ok
	
func on_pushed():
	if walk_on_push: speeddown()
	goto(grid_pos(),pushdir)

#dir:Dir2D
func play_move_anim(dir,forced:bool=true):
	CLASS.check(dir,"Dir2D")
	if dir.isNone(): 
		print_debug("Cannot manage dir")
	else:
		var anim_to_play="Going%s"%dir
		_animator.trigger_anim(anim_to_play,forced)
				

func is_actor(actor:int=-1):
	return ( .is_actor(actor) or GameEnums.ACTORS.ANY_RUNNER==actor )
