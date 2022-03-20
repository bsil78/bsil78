extends CanvasLayer

const menu_scene:="res://Game/GUIComponents/Menu/Menu.tscn"
const world_scene:="res://Game/GameScenes/World/World.tscn"

var fading_in := true
var waiting_fading_in := false

onready var text=$Canvas/Center/Text

func _ready():
	var gameOverPattern := tr("DEAD_AFTER")
	var previous_level:=GameData.current_level-1
	match GameData.transition_state:
		GameEnums.TRANSITION_STATUS.MENU:
			text.text_to_use = tr("GAME_OVER")
		GameEnums.TRANSITION_STATUS.WIN_GAME:
			text.text_to_use = tr("GAME_WON") % [previous_level, pluralDays(previous_level)]
		GameEnums.TRANSITION_STATUS.LEVEL_UP:
			text.text_to_use = tr("ENTER_LEVEL") % GameData.current_level
		GameEnums.TRANSITION_STATUS.DEAD_HUNGRY:
			text.text_to_use = gameOverPattern % [ tr("OF_NO_ENERGY"), previous_level, pluralDays(previous_level)]
		GameEnums.TRANSITION_STATUS.DEAD_TIRED:
			text.text_to_use = gameOverPattern % [ tr("OF_NO_LIFE"), previous_level, pluralDays(previous_level)]
	text.center_text()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	change_scene()

func pluralDays(level):
	return "" if level==1 else "s"
			

func change_scene():
	var delay:=GameData.short_transition_delay
	if (GameData.current_level==1 
		or GameData.transition_state==GameEnums.TRANSITION_STATUS.WIN_GAME):
			delay=GameData.long_transition_delay
	Utils.timer(delay).connect("timeout",self,"do_transition")
	
func do_transition():
	var next_scene=menu_scene
	if GameData.transition_state==GameEnums.TRANSITION_STATUS.LEVEL_UP: next_scene=world_scene
	CommonUI.fade_transition_scene(next_scene)

