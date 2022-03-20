extends "res://Game/BaseScripts/Pickable.gd"

func pickup(who)->bool:
	if .pickup(who):
		if who.life_points<50 and who.energy<50:
			who.consume_jar()
		else:
			if(who.inventory().store(GameEnums.ITEMS.JAR,self)):
				remove_from_world()
		GameData.world.update_indicators()
		return true
	return false

func is_item(item:=-1)->bool:
	return .is_item(item) or GameEnums.ITEMS.JAR==item
