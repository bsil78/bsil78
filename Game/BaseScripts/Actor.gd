extends KinematicBody2D

#GameData managed values :
var cell_size:=10
var ground_friction:=0.5


#exposed values
export(int,8,256,8) var run_speed:=128
export(int,8,128,8) var walk_speed:=32
export(int,0,1000,10) var max_life_points:=100
export(int,0,1000,10) var life_points:=100

export(GameEnums.FLIP) var onLeftFlip:=GameEnums.FLIP.H
export(GameEnums.FLIP) var onRightFlip:=GameEnums.FLIP.NONE
export(GameEnums.FLIP) var onUpFlip:=GameEnums.FLIP.NONE
export(GameEnums.FLIP) var onDownFlip:=GameEnums.FLIP.NONE
export(GameEnums.FLIP) var onIdleFlip:=GameEnums.FLIP.NONE

export(NodePath) var animator
export(NodePath) var raycast


#protected values
const NONE:=Vector2.ZERO
var Thing:=preload("res://Game/BaseScripts/Thing.gd").new(self)
var speed:=0
var max_speed:=walk_speed
var target_pos:=NONE
var next_dir:=NONE
var current_dir:=NONE
var last_pos:Vector2

var _animator:Node2D

var _raycast:RayCast2D

var debug:=DEBUG.ON

func _ready():
	#init GameData managed values
	cell_size=GameData.cell_size
	ground_friction=GameData.ground_friction
	_animator=get_node(animator)
	_raycast=get_node(raycast)

func _physics_process(delta):
	if $ObjectDebug: $ObjectDebug.message="LP: %s\n" % life_points
	if !Thing.freezed and is_alive():
		if !was_killed():
			if !manage_movement(delta):
				idle_if_possible()
		
func was_killed()->bool:
	if $ObjectDebug: $ObjectDebug.message+="testing if was killed"
	if life_points<=0:
		print("%s killed" % name)
		killed()
		return true
	return false

func idle_if_possible():
	if next_dir==NONE and current_dir==NONE:idle()

func manage_movement(delta)->bool:
	adjust_current_dir()
	adjust_facing()
	find_target_pos()
	if (target_pos!=NONE):
		adjust_speed()
		move(delta)
		return true
	else:
		return false	

func hit(from:Node2D,amount:int=1)->bool:
	if Thing.hit(from,amount):
		if life_points>0:
			life_points=max(life_points-amount,0)
			return true
	return false

func dead():
	Thing.dead()
	if(debug):debug.push("{} is dying and alive is {}",[name,is_alive()])
	remove_from_world()

func killed():
	if(debug):debug.push("%s killed" % name)
	dead()
	
func idle():
	speed=0
	target_pos=NONE
	current_dir=NONE
	next_dir=NONE

func is_actor(actor:int=-1)->bool:
	return actor==-1

func is_item(item:int)->bool:
	return false

func is_block(block:int)->bool:
	return false

func freeze():
	Thing.freeze()

func unfreeze():
	Thing.unfreeze()

func remove_from_world():
	Thing.remove_from_world()

func remove_from_game():
	Thing.remove_from_game()
	
func move(delta):
	if (!is_alive() or speed==0): return
	var path=target_pos-position
	var distance=path.length()
	var delta_move:Vector2=path.normalized()*(speed*delta) 
	var delta_len=delta_move.length()
	if( delta_len>cell_size 
		or delta_len>distance
		or distance<1.0		
		):
		delta_move=Vector2(round(path.x),round(path.y))
		position=target_pos #jump precisely
		target_pos=NONE #should find new target
		current_dir=NONE #and a new current dir
		speed=0
		
	var _collision=move_and_collide(delta_move)
	
	if current_dir==NONE:
		on_moved(last_pos,position)
	else:
		on_moving(last_pos,target_pos)
	
func adjust_facing(dir:Vector2=NONE,with_moving:bool=true):
	if with_moving:
		if dir!=NONE:current_dir=dir
		if current_dir!=NONE or onIdleFlip!=GameEnums.FLIP.KEEP:
			fliph(flip(current_dir,GameEnums.FLIP.H))
			flipv(flip(current_dir,GameEnums.FLIP.V))
	else:
		fliph(flip(dir,GameEnums.FLIP.H))
		flipv(flip(dir,GameEnums.FLIP.V))

func fliph(flip:bool):
	if _animator.get_visual().flip_h!=flip:
		_animator.get_visual().flip_h = flip

func flipv(flip:bool):
	if _animator.get_visual().flip_v!=flip:
		_animator.get_visual().flip_v = flip
	
func flip(dir:Vector2,flip_type:int)->bool:
	if flip_type!=GameEnums.FLIP.H and flip_type!=GameEnums.FLIP.V:
		if(debug):debug.error("flip type not supported")
		return false
	var flipProp=onIdleFlip
	match dir:
		Vector2.LEFT:
			flipProp=onLeftFlip
		Vector2.RIGHT:
			flipProp=onRightFlip
		Vector2.UP:
			flipProp=onUpFlip
		Vector2.DOWN:
			flipProp=onDownFlip
	if flipProp==GameEnums.FLIP.KEEP:
		if flip_type==GameEnums.FLIP.H:
			return _animator.get_visual().flip_h
		if flip_type==GameEnums.FLIP.V:
			return _animator.get_visual().flip_v	
	return flipProp==flip_type or flipProp==GameEnums.FLIP.BOTH
		
func adjust_current_dir():
	if next_dir!=NONE and current_dir==NONE:
		current_dir=next_dir

func find_target_pos():
	if target_pos!=NONE: return
	if current_dir!=NONE and target_pos==NONE and !can_go(next_pos_from(fixedgrid(),current_dir)) :
		target_pos=NONE
		next_dir=NONE
		current_dir=NONE
		return



func can_go(next_pos:Vector2)->bool:
	if is_something(next_pos):return false
	last_pos=fixedgrid()
	on_move(last_pos,next_pos)
	target_pos=next_pos
	return true

func on_move(from:Vector2,to:Vector2):
	add_as_blocker(to)
	
func next_pos(dir:Vector2)->Vector2:
	return position+dir*cell_size
	
func next_pos_from(pos:Vector2,dir:Vector2)->Vector2:
	var next_pos=pos+dir*cell_size	
	#print("next pos to %s from %s is %s" % [dir,pos,next_pos])
	return next_pos
		
# warning-ignore:unused_argument
func on_moving(from:Vector2,to:Vector2):
	if global_position.distance_to(to)<(cell_size/2):
		if GameData.world.level.objects_at(from).has(GameEnums.OBJECT_TYPE.ACTOR):
			if GameData.world.level.objects_at(from)[GameEnums.OBJECT_TYPE.ACTOR]==self:
				GameData.world.level.remove_object_at(from,GameEnums.OBJECT_TYPE.ACTOR) # remove self blocking old cell

func on_moved(from:Vector2,to:Vector2):
	if Thing.remove_from_level_objects():
		if not GameData.world.level.add_object(self):
			if(debug):
				debug.error("{} cannot add itself to {}",[name,GameFuncs.grid_pos(position)])
				print_debug(GameData.world.level.objects)
	elif(debug):
		debug.error("{} cannot be removed from {}",[name,GameFuncs.grid_pos(position)])
		print_debug(GameData.world.level.objects)
	current_dir=NONE
	target_pos=NONE
	last_pos=position

func push_to(who:Node2D,dir:Vector2)->bool:
	return Thing.push_to(who,dir)

func use_in_place(who:Node2D)->bool:
	return Thing.use_in_place(who)
	
func pickup(who:Node2D)->bool:
	return Thing.pickup(who)
	
func capabilities()->Array:
	var capas=Thing.capabilities()
	capas.append(GameEnums.CAPABILITIES.HIT)
	return capas

func add_as_blocker(pos:Vector2):
	if not GameData.world.level.add_object_at(self,pos):
		if(debug):debug.error("{} cannot block pos {}",[name,GameFuncs.grid_pos(pos)])

func is_alive()->bool:
	return Thing.is_alive()


func alive():
	Thing.alive()

func on_wall_collision(wall_pos:Vector2,collider:Node2D)->bool:
	return true

func on_collision(other:Dictionary)->bool:
	return true

func is_something(at:Vector2)->bool:
	return detect_walls(at) or detect_things(at) 
	
func detect_things(at:Vector2)->bool:
	var answer:=false
	var objects:Dictionary=GameData.world.level.objects_at(at)
	if !objects.empty():
		answer=  on_collision(objects)
	return answer

func detect_walls(at:Vector2)->bool:
	_raycast.cast_to=to_local(at)
	_raycast.force_raycast_update()
	var collider=_raycast.get_collider() as Node2D
	var wallcollision = collider and collider.name.matchn("*wall*")
	if !wallcollision:
		return false
	else:
		return on_wall_collision(at,collider)
	
func fixedgrid():
	return Vector2(16+round((position.x-16)/cell_size)*cell_size,16+round((position.y-16)/cell_size)*cell_size)

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
	#if $ObjectDebug: $ObjectDebug.message="Going to :\n{dir}".format({"dir":dir})
	next_dir=dir
	
func stop():
	next_dir=NONE
	
func speedup():
	max_speed=run_speed

func speeddown():
	max_speed=walk_speed

