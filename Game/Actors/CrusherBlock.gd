extends "res://Game/BaseScripts/SelfRunningActor.gd"

func fliph(_flip):
	pass
	
func flipv(_flip):
	pass

func idle():
	.play_move_anim(fixed_dir,false)
	.idle()

func push_from_front()->bool:
	var player:=GameFuncs.matching_level_object("Player*",next_pos(fixed_dir))
	if player: 
		player.hit(self,5)
	return false	
	
