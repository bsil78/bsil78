extends "res://Base/Characters/BaseActor.gd"

onready var actor_anim:AnimationPlayer=$AnimationPlayer

const all_dirs=[Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]
const all_dirs_and_idle=[Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN,Vector2.ZERO]


func _process(_delta):
	if is_idle():
		update_facing(Vector2.ZERO)
		playanim("idle")

func playanim(anim,with_yield=false)->void:
	if actor_anim.current_animation!=anim:
		set_process(false)
		actor_anim.play(anim)
		if with_yield:
			yield(actor_anim,"animation_finished")
		set_process(true)

func is_idle() -> bool:
	return !actor_anim.is_playing()

func use_effect(effect:PackedScene,effect_node:Node2D):
	var newEffect:=effect.instance() as Particles2D
	var effect_duration=newEffect.lifetime+newEffect.randomness
	effect_node.add_child(newEffect)
	newEffect.visible=true
	newEffect.emitting=true
	yield(get_tree().create_timer(effect_duration),"timeout")
		
func choose_sound(anim:String,tracks:Dictionary):
	var chosen=Utils.choose(tracks.keys())
	var theanim:=$AnimationPlayer.get_animation(anim) as Animation
	for track in tracks.keys():
		theanim.track_set_enabled(tracks[track],chosen==track)

