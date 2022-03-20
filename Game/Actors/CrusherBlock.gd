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
	
