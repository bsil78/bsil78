extends Node2D
class_name Inventory

#signals
signal inventory_changed
	
var jar:=0
var food:=0
var ankh:=0
var torch:=1
var god_signs:=0
var maps:={}

export(AudioStream) var backpack

func store(item:int,item_node:Node2D,backpack_play_sound:bool=true)->bool:
	var taken:=false
	
	match item:
		GameEnums.ITEMS.GOD_SIGN_GOOD:
			god_signs+=1
			update()
			taken= true
		GameEnums.ITEMS.JAR:
			jar+=1
			update()
			taken= true
		GameEnums.ITEMS.FOOD:
			food+=1
			update()
			taken= true
		GameEnums.ITEMS.ANKH:
			ankh+=1
			update()
			taken= true
		GameEnums.ITEMS.TORCH:
			torch+=1
			update()
			taken= true
		GameEnums.ITEMS.MAP:
			if !maps.has(GameData.current_level):maps[GameData.current_level]=[]
			maps[GameData.current_level].push_back(item_node)
			update()
			taken= true
		_:
			printerr("Unknown item %s of name %s" % [item,item_node.name])
			taken= false
	if taken and backpack_play_sound:backpack_sound()
	return taken

func duplicate(flags:int=6):
	var new_inv=.duplicate(DUPLICATE_GROUPS+DUPLICATE_SCRIPTS)
	new_inv.jar=jar
	new_inv.ankh=ankh
	new_inv.food=food
	new_inv.torch=torch
	new_inv.god_signs=god_signs
	new_inv.maps=maps.duplicate(true)
	return new_inv
	


func reset():
	jar=0
	food=0
	ankh=0
	torch=1
	god_signs=0
	maps={}
				
func use(item:int):
	match item:
		GameEnums.ITEMS.JAR:
			if jar>0:
				jar-=1
				update()
				return true
		GameEnums.ITEMS.FOOD:
			if food>0:
				food-=1
				update()
				return true
		GameEnums.ITEMS.ANKH:
			if ankh>0:
				ankh-=1
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
	if backpack:Utils.play_sound($SoundsEffects,backpack,-10)
