extends "res://Game/BaseScripts/Thing.gd"

func behaviors()->Array:
	var bhvs:=.behaviors().duplicate(true)
	bhvs.append(GameEnums.BEHAVIORS.STEP_ON)
	return bhvs

func step_on(_who:Node2D)->bool:
	return true

func is_item(item:int=-1)->bool:
	return item==-1

func type_id()->int:
	var types:Dictionary = GameEnums.ITEMS.duplicate(true)
	types.erase(GameEnums.ITEMS.ANY_GOD_SIGN)
	for type in types:
		if is_item(type): return type
	return -1 


func can_be_hit_by(_from)->bool:
	return true
