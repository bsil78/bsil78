extends "res://Game/BaseScripts/Actor.gd"

#exposed values
export(int,0,1000,10) var max_food_points:=100
export(int,0,1000,10) var food_points:=100
export(int) var ENERGY_LOSED_ON_CHOP:=5
export(int) var ENERGY_LOSED_ON_RUN:=3
export(int) var ENERGY_LOSED_ON_TIME:=1

export(AudioStream) var soda1
export(AudioStream) var soda2
export(AudioStream) var food1
export(AudioStream) var food2
export(AudioStream) var lifegain
export(AudioStream) var humhum
export(AudioStream) var sproutch
export(AudioStream) var mhm


#protected values
var active:=false
var _mask_light_on:Sprite
var _mask_light_off:Sprite
var hum_occuring:=false
var _torch:Node2D
var god_signs_count:=0
var taken_exit:String

const Actor:=preload("res://Game/BaseScripts/Actor.gd")
const LifeGainEffect:=preload("res://Game/Effects/PlayerLifeGain.tscn")
const FoodGainEffect:=preload("res://Game/Effects/PlayerFoodGain.tscn")
const hitEffect:=preload("res://Game/Effects/PlayerHitBlood.tscn")
const remains:=preload("res://Game/Items/PlayerRemains.tscn")
const explodeEffect:=preload("res://Game/Effects/PlayerDying.tscn")


func _ready():
	init_camera()
	_mask_light_on=get_parent().get_parent().get_node("MaskLayer/FixedMask")
	_mask_light_off=get_parent().get_parent().get_node("MaskLayer/FixedMask_LightOff")
	_torch=$Animation/Torch


func _physics_process(_delta):
	if !Thing.freezed and is_alive():
		if food_points<=0:
			_animator.trigger_anim("dying_no_energy")
			return
		if food_points<=max_food_points/3 or life_points<=max_life_points/3:
			var delay:=min(food_points,life_points)/10
			Utils.timer(delay).connect("timeout",self,"hum",[delay*-5])


func inventory()->Node2D:
	return $Inventory as Node2D

func init_camera():
	var marge=9
	$Camera2D.current=false
	$Camera2D.limit_left=-marge*cell_size
	$Camera2D.limit_top=-marge*cell_size
	$Camera2D.limit_right=(GameData.world.level.size+marge)*cell_size
	$Camera2D.limit_bottom=(GameData.world.level.size+marge)*cell_size

func on_entering_level():
	init_camera()
	taken_exit=""
	if GameData.current_level>1: _animator.restart()
	alive()
	hum()
	idle()
	unfreeze()
	desactivate()
	
func on_exiting_level():
	GameFuncs.exit_player(self,taken_exit)
	
func gather_god_sign():
	$Inventory.god_signs+=1

func freeze():
	.freeze()
	$LoseEnergyTimer.stop()
	torch().freeze()

func unfreeze():
	.unfreeze()
	$LoseEnergyTimer.start()
	torch().unfreeze()

func hum(db_volume:int=-40):
	if !hum_occuring:
		hum_occuring=true
		Utils.play_sound($Voice,humhum,-40)
		hum_occuring=false


func activate():
	$Camera2D.make_current()
	active=true
	
func torch():
	return _torch

func get_camera():
	return $Camera2D

func desactivate():
	$Camera2D.current=false
	active=false

func lose_torch():
	_torch.shutdown()
	_torch.visible=false

func remove_from_game():
	GameData.players.erase(name)
	
func use_torch():
	if $Inventory.use(GameEnums.ITEMS.TORCH):
		_torch.visible=true
		_torch.flamme_it()
		
func hit(from:Node2D,amount:int=1)->bool:
	if .hit(from,amount):
		_animator.trigger_anim("hit")
		Utils.play_effect_once(hitEffect,$FrontEffects,global_position)
		return true
	else:
		return false

func fliph(flip:bool):
	if $Animation/AnimatedSprite.flip_h!=flip:
		#print_debug("{} flip_h is {}".format([name,flip],"{}"))
		$Animation/AnimatedSprite.flip_h=flip
		_torch.flip(flip)
	
func loseEnergy(amount:int=ENERGY_LOSED_ON_TIME):
	if is_alive():food_points=max(food_points-amount,0)		

	
func on_move(from,to):
	if max_speed==run_speed:loseEnergy(ENERGY_LOSED_ON_RUN)
	.on_move(from,to)
	_animator.trigger_anim("walk")

func explode():
	Utils.play_sound($Voice as AudioStreamPlayer2D,sproutch,20)
	Utils.play_effect_once(explodeEffect,get_parent(),global_position)	
	
func on_collision(others:Dictionary)->bool:
	if others.empty():
		if debug: debug.error("{} colliding with nothing !",[name])
		return true
	
	var actor:= others.get(GameEnums.OBJECT_TYPE.ACTOR) as Actor
	var item_node:=	others.get(GameEnums.OBJECT_TYPE.ITEM) as Node2D
	var block:=	others.get(GameEnums.OBJECT_TYPE.BLOCK) as Node2D
	if actor:
		if actor.name.matchn("Enemy*"):
			if GameFuncs.are_in_hit_distance(self,actor):
				actor.hit(self,5)
				_animator.trigger_anim("chop")
				loseEnergy(ENERGY_LOSED_ON_CHOP)
			return true
		if actor.name.matchn("CrusherBlock*") or actor.name.matchn("Block*") or actor.name.matchn("Scarab*"):
			if actor.push_to(self,current_dir):
				Utils.timer(0.1).connect("timeout",self,"goto",[next_dir])
			return true
	if item_node:
		var item
		for key in GameEnums.ITEMS_MAP:
			if item_node.name.matchn(GameEnums.ITEMS_MAP[key]):
				item=key
				break
		if !item:
			printerr("Item unknown in GameEnums : %s" % item_node.name)
		if item_node.has_method("capabilities"):
			if item_node.capabilities().has(GameEnums.CAPABILITIES.USE_IN_PLACE):
				if item_node.use_in_place(self):return true
			if item_node.capabilities().has(GameEnums.CAPABILITIES.PICKUP):
				item_node.pickup(self)
				return false
		if item_node.name.matchn("Medkit*") :
			GameData.world.detroy_object(item_node)
			$Inventory.store(item,item_node)
			if life_points<10:
				use_medkit()
			else:
				$Inventory.backpack_sound()
			return false
		if item_node.name.matchn("Torch*") :
			GameData.world.detroy_object(item_node)
			$Inventory.store(item,item_node)
			$Inventory.backpack_sound()
			return false
		if item_node.name.matchn("Food*") :
			GameData.world.detroy_object(item_node)
			$Inventory.store(item,item_node)
			if food_points<10:
				consume_food()
			else:
				$Inventory.backpack_sound()
			return false
		if item_node.name.matchn("Soda*") :
			GameData.world.detroy_object(item_node)
			$Inventory.store(item,item_node)
			if life_points<50 and food_points<50:
				consume_soda()
			else:
				$Inventory.backpack_sound()
			return false
		if item_node.name.matchn("Map*") :
			Utils.play_sound($Voice,mhm,-10)
			GameData.world.detroy_object(item_node)
			$Inventory.store(item,item_node)
			return false
	if block:
		if block.is_block(GameEnums.BLOCKS.ANY_BREAKABLE):
			if block.capabilities().has(GameEnums.CAPABILITIES.HIT):
				if GameFuncs.are_in_hit_distance(self,block):
					block.hit(self,5)
					_animator.trigger_anim("chop")
					loseEnergy(ENERGY_LOSED_ON_CHOP)
		
		if block.is_block(GameEnums.BLOCKS.EXIT):
			if block.capabilities().has(GameEnums.CAPABILITIES.USE_IN_PLACE):
				block.use_in_place(self)
			elif block.capabilities().has(GameEnums.CAPABILITIES.STEP_ON):
				print("%s taken exit %s" % [name,block.name])
				taken_exit=block.name
				position=fixedgrid()
				_animator.trigger_anim("ExitLevel",false,true)	
				return false
	return true

func is_actor(actor:int=-1)->bool:
	return ( .is_actor(actor) 
			or GameEnums.ACTORS.ANY_PLAYER==actor
			or ( GameEnums.ACTORS.PLAYER_ONE==actor and "PlayerOne"==name )
			or ( GameEnums.ACTORS.PLAYER_TWO==actor and "PlayerTwo"==name ) )



func use_medkit():
	if $Inventory.use(GameEnums.ITEMS.MEDKIT):
		refill_life()

func refill_life(amount:int=-1,silently:bool=false):
	if amount<1:
		life_points=max_life_points
	else:
		life_points=min(max_life_points,life_points+amount)		
	if !silently:
		Utils.play_effect_once(LifeGainEffect,$FrontEffects,global_position)
	Utils.play_sound($Voice,lifegain)
	
func refill_energy(amount:int=-1,silently:bool=false):
	if amount<1:
		food_points=max_food_points
	else:
		food_points=min(max_food_points,food_points+50)
	if !silently:
		Utils.play_effect_once(FoodGainEffect,$FrontEffects,global_position)
		Utils.play_sound($Voice,lifegain)
	
func consume_food():
	if $Inventory.use(GameEnums.ITEMS.FOOD):
		Utils.play_sound($Voice,[food1,food2])
		refill_energy(-1)
		

func consume_soda():
	if $Inventory.use(GameEnums.ITEMS.SODA):
		Utils.play_sound($Voice,[soda1,soda2])	
		refill_energy(50,true)
		refill_life(50)
	
func killed():
	if is_alive():
		Thing.dead()
		_animator.trigger_anim("killed",false,true)
	
func dead():
	var items_layers:Node2D=GameData.world.level.find_node("ItemsLayer",true,false)
	GameFuncs.spawn(self.global_position,remains,items_layers)
	GameFuncs.player_died(self)
	
func chop(what:Node2D=null):
	if is_alive():
		_animator.trigger_anim("chop",false,true)
		if what and what.has_method("hit"):
			what.hit(50)

func goto(dir:Vector2):
	if is_alive():
		if !taken_exit.empty():_animator.trigger_anim("walk")
		.goto(dir)

func idle():
	if is_alive():
		_animator.trigger_anim("idle")
		.idle()
