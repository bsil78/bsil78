extends "res://Base/Objects/TransitionZone.gd"

func do_what_this_object_does():
	GameData.currentLevel+=1
	GameData.transition_state=GameEnums.TRANSISTION_STATUS.LEVEL_UP
	.do_what_this_object_does()

