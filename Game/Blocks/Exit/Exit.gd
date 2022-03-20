extends Block
class_name Exit

export(int) var needed_god_signs:=0

const STAIRS_FRAME:=25

var is_open:=false

func use_in_place(who:Node2D)->bool:
	if is_open:
		return false
	else:
		if who.is_actor(GameEnums.ACTORS.ANY_PLAYER):
			if who.inventory().god_signs>=needed_god_signs:
				who.inventory().god_signs-=needed_god_signs
				$Sprite.frame=STAIRS_FRAME
				is_open=true
				return true
	return false

func step_on(who:Node2D):
	return is_open and who.is_actor(GameEnums.ACTORS.ANY_PLAYER)

func is_block(block:int=-1)->bool:
	return ( .is_block(block)
			or GameEnums.BLOCKS.EXIT==block )
	
func capabilities()->Array:
	var capas=.capabilities()
	if is_open:
		capas.append(GameEnums.CAPABILITIES.STEP_ON)
	else:
		capas.append(GameEnums.CAPABILITIES.USE_IN_PLACE)
	return capas
