extends TextureRect

func _ready() -> void:
	$Count.text=""

func update_indicator(world=null):
	var level
	if world==null:
		if !GameData.world:
			$Count.text=""
			return
		else:
			level=GameData.world.level
	else:
		level=world.level
	if level:
		$Count.text="%s +[%s]" % [ 	level.remaining_good_godsigns_items(),
									level.remaining_good_godsigns_blocks() ]
	else:
		$Count.text=""	


	
