extends "res://Game/Characters/BaseCharacter.gd"

export(int,0,1000,10) var max_hit_points:=100
export(int,0,1000,10) var max_food_points:=100
export(int,0,1000,10) var hit_points:=100
export(int,0,1000,10) var food_points:=100

#var hitEffect:=preload("res://Game/Effects/PlayerHitRedBlood.tscn")


func _ready():
	GameData.player=self

func _process(_delta):
	if hit_points<=0:
		die()
	else:
		InputSystem.actor_process_input(self)
		
func is_idle() -> bool:
	return !InputSystem.input_activation and !InputSystem.input_direction

func interact_with(other:Node2D):
	if "Enemy" in other.name:
		playanim("Chop",true)
		other.hit(50)
	
func hit(amount:int):
	if hit_points>0:
		hit_points=(hit_points-amount)
		if hit_points<0:
			hit_points=0
		#use_effect(hitEffect,$FrontEffects)
		playanim("Hit")

func die():
	playanim("Killed",true)
	GameData.player=null
	remove_from_world()
	GameData.transition_state=GameEnums.TRANSITION_STATUS.DEAD_TIRED
	CommonUI.fade_transition_scene("res://Game/Scenes/Transitional/TransitionScene.tscn")
	queue_free()
