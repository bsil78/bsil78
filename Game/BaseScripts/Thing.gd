extends Node2D
class_name Thing

var itself:Node2D=self
var alive=true
var debug=DEBUG.ON
var frozen:=false

func _init(itself:Node2D=self):
	self.itself=itself
	if itself.debug:
		debug=DEBUG.ON
	else:
		debug=DEBUG.OFF

func is_alive()->bool:
	return alive
	
func alive():
	alive=true

func dead():
	alive=false

func freeze():
	if(debug):debug.push("%s frozen" % itself.name)
	frozen=true
	itself.set_physics_process(false)
	itself.set_process(false)

func unfreeze():
	frozen=false
	if(debug):debug.push("%s not frozen" % itself.name)
	itself.set_physics_process(true)
	itself.set_process(true)
	
func remove_from_level_objects():
	GameData.world.level.remove_object(itself)

func push_to(who,dir)->bool:
	CLASS.check(who,"Actor")
	CLASS.check(dir,"Dir2D")
	return false
	
func hit(from,amount:int)->bool:
	CLASS.check(from,"Thing|Actor")
	if alive:
		if(debug):debug.push("%s was hit by %s for %s points"%[itself.name,from.name,amount])
		return true
	else:
		return false

func grid_pos():
	return CLASS.stic("GridPos","from_Vector2",[itself.position])

func pickup(who)->bool:
	CLASS.check(who,"Actor")
	return false

func use_in_place(who)->bool:
	CLASS.check(who,"Actor")
	return false

func step_on(who)->bool:
	CLASS.check(who,"Actor")
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
	if(debug):debug.push("removing %s from world" % itself.name)
	var parent=itself.get_parent()
	alive=false
	freeze()	
	remove_from_level_objects()
	itself.position=Vector2(-999,-999)
	if parent: parent.remove_child(itself)
	itself.remove_from_game()
	
func remove_from_game():
	Utils.timer(0.5).connect("timeout",itself,"queue_free")
