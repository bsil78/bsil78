extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const minpos=64
const maxpos=1472-64

# Called when the node enters the scene tree for the first time.
func _ready():
	follow_cam()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	follow_cam()
	#pass
	
func follow_cam():
	var cam=(get_parent().get_node("Player/Camera2D") as Camera2D)
	var target_pos=cam.global_position+cam.offset #-Vector2(16,16)
	if(target_pos.x<minpos):target_pos.x=minpos
	if(target_pos.y<minpos):target_pos.y=minpos
	if(target_pos.x>maxpos):target_pos.x=maxpos
	if(target_pos.y>maxpos):target_pos.y=maxpos
	position=target_pos
		
