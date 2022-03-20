extends CanvasLayer

onready var animation_player = $AnimationPlayer

signal UI_faded_in
signal UI_faded_out

func fade_transition_scene(scene:String):
	fade_out()
	yield(self,"UI_faded_out")
	change_scene(scene)
	fade_in()
	yield(self,"UI_faded_in")

func fade_out():
	$FadePanel.visible = true
	animation_player.play("FadeOut")
	#InputSystem.disable_input_until(animation_player, "animation_finished")
	yield(animation_player, "animation_finished")
	emit_signal("UI_faded_out")
	
func fade_in():
	animation_player.play("FadeIn")
	#InputSystem.disable_input_until(animation_player, "animation_finished")
	yield(animation_player, "animation_finished")
	$FadePanel.visible = false
	emit_signal("UI_faded_in")

func change_scene(scene:String):
	var pckscn:=load(scene) as PackedScene
	var err=get_tree().change_scene_to(pckscn)
	if err!=OK:
		printerr("Error while changing scene to "+scene)
		Utils.quit_from(self,-1)

	
