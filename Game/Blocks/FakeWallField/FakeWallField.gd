extends "res://Game/BaseScripts/SolidBlock.gd"

export(int) var WALL_FRAME_ID:=6
var current_distord_sound=null
var activator=null

func _ready() -> void:
	$SoundWhenPlayerInto.autoplay=false
	$SoundWhenPlayerInto.stop()
	$Wall.frame=WALL_FRAME_ID
	$Wall.material=$Wall.material.duplicate()
	$Wall.material.set_shader_param("OFFSET",rand_range(0.0,50))
	$Wall.material.set_shader_param("SCALEI",rand_range(21.0,53))
	$Wall.material.set_shader_param("FLASH_OFFSET",rand_range(0.0,500.0))
	GameFuncs.connect("players_switched",self,"manage_volume")
	Utils.timer(0.2).connect("timeout",self,"deal_with_position")

func step_on(who:Node2D)->bool:
	return who.is_actor(GameEnums.ACTORS.ANY_PLAYER)
	

func is_block(block:int=-1)->bool:
	return ( .is_block(block)
			or block in [GameEnums.BLOCKS.FORCE_FIELD,GameEnums.BLOCKS.FAKE_WALL] )

func behaviors()->Array:
	var bhvs:=.behaviors().duplicate(true)
	bhvs.append(GameEnums.BEHAVIORS.STEP_ON)
	return bhvs


func _on_Area2D_body_entered(body: Node) -> void:
	dbgmsg("detected entry of %s"%body.name)
	if !body.is_actor(GameEnums.ACTORS.ANY_PLAYER):return
	activator=body as Node2D
	activator.torch_should_be_visible=false
	stop_distord_sound()
	current_distord_sound=Utils.play_sound($SoundWhenPlayerInto)

func _on_Area2D_body_exited(body: Node) -> void:
	dbgmsg("detected exit of %s"%body.name)
	if !body.is_actor(GameEnums.ACTORS.ANY_PLAYER):return
	activator.torch_should_be_visible=true
	activator=null
	stop_distord_sound()

func stop_distord_sound():
	if !current_distord_sound:return
	var tween_vol:Tween=Tween.new()
	tween_vol.interpolate_property(current_distord_sound,"volume_db",current_distord_sound.volume_db,-60.0,1.0,Tween.EASE_IN,Tween.EASE_IN_OUT)
	tween_vol.connect("tween_all_completed",self,"destroy_distord_sound",[current_distord_sound])
	current_distord_sound.add_child(tween_vol)
	tween_vol.start()
	current_distord_sound=null
	
func destroy_distord_sound(sound):
	dbgmsg("destroying sound %s of vol %s"%[sound.name,sound.volume_db])
	sound.stop()

func manage_volume():
	dbgmsg("manage volume on player switch")
	if !current_distord_sound:return
	if GameData.current_player!=activator:
		current_distord_sound.volume_db=-30
		dbgmsg("lowered sound vol for %s")
	else:
		current_distord_sound.volume_db=0
		dbgmsg("raised sound vol for %s")
		
func deal_with_position() -> void:
	$CanvasLayer/DarknessSmokingFog.global_position=global_position
		
