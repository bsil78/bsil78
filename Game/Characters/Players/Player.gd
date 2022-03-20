extends "res://Game/BaseScripts/Actor.gd"

#exposed values
export(int,0,1000,10) var max_food_points:=100
export(int,0,1000,10) var food_points:=100
export(NodePath) var camera
export(int) var TORCH_DELAY_SEC:=120

export(AudioStream) var soda1
export(AudioStream) var soda2
export(AudioStream) var food1
export(AudioStream) var food2
export(AudioStream) var lifegain
export(AudioStream) var humhum
export(AudioStream) var sproutch
export(AudioStream) var backpack

class Inventory:
	
	var sodas:int=0
	var food:int=0
	var medkit:int=0
	var torch:int=1


#protected values
var active:=false
var _camera:Camera2D
var _mask_light_on:Sprite
var _mask_light_off:Sprite
var inventory:=Inventory.new()
var hum_occuring:=false
var torch_timer:SceneTreeTimer

const Actor:=preload("res://Game/BaseScripts/Actor.gd")
const LifeGainEffect:=preload("res://Game/Effects/PlayerLifeGain.tscn")
const FoodGainEffect:=preload("res://Game/Effects/PlayerFoodGain.tscn")
const hitEffect:=preload("res://Game/Effects/PlayerHitBlood.tscn")


const explodeEffect:=preload("res://Game/Effects/PlayerDying.tscn")


func _ready():
	_camera=get_node(camera) as Camera2D
	_camera.limit_left=-9*grid_size
	_camera.limit_top=-9*grid_size
	_camera.limit_right=(level_size+9)*grid_size
	_camera.limit_bottom=(level_size+9)*grid_size
	_camera.current=false
	_mask_light_on=get_parent().get_parent().get_node("MaskLayer/FixedMask")
	_mask_light_off=get_parent().get_parent().get_node("MaskLayer/FixedMask_LightOff")
	use_torch()
	hum_occuring=true
	hum()

func _physics_process(_delta):
	if food_points<=0:
		killed()
	if !hum_occuring and food_points<=max_food_points/3 or life_points<=max_life_points/3:
		var delay:=min(food_points,life_points)/10
		Utils.timer(delay).connect("timeout",self,"hum",[delay*-5])
		hum_occuring=true
	else:
		hum_occuring=false
		
func hum(db_volume:int=-40):
	if hum_occuring:
		Utils.play_sound($Voice,humhum,-40)
		hum_occuring=false
	
func backpack_sound():
	Utils.play_sound($SoundsEffects,backpack,-10)

func activate():
	if(debug):debug.push("{} is active",[name])
	_camera.current=true
	active=true

func get_camera()->Camera2D:
	return _camera

func desactivate():
	if(debug):debug.push("{} no more active",[name])
	_camera.current=false
	active=false

func lose_torch(timer:SceneTreeTimer):
	if(torch_timer==timer):
		$Lights.torchOff()
		$AnimatedSprite/Torch/Flammes.emitting=false
		_mask_light_on.visible=false
		_mask_light_off.visible=true

func use_torch():
	if inventory.torch>0:
		inventory.torch-=1
		$Lights.torchOn()
		$AnimatedSprite/Torch/Flammes.emitting=true
		_mask_light_off.visible=false
		_mask_light_on.visible=true
		torch_timer=Utils.timer(TORCH_DELAY_SEC*Utils.randfpct(20))
		torch_timer.connect("timeout",self,"lose_torch",[torch_timer])
		
func hit(from:Node2D,amount:int=1):
	if life_points>0:
		_animator.trigger_anim("hit")
		life_points=max(life_points-amount,0)
		Utils.play_effect_once(hitEffect,$FrontEffects)


func fliph(flip:bool):
	var posfact=1
	if flip:posfact=-1
	$AnimatedSprite.flip_h=flip
	$AnimatedSprite/Torch.flip_h=flip
	$AnimatedSprite/Torch.position.x=abs($AnimatedSprite/Torch.position.x)*posfact
	$AnimatedSprite/Torch/Flammes.position.x=abs($AnimatedSprite/Torch/Flammes.position.x)*posfact

func loseEnergy(amount:int=1):
	food_points=max(food_points-amount,0)		

func on_move(from,to):
	if max_speed==walk_speed:
		loseEnergy(1)
	if max_speed==run_speed:
		loseEnergy(5)
	.on_move(from,to)

func explode():
	Utils.play_sound($Voice as AudioStreamPlayer2D,sproutch,20)
	Utils.play_effect_once(explodeEffect,$FrontEffects)	
	
func on_collision(others:Dictionary)->bool:
	if others.empty():
		if debug: debug.error("{} colliding with nothing !",[name])
		return true
	
	var actor:= others.get(GameEnums.OBJECT_TYPE.ACTOR) as Actor
	var item:=	others.get(GameEnums.OBJECT_TYPE.ITEM) as Node2D
	var block:=	others.get(GameEnums.OBJECT_TYPE.BLOCK) as Node2D
	
	if actor:
		if actor.name.matchn("Enemy*"):
			if GameFuncs.are_in_hit_distance(self,actor):
				actor.hit(self,5)
				_animator.trigger_anim("chop")
				loseEnergy(10)
			return true
	if item:
		if item.name.matchn("Medkit*") :
			GameFuncs.remove_from_world(item)
			inventory.medkit+=1
			if life_points<10:
				use_medkit()
			else:
				backpack_sound()
			return false
		if item.name.matchn("Torch*") :
			backpack_sound()
			GameFuncs.remove_from_world(item)
			inventory.torch+=1
			backpack_sound()
			return false
		if item.name.matchn("Food*") :
			GameFuncs.remove_from_world(item)
			inventory.food+=1
			if food_points<10:
				consume_food()
			else:
				backpack_sound()		
			return false
		if item.name.matchn("Soda*") :
			GameFuncs.remove_from_world(item)
			inventory.sodas+=1
			if life_points<50 and food_points<50:
				consume_soda()
			else:
				backpack_sound()
			return false
	if block:
		if block.name.matchn("Exit*") :
			if GameData.current_level==GameData.max_levels:
				GameData.transition_state=GameEnums.TRANSITION_STATUS.WIN_GAME
				GameFuncs.transition()
			return false
	return true

func use_medkit():
	if inventory.medkit>0:
		inventory.medkit-=1
		life_points=max_life_points
		Utils.play_effect_once(LifeGainEffect,$FrontEffects)
		Utils.play_sound($Voice,lifegain)

func consume_food():
	if inventory.food>0:
		inventory.food-=1
		food_points=max_food_points
		Utils.play_effect_once(FoodGainEffect,$FrontEffects)
		Utils.play_sound($Voice,[food1,food2])

func consume_soda():
	if inventory.sodas>0:
		inventory.sodas-=1
		food_points=min(max_food_points,food_points+50)
		life_points=min(max_life_points,life_points+50)
		Utils.play_effect_once(LifeGainEffect,$FrontEffects)
		Utils.play_sound($Voice,[soda1,soda2])	
	
func killed():
	if alive:
		alive=false
		_animator.trigger_anim("killed")
	
func dead():
	GameFuncs.player_died(self)
	
func chop(what:Node2D=null):
	if alive:
		_animator.trigger_anim("chop")
		if what and what.has_method("hit"):
			what.hit(50)

func goto(dir:Vector2):
	if alive:
		_animator.trigger_anim("walk")
		.goto(dir)

func idle():
	if alive:
		_animator.trigger_anim("idle")
		.idle()
