extends "res://Game/BaseScripts/SelfRunningActor.gd"

onready var explosion:= preload("res://Game/Effects/BlockExploding.tscn").instance()

func idle():
	.play_move_anim(fixed_dir)
	.idle()

func push_from_front(who:Node2D)->bool:
	if who.is_actor(GameEnums.ACTORS.ANY_PLAYER): who.hit(self,5)
	return false	
	
func collide_actor(actor:Node2D)->bool:
	dbgmsg("CD : %s, fixed_dir : %s; alive : %s"%[current_dir,fixed_dir,actor.is_alive()])
	if current_dir==fixed_dir or actor.current_dir in [fixed_dir,-1*fixed_dir]:
		if actor.can_be_hit_by(self):
			dbgmsg("hit %s"%actor.name)
			actor.hit(self,GameData.KILLER_HIT)
			return true	
	return .collide_actor(actor)

func explode():
	life_points=0
	Utils.play_effect_once(explosion,GameData.world.effects_node(),global_position)
	Utils.timer(0.5).connect("timeout",self,"cleanup")

func cleanup():
	explosion.queue_free()
	remove_from_world()

func is_actor(actor:int=-1):
	return (.is_actor(actor) or GameEnums.ACTORS.CRUSHER_BLOCK==actor)
