extends Node2D

var itself:Node2D=self
var alive=true
var debug:=DEBUG.ON
var freezed:=false

func _init(itself:Node2D=self):
	self.itself=itself

func is_alive()->bool:
	return alive
	
func alive():
	alive=true

func dead():
	alive=false

func freeze():
	print("%s freezed" % itself.name)
	freezed=true
	itself.set_physics_process(false)
	itself.set_process(false)

func unfreeze():
	freezed=false
	print("%s unfreezed" % itself.name)
	itself.set_physics_process(true)
	itself.set_process(true)
	
func remove_from_level_objects()->bool:
	return !GameData.world.level.remove_object(itself).empty() 

func push_to(who:Node2D,dir:Vector2)->bool:
	return false
	
func hit(from:Node2D,amount:int)->bool:
	if alive:
		if(debug):debug.push("{} was hit by {} for {} points",[itself.name,from.name,amount])
		return true
	else:
		return false

func pickup(who:Node2D)->bool:
	return false

func use_in_place(who:Node2D)->bool:
	return false

func step_on(who:Node2D)->bool:
	return false
	
func capabilities()->Array:
	return []

func is_actor(actor:int=-1)->bool:
	return false

func is_item(item:int=-1)->bool:
	return false

func is_block(block:int=-1)->bool:
	return false

func remove_from_world():
	print("removing %s from world" % itself.name)
	var parent=itself.get_parent()
	alive=false
	freeze()	
	remove_from_level_objects()
	itself.position=Vector2(-999,-999)
	if parent: parent.remove_child(itself)
	itself.remove_from_game()
	
func remove_from_game():
	Utils.timer(0.5).connect("timeout",itself,"queue_free")
