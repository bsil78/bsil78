extends Node

export(bool) var active
export(bool) var console
export(bool) var panel
export(bool) var objects

func _process(_delta):
	DEBUG.active=active
	DEBUG.console=console	
	DEBUG.panel=panel
	DEBUG.objects=objects	
