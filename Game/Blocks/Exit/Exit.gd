extends "res://Game/BaseScripts/Block.gd"

signal exit_fullfilled

export(int) var needed_god_signs:=0


var opened:=false
var fullfilled:=false

onready var label=$Message/Label

func _ready() -> void:
	$AnimationPlayer.play("init")

func use_in_place(who:Node2D)->bool:
	if fullfilled:
		$AnimationPlayer.play("fullfilled")
	else:
		if who.is_actor(GameEnums.ACTORS.ANY_PLAYER):
			if who.inventory().god_signs>0:
				var consumed=min(who.inventory().god_signs,needed_god_signs)
				who.inventory().god_signs-=consumed
				needed_god_signs-=consumed
				GameData.world.update_indicators()
			if needed_god_signs==0:
				fullfilled=true
				$AnimationPlayer.play("fullfilled")
				$ExitFullFilled.emitting=true
				emit_signal("exit_fullfilled")
				return true
			else:
				label.text="%s Symbol(s)"%needed_god_signs
				label.show()
				$TextTimer.start()
	return false
	
func hide_text():
	label.hide()

func is_fullfilled():
	return fullfilled

func open():
	print("%s is opening"%name)
	if ($AnimationPlayer.is_playing() 
		and $AnimationPlayer.current_animation=="opening"):return 
	$AnimationPlayer.play("opening")
	opened=true

func step_on(who:Node2D):
	return opened and who.is_actor(GameEnums.ACTORS.ANY_PLAYER)

func is_block(block:int=-1)->bool:
	return ( .is_block(block)
			or GameEnums.BLOCKS.EXIT==block )
	
func capabilities()->Array:
	var capas=.capabilities()
	if opened:
		capas.append(GameEnums.CAPABILITIES.STEP_ON)
	else:
		capas.append(GameEnums.CAPABILITIES.USE_IN_PLACE)
	return capas
