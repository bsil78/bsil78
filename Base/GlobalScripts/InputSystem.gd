extends Node

var input_direction
var input_activation

func _ready():
	# Do not disable this when game is paused
	set_pause_mode(PAUSE_MODE_PROCESS)


func _process(_delta):
	input_direction = get_input_direction()
	input_activation = get_input_activation()


func get_input_direction():
	var horizontal = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	var vertical = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	return Vector2(horizontal, vertical if horizontal == 0 else 0)

func actor_process_input(actor):
	if InputSystem.input_activation:
		if actor.has_method("activate_object"):
			actor.activate_object()
	elif InputSystem.input_direction:
		if actor.has_method("target_position"):
			actor.target_position(InputSystem.input_direction)

func get_input_activation():
	return Input.is_action_just_pressed("ui_accept")

func get_quit():
	return Input.is_action_just_pressed("ui_quit")


# Extremely useful for things like stopping "interact" from looping
# E.G. actor displays dialog, "interact" is the same button that closes dialog
# It would also, on the same frame, trigger interact again
func neutralize_inputs():
	input_direction = null
	input_activation = null


# Give other systems the ability to disable ALL input until a given trigger
# Useful for things like letting menu animations or scene transitions finish
func disable_input_until(wait_for_this_object, to_finish_this):
	neutralize_inputs()
	set_process(false)
	yield(wait_for_this_object, to_finish_this)
	set_process(true)


# Just for "game over"
func disable_input():
	neutralize_inputs()
	set_process(false)
