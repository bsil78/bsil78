extends CanvasLayer

var dirs:Dictionary
var last_pressed:String
export(NodePath) var controler
var controler_instance:Node2D
export(bool) var debug:=false


	
# Called when the node enters the scene tree for the first time.
func _ready():
	var scene=get_node("/root/World")
	assert(scene!=null)
	controler_instance=get_node(controler)
	assert(controler_instance!=null)
	dirs={"up":[Vector2.UP,$WalkUpBtn],"right":[Vector2.RIGHT,$WalkRightBtn],"left":[Vector2.LEFT,$WalkLeftBtn],"down":[Vector2.DOWN,$WalkDownBtn]}
	$HitBtn.connect("pressed",controler_instance,"trigger_anim",["hit"])
	$ChopBtn.connect("pressed",controler_instance,"trigger_anim",["chop"])
	connect_stop({$StopBtn:"pressed",$WalkRightBtn:"button_up",$WalkLeftBtn:"button_up",$WalkUpBtn:"button_up",$WalkDownBtn:"button_up"})
	connect_walk()


func connect_stop(dic_btn):
	for btn in dic_btn:
		btn.connect(dic_btn[btn],controler_instance,"trigger_anim",["walk","stop"])

func connect_walk():
	for dir in dirs:
		var tabdir=dirs[dir]
		var vect=tabdir[0]
		var btn=tabdir[1]
		btn.connect("button_down",controler_instance,"trigger_anim",["walk","goto",vect])


func _input(event):
	if pressed(event,"ui_speedup"):
		controler_instance.controlled_node().speedup()
		return
	
	if released(event,"ui_speedup"):
		controler_instance.controlled_node().speeddown()
		return
		
	
	for dir in dirs:
		if pressed(event,"ui_"+dir):
			controler_instance.trigger_anim("walk","goto",dirs[dir][0])
			last_pressed=dir
			return
		if released(event,"ui_"+dir):
			if last_pressed==dir:
				controler_instance.trigger_anim("walk","stop")
			return

func pressed(event,action):
	if event.is_action_pressed(action):
		if(debug):print("Pressed "+event.as_text())
		return true
	return false
	
func released(event,action):
	if event.is_action_released(action):
		if(debug):print("Released "+event.as_text())
		return true
	return false		


func _on_CheckButton_toggled(button_pressed):
	if button_pressed:
		controler_instance.controlled_node().speedup()
	else:
		controler_instance.controlled_node().speeddown()
