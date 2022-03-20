extends KinematicBody2D

export(float,0.1,1,0.1) var ground_friction:=0.1
export(int,8,64,8) var grid_size:=32
export(int,8,256,8) var run_speed:=128
export(int,8,128,8) var walk_speed:=32
export(int,10,40,1) var level_size:=40

var speed:=0
var target_pos:Vector2
var max_speed:=walk_speed
var next_dir:=Vector2.ZERO
var current_dir:=Vector2.ZERO

export(bool) var debug:=false


func _ready():
	$Camera2D.limit_left=-9*grid_size
	$Camera2D.limit_top=-9*grid_size
	$Camera2D.limit_right=(level_size+9)*grid_size
	$Camera2D.limit_bottom=(level_size+9)*grid_size
	#$RayCast2D.cast_to=Vector2(grid_size,0)
	#$RayCast2D.get_collider()

const NONE:=Vector2.ZERO

func _physics_process(delta):
	adjust_current_dir()
	find_target_pos()
	adjust_facing()
	var moved:=false
	if (target_pos!=NONE):
		adjust_speed()
		move(delta)
		moved=true
	if !moved and !$Controler.isanim("idle") and next_dir==NONE and current_dir==NONE:
		speed=0
		target_pos=NONE
		$Controler.trigger_anim("idle")	
			
	
func move(delta):
	if (speed==0): return
	var path=target_pos-position
	var distance=path.length()
	var delta_move:Vector2=path.normalized()*(speed*delta) 
	var delta_len=delta_move.length()
	if(
		delta_len>grid_size 
		or delta_len>distance
		or distance<1.0		
	):
		delta_move=Vector2(round(path.x),round(path.y))
		position=target_pos #jump precisely
		target_pos=Vector2.ZERO #should find new target
		current_dir=NONE #and a new current dir
	var _dismiss=move_and_collide(delta_move)

func adjust_facing():
	if current_dir==Vector2.RIGHT:
		$AnimatedSprite.flip_h=false
	elif current_dir==Vector2.LEFT:
		$AnimatedSprite.flip_h=true		

func adjust_current_dir():
	if next_dir!=NONE and current_dir==NONE:
		current_dir=next_dir
		

func find_target_pos():
	var collision:Node2D
	if next_dir!=NONE and target_pos==NONE:
		var caster=next_dir*grid_size
		$RayCast2D.cast_to=caster;
		$RayCast2D.force_raycast_update()
		collision=$RayCast2D.get_collider()
	if(collision):
		target_pos=NONE
		next_dir=NONE
		current_dir=NONE
		return
	if current_dir==NONE or target_pos!=NONE:
		return
	target_pos=fixedgrid()+(current_dir*grid_size)

func fixedgrid():
	return Vector2(16+round((position.x-16)/grid_size)*grid_size,16+round((position.y-16)/grid_size)*grid_size)

func adjust_speed():
	if current_dir==NONE:
		if speed>0:
			speed=lerp(speed,0,ground_friction)
		if abs(speed)<1.0:speed=0
	else:
		if speed<max_speed:
			speed=lerp(speed,max_speed,ground_friction)
		if abs(speed-max_speed)<1.0:speed=max_speed
	
		
func goto(dir:Vector2):
	next_dir=dir
	
	
func stop():
	next_dir=NONE
	
func speedup():
	max_speed=run_speed

func speeddown():
	max_speed=walk_speed
