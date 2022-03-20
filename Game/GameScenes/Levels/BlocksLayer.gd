extends "res://Game/GameScenes/Levels/GameObjectsReifier.gd"

const exit:PackedScene=preload("res://Game/Blocks/Exit/Exit.tscn")
const force_field:PackedScene=preload("res://Game/Blocks/ForceField/ForceField.tscn")
const fake_wall:PackedScene=preload("res://Game/Blocks/FakeWallField/FakeWallField.tscn")
const good_gs:PackedScene=preload("res://Game/Blocks/BreakableBlocks/GodSignBlockGood.tscn")
const bad_gs:PackedScene=preload("res://Game/Blocks/BreakableBlocks/GodSignBlockBad.tscn")
const green:PackedScene=preload("res://Game/Blocks/ExplodableBlocks/ExplodableBlockGreen.tscn")
const red:PackedScene=preload("res://Game/Blocks/ExplodableBlocks/ExplodableBlockRed.tscn")
const purple:PackedScene=preload("res://Game/Blocks/ExplodableBlocks/ExplodableBlockPurple.tscn")
const blue:PackedScene=preload("res://Game/Blocks/ExplodableBlocks/ExplodableBlockBlue.tscn")
const blank:PackedScene=preload("res://Game/Blocks/ExplodableBlocks/ExplodableBlockBlank.tscn")
const teleporter:PackedScene=preload("res://Game/Blocks/Teleporter/Teleporter.tscn")
const breakable:PackedScene=preload("res://Game/Blocks/BreakableBlocks/BreakableWall.tscn")

func _ready()->void:
	var dic:={
		GameEnums.BLOCKS.EXIT:"Exit",
		GameEnums.BLOCKS.FORCE_FIELD:"ForceField(.*)",
		GameEnums.BLOCKS.FAKE_WALL:"FakeWall",
		GameEnums.BLOCKS.GOD_SIGN_BLOCK_GOOD:"Good_GodSign",
		GameEnums.BLOCKS.GOD_SIGN_BLOCK_BAD:"Bad_GodSign",
		GameEnums.BLOCKS.ANY_EXPLODABLE:"Explodable_([^_]*)_?[A-Z]*",
		GameEnums.BLOCKS.TELEPORTER:"Teleporter",
		GameEnums.BLOCKS.BREAKABLE_WALL:"BreakableWall"
	}
	instantiate_objects(dic,get_parent().size)
	


func instantiate_object(id:int,args:Array,grid_pos:Vector2)->Node2D:
	var node:Node2D=null
	match id:
		GameEnums.BLOCKS.EXIT:
			node=exit.instance(1)
		GameEnums.BLOCKS.BREAKABLE_WALL:
			node=breakable.instance(1)
		GameEnums.BLOCKS.TELEPORTER:
			node=teleporter.instance(1)
		GameEnums.BLOCKS.FORCE_FIELD:
			node=force_field.instance(1)
			node.horizontal= (args[0]=="Horizontal")
		GameEnums.BLOCKS.FAKE_WALL:
			node=fake_wall.instance(1)
		GameEnums.BLOCKS.GOD_SIGN_BLOCK_GOOD:
			node=good_gs.instance(1)
		GameEnums.BLOCKS.GOD_SIGN_BLOCK_BAD:
			node=bad_gs.instance(1)
		GameEnums.BLOCKS.ANY_EXPLODABLE:
			match args[0]:
				"Blank":node=blank.instance(1)
				"Green":node=green.instance(1)
				"Red":node=red.instance(1)
				"Purple":node=purple.instance(1)
				"Blue":node=blue.instance(1)
	if !node:
		print_debug("Unknown id %s or args %s"%[id,args])
	return node
