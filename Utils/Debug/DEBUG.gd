extends Node

var messages:=[]
export(bool) var active
export(bool) var console
export(bool) var panel
export(bool) var objects

var forobj:Node2D

class MockDebug:
	func push(_message):
		pass


var ON:=self
var OFF:=MockDebug.new()

func foris(who:Node2D,mask:String):
	if not (who and mask and who.name.match(mask)):
		forobj=null
		return
	forobj=who
		
func pushif(condition:bool,message:String):
	if condition: push(message)

func pushfor(message:String):
	if forobj:
		push(message.format(forobj.name,"{?}"))

func push(message:String):
	if active:
		if console:print(message)
		messages.push_back(message)
		if(messages.size()>20):
			messages.pop_front()

func error(message:String):
	push_error(message)
	push(message)
	

