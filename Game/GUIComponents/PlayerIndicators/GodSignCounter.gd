extends TextureRect

func update():
	if ( is_instance_valid(GameData.current_player) 
		and is_instance_valid(GameData.world) 
		and is_instance_valid(GameData.world.level) ):
		$Count.text="%s/%s" % [ GameData.current_player.inventory().god_signs,
								GameData.world.level.remaining_good_godsigns() ]
	else:
		$Count.text="?/?"
