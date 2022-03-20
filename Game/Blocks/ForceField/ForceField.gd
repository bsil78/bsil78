extends "res://Game/BaseScripts/Block.gd"


export(bool) var horizontal:=false

export(PackedScene) var effect
var effect_as_node:Node2D

const MARGE:=8

func _ready():
	update_visual()
	effect_as_node=effect.instance()
	
func step_on(who:Node2D)->bool:
	if !GameFuncs.is_actor(who,[GameEnums.ACTORS.ANY_PLAYER,GameEnums.ACTORS.CRUSHER_BLOCK]): return false
	var stepon_ok:=false
	if horizontal:
		stepon_ok=who.position.x<(position.x-MARGE) or who.position.x>(position.x+MARGE)
	else:
		stepon_ok=who.position.y<(position.y-MARGE) or who.position.y>(position.y+MARGE)
	if stepon_ok:
		Utils.play_effect_once(effect_as_node,GameData.world.effects_node(),global_position)
		remove_from_world()
	return stepon_ok

func is_block(block:int=-1)->bool:
	return ( .is_block(block)
			or GameEnums.BLOCKS.FORCE_FIELD==block )

func capabilities()->Array:
	var capas=.capabilities()
	capas.append(GameEnums.CAPABILITIES.STEP_ON)
	return capas


func update_visual():
	$BlockFace.material.set_shader_param("horizontal", horizontal)
	if 	horizontal:
		$Spider.rotation_degrees=90
		$Arrows.rotation_degrees=90
	else:
		$Spider.rotation_degrees=0
		$Arrows.rotation_degrees=0
