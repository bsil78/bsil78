extends "res://Game/BaseScripts/Actor.gd"

var thinking:=false
var think_dir:=NONE
var attack:=false
var pause_attack:=false

export(AudioStream) var sproutch:AudioStream
export(int) var ATTACK_POWER:=20

const hitEffect:=preload("res://Game/Effects/EnemyHitGreenBlood.tscn")
const explodeEffect:=preload("res://Game/Effects/EnemyExploding.tscn")
const Actor:=preload("res://Game/BaseScripts/Actor.gd")

func _ready():
	$UI/LifeBar.max_value=max_life_points
	$UI/LifeBar.value=life_points
	$UI/LifeBar.visible=false
	
func _process(_delta):
	if !Thing.freezed and is_alive():
		manage_sound_volume()
		if thinking: return
		if think_dir!=NONE:
			goto(think_dir)
		else:
			if next_dir!=NONE and Utils.chance(90):return
			if current_dir!=NONE and Utils.chance(90):  return
			if Utils.chance(50):think_of_dir()
			
func idle():
	if is_alive():
		.idle()
		_animator.trigger_anim("idle")
		
func on_move(from,to):
	.on_move(from,to)
	_animator.trigger_anim("walk")

func hit(from:Node2D,amount:int=1):
	if .hit(from,amount):
		print("hit by %s" % from.name)
		_animator.trigger_anim("hit",false,true)
		Utils.play_effect_once(hitEffect,$FrontEffects,global_position)
		$UI/LifeBar.value=life_points
		$UI/LifeBar.visible=true
		Utils.timer(0.5).connect("timeout",$UI/LifeBar,"hide")
		if from and from.is_actor(GameEnums.ACTORS.ANY_PLAYER):
			var player_dir=(from.global_position-global_position).normalized()
			if not player_dir in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
				if Utils.chance(50):
					player_dir.x=0
				else:
					player_dir.y=0
			if life_points>(max_life_points/3):
				set_attack(true)
				think_dir=player_dir
				Utils.timer(2).connect("timeout",self,"set_attack",[false])
			else:
				set_attack(false)
				think_dir=-1*player_dir
				
func killed():
	if is_alive():
		Thing.dead()
		_animator.trigger_anim("killed",false,true)
	
func explode():
	Utils.play_sound($Voice as AudioStreamPlayer2D,sproutch,20)
	Utils.play_effect_once(explodeEffect,get_parent(),global_position)
			


func is_actor(actor:int=-1)->bool:
	return ( .is_actor(actor) 
			or GameEnums.ACTORS.ANY_ENEMY==actor )

	
func manage_sound_volume():
	if GameData.current_player and GameData.current_player.is_inside_tree():
		var player_pos:Vector2=GameData.current_player.global_position
		$SoundRayCast.cast_to=(player_pos-global_position)
		var volume_db=-1*global_position.distance_to(player_pos)/10
		var collider=$SoundRayCast.get_collider()
		if collider and collider.name!="PlayerBody":volume_db*=2
		$Steps.volume_db=volume_db-10
		$Voice.volume_db=volume_db
	else:
		$Steps.volume_db=-60
		$Voice.volume_db=-60

func on_wall_collision(_wall_pos:Vector2,_collider:Node2D)->bool:
	think_dir=NONE
	return true

func on_collision(others:Dictionary)->bool:
	if others.empty():
		if debug: debug.error("{} colliding with nothing !",[name])
		return true
	
	var actor:= others.get(GameEnums.OBJECT_TYPE.ACTOR) as Actor
	var item:=	others.get(GameEnums.OBJECT_TYPE.ITEM) as Node2D
	var block:=	others.get(GameEnums.OBJECT_TYPE.BLOCK) as Node2D
	
	if actor:
		if actor.is_actor(GameEnums.ACTORS.ANY_PLAYER):
			if !pause_attack and (actor as Node2D).global_position.distance_to(global_position)<40:
				_animator.trigger_anim("attack")
				actor.hit(self,ATTACK_POWER)
				set_attack(true)
				pause_attack=true
				Utils.timer(1.0).connect("timeout",self,"set_pause_attack",[false])
			think_dir=next_dir
			return true
	if item:
		return false
	think_dir=NONE
	return true	

func set_pause_attack(value:bool):
	pause_attack=value	
		
func set_attack(value:bool):
	attack=value
	if attack:
		speedup()
	else:
		speeddown()
	
func think_of_dir():
	thinking=true
	#$ObjectDebug.message="Yielding thinking"
	yield(Utils.timer(0.1),"timeout")
	var all_dirs_and_idle=[Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN,Vector2.ZERO]
	think_dir=Utils.choose(all_dirs_and_idle)
	#$ObjectDebug.message="Choosed %s" % think_dir
	thinking=false


