extends CanvasLayer

onready var pauseMenu=$PauseMenuControlsRoot
onready var items=$PauseMenuControlsRoot/ItemsContainer

func _input(event):
	var input:=Utils.input_from_event(event)

	if input.key_pressed==KEY_ESCAPE or input.pad_button==JOY_START:
		get_tree().paused=!get_tree().paused
		if get_tree().paused:
			pauseMenu.show()
		else:
			pauseMenu.hide()
	if input.key_pressed in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE] or input.pad_button==JOY_XBOX_A:
		match items.cur_pos:
			items.CONTINUE_LEVEL:
				quit_pause_menu()
			items.QUIT_WHOLE_GAME:
				quit_pause_menu()
				Utils.quit_from(self)
			items.QUIT_TO_MAIN:
				GameData.transition_state=GameEnums.TRANSITION_STATUS.MENU
				GameFuncs.transition()
				quit_pause_menu()
		return

#		GameData.transition_state=GameEnums.TRANSITION_STATUS.MENU
#		GameFuncs.transition()

func quit_pause_menu():
	pauseMenu.hide()
	Utils.quit_pause_from(self)
