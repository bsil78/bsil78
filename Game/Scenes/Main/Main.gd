extends "res://Base/World/LevelLoader.gd"



# Called when the node enters the scene tree for the first time.
func _ready():
	if GameData.currentLevel<1:
		print("Current level must be at least 1")
		Utils.quit(1)	
