extends "res://Game/BaseScripts/RunningActor.gd"


var last_dir:=Vector2.UP
var is_running:=false
var fixed_dir:=last_dir
var waiting_timer:SceneTreeTimer

export(String,"Up","Down","Right","Left") var running_dir:="Left"

func _ready():
	for dir in GameEnums.DIRS_MAP:
		if GameEnums.DIRS_MAP[dir]==running_dir:
			last_dir=dir
			fixed_dir=dir
			break
	idle()

func _physics_process(_delta):
	if $ObjectDebug:$ObjectDebug.message=("wt : %s \nir : %s \ncd : %s" % [waiting_timer,is_running,current_dir])
	if not waiting_timer and not is_running and current_dir==NONE:
		var pos_in_front=next_pos(last_dir)
		if not is_something(pos_in_front):
			var player_on_frontright:=GameFuncs.matching_level_object("Player*",next_pos_from(pos_in_front,GameFuncs.rotr(last_dir)))
			var player_on_frontleft:=GameFuncs.matching_level_object("Player*",next_pos_from(pos_in_front,GameFuncs.rotl(last_dir)))
			if player_on_frontleft or player_on_frontright:
				waiting_timer=Utils.timer(0.1)
				if !waiting_timer.is_connected("timeout",self,"try_run"): 
					var _err=waiting_timer.connect("timeout",self,"try_run",[player_on_frontright,player_on_frontleft],CONNECT_ONESHOT)
			else:
				run()

func try_run(right,left):
	waiting_timer=null
	if is_intersepting(right,GameFuncs.rotl(last_dir)): return 
	if is_intersepting(left,GameFuncs.rotr(last_dir)): return 
	run()
	
func run():
	speedup()
	goto(last_dir)

func is_intersepting(player:Node2D,intersect_pdir:Vector2)->bool:
	if not player : return false
	var pdir = player.next_dir
	if intersect_pdir!=pdir: return false
	return true
	
func push_to(dir):
	if is_running:
		return false
	if dir==fixed_dir:
		return push_from_front()
	if dir==fixed_dir*-1: 
		return push_from_back()
	return .push_to(dir)
	
func push_from_front()->bool:
	return false
	
func push_from_back()->bool:
	return false	

func on_move(from,to):
	if current_dir==fixed_dir:
		last_dir=current_dir
		is_running=true
	.on_move(from,to)

func on_moved(from,to):
	if !is_running:
		.on_moved(from,to)

func idle():
	is_running=false
	.idle()

func play_move_anim(dir:Vector2,forced:bool=true):
	if dir==fixed_dir: .play_move_anim(dir,forced)
	
func on_collision(objects:Dictionary)->bool:
	if current_dir==fixed_dir:
		if objects.has(GameEnums.OBJECT_TYPE.ACTOR):
			var actor:=objects[GameEnums.OBJECT_TYPE.ACTOR] as Node2D
			if actor.name.matchn("Player*") or actor.name.matchn("Enemy*"):
				actor.hit(self,200)
			idle()
		return true
	
	var collided = .on_collision(objects)
	if collided: 
		idle()
		return true
	else:
		return false
