extends "res://Game/BaseScripts/Block.gd"


export(PackedScene) var hitEffect
export(PackedScene) var explodingEffect

var hitEffect_as_node
var explodingEffect_as_node

export(int) var max_hit_points:=50
export(int) var broken_limit:=25
export(int) var hit_points:=max_hit_points

func _ready():
	if hitEffect:hitEffect_as_node=hitEffect.instance()
	if explodingEffect:explodingEffect_as_node=explodingEffect.instance()


func can_be_hit_by(from:Node2D)->bool:
	return .can_be_hit_by(from) or from.is_actor(GameEnums.ACTORS.ANY_PLAYER)

func hit(from:Node2D,amount:int)->bool:
	if .hit(from,amount):
# warning-ignore:narrowing_conversion
		hit_points=max(0,hit_points-amount)
		if hit_points<=0:
			dead()
			play_exploding_effect()
		else:
			if hit_points<=broken_limit:show_broken_block()
			play_hit_effect()
		return true
	return false

func play_hit_effect():
	if explodingEffect_as_node: 	Utils.play_effect_once(explodingEffect_as_node,GameData.world.effects_node(),global_position)

func play_exploding_effect():
	if hitEffect_as_node:
		Utils.play_effect_once(hitEffect_as_node,GameData.world.effects_node(),global_position)

func is_block(block:int=-1)->bool:
	return ( .is_block(block) 
			 or GameEnums.BLOCKS.ANY_BREAKABLE==block )

func show_broken_block():
	pass

func behaviors()->Array:
	var bhvs:=.behaviors().duplicate(true)
	bhvs.append(GameEnums.BEHAVIORS.HIT)
	return bhvs
