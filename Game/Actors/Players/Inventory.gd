extends Node2D
class_name Inventory

#signals
signal inventory_changed
	
var sodas:=0
var food:=0
var medkit:=0
var torch:=1
var god_signs:=0
var maps:={}

export(AudioStream) var backpack

func store(item:int,item_node:Node2D):
	backpack_sound()
	match item:
		GameEnums.ITEMS.GOD_SIGN_GOOD:
			god_signs+=1
			update()
			return
		GameEnums.ITEMS.SODA:
			sodas+=1
			update()
			return
		GameEnums.ITEMS.FOOD:
			food+=1
			update()
			return
		GameEnums.ITEMS.MEDKIT:
			medkit+=1
			update()
			return
		GameEnums.ITEMS.TORCH:
			torch+=1
			update()
			return
		GameEnums.ITEMS.MAP:
			if !maps.has(GameData.current_level):maps[GameData.current_level]=[]
			maps[GameData.current_level].push_back(item_node)
			update()
			return
		_:
			printerr("Unknown item %s of name %s" % [item,item_node.name])
			
func use(item:int):
	match item:
		GameEnums.ITEMS.SODA:
			if sodas>0:
				sodas-=1
				update()
				return true
		GameEnums.ITEMS.FOOD:
			if food>0:
				food-=1
				update()
				return true
		GameEnums.ITEMS.MEDKIT:
			if medkit>0:
				medkit-=1
				update()
				return true
		GameEnums.ITEMS.TORCH:
			if torch>0:
				torch-=1
				update()
				return true
		GameEnums.ITEMS.MAP:
			return false
		_:
			printerr("Unknown item %s to use" % [item])
	
	return false

func update():
	emit_signal("inventory_changed")
		
func backpack_sound():
	Utils.play_sound($SoundsEffects,backpack,-10)
