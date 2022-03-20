extends "res://Game/BaseScripts/RunningActor.gd"


func _ready():
	get_parent().connect("ready",self,"start_anim")
	
func start_anim():
	_animator.trigger_anim("Idle%s" % initial_dir)
	
func idle():
	_animator.trigger_anim("Idle%s" % GameEnums.DIRS_MAP[last_pushdir])
	.idle()

