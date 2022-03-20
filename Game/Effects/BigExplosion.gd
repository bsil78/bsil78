extends Node2D

# warning-ignore:unused_signal
signal center_started
# warning-ignore:unused_signal
signal center_ending
signal sides_exploding
signal explosion_finished

var ran_once=false
export(bool) var debug:=false
export(bool) var vertical:=true
export(bool) var horizontal:=true

var sound=preload("res://Game/Assets/Audio/ogg/effects/Hansjörg-Malthaner (@httpopengameart.orgusersvarkalandar) hjm-big_explosion_3.ogg")

func explode_with_sides():
	if !(horizontal or vertical): 
		explode()
		return
	if ran_once:
		printerr("Explosion instance already ran")
		return
	ran_once=true
	self.connect("center_started",self,"emit_sides",[true])
	self.connect("center_ending",self,"end_sides")
	emit_sides(false)
	emit_center(false)
	play_center_explosion()
	
func end_sides():
	emit_sides(false)
	self.disconnect("center_started",self,"emit_sides")
	self.disconnect("center_ending",self,"end_sides")

func emit_sides(value):
	if value:
		print("%s emit sides at %s"%[name,OS.get_unix_time()])
		emit_signal("sides_exploding")
	if horizontal:
		$ToRight.emitting=value
		$ToLeft.emitting=value
	if vertical:
		$ToUp.emitting=value
		$ToDown.emitting=value
	
func emit_center(value):
	if value:print("%s starts at %s"%[name,OS.get_unix_time()])
	$Center.emitting=value
	$Center/Light2D.show()
	
func explode():
	if ran_once:
		printerr("Explosion instance already ran")
		return
	#print_debug("Big Explosion !!!! (%s)"%name)
	ran_once=true
	play_center_explosion()
	
func play_center_explosion():
	Utils.timer(0.5).connect("timeout",self,"emit_signal",["center_started"])
	Utils.timer(1.0).connect("timeout",self,"emit_signal",["center_ending"])
	Utils.timer(1.5).connect("timeout",self,"end_explosion")
	emit_center(true)
	randomize()
	yield(Utils.timer(rand_range(0.0,0.2)),"timeout")
	Utils.play_sound($AudioStreamPlayer,sound,rand_range(-5,+5),rand_range(-5,+5))

func end_explosion():
	print("%s ends at %s"%[name,OS.get_unix_time()])
	emit_center(false)
	$Center/Light2D.hide()
	emit_signal("explosion_finished")
	queue_free()

#for test purpose
func _input(event: InputEvent) -> void:
	if debug:
		$Camera2D.show()
		$Camera2D.make_current()		
		if event is InputEventKey:
			var key=(event as InputEventKey)
			if key.is_action_pressed("ui_down"):
				explode()
			if key.is_action_pressed("ui_up"):
				explode_with_sides()
