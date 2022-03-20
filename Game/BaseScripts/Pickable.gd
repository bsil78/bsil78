extends Item
class_name Pickable

func capabilities()->Array:
	var base=.capabilities()
	base.append(GameEnums.CAPABILITIES.PICKUP)
	return base
	
func pickup(who:Node2D)->bool:
	return true

func is_item(item:int=-1)->bool:
	return item==-1
