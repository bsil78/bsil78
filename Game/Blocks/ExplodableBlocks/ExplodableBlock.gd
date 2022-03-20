extends "res://Game/BaseScripts/BreakableBlock.gd"

export(PoolIntArray) var variant_frames:=[]
export(bool) var explodeV:=false
export(bool) var explodeH:=false

const dirs_h=[Vector2.LEFT,Vector2.RIGHT]
const dirs_v=[Vector2.UP,Vector2.DOWN]

var explosion:Node2D=preload("res://Game/Effects/BigExplosion.tscn").instance()

func _ready():
	$Block.frame=Utils.choose(variant_frames)

func hit(from,amount:int=1):
	if GameFuncs.is_actor(from,[GameEnums.ACTORS.BOMB]) or \
		GameFuncs.is_block(from,[GameEnums.BLOCKS.ANY_EXPLODABLE]):
		.hit(from,amount)
		if alive(): printerr("%s should not be alive"%name)
		if explodeV:
			for dir in dirs_v:
				hit_dir(dir)
		if explodeH:
			for dir in dirs_h:
				hit_dir(dir)

func hit_dir(dir:Vector2):
	var objs:Dictionary=detect_things(next_pos(dir))
	var actor=objs.get(GameEnums.OBJECT_TYPE.ACTOR)
	var block=objs.get(GameEnums.OBJECT_TYPE.BLOCK)
	if block:
		if GameEnums.CAPABILITIES.HIT in block.capabilities():
			block.hit(self,9999)
	elif actor:
		if GameEnums.CAPABILITIES.HIT in actor.capabilities():
			actor.hit(self,9999)
			
func next_pos(dir:Vector2)->Vector2:
	return position+dir*GameData.cell_size
	
func detect_things(at:Vector2)->Dictionary:
	var objects:Dictionary=GameData.world.level.objects_at(at)
	var things:={}
	for type in objects:
		if objects[type]==self: continue
		things[type]=objects[type]
	return things

func play_exploding_effect():
	var explosion=$BigExplosion
	remove_child(explosion)	
	GameData.world.effects_node().add_child(explosion)
	explosion.connect("explosion_finished",self,"cleanup",[explosion])
	explosion.explode()

func cleanup(explosion):
	explosion.queue_free()
	.remove_from_world()
	
func is_block(block:int=-1)->bool:
	return ( .is_block(block) or GameEnums.BLOCKS.ANY_EXPLODABLE==block)

func show_broken_block():
	pass
