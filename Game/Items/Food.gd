extends "res://Game/BaseScripts/Pickable.gd"

func pickup(who)->bool:
	if .pickup(who):
		if who.energy<10:
			who.consume_food()
		else:
			if(who.inventory().store(GameEnums.ITEMS.FOOD,self)):
				remove_from_world()
		GameData.world.update_indicators()
		return true
	return false

func is_item(item:=-1)->bool:
	return .is_item(item) or GameEnums.ITEMS.FOOD==item
