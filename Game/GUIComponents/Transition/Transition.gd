extends CanvasLayer

const menu_scene:="res://Game/GUIComponents/Menu/Menu.tscn"
const world_scene:="res://Game/GameScenes/World/World.tscn"
const gameOverPattern := "Vous êtes mort\n%s\naprès %s jour%s."
var fading_in := true
var waiting_fading_in := false

onready var text=$Canvas/Center/Text

func _ready():
	var pluralDays := "s"
	if GameData.current_level==1:
			pluralDays=""
	match GameData.transition_state:
		GameEnums.TRANSITION_STATUS.MENU:
			text.text_to_use = "Je terminé...\n\nretour au menu"
		GameEnums.TRANSITION_STATUS.WIN_GAME:
			text.text_to_use = "B R A V O !\nVous avez réussi à sortir\naprès %s jour%s !" % [GameData.current_level, pluralDays]
		GameEnums.TRANSITION_STATUS.LEVEL_UP:
			text.text_to_use = "Jour %s" % GameData.current_level
		GameEnums.TRANSITION_STATUS.DEAD_HUNGRY:
			text.text_to_use = gameOverPattern % [ "épuisé", GameData.current_level, pluralDays]
		GameEnums.TRANSITION_STATUS.DEAD_TIRED:
			text.text_to_use = gameOverPattern % ["de blessures",GameData.current_level, pluralDays]
	text.center_text()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	change_scene()

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

