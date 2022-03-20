extends "res://Game/GameScenes/Levels/GameObjectsReifier.gd"

const exit:PackedScene=preload("res://Game/Blocks/Exit/Exit.tscn")
const force_field:PackedScene=preload("res://Game/Blocks/ForceField/ForceField.tscn")
const fake_wall:PackedScene=preload("res://Game/Blocks/FakeWallField/FakeWallField.tscn")
const good_gs:PackedScene=preload("res://Game/Blocks/GodSignBlocks/GodSignBlockGood.tscn")
const bad_gs:PackedScene=preload("res://Game/Blocks/GodSignBlocks/GodSignBlockBad.tscn")
const green:PackedScene=preload("res://Game/Blocks/ExplodableBlocks/ExplodableBlockGreen.tscn")
const red:PackedScene=preload("res://Game/Blocks/ExplodableBlocks/ExplodableBlockRed.tscn")
const purple:PackedScene=preload("res://Game/Blocks/ExplodableBlocks/ExplodableBlockPurple.tscn")
const blue:PackedScene=preload("res://Game/Blocks/ExplodableBlocks/ExplodableBlockBlue.tscn")


func _ready()->void:
	var dic:={
		GameEnums.BLOCKS.EXIT:"Exit",
		GameEnums.BLOCKS.FORCE_FIELD:"ForceField(.*)",
		GameEnums.BLOCKS.FAKE_WALL:"FakeWall",
		GameEnums.BLOCKS.GOD_SIGN_BLOCK_GOOD:"Good_GodSign",
		GameEnums.BLOCKS.GOD_SIGN_BLOCK_BAD:"Bad_GodSign",
		GameEnums.BLOCKS.ANY_EXPLODABLE:"Explodable_([^_]*)_?[A-Z]*",
	}
	instantiate_objects(dic,get_parent().size)


func instantiate_object(id:int,args:Array,grid_pos:Vector2)->Node2D:
	var node:Node2D=null
	match id:
		GameEnums.BLOCKS.EXIT:
			node=exit.instance(1)
			if has_property("params",tilemap()):
				for anExit in tilemap_params(GameEnums.BLOCKS.EXIT):
					if anExit[0]==grid_pos: 
						node.needed_god_signs=anExit[1]
						node.name=anExit[2]
			var level=find_parent("Level*")
			if level:
				level.connect_exit(node)
			else:
				print_debug("Cannot find parent level node...")
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
				"Green":node=green.instance(1)
				"Red":node=red.instance(1)
				"Purple":node=purple.instance(1)
				"Blue":node=blue.instance(1)
	if !node:
		print_debug("Unknown id %s or args %s"%[id,args])
	return node
