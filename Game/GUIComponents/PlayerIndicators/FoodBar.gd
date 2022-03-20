extends ProgressBar

func _process(_delta):
	if GameData.current_player:
		max_value=GameData.current_player.max_food_points
		value=GameData.current_player.food_points
	else:
		max_value=100
		value=100
