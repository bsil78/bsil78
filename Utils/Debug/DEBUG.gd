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
		
func pushif(condition:bool,message:String,args:Array=[]):
	if condition: push(message,args)

func pushfor(message:String,args:Array=[]):
	if forobj:
		push(message.format([forobj.name],"{?}"),args)

func push(message:String,args:Array=[]):
	if active:
		var msg=message.format(args,"{}")
		if console:print(msg)
		messages.push_back(msg)
		if(messages.size()>20):
			messages.pop_front()

func error(message:String,args:Array=[]):
	push_error(message.format(args,"{}"))
	push(message,args)
	

func format(message:String,args:Array):
	var msg:String=message
	for arg in args:
		var first:=msg.find("{}")
		if first>-1:
			msg.erase(first,2)
			msg=msg.insert(first,arg)
	return msg
