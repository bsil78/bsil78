extends "res://Game/BaseScripts/SolidBlock.gd"

signal exit_fullfilled

export(int) var needed_god_signs:=1

var opened:=false
var fullfilled:=false

var fullfilled_sound=preload("res://Game/Assets/Audio/ogg/effects/door_opening.ogg")
var opening_sound=preload("res://Game/Assets/Audio/ogg/effects/rock_moving.ogg")
var error_sound=preload("res://Game/Assets/Audio/ogg/effects/error.ogg")

var should_be_open:=false

onready var label=$Message/Label

func _ready() -> void:
	$AnimationPlayer.play("init")
	$AnimationPlayer.connect("animation_finished",self,"update_state")

func use_in_place(who:Node2D)->bool:
	if !.use_in_place(who): return false
	if !who.is_actor(GameEnums.ACTORS.ANY_PLAYER):return false
	if !fullfilled:	
		var gave_some:=somehow_fullfill(who)
		if needed_god_signs==0:
			$AnimationPlayer.play("fullfilled")
			$ExitFullFilled.emitting=true
			Utils.play_sound($AudioStreamPlayer,fullfilled_sound)
		else:
			label.text="%s Symbol(s)"%needed_god_signs
			label.show()
			$TextTimer.start()
			Utils.play_sound($AudioStreamPlayer,error_sound)
		return gave_some
	else:
		$AnimationPlayer.play("fullfilled")
		return false

func somehow_fullfill(who)->bool:
	if who.inventory().god_signs<1: return false
	var consumed=min(who.inventory().god_signs,needed_god_signs)
	who.inventory().god_signs-=consumed
	needed_god_signs-=consumed
	GameData.world.update_indicators()
	return true
		

func update_state(ended_anim):
	if ended_anim=="fullfilled":
		dbgmsg("is fullfilled")
		fullfilled=true
		emit_signal("exit_fullfilled")
		if should_be_open:open()
		return
	if ended_anim=="opening":
		dbgmsg("is open")
		opened=true
		return

func hide_text():
	label.hide()

func is_fullfilled():
	return fullfilled

func open():
	dbgmsg("is opening")
	if $AnimationPlayer.is_playing():
		dbgmsg("already playing opening anim %s"%$AnimationPlayer.current_animation,true)
		should_be_open=true
		return 
	$AnimationPlayer.play("opening")
	Utils.play_sound($AudioStreamPlayer,opening_sound)	

func step_on(who:Node2D):
	if !.step_on(who): return
	var ok:bool=opened and who.is_actor(GameEnums.ACTORS.ANY_PLAYER)
	if ok: dbgmsg("is stepped on by %s"%who.name)
	return ok

func is_block(block:int=-1)->bool:
	return ( .is_block(block)
			or GameEnums.BLOCKS.EXIT==block )
	
func behaviors()->Array:
	var bhvs:=[]
	if opened:
		bhvs.append(GameEnums.BEHAVIORS.STEP_ON)
	elif !fullfilled:
		bhvs.append(GameEnums.BEHAVIORS.USE_IN_PLACE)
	return bhvs
