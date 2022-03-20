extends ProgressBar

func _on_EnergyBarUpdateTimer_timeout() -> void:
	if GameData.current_player:
		max_value=GameData.current_player.max_energy
		value=GameData.current_player.energy
	else:
		max_value=100
		value=100
