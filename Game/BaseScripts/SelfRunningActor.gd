extends RunningActor
class_name SelfRunningActor


var last_dir
var is_running:=false
var fixed_dir
var waiting_timer:SceneTreeTimer

func _ready():
	for dir in GameEnums.DIRS_MAP:
		if GameEnums.DIRS_MAP[dir]==initial_dir:
			fixed_dir=CLASS.stic("Dir2D","from_Vector2",[dir])
			last_dir=fixed_dir
			break
	idle()

func _physics_process(_delta):
	dbgmsg("wt : %s \nir : %s \ncd : %s" % [waiting_timer,is_running,current_dir])
	if not waiting_timer and not is_running and current_dir.isNone():
		var pos_in_front=last_pos.step(last_dir)
		if not was_stopped(pos_in_front):
			var player_on_frontright:Node2D=GameData.world.level.matching_object_at("Player*",pos_in_front.step(last_dir.toRight()))
			var player_on_frontleft:Node2D=GameData.world.level.matching_object_at("Player*",pos_in_front.step(last_dir.toLeft()))
			if player_on_frontleft or player_on_frontright:
				waiting_timer=Utils.timer(0.1)
				if !waiting_timer.is_connected("timeout",self,"try_run"): 
					var _err=waiting_timer.connect("timeout",self,"try_run",[player_on_frontright,player_on_frontleft],CONNECT_ONESHOT)
			else:
				run()

func try_run(right,left):
	waiting_timer=null
	if is_intersepting(right,last_dir.toLeft()): return 
	if is_intersepting(left,last_dir.toRight()): return 
	run()
	
func run():
	speedup()
	goto(grid_pos(),last_dir)

#intersect_pdir:Dir2D
func is_intersepting(player:Player,intersect_pdir)->bool:
	CLASS.check(intersect_pdir,"Dir2D")
	if not player : return false
	var pdir = player.next_dir
	if intersect_pdir!=pdir: return false
	return true
	
#who:Actor,dir:Dir2D
func push_to(who,dir)->bool:
	CLASS.check(who,"Actor")
	CLASS.check(dir,"Dir2D")
	if is_running:
		return false
	if dir.equals(fixed_dir.opposite()):
		return push_from_front(who)
	if dir.equals(fixed_dir): 
		return push_from_back(who)
	return .push_to(who,dir)
	
#who:Actor
func push_from_front(who)->bool:
	CLASS.check(who,"Actor")
	return false

#who:Actor
func push_from_back(who)->bool:
	CLASS.check(who,"Actor")
	return false	

#from:Dir2D,to:Dir2D
func on_move(from,to)->bool:
	var move_ok=.on_move(from,to)
	if current_dir.equals(fixed_dir):
		last_dir=current_dir
		is_running=true
	return move_ok

#from:Dir2D,to:Dir2D	
func on_moved(from,to):
	CLASS.check(from,"GridPos")
	CLASS.check(to,"GridPos")	
	if !is_running:
		.on_moved(from,to)

func idle():
	is_running=false
	.idle()

#dir:Dir2D
func play_move_anim(dir,forced:bool=true):
	CLASS.check(dir,"Dir2D")
	if dir.equals(fixed_dir): .play_move_anim(dir,forced)
	

func on_collision(others:Dictionary)->bool:
	var collided = .on_collision(others)
	if collided: idle()
	return collided

func collide_actor(actor:Actor)->bool:
	if GameFuncs.is_actor(actor,[GameEnums.ACTORS.ANY_PLAYER,GameEnums.ACTORS.ANY_ENEMY]):
		if current_dir.equals(fixed_dir) or actor.current_dir.isIn([fixed_dir,fixed_dir.opposite()]):
			actor.hit(self,200)
			return false	
	return .collide_actor(actor)

	
