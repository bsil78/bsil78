extends Node

#protected values
var stopBtns:Dictionary
var walk:Dictionary
var connected_player:Node2D	
var debug:=DEBUG.OFF
var last_time_mouve_moved:int=0
var backpack:Node
var playergodsign:Node
var players_last_dir:={}
var world

func _ready():
	$TextureRect.hide()
	walk={"up":[Vector2.UP,$WalkUpBtn],"right":[Vector2.RIGHT,$WalkRightBtn],"left":[Vector2.LEFT,$WalkLeftBtn],"down":[Vector2.DOWN,$WalkDownBtn]}
	stopBtns={$WalkRightBtn:"button_up",$WalkLeftBtn:"button_up",$WalkUpBtn:"button_up",$WalkDownBtn:"button_up"}
	Input.set_use_accumulated_input(false)
	
	
			
func _physics_process(_delta):
	if  last_time_mouve_moved+5<OS.get_unix_time() :
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
#	capture_active_player()
	manage_input_of_connected_player()
	
func connect_to_world(world):
	print("connecting input to world..")
	self.world=world
	GameFuncs.connect("players_switched",self,"capture_active_player")
	world.connect("ready",self,"capture_active_player")
	
func capture_active_player():
	print("capturing active player")
	var active_player=GameData.current_player	
	if !active_player:
		connected_player=null
		return
	#else
	
	if active_player!=connected_player:
		if connected_player:
			disconnect_stop()
			disconnect_walk()
			disconnect_inventory()
		connected_player=active_player
		connect_stop()
		connect_walk()
		connect_inventory()
		adjust_speed($Run.pressed)
			
		
			
func manage_input_of_connected_player():
	if !connected_player: return
	var dir=players_last_dir.get(connected_player)
	var dirx=0
	var diry=0
	if Input.is_action_pressed("ui_down"):diry+=1
	if Input.is_action_pressed("ui_up"):diry-=1
	if Input.is_action_pressed("ui_left"):dirx-=1
	if Input.is_action_pressed("ui_right"):dirx+=1
	if dirx*diry!=0:#both are set ?? nullify one
		if Utils.chance(50):
			dirx=0
		else:
			diry=0
	if dirx==0 and diry==0: # no dir ?
		if dir:
			goto(dir)
		else:
			if connected_player.next_dir!=Vector2.ZERO:stop()
	else: # goto dir !
		goto(Vector2(dirx,diry))

func disconnect_inventory():
	world.get_node("PlayerIndicators").disconnect_inventory(connected_player)
	
func connect_inventory():
	world.get_node("PlayerIndicators").connect_inventory(connected_player)

func disconnect_stop():
	for btn in stopBtns:
		btn.disconnect(stopBtns[btn],self,"stop")

func disconnect_walk():
	for dir in walk:
		var tabdir=walk[dir]
		var btn=tabdir[1]
		btn.disconnect("button_down",self,"direction")

func connect_stop():
	for btn in stopBtns:
		btn.connect(stopBtns[btn],self,"stop")

func connect_walk():
	for dir in walk:
		var tabdir=walk[dir]
		var vect=tabdir[0]
		var btn=tabdir[1]
		btn.connect("button_down",self,"direction",[vect])


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
#	print("Goto %s"%dir)
	if connected_player:
		connected_player.goto(connected_player.position,dir)
		return true
	return false
	
func stop():
	if connected_player:
		connected_player.stop()
		players_last_dir.erase(connected_player)
		return true
	return false				
	

func _input(event):
	if event is InputEventMouseMotion:
		if (event as InputEventMouseMotion).speed>Vector2.ZERO:
			last_time_mouve_moved=OS.get_unix_time()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return
	
	if Utils.pressed(event,"ui_speedup"):
		adjust_speed(!$Run.pressed)
		return
	
	if Utils.released(event,"ui_speedup"):
		adjust_speed($Run.pressed)
		return
		
	if Utils.pressed(event,"ui_switch"):
		GameFuncs.change_active_player()
		return

func adjust_speed(should_run:bool):
	if !should_run:
		speeddown()
	else:
		speedup()
	
func run_toggled(button_pressed):
	if button_pressed:
		speedup()
	else:
		speeddown()

func direction(dir:Vector2):
	players_last_dir[connected_player]=dir

func torch_toggled(button_pressed):
	if button_pressed:
		GameData.current_player.use_torch()
	else:
		GameData.current_player.lose_torch()

