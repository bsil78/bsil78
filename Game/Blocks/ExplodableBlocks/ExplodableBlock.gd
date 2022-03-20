extends "res://Game/BaseScripts/Block.gd"

export(PoolIntArray) var variant_frames:=[]
export(bool) var explodeV:=false
export(bool) var explodeH:=false

const dirs_h=[Vector2.LEFT,Vector2.RIGHT]
const dirs_v=[Vector2.UP,Vector2.DOWN]

var explosion:Node2D=preload("res://Game/Effects/BigExplosion.tscn").instance()

func _ready():
	$Block.frame=Utils.choose(variant_frames)
	assert(explosion!=null)

func destroy(from,remove_instantly:bool=false)->bool:
	if explosion==null:return true
	if .destroy(from,false):
		.dead()
		explosion.connect("sides_exploding",self,"explode_things")
		play_exploding_effect()
	return true		
			
func explode_things():
	randomize()
	yield(Utils.timer(rand_range(0.0,0.3)),"timeout")
	if explodeV:
		for dir in dirs_v:
			hit_dir(dir)
	if explodeH:
		for dir in dirs_h:
			hit_dir(dir)
	hit_dir(Vector2.ZERO)
			
func hit_dir(dir:Vector2):
	var objs:Dictionary=detect_things(next_pos(dir))
	var types=[GameEnums.OBJECT_TYPE.ACTOR,GameEnums.OBJECT_TYPE.BLOCK,GameEnums.OBJECT_TYPE.ITEM]
	for type in types:
		var obj=objs.get(type)
		if obj and obj!=self:obj.destroy(self)
			
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
	explosion.name=explosion.name+"-Of_"+name
	explosion.vertical=explodeV
	explosion.horizontal=explodeH
	GameData.world.effects_node().add_child(explosion)
	explosion.global_position=global_position
	explosion.connect("center_ending",self,"remove_from_world")
	explosion.explode_with_sides()
	explosion=null
	
func is_block(block:int=-1)->bool:
	return ( .is_block(block) or GameEnums.BLOCKS.ANY_EXPLODABLE==block)

func behaviors()->Array:
	var bhvs:=.behaviors().duplicate(true)
	bhvs.append(GameEnums.BEHAVIORS.CAN_BE_DESTROYED)
	return bhvs
	
