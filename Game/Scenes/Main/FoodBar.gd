extends ProgressBar

func _process(_delta):
	if GameData.player:
		max_value=GameData.player.max_food_points
		value=GameData.player.food_points
	else:
		max_value=100
		value=100
