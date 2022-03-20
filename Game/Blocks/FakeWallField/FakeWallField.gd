extends "res://Game/BaseScripts/Block.gd"

export(int) var WALL_FRAME_ID:=6

func _ready() -> void:
	$Wall.frame=WALL_FRAME_ID
	$Wall.material=$Wall.material.duplicate()
	$Wall.material.set_shader_param("OFFSET",rand_range(0.0,50))
	$Wall.material.set_shader_param("SCALEI",rand_range(21.0,53))
	$Wall.material.set_shader_param("FLASH_OFFSET",rand_range(0.0,500.0))

func step_on(who:Node2D)->bool:
	return who.is_actor(GameEnums.ACTORS.ANY_PLAYER)
	

func is_block(block:int=-1)->bool:
	return ( .is_block(block)
			or block in [GameEnums.BLOCKS.FORCE_FIELD,GameEnums.BLOCKS.FAKE_WALL] )

func capabilities()->Array:
	var capas=.capabilities()
	capas.append(GameEnums.CAPABILITIES.STEP_ON)
	return capas
