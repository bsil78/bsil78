extends "res://Game/BaseScripts/Actor.gd"
class_name Player


#signals
signal light_changed

#exposed values
export(int,0,1000,10) var max_energy:=100
export(int,0,1000,10) var energy:=100
export(int) var ENERGY_LOSED_ON_CHOP:=4
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
var _mask_layer:Node
var torch_should_be_visible:=true


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
	_torch=$Animation/Torch
	


func _physics_process(_delta):
	if !Thing.frozen and is_alive():
		if energy<=0:
			_animator.trigger_anim("dying_no_energy")
			return
		if energy<=max_energy/3 or life_points<=max_life_points/3:
			var delay:=min(energy,life_points)/10
			Utils.timer(delay).connect("timeout",self,"hum",[delay*-5])


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
	emit_signal("has_moved")

func desactivate():
	$Camera2D.current=false
	active=false

func get_camera():
	return $Camera2D

func torch():
	return _torch

func manage_torch_visibility():
	if torch_should_be_visible:
		_torch.visuals_visible()
	else:
		_torch.visuals_hidden()


func lose_torch():
	_torch.shutdown()
	emit_signal("light_changed")
	_torch.visible=false

func remove_from_game():
	self.disconnect("has_moved",_mask_layer,"update")
	self.disconnect("light_changed",_mask_layer,"update")	
	GameData.players.erase(name)
	
func use_torch():
	if $Inventory.use(GameEnums.ITEMS.TORCH):
		_torch.visible=true
		_torch.flamme_it()
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
	if is_alive():energy=max(energy-amount,0)		
	
func on_move(from,to)->bool:
	if .on_move(from,to):
		torch_should_be_visible=should_torch_be_visible_at(to)
		manage_torch_visibility()
		if max_speed==run_speed:loseEnergy(ENERGY_LOSED_ON_RUN)
		_animator.trigger_anim("walk")
		return true
	else:
		return false
		
func should_torch_be_visible_at(to):
	var things=detect_things(to)
	print("detected %s"%GameFuncs.dump(things))
	var need_to_hide_torch=things.has(GameEnums.OBJECT_TYPE.BLOCK) and things[GameEnums.OBJECT_TYPE.BLOCK].is_block(GameEnums.BLOCKS.FAKE_WALL)
	return torch().is_flammed() and !need_to_hide_torch 
		
func explode():
	Utils.play_sound($Voice as AudioStreamPlayer2D,sproutch,20)
	Utils.play_effect_once(explodeEffect,GameData.world.effects_node(),global_position)	
	
	
#func on_collision(others:Dictionary)->bool:
#	return .on_collision(others)

func collide_block(block:Node2D)->bool:
	if block.is_block(GameEnums.BLOCKS.FORCE_FIELD):
		if GameEnums.CAPABILITIES.STEP_ON in block.capabilities():
			var should_stop=!block.step_on(self)
			print("should hide torch : %s"%(!should_stop and block.is_block(GameEnums.BLOCKS.FAKE_WALL)))
			if !should_stop and block.is_block(GameEnums.BLOCKS.FAKE_WALL):
				torch_should_be_visible=false
				manage_torch_visibility()
			return should_stop
	if block.is_block(GameEnums.BLOCKS.ANY_BREAKABLE):
		if block.capabilities().has(GameEnums.CAPABILITIES.HIT):
			if !cool_down and GameFuncs.are_in_hit_distance(self,block):
				dbgmsg("chop to %s"%block.name)
				_animator.trigger_anim("chop",false,true)
				Utils.timer(0.3).connect("timeout",block,"hit",[self,5])
				loseEnergy(ENERGY_LOSED_ON_CHOP)
				start_cool_down(0.5)
	if block.is_block(GameEnums.BLOCKS.EXIT):
		dbgmsg("detected Exit %s"%block.name)
		if block.capabilities().has(GameEnums.CAPABILITIES.USE_IN_PLACE):
			block.use_in_place(self)
			start_cool_down(0.2)
		elif !cool_down and block.capabilities().has(GameEnums.CAPABILITIES.STEP_ON):
			print("%s taken exit %s" % [name,block.name])
			taken_exit=block.name
			position=snapped_pos()
			_animator.trigger_anim("ExitLevel",false,true)
			return false
	return .collide_block(block)
	
func collide_item(item:Node2D)->bool:
	var item_id
	for key in GameEnums.ITEMS_MAP:
		if item.name.matchn(GameEnums.ITEMS_MAP[key]):
			item_id=key
			break
	if !item_id:
		dbgmsg("Item unknown in GameEnums : %s" % item.name,ERROR)
		return true
	if item.has_method("capabilities"):
		if item.capabilities().has(GameEnums.CAPABILITIES.USE_IN_PLACE):
			if item.use_in_place(self):return true
		if item.capabilities().has(GameEnums.CAPABILITIES.PICKUP):
			item.pickup(self)
			return false
	if item.name.matchn("Medkit*") :
		GameData.world.detroy_object(item)
		$Inventory.store(item_id,item)
		if life_points<10:
			use_medkit()
		else:
			$Inventory.backpack_sound()
		return false
	if item.name.matchn("Torch*") :
		GameData.world.detroy_object(item)
		$Inventory.store(item_id,item)
		$Inventory.backpack_sound()
		return false
	if item.name.matchn("Food*") :
		GameData.world.detroy_object(item)
		$Inventory.store(item_id,item)
		if energy<10:
			consume_food()
		else:
			$Inventory.backpack_sound()
		return false
	if item.name.matchn("Soda*") :
		GameData.world.detroy_object(item)
		$Inventory.store(item_id,item)
		if life_points<50 and energy<50:
			consume_soda()
		else:
			$Inventory.backpack_sound()
		return false
	if item.name.matchn("Map*") :
		Utils.play_sound($Voice,mhm,-10)
		GameData.world.detroy_object(item)
		$Inventory.store(item_id,item)
		return false
	return .collide_item(item)

func collide_actor(actor:Node2D)->bool:
	if pushed_thing==actor:return false
	if actor.name.matchn("Enemy*"):
		if !cool_down and GameFuncs.are_in_hit_distance(self,actor):
			_animator.trigger_anim("chop")
			Utils.timer(0.5).connect("timeout",actor,"hit",[self,5])
			loseEnergy(ENERGY_LOSED_ON_CHOP)
			start_cool_down(0.5)
		return true
	if  ( actor.is_actor(GameEnums.ACTORS.ANY_RUNNER) ):
		if actor.speed!=0:
			return actor.current_dir!=current_dir
		if actor.push_to(self,current_dir):
			pushed_thing=actor
			var pushspeed=actor.run_speed
			if actor.walk_on_push:pushspeed=actor.walk_speed
			if pushspeed>run_speed:
				Utils.timer(0.1).connect("timeout",self,"goto",[position,current_dir])
			else:
				forced_speed=pushspeed*0.95
				Utils.timer(0.2).connect("timeout",self,"goto",[position,current_dir,forced_speed])
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
		energy=max_energy
	else:
		energy=min(max_energy,energy+50)
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

func goto(from:Vector2,dir:Vector2,fspeed:int=-1):
	#dbgmsg("asked to go %s"%dir)
	if !(is_alive() and taken_exit.empty()):return
	if GameFuncs.grid_pos(from)!=GameFuncs.grid_pos(position):return
	if pushed_thing:
		var calc_dir= GameFuncs.grid_pos(pushed_thing.position)-GameFuncs.grid_pos(from)
		if calc_dir!=dir: return
	if fspeed>0:forced_speed=fspeed
	.goto(from,dir)

func idle():
	if is_alive():
		_animator.trigger_anim("idle")
		.idle()
