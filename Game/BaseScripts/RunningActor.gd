extends "res://Game/BaseScripts/Actor.gd"

export(bool) var one_step_on_push:=false
export(bool) var always_running:=false
export(bool) var walk_on_push:=true
export(String,"Up","Right","Down","Left") var initial_dir:String="Up"

var push_hardness:=10
var push_reset_timer:Timer=Timer.new()
var push_effort:=0
var last_pushdir:=Vector2.UP
var pushdir:=NONE
var is_running:=false

export(NodePath) var audio_player_path 
var rock_sound=preload("res://Game/Assets/Audio/ogg/effects/rock_moving.ogg")
var audio_player

func _ready():
	audio_player=get_node(audio_player_path)
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

func can_be_push_by(who:Node2D)->bool:
	return who.is_actor(GameEnums.ACTORS.ANY_PLAYER)

func push_to(who:Node2D,pdir:Vector2)->bool:
	if !can_be_push_by(who):return false
	push_reset_timer.stop()
	if (pushdir!=NONE and pushdir!=pdir):reset_push()
	push_effort+=1
	dbgmsg("pushed by %s with effort %s"%[who,push_effort])
	pushdir=pdir
	if push_effort<push_hardness: 
		pushdir=pdir
		push_reset_timer.start(0.2)
		return false
	if was_stopped(next_pos(pdir)):
		dbgmsg("pushed by %s but is blocked"%who)
		return false
	play_push_sound()
	on_pushed(who)
	return true
	
func reset_push():
	dbgmsg("push reset")
	pushdir=NONE
	push_effort=0

func on_moved(_from,_to):
	.on_moved(_from,_to)
	if !can_move: return
	if last_pushdir!=NONE:
		if one_step_on_push:
			last_pushdir=NONE
			is_running=false
		else:	
			pushdir=last_pushdir
			on_pushed(self)
	
func on_moving(from:Vector2,to:Vector2):
	if global_position.distance_to(to)<(cell_size-2):
		if lvl.has_actor_at(from,self):
			var _done=lvl.remove_object_at(from,self) # remove self blocking old cell
			if !_done: printerr("Cannot remove %s from game map at %s\n%s" % [name, from, GameFuncs.dump(lvl.objects)])
	return true

func on_move(from,to)->bool:
	var move_ok=.on_move(from,to)
	if move_ok:play_move_anim(current_dir)
	if last_pushdir!=NONE and !walk_on_push: is_running=true
	return move_ok
	
func on_pushed(by):
	dbgmsg("was pushed by %s !"%by.name)
	if walk_on_push: speeddown()
	goto(position,pushdir)
	last_pushdir=pushdir
	reset_push()

func play_push_sound():
	if audio_player:
		audio_player.play()


func play_move_anim(dir:Vector2):
	if !_animator: 
		dbgmsg("should play move anim for %s but has no animator !"%dir)
		return
	match dir:
		Vector2.RIGHT:
			_animator.trigger_anim("GoingRight")
		Vector2.UP:
			_animator.trigger_anim("GoingUp")
		Vector2.DOWN:
			_animator.trigger_anim("GoingDown")
		Vector2.LEFT:
			_animator.trigger_anim("GoingLeft")
		_:
			printerr("Cannot manage dir {}".format([current_dir],"{}"))

func is_actor(actor:int=-1):
	return ( .is_actor(actor) or GameEnums.ACTORS.ANY_RUNNER==actor )

func behaviors()->Array:
	var bhvs=.behaviors()
	bhvs.erase(GameEnums.BEHAVIORS.HIT)
	bhvs.append(GameEnums.BEHAVIORS.PUSH)
	return bhvs
