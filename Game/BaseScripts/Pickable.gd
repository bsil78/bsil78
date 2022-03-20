extends "res://Game/BaseScripts/Item.gd"

func behaviors()->Array:
	var bhvs:=.behaviors().duplicate(true)
	bhvs.append(GameEnums.BEHAVIORS.PICKUP)
	return bhvs
	
func pickup(who:Node2D)->bool:
	return who.is_actor(GameEnums.ACTORS.ANY_PLAYER)

func is_item(item:int=-1)->bool:
	return item==-1
