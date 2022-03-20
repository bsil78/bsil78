extends "res://Game/BaseScripts/RunningActor.gd"

func _ready():
	if _animator.is_processing():start()
	
func start():
	var t:=_animator.get_transition_from_to("start","Idle%s" % initial_dir) as AnimationNodeStateMachineTransition
	t.auto_advance=true
	_animator.restart()
	
func fliph(_flip):
	pass
	
func flipv(_flip):
	pass
	
func idle():
	_animator.trigger_anim("Idle%s" % GameEnums.DIRS_MAP[last_pushdir],false)
	.idle()
