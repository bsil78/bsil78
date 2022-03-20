extends Node

#protected values
var stopBtns:Dictionary
var walk:Dictionary
var last_pressed:={}
var connected_player:Node2D	
var debug:=DEBUG.OFF
var last_time_mouve_moved:int=0

	
func _ready():
	walk={"up":[Vector2.UP,$WalkUpBtn],"right":[Vector2.RIGHT,$WalkRightBtn],"left":[Vector2.LEFT,$WalkLeftBtn],"down":[Vector2.DOWN,$WalkDownBtn]}
	stopBtns={$StopBtn:"pressed",$WalkRightBtn:"button_up",$WalkLeftBtn:"button_up",$WalkUpBtn:"button_up",$WalkDownBtn:"button_up"}
	
func _physics_process(_delta):
	if  last_time_mouve_moved+5<OS.get_unix_time() :
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		
	var player=GameData.current_player	
	if player:
		if player!=connected_player:
			if connected_player:
				$HitBtn.disconnect("pressed",connected_player,"hit")
				$ChopBtn.disconnect("pressed",connected_player,"chop")
				disconnect_stop()
				disconnect_walk()
			connected_player=player
			$HitBtn.connect("pressed",connected_player,"hit")
			$ChopBtn.connect("pressed",connected_player,"chop")
			connect_stop()
			connect_walk()

func disconnect_stop():
	for btn in stopBtns:
		btn.disconnect(stopBtns[btn],connected_player,"stop")

func disconnect_walk():
	for dir in walk:
		var tabdir=walk[dir]
		var btn=tabdir[1]
		btn.disconnect("button_down",connected_player,"goto")

func connect_stop():
	for btn in stopBtns:
		btn.connect(stopBtns[btn],connected_player,"stop")

func connect_walk():
	for dir in walk:
		var tabdir=walk[dir]
		var vect=tabdir[0]
		var btn=tabdir[1]
		btn.connect("button_down",connected_player,"goto",[vect])


func speedup():
	if connected_player:
		connected_player.speedup()
		return true
	return false

func speeddown():
	if connected_player:
		connected_player.speeddown()
		return true
	return false

func goto(dir:Vector2):
	if connected_player:
		connected_player.goto(dir)
		return true
	return false
	
func stop():
	if connected_player:
		connected_player.stop()
		return true
	return false				
	

func _input(event):
	if event is InputEventMouseMotion:
		if (event as InputEventMouseMotion).speed>Vector2.ZERO:
			last_time_mouve_moved=OS.get_unix_time()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if pressed(event,"ui_speedup"):
		speedup()
		return
	
	if released(event,"ui_speedup"):
		speeddown()
		return
	
	for dir in walk:
		if pressed(event,"ui_"+dir):
			if goto(walk[dir][0]):
				last_pressed[connected_player]=dir
			return
		if released(event,"ui_"+dir):
			if connected_player and last_pressed.has(connected_player) and last_pressed[connected_player]==dir:
				if stop():last_pressed.erase(connected_player)
			return

func pressed(event,action):
	if not event is InputEventKey: return
	if event.is_action_pressed(action):
		if(debug):debug.push("Pressed "+event.as_text())
		return true
	return false
	
func released(event,action):
	if not event is InputEventKey: return
	if event.is_action_released(action):
		if(debug):debug.push("Released "+event.as_text())
		return true
	return false		


func run_toggled(button_pressed):
	if button_pressed:
		speedup()
	else:
		speeddown()


func torch_toggled(button_pressed):
	if button_pressed:
		GameData.current_player.use_torch()
	else:
		GameData.current_player.lose_torch()


func _on_Run_gui_input(event:InputEvent):
	if event.is_action_pressed("ui_speedup"):
		$Run.pressed=true
	if event.is_action_released("ui_speedup"):
		$Run.pressed=false
