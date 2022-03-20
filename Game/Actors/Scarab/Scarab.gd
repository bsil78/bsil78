extends "res://Game/BaseScripts/RunningActor.gd"

func fliph(_flip):
	pass
	
func flipv(_flip):
	pass
	
func idle():
	_animator.trigger_anim("Idle%s" % GameEnums.DIRS_MAP[pushdir])
	.idle()
