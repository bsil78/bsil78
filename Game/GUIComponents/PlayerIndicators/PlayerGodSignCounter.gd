extends TextureRect

func _ready()->void:
	$Count.text="?"

func update_indicator(player)->void:
	$Count.text="%s" % player.inventory().god_signs
		
