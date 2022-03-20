extends ProgressBar

func _on_LifeBarUpdateTimer_timeout() -> void:
	if GameData.current_player:
		max_value=GameData.current_player.max_life_points
		value=GameData.current_player.life_points
	else:
		max_value=100
		value=100
