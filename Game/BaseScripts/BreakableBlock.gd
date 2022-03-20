extends "res://Game/BaseScripts/Block.gd"


export(PackedScene) var hitEffect
export(PackedScene) var explodingEffect

var hitEffect_as_node
var explodingEffect_as_node

export(int) var max_hit_points:=50
export(int) var broken_limit:=25
export(int) var hit_points:=max_hit_points

func _ready():
	hitEffect_as_node=hitEffect.instance()
	explodingEffect_as_node=explodingEffect.instance()

func hit(from:Node2D,amount:int)->bool:
	if alive and hit_points>0:
		hit_points=max(0,hit_points-amount)
		if hit_points<=0:
			alive=false
			play_exploding_effect()
		else:
			if hit_points<=broken_limit:show_broken_block()
			play_hit_effect()
		return true
	return false

func play_hit_effect():
	Utils.play_effect_once(explodingEffect_as_node,GameData.world.effects_node(),global_position)

func play_exploding_effect():
	Utils.play_effect_once(hitEffect_as_node,GameData.world.effects_node(),global_position)

func is_block(block:int=-1)->bool:
	return ( .is_block(block) 
			 or GameEnums.BLOCKS.ANY_BREAKABLE==block )

func show_broken_block():
	pass

func capabilities():
	var capas=.capabilities()
	capas.append(GameEnums.CAPABILITIES.HIT)
	return capas
