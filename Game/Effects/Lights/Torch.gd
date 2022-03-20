tool
extends Node2D

export(bool) var flamming:=false setget set_flamming
export(int) var TORCH_DELAY_SEC:=120
var max_delay:float=TORCH_DELAY_SEC

func _ready():
	shutdown()

func set_flamming(value:bool):
	if is_instance_valid($Light):
		if value:
			flamme_it()
		else:
			shutdown()

func is_flammed()->bool:
	return flamming

func remaing_time()->float:
	return $Timer.time_left

func max_delay()->float:
	return max_delay

func queue_free():
	$Timer.stop()
	shutdown()
	.queue_free()

func freeze():
	$Timer.paused=true

func unfreeze():
	$Timer.paused=false

func shutdown():
	flamming=false
	hide()
	$Light.hide()		
	$Flammes.emitting=false
	$Timer.stop()

func flamme_it():
	if !$Timer.is_stopped():
		DEBUG.error("Torch already flamming !")
		return
	$Timer.paused=false
	flamming=true
	show()
	$Light.show()	
	$Flammes.emitting=true
	var delay=TORCH_DELAY_SEC
	max_delay*=randfpct(20)
	$Timer.start(max_delay)

func randfpct(pct:int=50)->float:
	var marge=(pct/2.0)/100.0
	return ((1.0-marge)+(randf()/(100.0/pct)))
	
func flip(flip:bool):
	var posfact=1
	if flip:posfact=-1
	position.x=abs(position.x)*posfact
	$Wand.flip_h=flip
	$Wand.position.x=abs($Wand.position.x)*posfact
	$Light.position.x=-1*position.x
	$Flammes.position.x=abs($Flammes.position.x)*posfact

func visuals_hidden():
	$Wand.hide()
	$Flammes.hide()
	
func visuals_visible():
	$Wand.show()
	$Flammes.show()
