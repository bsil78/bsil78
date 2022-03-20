extends CanvasLayer

const gameOverPattern := "Vous êtes mort\n%s\naprès %s jour%s."
var fading_in := true
var changing_scene := false
var waiting_fading_in := false

onready var text=$Canvas/Center/Text

func _ready():
	var pluralDays := "s"
	if GameData.currentLevel==1:
			pluralDays=""
	match GameData.transition_state:
		GameEnums.TRANSITION_STATUS.LEVEL_UP:
			text.text_to_use = "Jour %s" % GameData.currentLevel
		GameEnums.TRANSITION_STATUS.DEAD_HUNGRY:
			text.text_to_use = gameOverPattern % [ "de faim", GameData.currentLevel, pluralDays]
		GameEnums.TRANSITION_STATUS.DEAD_TIRED:
			text.text_to_use = gameOverPattern % ["de fatigue ou de blessures",GameData.currentLevel, pluralDays]
	text.center_text()	

# Called when the node enters the scene tree for the first time.
func _process(_delta):
	if !changing_scene:
		changing_scene=true
		change_scene()
		
		
func change_scene():
	if GameData.currentLevel==1:
		yield(get_tree().create_timer(7.0),"timeout")
		#Utils.yield_time(7.0)
	else:
		yield(get_tree().create_timer(4.0),"timeout")
		#Utils.yield_time(4.0)
	if GameData.transition_state==GameEnums.TRANSITION_STATUS.LEVEL_UP:
		CommonUI.fade_transition_scene("res://Game/Scenes/Main/Main.tscn")
	else:
		CommonUI.fade_transition_scene("res://Game/Scenes/Menu/Menu.tscn")

