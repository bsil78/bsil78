extends "res://Game/BaseScripts/Block.gd"


export(PackedScene) var hitEffect:=preload("res://Game/Effects/HitBlock.tscn")
export(PackedScene) var explodingEffect:=preload("res://Game/Effects/BlockExploding.tscn")

export(int) var max_hit_points:=50
export(int) var hit_points:=max_hit_points

func hit(from:Node2D,amount:int)->bool:
	if alive and hit_points>0:
		hit_points=max(0,hit_points-amount)
		if hit_points<=0:
			alive=false
			Utils.play_effect_once(explodingEffect,get_parent(),global_position)
		else:
			Utils.play_effect_once(hitEffect,get_parent(),global_position)
			if hit_points<=max_hit_points/2:show_broken_block()
		return true
	return false

func is_block(block:int=-1)->bool:
	return ( .is_block(block) 
			 or GameEnums.BLOCKS.ANY_BREAKABLE==block )

func show_broken_block():
	pass

func capabilities():
	var capas=.capabilities()
	capas.append(GameEnums.CAPABILITIES.HIT)
	return capas
