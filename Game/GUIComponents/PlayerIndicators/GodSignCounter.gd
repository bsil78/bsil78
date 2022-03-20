extends TextureRect

func _ready() -> void:
	$Count.text="? +[?]"

func update_indicator(world):
	var level=world.level
	$Count.text="%s +[%s]" % [ 	level.remaining_good_godsigns_items(),
								level.remaining_good_godsigns_blocks() ]
		


	
