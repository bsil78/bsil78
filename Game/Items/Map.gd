extends "res://Game/BaseScripts/Pickable.gd"


func _ready() -> void:
	$Parts.hide()


var my_parts=[]
func parts()->Array:
	if my_parts.empty():
		my_parts=$Parts.get_used_cells()
	return my_parts

func pickup(who)->bool:
	if .pickup(who):
		if(who.inventory().store(GameEnums.ITEMS.MAP,self)):
			remove_from_world()
			GameData.world.update_indicators()
			return true
	return false
	
func remove_from_world():
	dbgmsg("is removing itself from world")
	var parent=itself.get_parent()
	alive=false
	freeze()	
	remove_from_level_objects()
	itself.position=Vector2(-999,-999)
	if parent: parent.remove_child(itself)
	
func is_item(item:=-1)->bool:
	return .is_item(item) or GameEnums.ITEMS.MAP==item

