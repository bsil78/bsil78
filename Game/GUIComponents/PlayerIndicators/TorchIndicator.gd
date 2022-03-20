extends Node2D

func _ready():
	visible=false

func _on_TorchUpdateTimer_timeout() -> void:
	if (GameData.current_player and 
		GameData.current_player.torch() and
		GameData.current_player.torch().is_flammed()):
			$ConsumingDelay.max_value=GameData.current_player.torch().max_delay
			var delay=GameData.current_player.torch().remaing_time()
			$ConsumingDelay.value=delay
			$Countdown.text="{} s".format([int(delay/5)*5],"{}")
			visible=true
	else:
		visible=false
