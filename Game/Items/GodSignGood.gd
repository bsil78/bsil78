extends "res://Game/BaseScripts/Pickable.gd"

func pickup(who:Node2D)->bool:
	if .pickup(who):
		if who.inventory().store(GameEnums.ITEMS.GOD_SIGN_GOOD,self):
			Utils.play_sound($GoodGodSignTakenSound)
			GameData.world.play_coin_gain_for(who)
			remove_from_world()
			return true
	return false

func is_item(item:int=-1):
	return ( .is_item(item) 
	or GameEnums.ITEMS.ANY_GOD_SIGN==item
	or GameEnums.ITEMS.GOD_SIGN_GOOD==item 
	)

func remove_from_world():
	self.connect("tree_exited",GameData.world,"update_indicators")
	.remove_from_world()
	
