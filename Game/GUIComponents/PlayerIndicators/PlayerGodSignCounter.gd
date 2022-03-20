extends TextureRect

func _ready()->void:
	$Count.text=""

func update_indicator(player=null)->void:
	var inv
	if player==null:
		if GameData.current_player==null:
			$Count.text=""
			return
		else:
			inv=GameData.current_player.inventory()
	else:
		inv=player.inventory()
	if inv:
		$Count.text="%s" % inv.god_signs
	else:
		$Count.text=""
