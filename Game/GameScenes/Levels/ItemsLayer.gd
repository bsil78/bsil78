extends "res://Game/GameScenes/Levels/GameObjectsReifier.gd"


const ankh:PackedScene=preload("res://Game/Items/Ankh.tscn")
const food:PackedScene=preload("res://Game/Items/Food.tscn")
const bad_gs:PackedScene=preload("res://Game/Items/GodSignBad.tscn")
const good_gs:PackedScene=preload("res://Game/Items/GodSignGood.tscn")
const jar:PackedScene=preload("res://Game/Items/Jar.tscn")
const map:PackedScene=preload("res://Game/Items/Map.tscn")
const torch:PackedScene=preload("res://Game/Items/Torch.tscn")

func _ready()->void:
	var dic:={
		GameEnums.ITEMS.ANKH:"Ankh",
		GameEnums.ITEMS.FOOD:"Food",
		GameEnums.ITEMS.GOD_SIGN_BAD:"GodSignBad",
		GameEnums.ITEMS.GOD_SIGN_GOOD:"GodSignGood",
		GameEnums.ITEMS.JAR:"Jar",
		GameEnums.ITEMS.MAP:"Map",
		GameEnums.ITEMS.TORCH:"Torch"
	}
	instantiate_objects(dic,get_parent().size)

func instantiate_object(id:int,args:Array,_grid_pos:Vector2)->Node2D:
	var node:Node2D=null
	match id:
		GameEnums.ITEMS.ANKH:
			node=ankh.instance(1)
		GameEnums.ITEMS.FOOD:
			node=food.instance(1)
		GameEnums.ITEMS.GOD_SIGN_BAD:
			node=bad_gs.instance(1)
		GameEnums.ITEMS.GOD_SIGN_GOOD:
			node=good_gs.instance(1)
		GameEnums.ITEMS.JAR:
			node=jar.instance(1)
		GameEnums.ITEMS.MAP:
			node=map.instance(1)
		GameEnums.ITEMS.TORCH:
			node=torch.instance(1)
	if !node:
		print_debug("Unknown id %s or args %s"%[id,args])
	return node
