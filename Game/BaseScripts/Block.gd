extends "res://Game/BaseScripts/Thing.gd"

func is_block(block:int=-1)->bool:
	return block==-1

func type_id()->int:
	var types:Dictionary = GameEnums.BLOCKS.duplicate(true)
	types.erase(GameEnums.BLOCKS.ANY_BREAKABLE)
	types.erase(GameEnums.BLOCKS.ANY_EXPLODABLE)
	types.erase(GameEnums.BLOCKS.ANY_GOD_SIGN_BLOCK)
	for type in types:
		if is_item(type): return type
	return -1 
