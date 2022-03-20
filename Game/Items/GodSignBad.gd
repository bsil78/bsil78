extends "res://Game/BaseScripts/Pickable.gd"

func pickup(who:Node2D)->bool:
	if .pickup(who):
		who.lose_torch()
		Utils.play_sound($BadGodSignTakenSound)
		remove_from_world()
		return true
	else:
		return false

func is_item(item:int=-1):
	return ( .is_item(item) 
	or GameEnums.ITEMS.ANY_GOD_SIGN==item
	or GameEnums.ITEMS.GOD_SIGN_BAD==item 
	)
