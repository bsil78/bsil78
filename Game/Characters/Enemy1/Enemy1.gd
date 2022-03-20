extends "res://Game/BaseScripts/Actor.gd"

var thinking:=false
var think_dir:=NONE
var attack:bool=true

export(AudioStream) var sproutch:AudioStream

const hitEffect:=preload("res://Game/Effects/EnemyHitGreenBlood.tscn")
const explodeEffect:=preload("res://Game/Effects/EnemyExploding.tscn")
const Actor:=preload("res://Game/BaseScripts/Actor.gd")

func _ready():
	$UI/LifeBar.max_value=max_life_points
	$UI/LifeBar.value=life_points
	$UI/LifeBar.visible=false
	

func hit(from:Node2D,amount:int=1):
	if life_points>0:
		_animator.trigger_anim("hit")
		Utils.play_effect_once(hitEffect,$FrontEffects)
		life_points=max(life_points-amount,0)
		$UI/LifeBar.value=life_points
		$UI/LifeBar.visible=true
		yield(Utils.timer(0.5),"timeout")
		$UI/LifeBar.visible=false
		if from and from.name.matchn("Player*"):
			if life_points>(max_life_points/3):
				speedup()
				var player_dir=(from.global_position-global_position).normalized()
				if not player_dir in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
					if Utils.chance(50):
						player_dir.x=0
					else:
						player_dir.y=0
				think_dir=player_dir
		
func killed():
	_animator.trigger_anim("killed")
	alive=false

	
func explode():
	Utils.play_sound($Voice as AudioStreamPlayer2D,sproutch,20)
	Utils.play_effect_once(explodeEffect,$FrontEffects)
			
func _process(_delta):
	manage_sound_volume()
	if thinking: return
	if think_dir!=NONE:
		goto(think_dir)
	else:
		if next_dir!=NONE and Utils.chance(90):return
		if current_dir!=NONE and Utils.chance(90):  return
		if Utils.chance(50):think_of_dir()
	
func manage_sound_volume():
	if GameData.current_player and global_position:
		var player_pos:Vector2=GameData.current_player.global_position
		$SoundRayCast.cast_to=(player_pos-global_position)
		var volume_db=-1*global_position.distance_to(player_pos)/10
		var collider=$SoundRayCast.get_collider()
		if collider and collider.name!="PlayerBody":
				volume_db*=2
		$Steps.volume_db=volume_db-10
		$Voice.volume_db=volume_db

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
		if actor.name.matchn("Player*"):
			if attack and (actor as Node2D).global_position.distance_to(global_position)<40:
				_animator.trigger_anim("attack")
				actor.hit(self,20)
				speeddown()
				set_attack(false)
				Utils.timer(1.0).connect("timeout",self,"set_attack",[true])
			think_dir=next_dir
			return true
	if item:
		return false
	if block:
		return true
	return true	
	
		
func set_attack(value:bool):
	attack=value
	
func think_of_dir():
	thinking=true
	yield(Utils.timer(0.1),"timeout")
	var all_dirs_and_idle=[Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN,Vector2.ZERO]
	think_dir=Utils.choose(all_dirs_and_idle)
	#$ObjectDebug.message="new dir :\n{nd}".format({"nd":new_dir})
	
	thinking=false
	#$ObjectDebug.message=""


