extends "res://Game/BaseScripts/BreakableBlock.gd"

export(bool) var is_good:=true
export(int) var damaged_frame:int
export(NodePath) var sprite_node
var sprite:Sprite

enum { GOOD=1, BAD=0 }

var godsign_items:={
	GOOD:preload("res://Game/Items/GodSignGood.tscn"),
	BAD:preload("res://Game/Items/GodSignBad.tscn")
}

func _ready():
	sprite=get_node(sprite_node) as Sprite
	assert(sprite!=null)

func hit(from,amount:int=1):
	if GameFuncs.is_actor(from,[GameEnums.ACTORS.ANY_PLAYER]):
		.hit(from,amount)
		if !alive:
			var item:=BAD
			if is_good: item=GOOD
			var item_node=GameFuncs.spawn(global_position,godsign_items[item],GameData.world.level.items_node())	
			GameData.world.level.add_object(item_node)
			remove_from_world()
			if is_good:
				GameData.world.update_indicators()
	
func is_block(block:int=-1)->bool:
	return ( .is_block(block) 
			or GameEnums.BLOCKS.ANY_GOD_SIGN_BLOCK==block
			or (is_good and GameEnums.BLOCKS.GOD_SIGN_BLOCK_GOOD==block)
			or (!is_good and GameEnums.BLOCKS.GOD_SIGN_BLOCK_BAD==block)
			)

func show_broken_block():
	sprite.frame=damaged_frame
