extends KinematicBody2D
class_name Actor

#signals
signal has_moved

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
export(NodePath) var tween

#protected values
var this=CLASS.new("Thing",[self])
var speed:=0
var max_speed:=walk_speed
var forced_speed:int=0

var DirNONE=CLASS.stic("Dir2D","NONE")
var PosNONE=CLASS.stic("GridPos","NONE")
var DirLEFT=CLASS.stic("Dir2D","LEFT")
var DirRIGHT=CLASS.stic("Dir2D","RIGHT")
var DirUP=CLASS.stic("Dir2D","UP")
var DirDOWN=CLASS.stic("Dir2D","DOWN")


var next_dir=DirNONE
var current_dir=DirNONE
var target_pos=PosNONE
var last_pos=grid_pos()
var _animator:Animator
var _tween:Tween
var pushed_thing:Actor
var last_collision
var cool_down:=false


const ERROR:=true

export(bool) var debug:=false
var messages:=[]

func _ready():
	#init GameData managed values
	cell_size=GameData.cell_size
	ground_friction=GameData.ground_friction
	_animator=get_node(animator) as Animator
	#_tween=get_node(tween) as Tween


func _draw():
	if debug and last_collision:
		draw_string(CommonUI.get_node("DebugPanel/ObjectDebug").font,to_local(last_collision.position)+Vector2(0,-16),last_collision.collider.name,Color.white)
		draw_line(Vector2(),to_local(last_collision.position),Color.red,1.0)

func state_str()->String:
	return ("%s\nglobal pos:%s\ngrid pos:%s\nanim:%s\nLP: %s\nCD:%s\nND:%s\n%s" % [
									name,
									global_position,
									CLASS.new("GridPos",[global_position]),
									_animator.getanim(),
									life_points,
									current_dir,
									next_dir,
									GameFuncs.dump(messages)
									])

func _physics_process(delta):
	if debug:update()
	if !this.frozen and is_alive():
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
	if next_dir.isNone() and current_dir.isNone():idle()

func manage_movement(_delta)->bool:
	adjust_current_dir()
	adjust_facing()
	find_target_pos()
	if (target_pos):
#		move_to(target_pos)
		adjust_speed()
		move(_delta)
		return true
	else:
		return false	

func move_to(_pos=PosNONE):
	pass

func hit(from,amount:int=1)->bool:
	if this.hit(from,amount):
		if life_points>0:
			life_points=max(life_points-amount,0)
			return true
	return false

func dead():
	this.dead()
	dbgmsg("is dying and alive is %s"%is_alive())
	remove_from_world()

func killed():
	if(debug):DEBUG.push("%s killed" % name)
	dead()
	
func idle():
	forced_speed=0
	speed=0
	target_pos=PosNONE
	current_dir=DirNONE
	next_dir=DirNONE

func is_actor(actor:int=-1)->bool:
	return actor==-1

func is_item(item:int=-1)->bool:
	return false

func is_block(block:int=-1)->bool:
	return false

func freeze():
	this.freeze()

func unfreeze():
	this.unfreeze()

func remove_from_world():
	this.remove_from_world()

func remove_from_game():
	this.remove_from_game()
	
func move(delta):
	if (!is_alive() or speed==0 or current_dir.isNone() or target_pos.isNone()): return
	var target=target_pos.as_Vector2()
	var path=target-position
	var distance=path.length()
	if(distance>cell_size):dbgmsg("cannot move because distance between %s and %s (%s) is too big : %s"%[position,target,target_pos,distance],ERROR)
	var delta_move:Vector2=path.normalized()*(speed*delta) 
	var delta_len=delta_move.length()
	#dbgmsg("moving with speed : %s"%speed)
	if( delta_len>cell_size 
		or delta_len>distance
		or distance<1.0		
		):
		delta_move=Vector2(floor(path.x),floor(path.y))
		position=snapped_pos().as_Vector2() #jump precisely
		emit_signal("has_moved")
		target_pos=PosNONE #should find new target
		current_dir=DirNONE #and a new current dir
		speed=0
		forced_speed=0
	
	if !target_pos.isNone():
		var _collision=move_and_collide(delta_move,false,true,true)
		var collider:Node2D
		if _collision:collider=_collision.collider as Node2D
		if !_collision or GameFuncs.is_item(collider):
			move_and_collide(delta_move,true,true,false)
			emit_signal("has_moved")
		else: # wall or block or actor
			dbgmsg("colliding %s at speed %s"%[collider.name,speed])
			move_and_collide(_collision.remainder,true,true,false)
			#check if we have to stop right now
			if collider_stop_me(collider):
				position=snapped_pos().as_Vector2()
				target_pos=PosNONE #should find new target
				current_dir=DirNONE #and a new current dir
				speed=0
				forced_speed=0 
			emit_signal("has_moved")
			
	if current_dir.isNone():
		on_moved(last_pos,grid_pos())
	else:
		on_moving(last_pos,target_pos)
	
func collider_stop_me(collider):
	var let_me_continue=( GameFuncs.is_actor(collider) and collider.current_dir.equals(current_dir) )
	return not let_me_continue
	
func adjust_facing(dir=DirNONE,with_moving:bool=true):
	CLASS.check(dir,"Dir2D")
	if with_moving:
		if !dir.isNone():current_dir=dir
		if !current_dir.isNone() or onIdleFlip!=GameEnums.FLIP.KEEP:
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
	
func flip(dir,flip_type:int)->bool:
	if flip_type!=GameEnums.FLIP.H and flip_type!=GameEnums.FLIP.V:
		dbgmsg("flip type not supported",ERROR)
		return false
	var flipProp:int=dir.match_to(
				{
					DirLEFT:onLeftFlip,
					DirRIGHT:onRightFlip,
					DirUP:onUpFlip,
					DirDOWN:onDownFlip
				},
				onIdleFlip )
				
	if flipProp==GameEnums.FLIP.KEEP:
		if flip_type==GameEnums.FLIP.H:
			return _animator.get_visual().flip_h
		if flip_type==GameEnums.FLIP.V:
			return _animator.get_visual().flip_v	
	return flipProp==flip_type or flipProp==GameEnums.FLIP.BOTH
		
func adjust_current_dir():
	if !next_dir.isNone() and current_dir.isNone():
		current_dir=next_dir
		next_dir=DirNONE

func find_target_pos():
	if !target_pos.isNone(): return
	var next_pos=snapped_pos().step(current_dir)
#	dbgmsg("looking at pos : %s"%next_pos)
	if !current_dir.isNone() and target_pos.isNone() and !can_go(next_pos) :
		dbgmsg("Cannot go, then rest")
		target_pos=PosNONE
		next_dir=DirNONE
		current_dir=DirNONE
		return

func can_go(my_next_pos)->bool:
	CLASS.check(my_next_pos,"GridPos")
	if was_stopped(my_next_pos):return false
	last_pos=snapped_pos()
	if !on_move(last_pos,my_next_pos):return false
	target_pos=my_next_pos
	return true
	

func on_move(from,to)->bool:
	CLASS.check(from,"GridPos")
	CLASS.check(to,"GridPos")
	dbgmsg("move from %s to %s"%[from,to])
	return add_as_blocker(to)
		
func on_moving(from,to):
	CLASS.check(from,"GridPos")
	CLASS.check(to,"GridPos")
	if global_position.distance_to(to.as_Vector2())<(cell_size/2):
		if GameData.world.level.objects_at(from).has(GameEnums.OBJECT_TYPE.ACTOR):
			if GameData.world.level.objects_at(from)[GameEnums.OBJECT_TYPE.ACTOR]==self:
				GameData.world.level.remove_object_at(from,GameEnums.OBJECT_TYPE.ACTOR) # remove self blocking old cell

func on_moved(from,to):
	CLASS.check(from,"GridPos")
	CLASS.check(to,"GridPos")
	dbgmsg("Ended move")
	this.remove_from_level_objects()
	if not GameData.world.level.add_object(self):
		dbgmsg("cannot add itself to %s"%grid_pos(),ERROR)
		if debug:print(GameData.world.level.dump_grid_pos_and_neighbors(grid_pos()))
	else:
		dbgmsg("added itself to %s"%grid_pos())
	if pushed_thing:pushed_thing=null
	forced_speed=0
	speed=0
	current_dir=DirNONE
	target_pos=PosNONE
	last_pos=grid_pos()

func grid_pos():
	var grid_pos=this.grid_pos()
	assert(grid_pos!=null)
	return grid_pos

func push_to(who,pdir)->bool:
	return this.push_to(who,pdir)

func use_in_place(who)->bool:
	return this.use_in_place(who)
	
func pickup(who)->bool:
	return this.pickup(who)
	
func capabilities()->Array:
	var capas=this.capabilities()
	capas.append(GameEnums.CAPABILITIES.HIT)
	return capas

func add_as_blocker(pos)->bool:
	CLASS.check(pos,"GridPos")
	var added:bool=GameData.world.level.add_object_at(self,pos)
	if not added:
		dbgmsg("not able to add blocker at %s"%grid_pos(),ERROR)
		GameData.world.level.dump_grid_pos_and_neighbors(grid_pos())
		return false
	else:
		dbgmsg("added blocker to %s"%grid_pos())
		return true

func is_alive()->bool:
	return this.is_alive()


func alive():
	this.alive()

func on_wall_collision(wall_pos)->bool:
	CLASS.check(wall_pos,"GridPos")
	return true

func on_collision(others:Dictionary)->bool:
	if others.empty():
		dbgmsg("colliding with nothing !",ERROR)
		return false
	var actor:= others.get(GameEnums.OBJECT_TYPE.ACTOR) as Actor
	var item:=	others.get(GameEnums.OBJECT_TYPE.ITEM) as Item
	var block:=	others.get(GameEnums.OBJECT_TYPE.BLOCK) as Block
	if block and collide_block(block): return true
	if actor and collide_actor(actor): return true
	if item and collide_item(item): return true
	return false

func collide_actor(actor:Actor)->bool:
	return true
	
func collide_item(item:Item)->bool:
	return false
	
func collide_block(block:Block)->bool:
	return true	

func was_stopped(at)->bool:
	CLASS.check(at,"GridPos")
	var obstacles:=detect_obstacles(at)
	if obstacles.empty():return false
	if obstacles.has("WALL"):return on_wall_collision(at)	
	return on_collision(obstacles)

func detect_obstacles(at)->Dictionary:
	CLASS.check(at,"GridPos")
	var objects:={}
	var is_wall:=detect_walls(at)
	if is_wall:
		objects["WALL"]="YES"
		return objects
	return detect_things(at)
	
func detect_things(at)->Dictionary:
	CLASS.check(at,"GridPos")
	var objects:Dictionary=GameData.world.level.objects_at(at)
	if objects.values().has(self): 
		dbgmsg("%s detected itself"%name,ERROR)
		if debug:print(GameData.world.level.dump_grid_pos_and_neighbors(grid_pos()))
		return {}
	return objects

func detect_walls(at)->bool:
	CLASS.check(at,"GridPos")
	var wallcollision:=false
	last_collision=null
	var space_state:Physics2DDirectSpaceState = GameData.world.get_world_2d().direct_space_state
	var result = space_state.intersect_ray(global_position,at.as_Vector2(),[self],collision_mask,true,false)
	if !result.empty():
		var collider:=result.collider as Node2D
		dbgmsg("raycast detection : %s"%collider.name)
		last_collision=result
		if collider.name.matchn("*wall*"):
			dbgmsg("has detected wall :%s"%collider.name)
			return true
	return false
	
func snapped_pos():
	return CLASS.stic("GridPos","snapped",[position])

func adjust_speed():
	if current_dir.isNone():
		if speed>0:
			speed=lerp(speed,0,ground_friction)
		if abs(speed)<1.0:speed=0
	else:
		var target_speed=max_speed
		if pushed_thing and forced_speed>0:
			dbgmsg("set its target speed to %s"%forced_speed)
			target_speed=forced_speed
		if speed!=target_speed:
			speed=lerp(speed,target_speed,ground_friction)
		if abs(speed-target_speed)<1.0:speed=target_speed
	
func goto(from,dir):
	CLASS.check(from,"GridPos")
	CLASS.check(dir,"Dir2D")
	#dbgmsg("Going to %s"%dir)
	next_dir=dir
	
func stop():
	next_dir=DirNONE
	cool_down=false
	
func speedup():
	max_speed=run_speed

func speeddown():
	max_speed=walk_speed

