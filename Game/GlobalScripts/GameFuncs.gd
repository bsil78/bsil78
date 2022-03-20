extends Node

var music=preload("res://Game/Effects/Music.tscn")

func _ready():
	CommonUI.add_child(music.instance())

func _process(_delta):
	if InputSystem.get_quit():
		Utils.quit(0)


func init_new_game():
	GameData.transition_state=GameEnums.TRANSITION_STATUS.LEVEL_UP
	GameData.currentLevel=GameData.startLevel
	CommonUI.fade_transition_scene("res://Game/Scenes/Transitional/TransitionScene.tscn")
		
