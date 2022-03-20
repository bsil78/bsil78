extends "res://Game/BaseScripts/RunningActor.gd"

var last_dir:=Vector2.UP

var fixed_dir:=last_dir
var waiting_timer:Timer=Timer.new()

func _ready():
	add_child(waiting_timer)
	for dir in GameEnums.DIRS_MAP:
		if GameEnums.DIRS_MAP[dir]==initial_dir:
			last_dir=dir
			fixed_dir=dir
			break
	idle()
	waiting_timer.one_shot=true

func _physics_process(_delta):
	#dbgmsg("wt : %s \nir : %s \ncd : %s" % [waiting_timer,is_running,current_dir])
	if can_move and current_dir==NONE:
		if not is_running:
			if waiting_timer.is_stopped():
				if has_detected_outerwall:return
				try_to_run()
			else:
				dbgmsg("not running and waiting")
			return
		else: #was running !
			dbgmsg("is no more running !")
			var pos_in_front=next_pos(last_dir)
			dbgmsg("pos in dir %s is %s"%[last_dir,pos_in_front])
			if was_stopped(pos_in_front):
				dbgmsg("was stopped at %s, need to idle"%pos_in_front)
				idle()
			else:
				run()
		
func run_if_free(right,left):
	if !can_move: return
	if is_blocked_by(right,GameFuncs.rotl(last_dir)): 
		dbgmsg("blocked on right !")
		return 
	if is_blocked_by(left,GameFuncs.rotr(last_dir)):
		dbgmsg("blocked on left !")
		return 
	run()

func try_to_run():
	#dbgmsg("try to run")
	if waiting_timer.is_connected("timeout",self,"run_if_free"): 	waiting_timer.disconnect("timeout",self,"run_if_free")
	var pos_in_front=next_pos(last_dir)
	if not was_stopped(pos_in_front):
		var next_pos_r=next_pos_from(pos_in_front,GameFuncs.rotr(last_dir))
		var matcher={GameEnums.OBJECT_TYPE.ACTOR:[GameEnums.ACTORS.ANY_PLAYER]}
		var objs_r=GameData.world.level.matching_objects_at(matcher,next_pos_r)
		var player_on_frontright:Node2D=null if objs_r.empty() else objs_r[0]
		var next_pos_l=next_pos_from(pos_in_front,GameFuncs.rotl(last_dir))
		var objs_l=GameData.world.level.matching_objects_at(matcher,next_pos_l)
		var player_on_frontleft:Node2D=null if objs_l.empty() else objs_l[0]
		if player_on_frontleft or player_on_frontright:
			if not ( (player_on_frontleft and player_on_frontleft.next_dir in [fixed_dir,fixed_dir*-1]) \
			  		or \
					 (player_on_frontright and player_on_frontright.next_dir in [fixed_dir,fixed_dir*-1]) ): 
				if !waiting_timer.is_connected("timeout",self,"run_if_free"): 
					var _err=waiting_timer.connect("timeout",self,"run_if_free",[player_on_frontright,player_on_frontleft],CONNECT_ONESHOT)
				waiting_timer.start(0.1)
				return
		run()

func run():
	speedup()
	goto(position,last_dir)

func is_blocked_by(player:Node2D,intersect_pdir:Vector2)->bool:
	if not player : return false
	var pdir = player.next_dir
#	if intersect_pdir!=pdir or pdir in [ fixed_dir, fixed_dir*-1 ]: return false
	if intersect_pdir!=pdir: return false
	return true
	
func push_to(who:Node2D,dir:Vector2)->bool:
	if !can_be_push_by(who): return false
	if is_running:return false
	if dir==fixed_dir*-1:
		return push_from_front(who)
	if dir==fixed_dir: 
		return push_from_back(who)
	return .push_to(who,dir)
	
func push_from_front(_who:Node2D)->bool:
	return false
	
func push_from_back(_who:Node2D)->bool:
	return false	

func on_move(from,to)->bool:
	var move_ok=.on_move(from,to)
	if current_dir==fixed_dir:
		last_dir=current_dir
		is_running=true
	return move_ok
	
func on_moved(from,to):
	#dbgmsg("has moved and should resolve collision if running (%s)"%is_running)
	if is_running:
		dbgmsg("testing collision at end of move")
		if was_stopped(next_pos_from(to,current_dir)):
			yield(Utils.timer(0.1),"timeout") 
			if can_move: 
				.idle()
				return
	.on_moved(from,to)
	

func idle():
	is_running=false
	.idle()

func play_move_anim(dir:Vector2):
	if dir==fixed_dir: .play_move_anim(dir)
	
#func on_collision(others:Dictionary)->bool:
#	var collided = .on_collision(others)
#	if collided: is_running=false
#	return collided
