extends Node2D

var itself:Node2D=self
var alive=true
var frozen:=false

export(bool) var debug:=false
var messages:=[]

func _init(the_self:Node2D=self):
	self.itself=the_self

func dbgmsg(msg,error:bool=false):
	if(itself.debug):
		itself.messages.push_back(msg)
		if itself.messages.size()>10: itself.messages.pop_front()
		var scene_frame=itself.get_tree().get_frame() if itself.is_inside_tree() else "NOT_IN_TREE"
		var formated_msg="[%s] %s %s" % [scene_frame,itself.name,msg]
		if error:
			DEBUG.error(formated_msg)
		else:
			DEBUG.push(formated_msg)

func is_alive()->bool:
	return alive
	
func make_alive():
	alive=true

func dead():
	alive=false

func freeze():
	if !frozen:
		dbgmsg("frozen")
		frozen=true
		itself.set_physics_process(false)
		itself.set_process(false)
	else:
		dbgmsg("already frozen [PHI_PS : %s, PS : %s]"%[itself.is_physics_processing(),itself.is_processing()])
		
func unfreeze():
	if frozen:
		dbgmsg("no more frozen")
		frozen=false
		itself.set_physics_process(true)
		itself.set_process(true)
	else:
		dbgmsg("already not frozen [PHI_PS : %s, PS : %s]"%[itself.is_physics_processing(),itself.is_processing()])
	
func remove_from_level_objects():
	GameData.world.level.remove_object(itself)

func push_to(_who:Node2D,_dir:Vector2)->bool:
	return GameEnums.BEHAVIORS.PUSH in itself.behaviors()
	
func hit(from:Node2D,amount:int)->bool:
	if alive and GameEnums.BEHAVIORS.HIT in itself.behaviors() and itself.can_be_hit_by(from):
		dbgmsg("was hit by %s for %s points"%[from.name,amount])
		return true
	else:
		return false

func can_be_hit_by(from:Node2D)->bool:
	return false

func destroy(from:Node2D,remove_instantly:bool=true)->bool:
	if alive and GameEnums.BEHAVIORS.CAN_BE_DESTROYED in itself.behaviors():
		alive=false
		dbgmsg("was destroyed by %s"%from.name)
		if remove_instantly:remove_from_world()
		return true
	else:
		return false

func pickup(_who:Node2D)->bool:
	return GameEnums.BEHAVIORS.PICKUP in itself.behaviors()

func use_in_place(_who:Node2D)->bool:
	return GameEnums.BEHAVIORS.USE_IN_PLACE in itself.behaviors()

func step_on(_who:Node2D)->bool:
	return GameEnums.BEHAVIORS.STEP_ON in itself.behaviors()
	
func behaviors()->Array:
	return [GameEnums.BEHAVIORS.CAN_BE_DESTROYED]

func is_actor(_actor:int=-1)->bool:
	return false

func is_item(_item:int=-1)->bool:
	return false

func is_block(_block:int=-1)->bool:
	return false

func remove_from_world():
	dbgmsg("is removing itself from world")
	var parent=itself.get_parent()
	alive=false
	freeze()	
	remove_from_level_objects()
	itself.position=Vector2(-999,-999)
	if parent: parent.remove_child(itself)
	itself.remove_from_game()
	
func remove_from_game():
	Utils.timer(0.5).connect("timeout",itself,"queue_free")

func type_id()->int:
	return -1
