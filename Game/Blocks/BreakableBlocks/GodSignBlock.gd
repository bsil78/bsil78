extends "res://Game/BaseScripts/BreakableBlock.gd"

export(bool) var is_good:=true

enum { GOOD=1, BAD=0 }

var godsign_items:={
	GOOD:preload("res://Game/Items/GodSignGood.tscn"),
	BAD:preload("res://Game/Items/GodSignBad.tscn")
}


func hit(from,amount:int=1)->bool:
	if GameFuncs.is_actor(from,[GameEnums.ACTORS.ANY_PLAYER]):
		.hit(from,amount)
		if !alive:reveal_token()
		return true
	return false

func destroy(from:Node2D,_remove_instantly:bool=true)->bool:
	if .destroy(from,false):
		reveal_token()
		return true
	else:
		return false
	

func reveal_token():
	var item:=BAD
	if is_good: item=GOOD
	var item_node=GameFuncs.spawn(global_position,godsign_items[item],GameData.world.level.items_node())	
	GameData.world.level.add_object(item_node)
	remove_from_world()
	if is_good:GameData.world.update_indicators()	

func is_block(block:int=-1)->bool:
	return ( .is_block(block) 
			or GameEnums.BLOCKS.ANY_GOD_SIGN_BLOCK==block
			or (is_good and GameEnums.BLOCKS.GOD_SIGN_BLOCK_GOOD==block)
			or (!is_good and GameEnums.BLOCKS.GOD_SIGN_BLOCK_BAD==block)
			)

func behaviors()->Array:
	var bhvs:=.behaviors().duplicate(true)
	bhvs.append(GameEnums.BEHAVIORS.CAN_BE_DESTROYED)
	return bhvs
