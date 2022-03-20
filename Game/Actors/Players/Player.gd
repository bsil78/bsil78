extends "res://Game/BaseScripts/WeakActor.gd"
class_name Player


#signals
signal light_changed

#exposed values
export(int,0,1000,10) var max_energy:=100
export(int,0,1000,10) var energy:=100
export(int) var ENERGY_LOSED_ON_CHOP:=3
export(int) var ENERGY_LOSED_ON_RUN:=2
export(int) var ENERGY_LOSED_ON_TIME:=1

var jar1=preload("res://Game/Assets/Audio/ogg/player/scavengers_soda1.ogg")
var jar2=preload("res://Game/Assets/Audio/ogg/player/scavengers_soda2.ogg")
var food1=preload("res://Game/Assets/Audio/ogg/enemies/scavengers_footstep1.ogg")
var food2=preload("res://Game/Assets/Audio/ogg/enemies/scavengers_footstep2.ogg")
var lifegain=preload("res://Game/Assets/Audio/ogg/player/haan.ogg")
var humhum=preload("res://Game/Assets/Audio/ogg/player/humhum.ogg")
var sproutch=preload("res://Game/Assets/Audio/ogg/enemies/sproutch.ogg")
var mhm=preload("res://Game/Assets/Audio/ogg/player/mhm.ogg")
var pickhit=preload("res://Game/Assets/Audio/ogg/player/Pick_Hitting_Rock.ogg")
var exit_sound=preload("res://Game/Assets/Audio/ogg/effects/exit.ogg")

var letsgo=preload("res://Game/Assets/Audio/ogg/player/let-s-go-male.ogg")

#protected values
var active:=false
var _mask_light_on:Sprite
var _mask_light_off:Sprite
var hum_occuring:=false
var _torch:Node2D
var god_signs_count:=0
var taken_exit:String
var _mask_layer:Node
var torch_should_be_visible:=true
var torch_is_temporarily_hidden:=false


const Actor:=preload("res://Game/BaseScripts/Actor.gd")
const remains:=preload("res://Game/Items/PlayerRemains.tscn")
var LifeGainEffect:=preload("res://Game/Effects/PlayerLifeGain.tscn").instance()
var FoodGainEffect:=preload("res://Game/Effects/PlayerFoodGain.tscn").instance()
var hitEffect:=preload("res://Game/Effects/PlayerHitBlood.tscn").instance()
var explodeEffect:=preload("res://Game/Effects/PlayerDying.tscn").instance()



func _ready():
	init_camera()
	_mask_light_on=get_parent().get_parent().get_node("MaskLayer/FixedMask")
	_mask_light_off=get_parent().get_parent().get_node("MaskLayer/FixedMask_LightOff")
	_torch=$Animation/AnimatedSprite/Torch

func _physics_process(_delta):
	if !Thing.frozen and is_alive():
		if energy<=0:
			_animator.trigger_anim("dying_no_energy")
			return
		manage_torch_visibility()
# warning-ignore:integer_division
# warning-ignore:integer_division
		if energy<=max_energy/3 or life_points<=max_life_points/3:
			if $Reminder.is_stopped():
				var delay:=min(energy,life_points)/10
				if $Reminder.is_connected("timeout",self,"hum"):
					$Reminder.disconnect("timeout",self,"hum")
				$Reminder.connect("timeout",self,"hum",[delay*-5])
				$Reminder.start(3.0)


func inventory()->Inventory:
	return $Inventory as Inventory

func init_camera():
	var marge=9
	$Camera2D.current=false
	$Camera2D.limit_left=-marge*cell_size
	$Camera2D.limit_top=-marge*cell_size
	$Camera2D.limit_right=(GameData.world.level.size+marge)*cell_size
	$Camera2D.limit_bottom=(GameData.world.level.size+marge)*cell_size

func on_entering_level():
	dbgmsg("entering level")
	init_camera()
	_mask_layer=GameData.world.get_node("MaskLayer")
	_mask_layer.update()
	self.connect("has_moved",_mask_layer,"update")
	self.connect("light_changed",_mask_layer,"update")
	taken_exit=""
	if GameData.current_level>1: _animator.reset()
	make_alive()
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
		Utils.play_sound($Voice,humhum,db_volume)
		hum_occuring=false

func hide_torch_temporarily(delay):
	torch_is_temporarily_hidden=true
	$RevertHidingTorchTimer.start(delay)

func activate(first_for_level:=false):
	if first_for_level: Utils.play_sound($Voice,letsgo,-20)
	$Camera2D.make_current()
	z_index=2
	active=true
	emit_signal("has_moved")

func desactivate():
	$Camera2D.current=false
	z_index=1
	active=false

func get_camera():
	return $Camera2D

func torch():
	return _torch

func manage_torch_visibility():
	if !torch_is_temporarily_hidden and torch_should_be_visible:
		_torch.visuals_visible()
	else:
		_torch.visuals_hidden()


func lose_torch():
	_torch.shutdown()
	emit_signal("light_changed")
	_torch.visuals_hidden()

func remove_from_game():
	self.disconnect("has_moved",_mask_layer,"update")
	self.disconnect("light_changed",_mask_layer,"update")	
	GameData.players.erase(name)
	
func use_torch():
	if _torch.is_flammed():return
	if $Inventory.use(GameEnums.ITEMS.TORCH):
		_torch.flamme_it()
		if torch_should_be_visible:_torch.visuals_visible()
		emit_signal("light_changed")
		
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
# warning-ignore:narrowing_conversion
	if is_alive():energy=max(energy-amount,0)		
	
func on_move(from,to)->bool:
	if .on_move(from,to):
#		torch_should_be_visible=should_torch_be_visible_at(to)
		if max_speed==run_speed:loseEnergy(ENERGY_LOSED_ON_RUN)
		_animator.trigger_anim("walk")
		return true
	else:
		return false
		
#func should_torch_be_visible_at(to):
#	var things=detect_things(to)
#	dbgmsg("detected %s"%GameFuncs.dump(things))
#	var need_to_hide_torch=things.has(GameEnums.OBJECT_TYPE.BLOCK) and things[GameEnums.OBJECT_TYPE.BLOCK].is_block(GameEnums.BLOCKS.FAKE_WALL)
#	return !need_to_hide_torch 
		
func explode():
	Utils.play_sound($Voice as AudioStreamPlayer2D,sproutch,20)
	Utils.play_effect_once(explodeEffect,GameData.world.effects_node(),global_position)	
	
	
#func on_collision(others:Dictionary)->bool:
#	return .on_collision(others)

func collide_block(block:Node2D)->bool:
	if cool_down: return true 
	if block.can_be_hit_by(self) and GameFuncs.are_in_hit_distance(self,block):
		dbgmsg("chop to %s"%block.name)
		_animator.trigger_anim("chop")
		Utils.timer(0.3).connect("timeout",block,"hit",[self,5])
		loseEnergy(ENERGY_LOSED_ON_CHOP)
		Utils.play_sound($SoundsEffects,pickhit)
		start_cool_down(0.5)
		return true
	if block.use_in_place(self):
		dbgmsg("using %s"%block.name)
		start_cool_down(0.4)
		return true
	if block.step_on(self):
		dbgmsg("stepping on %s" % block.name)
		if block.is_block(GameEnums.BLOCKS.FAKE_WALL):
			pass
#			torch_should_be_visible=false
		elif block.is_block(GameEnums.BLOCKS.EXIT):
			dbgmsg("taken exit %s" % block.name)
			taken_exit=block.name
			position=snapped_pos()
			_animator.trigger_anim("exit_level")
			Utils.play_sound($SoundsEffects,exit_sound)
		return false	
		
	return .collide_block(block)

	
func collide_item(item:Node2D)->bool:
	if item.behaviors().has(GameEnums.BEHAVIORS.USE_IN_PLACE): item.use_in_place(self)
	if item.behaviors().has(GameEnums.BEHAVIORS.PICKUP): item.pickup(self)
	return .collide_item(item)

func can_be_hit_by(from)->bool:
	return .can_be_hit_by(from) and !from.is_actor(GameEnums.ACTORS.ANY_PLAYER)

func collide_actor(actor:Node2D)->bool:
	if pushed_thing==actor:return false
	if (!actor.is_actor(GameEnums.ACTORS.ANY_PLAYER) or is_amok) and actor.can_be_hit_by(self):
		if !cool_down and GameFuncs.are_in_hit_distance(self,actor):
			_animator.trigger_anim("chop")
			Utils.timer(0.3).connect("timeout",actor,"hit",[self,5])
			loseEnergy(ENERGY_LOSED_ON_CHOP)
			start_cool_down(0.5)
		return true
	if  ( actor.is_actor(GameEnums.ACTORS.ANY_RUNNER) ):
		if actor.speed!=0:
			return actor.current_dir!=current_dir
		dbgmsg("try pushing %s"%actor.name)
		if actor.push_to(self,current_dir):
			dbgmsg("pushing %s"%actor.name)
			pushed_thing=actor
			var pushspeed=actor.run_speed
			if actor.walk_on_push:pushspeed=actor.walk_speed
			var goto_args:=[position,current_dir]
			if pushspeed<=run_speed:goto_args.push_back(pushspeed*0.95)
			Utils.timer(0.2).connect("timeout",self,"goto",goto_args)
			return false
		return true
	return false

func start_cool_down(delay):
	cool_down=true
	Utils.timer(delay).connect("timeout",self,"reset_cool_down")

func reset_cool_down():
	cool_down=false

func is_actor(actor:int=-1)->bool:
	return ( .is_actor(actor) 
			or GameEnums.ACTORS.ANY_PLAYER==actor
			or ( GameEnums.ACTORS.PLAYER_ONE==actor and "PlayerOne"==name )
			or ( GameEnums.ACTORS.PLAYER_TWO==actor and "PlayerTwo"==name ) )



func use_ankh():
	if $Inventory.use(GameEnums.ITEMS.ANKH):
		refill_life()

func refill_life(amount:int=-1,silently:bool=false):
	if amount<1:
		life_points=max_life_points
	else:
# warning-ignore:narrowing_conversion
		life_points=min(max_life_points,life_points+amount)		
	if !silently:
		Utils.play_effect_once(LifeGainEffect,$FrontEffects,global_position)
	Utils.play_sound($Voice,lifegain)
	
func refill_energy(amount:int=-1,silently:bool=false):
	if amount<1:
		energy=max_energy
	else:
# warning-ignore:narrowing_conversion
		energy=min(max_energy,energy+50)
	if !silently:
		Utils.play_effect_once(FoodGainEffect,$FrontEffects,global_position)
		Utils.play_sound($Voice,lifegain)
	
func consume_food():
	if $Inventory.use(GameEnums.ITEMS.FOOD):
		Utils.play_sound($Voice,[food1,food2])
		refill_energy(-1)


func consume_jar():
	if $Inventory.use(GameEnums.ITEMS.JAR):
		Utils.play_sound($Voice,[jar1,jar2])	
		refill_energy(50,true)
		refill_life(50)
	
func killed():
	if is_alive():
		Thing.dead()
		dbgmsg("killed")
		_animator.trigger_anim("killed")
	else:
		dbgmsg("killed but not alive")
	
func dead():
	var items_layers:Node2D=GameData.world.level.find_node("ItemsLayer",true,false)
	var inventory=inventory()
	var remains_node=GameFuncs.spawn(self.global_position,remains,items_layers)
	var new_inv=inventory.duplicate()
	inventory.reset()
	if lvl.has_item_at(position):
		var item=lvl.objects_at(position)[GameEnums.OBJECT_TYPE.ITEM]
		new_inv.store(item.type_id(),item,false)
	remains_node.add_child(new_inv)
	lvl.add_object(remains_node)
	$Inventory.update()
	GameFuncs.player_died(self)


	
func goto(from:Vector2,dir:Vector2,fspeed:int=-1):
	if !(is_alive() and taken_exit.empty()):
		dbgmsg("asked to go %s but not alive or gone out"%dir)
		return
	if GameFuncs.grid_pos(from)!=GameFuncs.grid_pos(position):
		dbgmsg("asked to go %s from %s but position does not match actual one %s"%[dir,from,position])
		return
	var pushed_thing_pos=pushed_thing.position if is_instance_valid(pushed_thing) else null  
	if pushed_thing_pos:
		var calc_dir= GameFuncs.grid_pos(pushed_thing_pos)-GameFuncs.grid_pos(from)
		if calc_dir!=dir: return
	if fspeed>0:forced_speed=fspeed
	.goto(from,dir)

func idle():
	if is_alive():
		_animator.trigger_anim("idle")
		.idle()


func _on_RevertHidingTorchTimer_timeout() -> void:
	torch_is_temporarily_hidden=false
