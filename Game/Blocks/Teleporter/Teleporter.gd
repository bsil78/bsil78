extends "res://Game/BaseScripts/SolidBlock.gd"

signal teleporter_activated

enum { IDLE,ACTIVATED,THROWING_BACK,RECEIVING }
export(int) var teleporter_id
export(int) var teleporter_target

var state = IDLE

var current_sound=null
var activator=null

var activation_sound=preload("res://Game/Assets/Audio/ogg/effects/teleport.ogg")
var error_sound=preload("res://Game/Assets/Audio/ogg/effects/error.ogg")

func _ready() -> void:
	$AnimationPlayer.play("idle")
	$AudioStreamPlayer.autoplay=false
	$AudioStreamPlayer.stop()
	GameFuncs.connect("players_switched",self,"manage_volume")
	Utils.timer(0.2).connect("timeout",self,"deal_with_position")
	Utils.timer(0.2).connect("timeout",self,"connect_to_level")

func connect_to_level():
	var level=find_parent("Level*")
	if level:
		level.connect_teleporter(self)
	else:
		print_debug("Cannot find parent level node...")
	
func receive(from_teleport,player):
	dbgmsg("receiving player %s"%player.name)
	state=RECEIVING
	$AnimationPlayer.play("activated")
	if player.teleportTo(position):
		from_teleport.disactivate()
		current_sound=Utils.play_sound($AudioStreamPlayer)
		if available_position(player): 
			Utils.timer(0.5).connect("timeout",self,"let_player_move",[player])
			return
	#else throw player back
	Utils.play_sound($AudioStreamPlayer,error_sound)
	from_teleport.throw_back(player)		
	disactivate()

func let_player_move(player):
	player.can_move=true

func available_position(player)->bool:
	for dir in GameEnums.DIRS_MAP:
		var obstacles=player.detect_obstacles(player.next_pos(dir))
		if obstacles.get(GameEnums.OBJECT_TYPE.ACTOR): continue #: not free
		if obstacles.get("WALL"): continue #: not free
		var block=obstacles.get(GameEnums.OBJECT_TYPE.BLOCK)
		if is_free_of_block(dir,block):return true
		#continue : not free 
	return false

func is_free_of_block(dir,block)->bool:
	if block:
		print("dir %s has block %s"%[dir,block.name])
		if GameFuncs.is_block(block,[GameEnums.BLOCKS.FAKE_WALL,GameEnums.BLOCKS.TELEPORTER]):
			return true
		elif block.is_block(GameEnums.BLOCKS.EXIT) and block.is_open():
			return true
		elif block.is_block(GameEnums.BLOCKS.FORCE_FIELD):
			if dir in [Vector2.UP,Vector2.DOWN] and !block.horizontal:return true
			if dir in [Vector2.LEFT,Vector2.RIGHT] and block.horizontal:return true
		print("blocking teleport")
		return false
	else:
		print("no block at dir %s"%dir)
		return true
	

func throw_back(player):
	state=THROWING_BACK
	$AnimationPlayer.play("activated")
	stop_sound()
	current_sound=Utils.play_sound($AudioStreamPlayer)
	player.teleportTo(position)
	Utils.timer(0.5).connect("timeout",self,"let_player_move",[player])

func step_on(who:Node2D)->bool:
	if !.step_on(who) or !who.is_actor(GameEnums.ACTORS.ANY_PLAYER): return false
	dbgmsg("is stepped on by %s"%who.name)
	return true

func teleport(who:Node2D):
	$AnimationPlayer.play("activated")
	state=ACTIVATED
	who.can_move=false
	Utils.timer(0.5).connect("timeout",self,"emit_signal",["teleporter_activated",self,teleporter_target,who])

func disactivate():
	state=IDLE
	$AnimationPlayer.play("idle")
	stop_sound()

func is_block(block:int=-1)->bool:
	return ( .is_block(block)
			or GameEnums.BLOCKS.TELEPORTER==block )
	
func behaviors()->Array:
	var bhvs:=[]
	if state==IDLE:
		bhvs.append(GameEnums.BEHAVIORS.STEP_ON)
	return bhvs

func _on_Area2D_body_entered(body: Node) -> void:
	dbgmsg("detected entry of %s"%body.name)
	if !body.is_actor(GameEnums.ACTORS.ANY_PLAYER):return
	activator=body as Node2D
	activator.torch_should_be_visible=false
	stop_sound()
	current_sound=Utils.play_sound($AudioStreamPlayer)

func _on_Area2D_body_exited(body: Node) -> void:
	if state in [ RECEIVING, THROWING_BACK ]:
		dbgmsg("detected exit of %s"%body.name)
		if !body.is_actor(GameEnums.ACTORS.ANY_PLAYER):return
		body.torch_should_be_visible=true
		disactivate()

func stop_sound():
	if !current_sound:
		print("current sound is null")
		return
	var tween_vol:Tween=Tween.new()
	tween_vol.interpolate_property(current_sound,"volume_db",current_sound.volume_db,-60.0,1.0,Tween.EASE_IN,Tween.EASE_IN_OUT)
	tween_vol.connect("tween_all_completed",self,"destroy_sound",[current_sound])
	current_sound.add_child(tween_vol)
	tween_vol.start()
	current_sound=null
	
func destroy_sound(sound):
	dbgmsg("destroying sound %s of vol %s"%[sound.name,sound.volume_db])
	sound.stop()

func manage_volume():
	dbgmsg("manage volume on player switch")
	if !current_sound:return
	if GameData.current_player!=activator:
		current_sound.volume_db=-30
		dbgmsg("lowered sound vol for %s")
	else:
		current_sound.volume_db=0
		dbgmsg("raised sound vol for %s")
		
func deal_with_position() -> void:
	$CanvasLayer/BordersActivated.global_position=global_position
