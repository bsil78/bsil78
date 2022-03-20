extends KinematicBody2D
class_name Actor

#signals
signal has_moved

#GameData managed values :
var cell_size:=32
var ground_friction:=0.5


#exposed values
export(int,8,256,8) var run_speed:int
export(int,8,128,8) var walk_speed:int
export(int,0,1000,10) var max_life_points:=100
export(int,0,1000,10) var life_points:=100

export(GameEnums.FLIP) var onLeftFlip:=GameEnums.FLIP.H
export(GameEnums.FLIP) var onRightFlip:=GameEnums.FLIP.NONE
export(GameEnums.FLIP) var onUpFlip:=GameEnums.FLIP.NONE
export(GameEnums.FLIP) var onDownFlip:=GameEnums.FLIP.NONE
export(GameEnums.FLIP) var onIdleFlip:=GameEnums.FLIP.NONE

export(NodePath) var animator
export(NodePath) var tween

#protected values
const NONE:=Vector2.ZERO
var Thing:=preload("res://Game/BaseScripts/Thing.gd").new(self)
var speed:=0
var max_speed:int
var forced_speed:int=0
var target_pos:=NONE
var next_dir:=NONE
var current_dir:=NONE
export(Vector2) var facing:=Vector2.RIGHT
var last_pos:Vector2
var _animator:Node2D
var _tween:Tween
var pushed_thing:Node2D
var last_collision
var cool_down:=false

const ERROR:=true

export(bool) var debug:=false
var messages:=[]

func _ready():
	#init GameData managed values
	cell_size=GameData.cell_size
	ground_friction=GameData.ground_friction
	_animator=get_node(animator) as Node2D
	max_speed=walk_speed
	#_tween=get_node(tween) as Tween

func knockback(hitdir:Vector2):
	match hitdir:
		Vector2.RIGHT:
			_animator.get_visual().position.x+=5
		Vector2.LEFT:
			_animator.get_visual().position.x-=5
		Vector2.DOWN:
			_animator.get_visual().position.y+=5
		Vector2.UP:
			_animator.get_visual().position.y-=5
	yield(Utils.timer(0.2),"timeout")
	_animator.get_visual().position.x=0
	_animator.get_visual().position.y=0
		

func _draw():
	if debug and last_collision:
		draw_string(CommonUI.get_node("DebugPanel/ObjectDebug").font,to_local(last_collision.position)+Vector2(0,-16),last_collision.collider.name,Color.white)
		draw_line(Vector2(),to_local(last_collision.position),Color.red,1.0)

func state_str()->String:
	return ("%s\nglobal pos:%s\ngrid pos:%s\nanim:%s\nLP: %s\nCD:%s\nND:%s\n%s" % [
									name,
									global_position,
									GameFuncs.grid_pos(global_position),
									_animator.getanim(),
									life_points,
									current_dir,
									next_dir,
									GameFuncs.dump(messages)
									])

func _physics_process(delta):
	if debug:update()
	if !Thing.frozen and is_alive():
		if !was_killed():
			if !manage_movement(delta):
				idle_if_possible()
	
func dbgmsg(msg,error:bool=false):
	if(debug):
		messages.push_back(msg)
		if messages.size()>10: messages.pop_front()
		if error:
			DEBUG.error("%s %s" % [name,msg])
		else:
			DEBUG.push("%s %s" % [name,msg])
		
func was_killed()->bool:
	if life_points<=0:
		dbgmsg("killed")
		killed()
		return true
	return false

func idle_if_possible():
	if next_dir==NONE and current_dir==NONE:idle()

func manage_movement(delta)->bool:
	adjust_current_dir()
	adjust_facing()
	find_target_pos()
	if (target_pos):
#		move_to(target_pos)
		adjust_speed()
		move(delta)
		return true
	else:
		return false	

func move_to(_pos=NONE):
	pass

func hit(from:Node2D,amount:int=1)->bool:
	if Thing.hit(from,amount):
		if life_points>0:
			life_points=max(life_points-amount,0)
			knockback(GameFuncs.grid_pos(global_position)-GameFuncs.grid_pos(from.global_position))
			return true
	return false

func dead():
	Thing.dead()
	dbgmsg("is dying and alive is %s"%is_alive())
	remove_from_world()

func killed():
	dbgmsg("killed (base)")
	dead()
	
func idle():
	forced_speed=0
	speed=0
	target_pos=NONE
	current_dir=NONE
	next_dir=NONE

func is_actor(actor:int=-1)->bool:
	return actor==-1

func is_item(item:int=-1)->bool:
	return false

func is_block(block:int=-1)->bool:
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
	if (!is_alive() or speed==0 or current_dir==NONE): 
		dbgmsg("not able to move ! %s/%s/%s"%[is_alive(),speed,current_dir])
		return
	var path=target_pos-position
	var distance=path.length()
	if(distance>cell_size):dbgmsg("distance move too big : %s"%distance,ERROR)
	var delta_move:Vector2=path.normalized()*(speed*delta) 
	var delta_len=delta_move.length()
	#dbgmsg("moving with speed : %s"%speed)
	if( delta_len>cell_size 
		or delta_len>distance
		or distance<1.0		
		):
		delta_move=Vector2(floor(path.x),floor(path.y))
		position=snapped_pos() #jump precisely
		emit_signal("has_moved")
		target_pos=NONE #should find new target
		current_dir=NONE #and a new current dir
		speed=0
		forced_speed=0
	
	if target_pos!=NONE:
		move_and_collide(delta_move,true,true,false)
		emit_signal("has_moved")
		
#		var _collision=move_and_collide(delta_move,false,true,true)
#		var collider:Node2D
#		if _collision:collider=_collision.collider as Node2D
#		if !_collision or GameFuncs.is_item(collider):
#			move_and_collide(delta_move,true,true,false)
#			emit_signal("has_moved")
#		else: # wall or block or actor
#			dbgmsg("colliding %s at speed %s"%[collider.name,speed])
#			move_and_collide(_collision.remainder,true,true,false)
#			#check if we have to stop right now
#			if collider_stop_me(collider):
#				position=snapped_pos()
#				target_pos=NONE #should find new target
#				current_dir=NONE #and a new current dir
#				speed=0
#				forced_speed=0 
#			emit_signal("has_moved")
			
	if current_dir==NONE:
		on_moved(last_pos,position)
	else:
		on_moving(last_pos,target_pos)
	
func collider_stop_me(collider):
	var let_me_continue=( GameFuncs.is_actor(collider) and collider.current_dir==current_dir )
	return not let_me_continue
	
func adjust_facing(dir:Vector2=NONE,with_moving:bool=true):
	if with_moving and dir!=NONE:current_dir=dir
	if current_dir!=NONE or onIdleFlip!=GameEnums.FLIP.KEEP: facing=current_dir
	fliph(flip(facing,GameEnums.FLIP.H))
	flipv(flip(facing,GameEnums.FLIP.V))
		
func fliph(flip:bool):
	if _animator.get_visual().flip_h!=flip:
		_animator.get_visual().flip_h = flip

func flipv(flip:bool):
	if _animator.get_visual().flip_v!=flip:
		_animator.get_visual().flip_v = flip
	
func flip(dir:Vector2,flip_type:int)->bool:
	if flip_type!=GameEnums.FLIP.H and flip_type!=GameEnums.FLIP.V:
		dbgmsg("flip type not supported",ERROR)
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
		next_dir=NONE

func find_target_pos():
	if target_pos!=NONE: return
	if current_dir!=NONE and target_pos==NONE and !can_go(next_pos_from(snapped_pos(),current_dir)) :
		dbgmsg("Cannot go, then rest")
		target_pos=NONE
		next_dir=NONE
		current_dir=NONE
		return

func can_go(my_next_pos:Vector2)->bool:
	if was_stopped(my_next_pos):return false
	last_pos=snapped_pos()
	if !on_move(last_pos,my_next_pos):return false
	target_pos=my_next_pos
	return true
	

func on_move(from:Vector2,to:Vector2)->bool:
	dbgmsg("move from %s to %s"%[GameFuncs.grid_pos(from),GameFuncs.grid_pos(to)])
	return add_as_blocker(to)
	
func next_pos(dir:Vector2)->Vector2:
	return position+dir*cell_size
	
func next_pos_from(pos:Vector2,dir:Vector2)->Vector2:
	var my_next_pos=pos+dir*cell_size	
	#print("next pos to %s from %s is %s" % [dir,pos,my_next_pos])
	return my_next_pos
		
func on_moving(from:Vector2,to:Vector2):
	if global_position.distance_to(to)<(cell_size/2):
		if GameData.world.level.objects_at(from).has(GameEnums.OBJECT_TYPE.ACTOR):
			if GameData.world.level.objects_at(from)[GameEnums.OBJECT_TYPE.ACTOR]==self:
				GameData.world.level.remove_object_at(from,GameEnums.OBJECT_TYPE.ACTOR) # remove self blocking old cell

func on_moved(from:Vector2,to:Vector2):
	dbgmsg("Ended move")
	Thing.remove_from_level_objects()
	if not GameData.world.level.add_object(self):
		dbgmsg("cannot add itself to %s"%GameFuncs.grid_pos(position),ERROR)
		if debug:print(GameData.world.level.dump_grid_pos_and_neighbors(GameFuncs.grid_pos(position)))
	else:
		dbgmsg("added itself to %s"%GameFuncs.grid_pos(position))
	if pushed_thing:pushed_thing=null
	forced_speed=0
	speed=0
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

func add_as_blocker(pos:Vector2)->bool:
	var added:bool=GameData.world.level.add_object_at(self,pos)
	var grid_pos:=GameFuncs.grid_pos(pos)
	if not added:
		dbgmsg("not able to add blocker at %s"%grid_pos,ERROR)
		GameData.world.level.dump_grid_pos_and_neighbors(grid_pos)
		return false
	else:
		dbgmsg("added blocker to %s"%grid_pos)
		return true

func is_alive()->bool:
	return Thing.is_alive()


func alive():
	Thing.alive()

func on_wall_collision(wall_pos:Vector2)->bool:
	return true

func on_collision(others:Dictionary)->bool:
	if others.empty():
		dbgmsg("colliding with nothing !",ERROR)
		return false
	var actor:= others.get(GameEnums.OBJECT_TYPE.ACTOR) as Node2D
	var item:=	others.get(GameEnums.OBJECT_TYPE.ITEM) as Node2D
	var block:=	others.get(GameEnums.OBJECT_TYPE.BLOCK) as Node2D
	if block and collide_block(block): return true
	if actor and collide_actor(actor): return true
	if item and collide_item(item): return true
	return false

func collide_actor(actor:Node2D)->bool:
	return true
	
func collide_item(item:Node2D)->bool:
	return false
	
func collide_block(block:Node2D)->bool:
	return true	

func was_stopped(at:Vector2)->bool:
	var obstacles:=detect_obstacles(at)
	if obstacles.empty():return false
	if obstacles.has("WALL"):return on_wall_collision(at)	
	return on_collision(obstacles)

func detect_obstacles(at:Vector2)->Dictionary:
	var objects:={}
	var is_wall:=detect_walls(at)
	if is_wall:
		objects["WALL"]="YES"
		return objects
	return detect_things(at)
	
func detect_things(at:Vector2)->Dictionary:
	var objects:Dictionary=GameData.world.level.objects_at(at)
	var things:={}
	for type in objects:
		if objects[type]==self: continue
		things[type]=objects[type]
	return things
	

func detect_walls(at:Vector2)->bool:
	var wallcollision:=false
	last_collision=null
	var space_state:Physics2DDirectSpaceState = GameData.world.get_world_2d().direct_space_state
	var result = space_state.intersect_ray(global_position,at,[self],collision_mask,true,false)
	if !result.empty():
		var collider:=result.collider as Node2D
		dbgmsg("raycast detection : %s"%collider.name)
		last_collision=result
		if collider.name.matchn("*wall*"):
			dbgmsg("has detected wall :%s"%collider.name)
			return true
	return false
	
func snapped_pos(pos:Vector2=Vector2.ZERO):
	var half=cell_size/2
	if pos==Vector2.ZERO:
#		return Vector2(half+floor((position.x-half)/cell_size)*cell_size,half+floor((position.y-half)/cell_size)*cell_size)
		return Vector2(half+(floor(position.x/cell_size)*cell_size),half+(floor(position.y/cell_size)*cell_size))	
	else:
		return Vector2(half+(floor(pos.x/cell_size)*cell_size),half+(floor(pos.y/cell_size)*cell_size))	

func adjust_speed():
	if current_dir==NONE:
		if speed>0:
			speed=lerp(speed,0,ground_friction)
		if abs(speed)<1.0:speed=0
	else:
		var target_speed=max_speed
		if pushed_thing and forced_speed>0:
			dbgmsg("set its target speed to %s"%forced_speed)
			target_speed=forced_speed
		dbgmsg("adjusting it speed to %s, from %s (max:%s,forced:%s)"%[target_speed,speed,max_speed,forced_speed])
		if speed!=target_speed:
			speed=lerp(speed,target_speed,ground_friction)
		if abs(speed-target_speed)<1.0:speed=target_speed
	
func goto(from:Vector2,dir:Vector2):
	#dbgmsg("Going to %s"%dir)
	next_dir=dir
	
func stop():
	next_dir=NONE
	cool_down=false
	
func speedup():
	max_speed=run_speed

func speeddown():
	max_speed=walk_speed

