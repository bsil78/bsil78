extends "res://Game/BaseScripts/WeakActor.gd"

#signals
signal light_changed

#exposed values
export(int,0,1000,10) var max_energy:=100
export(int,0,1000,10) var energy:=100
export(int) var ENERGY_LOSED_ON_PUSH:=1
export(int) var ENERGY_LOSED_ON_CHOP:=1
export(int) var ENERGY_LOSED_ON_ATTACK:=2
export(int) var ENERGY_LOSED_ON_RUN:=1
export(int) var ENERGY_LOSED_ON_TIME:=1

var jar1=preload("res://Game/Assets/Audio/ogg/player/scavengers_soda1.ogg")
var jar2=preload("res://Game/Assets/Audio/ogg/player/scavengers_soda2.ogg")
var food1=preload("res://Game/Assets/Audio/ogg/enemies/scavengers_footstep1.ogg")
var food2=preload("res://Game/Assets/Audio/ogg/enemies/scavengers_footstep2.ogg")
var lifegain=preload("res://Game/Assets/Audio/ogg/player/haan.ogg")
var humhum=preload("res://Game/Assets/Audio/ogg/player/humhum.ogg")
var chop1=preload("res://Game/Assets/Audio/ogg/player/scavengers_chop1.ogg")
var chop2=preload("res://Game/Assets/Audio/ogg/player/scavengers_chop2.ogg")
var step1=preload("res://Game/Assets/Audio/ogg/player/step1.ogg")
var step2=preload("res://Game/Assets/Audio/ogg/player/step2.ogg")
var sproutch=preload("res://Game/Assets/Audio/ogg/enemies/sproutch.ogg")
var mhm=preload("res://Game/Assets/Audio/ogg/player/mhm.ogg")
var pickhit=preload("res://Game/Assets/Audio/ogg/player/Pick_Hitting_Rock.ogg")
var exit_sound=preload("res://Game/Assets/Audio/ogg/effects/exit.ogg")

var letsgo=preload("res://Game/Assets/Audio/ogg/player/let-s-go-male.ogg")

#protected values
var active:=false
var _torch:Node2D
var god_signs_count:=0
var taken_exit:String
var _mask_layer:Node
var torch_should_be_visible:=true
var into_block
var torch_is_temporarily_hidden:=false
var lastAlertingTime:=OS.get_unix_time()


const remains:=preload("res://Game/Items/PlayerRemains.tscn")
var LifeGainEffect:=preload("res://Game/Effects/PlayerLifeGain.tscn").instance()
var FoodGainEffect:=preload("res://Game/Effects/PlayerFoodGain.tscn").instance()
var hitEffect:=preload("res://Game/Effects/PlayerHitBlood.tscn").instance()
var explodeEffect:=preload("res://Game/Effects/PlayerDying.tscn").instance()

var to_step_on_after_move

func _ready():
	_torch=$Animation/AnimatedSprite/Torch

func _physics_process(_delta):
	if !Thing.frozen and is_alive():
		if energy<=0:
			_animator.trigger_anim("dying_no_energy")
			return
		manage_torch_visibility()

func inventory()->Inventory:
	return $Inventory as Inventory

#func init_camera():
#	$Camera2D.current=false
#	var marge=10
#	$Camera2D.limit_left=-marge*cell_size
#	$Camera2D.limit_top=-marge*cell_size
#	$Camera2D.limit_right=(GameData.world.level.size+marge)*cell_size
#	$Camera2D.limit_bottom=(GameData.world.level.size+marge)*cell_size

func on_entering_level():
	dbgmsg("entering level")
#	init_camera()
	_mask_layer=get_viewport().find_node("MaskLayer",true,false)
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


func hide_torch_temporarily(delay):
	torch_is_temporarily_hidden=true
	$RevertHidingTorchTimer.start(delay)

func activate(first_for_level:=false):
	if first_for_level: Utils.timer(0.5).connect("timeout",Utils,"play_sound",[$Voice,letsgo,-15])
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
		alertPlayerIfDanger()
		return true
	else:
		return false

func fliph(flip:bool):
	if $Animation/AnimatedSprite.flip_h!=flip:
		#print_debug("{} flip_h is {}".format([name,flip],"{}"))
		$Animation/AnimatedSprite.flip_h=flip
		_torch.flip(flip)

func timeElapsing():
	loseEnergy(ENERGY_LOSED_ON_TIME)
	
	
func loseEnergy(amount:int=ENERGY_LOSED_ON_TIME):
# warning-ignore:narrowing_conversion
	if is_alive():
		energy=max(energy-amount,0)
		alertPlayerIfDanger()

func alertPlayerIfDanger():
	if OS.get_unix_time()<lastAlertingTime+5:return
	if energy<=max_energy/3 or life_points<=max_life_points/3: 
		Utils.play_sound($Voice,humhum)
		lastAlertingTime=OS.get_unix_time()
	
func on_move(from,to)->bool:
	if .on_move(from,to):
		if max_speed==run_speed:loseEnergy(ENERGY_LOSED_ON_RUN)
		_animator.trigger_anim("walk")
		var step_sound=Utils.choose([step1,step2])
		Utils.play_sound($SoundsEffects,step_sound)
		return true
	else:
		return false

func on_moved(from,to):
	if next_dir==NONE:stop()
	.on_moved(from,to)
	var step_sound=Utils.choose([step1,step2])
	Utils.play_sound($SoundsEffects,step_sound)	
	var block=to_step_on_after_move
	to_step_on_after_move=null
	if is_instance_valid(block):
		if block.is_block(GameEnums.BLOCKS.EXIT):
			dbgmsg("taking exit %s" % block.name)
			taken_exit=block.name
			position=snapped_pos()
			_animator.trigger_anim("exit_level")
			Utils.play_sound($SoundsEffects,exit_sound)
		if block.is_block(GameEnums.BLOCKS.TELEPORTER):
			dbgmsg("taking teleporter %s" % block.name)
			position=snapped_pos()
			block.teleport(self)


func teleportTo(pos:Vector2)->bool:
	var objs=lvl.objects_at(pos)
	var block=objs.get(GameEnums.OBJECT_TYPE.BLOCK)
	if block and block.is_block(GameEnums.BLOCKS.TELEPORTER):
		var actor=objs.get(GameEnums.OBJECT_TYPE.ACTOR)
		if !actor:
			lvl.remove_object(self)
			position=pos
			lvl.add_object(self)
			return true
	return false
		
func explode():
	Utils.play_sound($Voice,sproutch,20)
	Utils.play_effect_once(explodeEffect,GameData.world.effects_node(),global_position)	
	
	

func collide_block(block:Node2D)->bool:
	if cool_down: return true 
	if block.can_be_hit_by(self) and GameFuncs.are_in_hit_distance(self,block):
		dbgmsg("chop to %s"%block.name)
		_animator.trigger_anim("chop")
		Utils.timer(0.3).connect("timeout",block,"hit",[self,5])
		loseEnergy(ENERGY_LOSED_ON_CHOP)
		Utils.play_sound($SoundsEffects,pickhit,-999,rand_range(0.75,1.25))
		start_cool_down(0.5)
		return true
	if block.use_in_place(self):
		dbgmsg("using %s"%block.name)
		start_cool_down(0.4)
		return true
	if block.step_on(self):
		dbgmsg("stepping on %s" % block.name)
		to_step_on_after_move=block
		return false	
		
	return .collide_block(block)

	
func collide_item(item:Node2D)->bool:
	if item.behaviors().has(GameEnums.BEHAVIORS.USE_IN_PLACE): item.use_in_place(self)
	if item.behaviors().has(GameEnums.BEHAVIORS.PICKUP): item.pickup(self)
	return .collide_item(item)

func can_be_hit_by(from)->bool:
	if GameFuncs.is_actor(from,[GameEnums.ACTORS.MUMMY]) and !torch_should_be_visible: return false
	return .can_be_hit_by(from) and !from.is_actor(GameEnums.ACTORS.ANY_PLAYER)

func collide_actor(actor:Node2D)->bool:
	if followed_actor==actor:return false
		
	if (!actor.is_actor(GameEnums.ACTORS.ANY_PLAYER) or is_amok) and actor.can_be_hit_by(self):
		if !cool_down and GameFuncs.are_in_hit_distance(self,actor):
			var chop_sound=Utils.choose([chop1,chop2])
			Utils.play_sound($SoundsEffects,chop_sound)
			_animator.trigger_anim("chop")
			Utils.timer(0.3).connect("timeout",actor,"hit",[self,5])
			loseEnergy(ENERGY_LOSED_ON_ATTACK)
			start_cool_down(0.5)
		return !(actor.current_dir==(next_dir if current_dir==NONE else current_dir))
	if  ( actor.is_actor(GameEnums.ACTORS.ANY_RUNNER) ):
		if actor.speed!=0:
			return actor.current_dir!=current_dir
		dbgmsg("try pushing %s"%actor.name)
		if actor.push_to(self,current_dir):
			loseEnergy(ENERGY_LOSED_ON_PUSH)
			dbgmsg("pushing %s"%actor.name)
			follow(actor)
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
# warning-ignore:incompatible_ternary
	if followed_actor:
		dbgmsg("asked to go %s but following %s"%[dir,followed_actor.name])
		return
	.goto(from,dir)

func idle():
	if is_alive():
		_animator.trigger_anim("idle")
		.idle()


func _on_RevertHidingTorchTimer_timeout() -> void:
	torch_is_temporarily_hidden=false

