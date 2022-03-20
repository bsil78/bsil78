extends Thing
class_name Item

func capabilities()->Array:
	return [GameEnums.CAPABILITIES.STEP_ON]

func step_on(who:Node2D)->bool:
	return true

func is_item(item:int=-1)->bool:
	return item==-1
