extends "res://Game/BaseScripts/Block.gd"


export(bool) var horizontal:=false

export(PackedScene) var effect
var effect_as_node:Node2D


const MARGE:=8
var bats={}

func _ready():
	update_visual()
	effect_as_node=effect.instance()
	var nbbats=2+randi()%3
	bats={}
	for _b in range(0,nbbats):
		var dir=Vector2(-1+randf()*2,-1+randf()*2)
		var bat=$BatPrototype.duplicate()
		bats[bat]=dir
		bat.flip_h=dir.x<0
		bat.position=Vector2(randi()%17-8,randi()%17-8)
		$BatsPlaceHolder.add_child(bat)
		bat.show()
	Utils.timer(0.2).connect("timeout",self,"deal_with_position")

func update_bats():
	for bat in bats:
		var dir=bats[bat]
		var new_pos=bat.position+dir
		if new_pos.x<-8 or new_pos.x>8:
			new_pos.x=clamp(new_pos.x,-8,+8)
			dir=dir*Vector2(-1,1)
		if new_pos.y<-8 or new_pos.y>8:
			new_pos.y=clamp(new_pos.y,-8,+8)
			dir=dir*Vector2(1,-1)
		bats[bat]=dir
		bat.flip_h=dir.x<0
		bat.position=new_pos	

		
func step_on(who:Node2D)->bool:
	if !is_allowed_to_stepon(who): return false
	var stepon_ok:=false
	if horizontal:
		stepon_ok=who.position.x<(position.x-MARGE) or who.position.x>(position.x+MARGE)
	else:
		stepon_ok=who.position.y<(position.y-MARGE) or who.position.y>(position.y+MARGE)
	if stepon_ok:disappear()
	return stepon_ok

func is_allowed_to_stepon(who:Node2D)->bool:
	return GameFuncs.is_actor(who,[GameEnums.ACTORS.ANY_PLAYER,
								   GameEnums.ACTORS.CRUSHER_BLOCK,
								   GameEnums.ACTORS.BOMB])

func disappear():
	Utils.play_effect_once(effect_as_node,GameData.world.effects_node(),global_position)
	Utils.play_sound($BatsSound)
	remove_from_world()

func is_block(block:int=-1)->bool:
	return ( .is_block(block)
			or GameEnums.BLOCKS.FORCE_FIELD==block )

func behaviors()->Array:
	var bhvs:=.behaviors().duplicate(true)
	bhvs.append(GameEnums.BEHAVIORS.STEP_ON)
	bhvs.append(GameEnums.BEHAVIORS.HIT)
	return bhvs

func destroy(from:Node2D,remove_instantly:bool=false)->bool:
	if .destroy(from,remove_instantly):
		if !remove_instantly:disappear()
		return true
	else:
		return false
		

func update_visual():
	$BlockFace.material.set_shader_param("horizontal", horizontal)
	if 	horizontal:
		$Background.rotation_degrees=90
		$Arrows.rotation_degrees=90
	else:
		$Background.rotation_degrees=0
		$Arrows.rotation_degrees=0


func deal_with_position() -> void:
	$CanvasLayer/BatsSmokingFog.global_position=global_position
