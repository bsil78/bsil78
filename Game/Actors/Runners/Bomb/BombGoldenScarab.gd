extends "res://Game/BaseScripts/SelfRunningActor.gd"

const dirs_h=[Vector2.LEFT,Vector2.RIGHT]
const dirs_v=[Vector2.UP,Vector2.DOWN]

onready var explosion:=$BigExplosion

func idle():
	.play_move_anim(fixed_dir)
	.idle()

func collide_actor(actor:Node2D)->bool:
	if current_dir==fixed_dir or actor.current_dir in [fixed_dir,-1*fixed_dir]:
		if actor.can_be_hit_by(self): 
			actor.hit(self,GameData.KILLER_HIT)
			return true
	return .collide_actor(actor)

func can_be_hit_by(from:Node2D)->bool:
	return .can_be_hit_by(from) or GameFuncs.is_actor(from,[GameEnums.ACTORS.CRUSHER_BLOCK,GameEnums.ACTORS.BOMB])

func explode():
	if !explosion or !is_alive(): return
	life_points=0
	Thing.dead()
	var explode_vertically:=fixed_dir in [Vector2.LEFT,Vector2.RIGHT]
	var to_hit_dirs=dirs_v if(explode_vertically) else dirs_h
	to_hit_dirs.append(Vector2.ZERO)
	explosion.name=explosion.name+"-Of_"+name
	explosion.vertical=explode_vertically
	explosion.horizontal=!explode_vertically
	explosion.connect("sides_exploding",self,"explode_things",[to_hit_dirs])
	play_explosion()

func destroy(_from:Node2D,_remove_instantly:bool=true)->bool:
	if is_alive():explode()
	return true
	
func explode_things(to_hit_dirs):
	randomize()
	yield(Utils.timer(rand_range(0.0,0.3)),"timeout")
	for dir in to_hit_dirs:
		var objs:Dictionary=detect_things(next_pos(dir))
		var types=[GameEnums.OBJECT_TYPE.ACTOR,GameEnums.OBJECT_TYPE.BLOCK,GameEnums.OBJECT_TYPE.ITEM]
		for type in types:
			var obj=objs.get(type)
			if obj!=self:if obj:obj.destroy(self)

func play_explosion():
	remove_child(explosion)	
	GameData.world.effects_node().add_child(explosion)
	explosion.global_position=global_position
	_animator.trigger_anim("exploding")
	explosion.connect("center_ending",self,"remove_from_world")
	explosion.explode_with_sides()
	explosion=null
	
func hit(from:Node2D,amount:int=1)->bool:
	if Thing.hit(from,amount) and amount==GameData.KILLER_HIT:
		hit_and_explode(from)
		return true
	return false	

func collide_block(block:Node2D)->bool:
	if block.step_on(self):
		Utils.timer(0.1).connect("timeout",self,"goto",[position,current_dir])
		return false
	if current_dir==fixed_dir:
		block.hit(self,GameData.KILLER_HIT)
		return true
	return .collide_block(block)	

func is_actor(actor:int=-1):
	return (.is_actor(actor) or GameEnums.ACTORS.BOMB==actor)
	
func hit_and_explode(obj):
	can_move=false
	explode()
	obj.destroy(self)
	return true

func behaviors()->Array:
	var bhvs:=.behaviors().duplicate(true)
	bhvs.append(GameEnums.BEHAVIORS.HIT)
	bhvs.append(GameEnums.BEHAVIORS.EXPLODER)
	bhvs.append(GameEnums.BEHAVIORS.CAN_BE_DESTROYED)
	return bhvs




