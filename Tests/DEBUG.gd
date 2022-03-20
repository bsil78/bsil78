extends Node

var messages:=[]

func _ready():
	pass

func info(message):
	print(message)
	messages.push_back(message)
	if(messages.size()>20):
		messages.pop_front()
