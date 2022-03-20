extends "res://Game/BaseScripts/Pickable.gd"

func pickup(who)->bool:
	if .pickup(who):
		var would_consume=(who.life_points<50 and who.energy<50)
		who.inventory().store(GameEnums.ITEMS.JAR,self,!would_consume)
		remove_from_world()
		if would_consume:who.consume_jar()
		GameData.world.update_indicators()
		return true
	return false

func is_item(item:=-1)->bool:
	return .is_item(item) or GameEnums.ITEMS.JAR==item
