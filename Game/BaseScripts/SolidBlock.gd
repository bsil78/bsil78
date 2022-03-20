extends "res://Game/BaseScripts/Block.gd"

func is_block(block:int=-1)->bool:
	return .is_block(block) or GameEnums.BLOCKS.ANY_SOLID_BLOCK==block

func behaviors()->Array:
	var bhvs:=.behaviors().duplicate(true)
	bhvs.erase(GameEnums.BEHAVIORS.CAN_BE_DESTROYED)
	return bhvs
