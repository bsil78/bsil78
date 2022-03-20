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

var runBtn
var rightBtn
var leftBtn
var upBtn
var downBtn
var design_bkgd
var mouseIsInto=true

var ready:=false

func _ready() -> void:
	get_parent().connect("ready",self,"connect_input_and_gui")	
			
func connect_input_and_gui():
	var ui_buttons_root="../Game_UI_Buttons/%s"
	runBtn=get_node(ui_buttons_root%"Run")
	rightBtn=get_node(ui_buttons_root%"WalkRightBtn")
	leftBtn=get_node(ui_buttons_root%"WalkLeftBtn")
	upBtn=get_node(ui_buttons_root%"WalkUpBtn")
	downBtn=get_node(ui_buttons_root%"WalkDownBtn")
	design_bkgd=get_node(ui_buttons_root%"TextureRect")
	design_bkgd.hide()
	walk={"up":[Vector2.UP,upBtn],"right":[Vector2.RIGHT,rightBtn],"left":[Vector2.LEFT,leftBtn],"down":[Vector2.DOWN,downBtn]}
	stopBtns={upBtn:"button_up",rightBtn:"button_up",leftBtn:"button_up",downBtn:"button_up"}
	Input.set_use_accumulated_input(false)
	ready=true
			
func _physics_process(_delta):
	if !ready:return
	hide_mouse_if_still()
	manage_input_of_connected_player()

func hide_mouse_if_still():
	if last_time_mouve_moved+5<OS.get_unix_time() :
		last_time_mouve_moved=OS.get_unix_time()
		if mouseIsInto:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			Input.warp_mouse_position(Vector2(50,50))
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
func connect_to_world(the_world):
	#print("connecting input to world...")
	self.world=the_world
	GameFuncs.connect("players_switched",self,"capture_active_player")
	the_world.connect("ready",self,"capture_active_player")
	
func capture_active_player():
	#print("capturing active player")
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
		adjust_speed(runBtn.pressed)
			
		
			
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
		if (event as InputEventMouseMotion).speed.length()>4:
			last_time_mouve_moved=OS.get_unix_time()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			#print("setting mouse into")
			mouseIsInto=true
		return
	
	if Utils.pressed(event,"ui_speedup"):
		adjust_speed(!runBtn.pressed)
		return
	
	if Utils.released(event,"ui_speedup"):
		adjust_speed(runBtn.pressed)
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



func _on_MouseTimer_timeout() -> void:
	#print("setting mouse out")
	mouseIsInto=false
