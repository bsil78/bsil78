extends "res://Game/BaseScripts/WeakActor.gd"

var thinking:=false
var think_dir:=NONE
var attack:=false
var can_attack:=true
var last_dir:Vector2=NONE

export(int) var ATTACK_POWER:=20

var hitEffect:=preload("res://Game/Effects/EnemyHitGreenBlood.tscn").instance()
var explodeEffect:=preload("res://Game/Effects/EnemyExploding.tscn").instance()
const CALM_DELAY_WHEN_HIT:=4
const CALM_DELAY_WHEN_AFTER_ATTACK:=2
const COOL_DOWN_ATTACK:=1

var sproutch=preload("res://Game/Assets/Audio/ogg/enemies/sproutch.ogg")
var step1=preload("res://Game/Assets/Audio/ogg/enemies/scavengers_footstep1.ogg")
var step2=preload("res://Game/Assets/Audio/ogg/enemies/scavengers_footstep2.ogg")

func _ready():
	$UI/LifeBar.max_value=max_life_points
	$UI/LifeBar.value=life_points
	$UI/LifeBar.visible=false
	
func think_update():
	if !Thing.frozen and is_alive():
		manage_sound_volume()
		if thinking: return
		if think_dir!=NONE and current_dir==NONE:
			goto(position,think_dir)
		else:
			if(target_pos==NONE):
				if next_dir!=NONE and Utils.chance(90):return
				if current_dir!=NONE and Utils.chance(90):  return
				if Utils.chance(50):think_of_dir()


func fliph(flip:bool):
	$Animation/Sprite.flip_h=flip
			
func idle():
	if is_alive():
		.idle()
		think_dir=NONE
		_animator.trigger_anim("idle")
		
func on_move(from,to)->bool:
	if .on_move(from,to):
		_animator.trigger_anim("walk")
		var step_sound=Utils.choose([step1,step2])
		Utils.play_sound($Steps,step_sound)
		return true
	else:
		think_dir=NONE
		return false

func on_moved(from,to):
	.on_moved(from,to)
	var step_sound=Utils.choose([step1,step2])
	Utils.play_sound($Steps,step_sound)

func on_moving(from,to):
	.on_moving(from,to)
	if Utils.chance(1):
		var step_sound=Utils.choose([step1,step2])
		Utils.play_sound($Steps,step_sound)
	
		
func hit(from:Node2D,amount:int=1):
	if .hit(from,amount):
		dbgmsg("hit by %s" % from.name)
		_animator.trigger_anim("hit")
		Utils.play_effect_once(hitEffect,$FrontEffects,global_position)
		$UI/LifeBar.value=life_points
		$UI/LifeBar.visible=true
		$UI/LifeBar/HideTimer.start(0.5)
		if from and from.is_actor(GameEnums.ACTORS.ANY_PLAYER):
			var player_dir=(from.global_position-global_position).normalized()
			if not player_dir in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
				if Utils.chance(50):
					player_dir.x=0
				else:
					player_dir.y=0
# warning-ignore:integer_division
			if life_points>(max_life_points/3):
				set_attack(true)
				think_dir=player_dir
				$CalmDownTimer.start(CALM_DELAY_WHEN_HIT)
			else:
				set_attack(false)
				think_dir=-1*player_dir
				
func killed():
	if is_alive():
		Thing.dead()
		_animator.trigger_anim("killed")
	
func explode():
	Utils.play_sound($Voice,sproutch,20)
	Utils.play_effect_once(explodeEffect,GameData.world.effects_node(),global_position)
			


func is_actor(actor:int=-1)->bool:
	return ( .is_actor(actor) or actor in [GameEnums.ACTORS.ANY_ENEMY,GameEnums.ACTORS.MUMMY] )

	
func manage_sound_volume():
	if GameData.current_player and GameData.current_player.is_inside_tree():
		var player_pos:Vector2=GameData.current_player.global_position
		$SoundRayCast.cast_to=(player_pos-global_position)
		var volume_db=2-1*global_position.distance_to(player_pos)/10
		var collider=$SoundRayCast.get_collider()
		if collider and (collider is TileMap or !collider.is_actor(GameEnums.ACTORS.ANY_PLAYER)):volume_db=-20
		$Steps.volume_db=volume_db-14
		$Voice.volume_db=volume_db
	else:
		$Steps.volume_db=-60
		$Voice.volume_db=-60

func on_wall_collision(_wall_pos:Vector2)->bool:
	dbgmsg("colliding wall")
	reset_think_dir()
	idle()
	return true

func reset_think_dir():
	think_dir=NONE

func collide_actor(actor:Node2D)->bool:
	if (!actor.is_actor(GameEnums.ACTORS.ANY_ENEMY) or is_amok) and actor.can_be_hit_by(self):
		if can_attack and GameFuncs.are_in_hit_distance(self,actor):
			_animator.trigger_anim("attack")
			can_attack=false
			can_move=false
			last_dir=current_dir
			set_attack(true)
			$CoolDownTimer.start(COOL_DOWN_ATTACK)
			$CalmDownTimer.start(CALM_DELAY_WHEN_AFTER_ATTACK)
			actor.hit(self,ATTACK_POWER)
		return true
	reset_think_dir()
	return true

func collide_block(_block:Node2D)->bool:
	reset_think_dir()
	return true

func set_can_attack(value:bool):
	can_attack=value
	think_dir=last_dir
	can_move=true	
		
func set_attack(value:bool):
	attack=value
	if attack:
		speedup()
	else:
		speeddown()
	
func think_of_dir():
	thinking=true
	dbgmsg("Thinking dir")
	var all_dirs_and_idle=[Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN,NONE]
	randomize()
	all_dirs_and_idle.shuffle()
	var blocked=true
	while blocked:
		think_dir=all_dirs_and_idle.pop_front()
		if think_dir==NONE:
			blocked=false
		else:
			blocked=is_something(next_pos(think_dir))			
	dbgmsg("Choosed %s" % think_dir)
	if think_dir==NONE:idle()
	thinking=false

func is_something(at:Vector2)->bool:
	var objs:=detect_obstacles(at)
	if objs.has("WALL"):return true
	if objs.has(GameEnums.OBJECT_TYPE.BLOCK): return true
	if objs.has(GameEnums.OBJECT_TYPE.ACTOR):
		if (objs[GameEnums.OBJECT_TYPE.ACTOR]).is_actor(GameEnums.ACTORS.ANY_PLAYER):
			return false
		else:
			return true
	return false
			

func hide_life_bar() -> void:
	$UI/LifeBar.hide()
