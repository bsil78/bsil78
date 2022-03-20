extends "res://Game/BaseScripts/SolidBlock.gd"

signal exit_fullfilled

export(int) var needed_god_signs:=1

enum ExitState { LOCKED,UNLOCKING,FULLFILLED,BLINKING,OPENING, OPENED } 

var state = ExitState.LOCKED

var fullfilled_sound=preload("res://Game/Assets/Audio/ogg/effects/door_opening.ogg")
var opening_sound=preload("res://Game/Assets/Audio/ogg/effects/rock_moving.ogg")
var error_sound=preload("res://Game/Assets/Audio/ogg/effects/error.ogg")

onready var label=$Message/Label

func _ready() -> void:
	$AnimationPlayer.play("init")
	$AnimationPlayer.connect("animation_finished",self,"update_state")
	Utils.timer(0.2).connect("timeout",self,"connect_to_level")
	
func connect_to_level():
	var level=find_parent("Level*")
	if level:
		level.connect_exit(self)
	else:
		print_debug("Cannot find parent level node...")

func use_in_place(who:Node2D)->bool:
	if !.use_in_place(who): return false
	if !who.is_actor(GameEnums.ACTORS.ANY_PLAYER):return false
	if state==ExitState.LOCKED:	
		var gave_some:=somehow_fullfill(who)
		if needed_god_signs==0:
			state=ExitState.UNLOCKING
			$AnimationPlayer.play("fullfilled")
			$ExitFullFilled.emitting=true
			Utils.play_sound($AudioStreamPlayer,fullfilled_sound)
		else:
			label.text="%s Symbol(s)"%needed_god_signs
			label.show()
			$TextTimer.start()
			Utils.play_sound($AudioStreamPlayer,error_sound)
		return gave_some
	if state==ExitState.FULLFILLED:	
		$AnimationPlayer.play("already_fullfilled")
		state=ExitState.BLINKING
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
		dbgmsg("was fullfilled")
		state=ExitState.FULLFILLED
		emit_signal("exit_fullfilled")
		return
	if ended_anim=="opening":
		dbgmsg("was opened")
		state=ExitState.OPENED
		return
	if ended_anim=="already_fullfilled":
		dbgmsg("refusing")
		state=ExitState.FULLFILLED
		return

func hide_text():
	label.hide()

func is_fullfilled():
	return state==ExitState.FULLFILLED

func is_open():
	return state==ExitState.OPENED

func open():
	if state==ExitState.FULLFILLED:
		dbgmsg("is opening")
		state=ExitState.OPENING
		$AnimationPlayer.play("opening")
		Utils.play_sound($AudioStreamPlayer,opening_sound)

func step_on(who:Node2D)->bool:
	if !.step_on(who) or !who.is_actor(GameEnums.ACTORS.ANY_PLAYER): return false
	dbgmsg("is stepped on by %s"%who.name)
	return true

func is_block(block:int=-1)->bool:
	return ( .is_block(block)
			or GameEnums.BLOCKS.EXIT==block )
	
func behaviors()->Array:
	var bhvs:=[]
	if state==ExitState.OPENED:
		bhvs.append(GameEnums.BEHAVIORS.STEP_ON)
	if state in [ ExitState.FULLFILLED,ExitState.LOCKED]:
		bhvs.append(GameEnums.BEHAVIORS.USE_IN_PLACE)
	return bhvs
