extends "res://Game/Characters/BaseCharacter.gd"

var change_dir:=true
var actual_dir:=Vector2.ZERO
var thinking:=false
export(bool) var dissolving:=false
export(float,0.0,100.0,0.1) var dissolve_amount:=0.0
var dissolve_material:Material

export(int,0,1000,10) var hit_points:=100

var hitEffect:=preload("res://Game/Effects/EnemyHitGreenBlood.tscn")

func _ready():
	$Pivot/Sprite.scale=Vector2.ONE
	$Pivot/Sprite.position=Vector2.ZERO
	$Pivot/Sprite.self_modulate=Color.white
	dissolving=false
	dissolve_amount=0
	visible=true
	push_dissolve()
	
func push_dissolve():
	if not dissolve_material:
		dissolve_material=$Pivot/Sprite.get_material()
	if dissolve_material:
		dissolve_material.set_shader_param("amount", dissolve_amount)
		dissolve_material.set_shader_param("running", dissolving)

func hit(amount):
	playanim("Hit")
	hit_points=(hit_points-amount)
	if hit_points<0:
		hit_points=0
	use_effect(hitEffect,$FrontEffects)

func die():
	playanim("Killed",true)
	remove_from_world()
	queue_free()
	
func interact_with(other:Node2D):
	if other.name=="Player":
		playanim("Attack",true)
		other.hit(50)

func _draw():
	if dissolving:
		push_dissolve()
			
func _process(_delta):
	manage_sound_volume()
	if hit_points<=0:
		die()
	if Utils.chance(50):
		try_move()
	else:
		change_dir=false
		actual_dir=Vector2.ZERO

func manage_sound_volume():
	if GameData.player and global_position:
		var player_pos:Vector2=GameData.player.find_node("Pivot").global_position
		$Pivot/RayCast2D.cast_to=(player_pos-global_position)
		var volume_db=-1*global_position.distance_to(player_pos)/10
		var collider=$Pivot/RayCast2D.get_collider()
		if collider and collider.name!="PlayerBody":
				volume_db*=2
		$SlowPitch.volume_db=volume_db
		$NormalPitch.volume_db=volume_db
		
func bump()->void:
	change_dir=true	
	actual_dir=Vector2.ZERO

func try_move():
	if change_dir or Utils.chance(10):
		if !thinking:
			think_dir()
	target_position(actual_dir)
	
func think_dir():
	thinking=true
	yield(get_tree().create_timer(0.1),"timeout")
	var new_dir=Utils.choose(all_dirs_and_idle)
	if new_dir.x!=0 and new_dir.y!=0:
		if Utils.chance(50):
			new_dir.x=0
		else:
			new_dir.y=0
	actual_dir=new_dir
	change_dir=false
	thinking=false


