extends Node2D

const Overworld:=preload("res://Base/World/Overworld.gd")

onready var overworld:= get_parent() as Overworld

enum CELL_TYPES { ACTOR, OBJECT }
export(CELL_TYPES) var obj_type = CELL_TYPES.OBJECT

func do_what_this_object_does():
	print(name, " is an OverworldObject that doesn't do anything.")


# An object can specify its condition for being preent in the scene by defining
# this method. By default, if an actor is present in the editor, it will be
# present in game.
func spawn_condition()->bool:
	return true
	
func remove_from_world():
	print(name+" is removing itself from world")
	overworld.remove_from_active(self)
