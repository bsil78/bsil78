extends Pickable
class_name GodSignBad

func pickup(who)->bool:
	CLASS.check(who,"Actor")
	if who.is_actor(GameEnums.ACTORS.ANY_PLAYER):
		who.lose_torch()
		remove_from_world()
		return true
	else:
		return false

func is_item(item:int=-1):
	return ( .is_item(item) 
	or GameEnums.ITEMS.ANY_GOD_SIGN==item
	or GameEnums.ITEMS.GOD_SIGN_BAD==item 
	)
