extends "res://Game/BaseScripts/SelfRunningActor.gd"

func fliph(_flip):
	pass
	
func flipv(_flip):
	pass

func idle():
	.play_move_anim(fixed_dir,false)
	.idle()

func push_from_front(who:Node2D)->bool:
	if who.is_actor(GameEnums.ACTORS.ANY_PLAYER): who.hit(self,5)
	return false	
	
func collide_actor(actor:Node2D)->bool:
	if GameFuncs.is_actor(actor,[GameEnums.ACTORS.ANY_PLAYER,
								 GameEnums.ACTORS.ANY_ENEMY,
								 GameEnums.ACTORS.BOMB]):
		if current_dir==fixed_dir or actor.current_dir in [fixed_dir,-1*fixed_dir]:
			print("hit %s"%actor.name)
			actor.hit(self,9999)
			if actor.is_actor(GameEnums.ACTORS.BOMB):
				explode()
				return true
			else:
				return false
	if actor.is_actor(GameEnums.ACTORS.CRUSHER_BLOCK):
		if current_dir==fixed_dir or actor.current_dir in [fixed_dir,-1*fixed_dir]:
			print("hit %s"%actor.name)
			Utils.timer(0.5).connect("timeout",self,"explode")
			return false		
	return .collide_actor(actor)

func explode():
	life_points=0
	Utils.play_effect_once($Explode,GameData.world.effects_node(),global_position)
	yield(Utils.timer(0.5),"timeout")
	remove_from_world()

func collide_block(block:Node2D)->bool:
	if GameFuncs.is_block(block,[GameEnums.BLOCKS.FORCE_FIELD]):
		if GameEnums.CAPABILITIES.STEP_ON in block.capabilities():
			return !block.step_on(self)
	return .collide_block(block)


