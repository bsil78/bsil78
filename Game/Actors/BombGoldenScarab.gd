extends "res://Game/BaseScripts/SelfRunningActor.gd"

const dirs_h=[Vector2.LEFT,Vector2.RIGHT]
const dirs_v=[Vector2.UP,Vector2.DOWN]

func fliph(_flip):
	pass
	
func flipv(_flip):
	pass

func idle():
	.play_move_anim(fixed_dir,false)
	.idle()

func collide_actor(actor:Node2D)->bool:
	if GameFuncs.is_actor(actor,[GameEnums.ACTORS.ANY_PLAYER,
								 GameEnums.ACTORS.BOMB]):
		if current_dir==fixed_dir or actor.current_dir in [fixed_dir,-1*fixed_dir]:
			print("hit %s"%actor.name)
			explode()
			return false	
	return .collide_actor(actor)

func explode():
	var explode_vertically:=current_dir in [Vector2.LEFT,Vector2.RIGHT]
	var to_hit_dirs=dirs_v if(explode_vertically) else dirs_h
	$BigExplosion.vertical=explode_vertically
	$BigExplosion.horizontal=!explode_vertically
	play_explosion()
	for dir in to_hit_dirs:
		var objs:Dictionary=detect_things(next_pos(dir))
		var actor=objs.get(GameEnums.OBJECT_TYPE.ACTOR)
		var block=objs.get(GameEnums.OBJECT_TYPE.BLOCK)
		if block:
			if GameEnums.CAPABILITIES.HIT in block.capabilities():
				block.hit(self,9999)
		elif actor:
			if GameEnums.CAPABILITIES.HIT in actor.capabilities():
				actor.hit(self,9999)

func play_explosion():
	var explosion=$BigExplosion
	remove_child(explosion)	
	GameData.world.effects_node().add_child(explosion)
	explosion.connect("explosion_finished",explosion,"cleanup",[explosion])
	explosion.explode_with_sides()

func cleanup(explosion):
	explosion.queue_free()
	.remove_from_world()
	
func hit(from:Node2D,amount:int=1)->bool:
	if GameFuncs.is_actor(from,[GameEnums.ACTORS.BOMB,GameEnums.ACTORS.CRUSHER_BLOCK]):
		if life_points>0:
			.hit(from,amount)
			if alive(): printerr("%s should not be alive"%name)
			explode()
			return true
	return false	

func collide_block(block:Node2D)->bool:
	if GameFuncs.is_block(block,[GameEnums.BLOCKS.FORCE_FIELD]):
		if GameEnums.CAPABILITIES.STEP_ON in block.capabilities():
			return !block.step_on(self)
	return .collide_block(block)	

func is_actor(actor:int=-1):
	return (.is_actor(actor) or GameEnums.ACTORS.BOMB==actor)
	

