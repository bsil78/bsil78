tool
extends Node2D

var torch_timer:Timer
export(bool) var flamming:=false setget set_flamming
export(int) var TORCH_DELAY_SEC:=120
var max_delay:float=TORCH_DELAY_SEC

func _ready():
	if !flamming:
		shutdown(torch_timer)

func set_flamming(value:bool):
	if is_instance_valid($Light):
		if value:
			flamme_it()
		else:
			shutdown(torch_timer)

func is_flammed()->bool:
	return flamming

func remaing_time()->float:
	if torch_timer:
		return torch_timer.time_left
	else:
		return 0.0

func max_delay()->float:
	return max_delay

func queue_free():
	shutdown(torch_timer)
	.queue_free()

func freeze():
	if torch_timer:
		torch_timer.stop()

func unfreeze():
	if torch_timer:
		torch_timer.start()

func shutdown(timer:Timer=null):
	var aTimer:Timer=timer
	if aTimer==null:aTimer=torch_timer
	if(torch_timer==aTimer):
		flamming=false
		visible=false
		$Light.visible=false		
		$Flammes.emitting=false
		torch_timer=null
	if aTimer:
		aTimer.stop()
		aTimer.queue_free()	

func flamme_it():
	if torch_timer: 
		DEBUG.error("Torch already flamming !")
		return
	flamming=true
	visible=true
	$Light.visible=true		
	$Flammes.emitting=true
	var delay=TORCH_DELAY_SEC
	max_delay*=randfpct(20)
	torch_timer=Timer.new()
	add_child(torch_timer)
	torch_timer.connect("timeout",self,"shutdown",[torch_timer])
	torch_timer.start(max_delay)

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
	$Wand.visible=false
	$Flammes.visible=false
	
func visuals_visible():
	$Wand.visible=true
	$Flammes.visible=true
