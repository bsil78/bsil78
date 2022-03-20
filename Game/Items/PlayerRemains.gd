extends "res://Game/BaseScripts/Item.gd"

func step_on(_who:Node2D)->bool:
	if _who.is_actor(GameEnums.ACTORS.ANY_PLAYER):
		var item_count:int
		var remaining:int
		item_count=$Inventory.ankh
		remaining=give(_who,GameEnums.ITEMS.ANKH,null,item_count)
		$Inventory.ankh=remaining
		
		item_count=$Inventory.jar
		remaining=give(_who,GameEnums.ITEMS.JAR,null,item_count)
		$Inventory.jar=remaining
		
		item_count=$Inventory.food
		remaining=give(_who,GameEnums.ITEMS.FOOD,null,item_count)
		$Inventory.food=remaining
		
		item_count=$Inventory.torch
		remaining=give(_who,GameEnums.ITEMS.TORCH,null,item_count)
		$Inventory.torch=remaining
		
		item_count=$Inventory.god_signs
		remaining=give(_who,GameEnums.ITEMS.GOD_SIGN_GOOD,null,item_count)
		$Inventory.god_signs=remaining
		
		for iLvl in $Inventory.maps:
			var maps_to_remove=[]
			var lvlMaps=$Inventory.maps[iLvl]
			for map in lvlMaps:
				if give(_who,GameEnums.ITEMS.MAP,map,1)==0:
					maps_to_remove.append(map)
			for map in maps_to_remove:
				lvlMaps.remove(lvlMaps.find(map))
				
		$Inventory.god_signs=remaining
		_who.inventory().update()
	return true
			
func give(_who:Node2D,item_id,item_node,count)->int:
	var remaining=count
	if count>0:
		for i in range(0,count):
			if _who.inventory().store(item_id,item_node):
				remaining-=1
			else:
				break
	return remaining
	
func is_item(item:=-1)->bool:
	return .is_item(item) or GameEnums.ITEMS.PLAYER_REMAINS==item

func can_be_hit_by(_from)->bool:
	return false

func behaviors()->Array:
	var bhvs:=.behaviors().duplicate(true)
	bhvs.erase(GameEnums.BEHAVIORS.CAN_BE_DESTROYED)
	bhvs.erase(GameEnums.BEHAVIORS.HIT)
	return bhvs
