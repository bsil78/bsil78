extends CanvasLayer


const gameOverPattern := "Vous êtes mort\n%s\naprès %s jour%s."
var fading_in := true
var changing_scene := false
var waiting_fading_in := false

onready var text=$Canvas/Center/Text

func _ready():
	var pluralDays := "s"
	if GameData.current_level==1:
			pluralDays=""
	match GameData.transition_state:
		GameEnums.TRANSITION_STATUS.WIN_GAME:
			text.text_to_use = "B R A V O !\nVous avez réussi à sortir\naprès %s jour%s !" % [GameData.current_level, pluralDays]
		GameEnums.TRANSITION_STATUS.LEVEL_UP:
			text.text_to_use = "Jour %s" % GameData.current_level
		GameEnums.TRANSITION_STATUS.DEAD_HUNGRY:
			text.text_to_use = gameOverPattern % [ "de faim ou de fatigue", GameData.current_level, pluralDays]
		GameEnums.TRANSITION_STATUS.DEAD_TIRED:
			text.text_to_use = gameOverPattern % ["de blessures",GameData.current_level, pluralDays]
	text.center_text()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _process(_delta):
	if !changing_scene:
		changing_scene=true
		change_scene()
		
func change_scene():
	if GameData.current_level==1 or GameData.transition_state==GameEnums.TRANSITION_STATUS.WIN_GAME:
		Utils.timer(GameData.long_transition_delay).connect("timeout",self,"do_transition")
	else:
		Utils.timer(GameData.short_transition_delay).connect("timeout",self,"do_transition")

func do_transition():
	if GameData.transition_state==GameEnums.TRANSITION_STATUS.LEVEL_UP:
		CommonUI.fade_transition_scene("res://Game/GameScenes/World/World.tscn")
	else:
		CommonUI.fade_transition_scene("res://Game/GUIComponents/Menu/Menu.tscn")

