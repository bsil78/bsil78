extends "res://Game/BaseScripts/RunningActor.gd"


var last_dir:=Vector2.UP
var is_running:=false
var fixed_dir:=last_dir
var waiting_timer:SceneTreeTimer

func _ready():
	for dir in GameEnums.DIRS_MAP:
		if GameEnums.DIRS_MAP[dir]==initial_dir:
			last_dir=dir
			fixed_dir=dir
			break
	idle()

func _physics_process(_delta):
	dbgmsg("wt : %s \nir : %s \ncd : %s" % [waiting_timer,is_running,current_dir])
	if current_dir==NONE:
		if not is_running:
			if not waiting_timer :
				var pos_in_front=next_pos(last_dir)
				if not was_stopped(pos_in_front):
					var player_on_frontright:Node2D=GameData.world.level.matching_object_at("Player*",next_pos_from(pos_in_front,GameFuncs.rotr(last_dir)))
					var player_on_frontleft:Node2D=GameData.world.level.matching_object_at("Player*",next_pos_from(pos_in_front,GameFuncs.rotl(last_dir)))
					if player_on_frontleft or player_on_frontright:
						waiting_timer=Utils.timer(0.1)
						if !waiting_timer.is_connected("timeout",self,"try_run"): 
							var _err=waiting_timer.connect("timeout",self,"try_run",[player_on_frontright,player_on_frontleft],CONNECT_ONESHOT)
					else:
						run()
			return
		else: #was running !
			var pos_in_front=next_pos(last_dir)
			if was_stopped(pos_in_front):
				idle()
		
func try_run(right,left):
	waiting_timer=null
	if is_intersepting(right,GameFuncs.rotl(last_dir)): return 
	if is_intersepting(left,GameFuncs.rotr(last_dir)): return 
	run()
	
func run():
	speedup()
	goto(position,last_dir)

func is_intersepting(player:Node2D,intersect_pdir:Vector2)->bool:
	if not player : return false
	var pdir = player.next_dir
	if intersect_pdir!=pdir: return false
	return true
	
func push_to(who:Node2D,dir:Vector2)->bool:
	if is_running:
		return false
	if dir==fixed_dir*-1:
		return push_from_front(who)
	if dir==fixed_dir: 
		return push_from_back(who)
	return .push_to(who,dir)
	
func push_from_front(who:Node2D)->bool:
	return false
	
func push_from_back(who:Node2D)->bool:
	return false	

func on_move(from,to)->bool:
	var move_ok=.on_move(from,to)
	if current_dir==fixed_dir:
		last_dir=current_dir
		is_running=true
	return move_ok
	
func on_moved(from,to):
	if !is_running:
		.on_moved(from,to)

func idle():
	is_running=false
	.idle()

func play_move_anim(dir:Vector2,forced:bool=true):
	if dir==fixed_dir: .play_move_anim(dir,forced)
	
func on_collision(others:Dictionary)->bool:
	var collided = .on_collision(others)
	if collided: idle()
	return collided



	
