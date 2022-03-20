extends Node

export(bool) var active
export(bool) var console
export(bool) var panel
export(bool) var objects
export(bool) var debuglevel

func _ready():
	update_debug()
	
	
func update_debug():
	DEBUG.active=active
	DEBUG.console=console	
	DEBUG.panel=panel
	DEBUG.objects=objects
	DEBUG.debuglevel=debuglevel	
	GameData.max_levels=1
	
