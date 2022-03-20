extends "res://Game/GameScenes/Levels/GameObjectsReifier.gd"

const mummy:PackedScene=preload("res://Game/Actors/Mummy/Mummy.tscn")
const bomb:PackedScene=preload("res://Game/Actors/Runners/Bomb/BombGoldenScarab.tscn")
const crusher:PackedScene=preload("res://Game/Actors/Runners/Crusher/CrusherBlock.tscn")
const mobile_wall:PackedScene=preload("res://Game/Actors/Runners/MobileWall/MobileWall.tscn")
const scarab:PackedScene=preload("res://Game/Actors/Runners/Scarab/Scarab.tscn")

func _ready()->void:
	var dic:={
		GameEnums.ACTORS.MUMMY:"Mummy",
		GameEnums.ACTORS.BOMB:"Bomb_(.*)",
		GameEnums.ACTORS.CRUSHER_BLOCK:"CrusherBlock_(.*)",
		GameEnums.ACTORS.MOBILE_WALL:"MobileWall",
		GameEnums.ACTORS.SCARAB:"Scarab_(.*)"
	}
	instantiate_objects(dic,get_parent().size)

func instantiate_object(id:int,args:Array,_grid_pos:Vector2)->Node2D:
	var node:Node2D=null
	match id:
		GameEnums.ACTORS.MUMMY:
			node=mummy.instance(1)
		GameEnums.ACTORS.BOMB:
			node=bomb.instance(1)
			node.initial_dir=args[0]
		GameEnums.ACTORS.CRUSHER_BLOCK:
			node=crusher.instance(1)
			node.initial_dir=args[0]
		GameEnums.ACTORS.MOBILE_WALL:
			node=mobile_wall.instance(1)
		GameEnums.ACTORS.SCARAB:
			node=scarab.instance(1)
			node.initial_dir=args[0]
	if !node:
		print_debug("Unknown id %s or args %s"%[id,args])
	return node
