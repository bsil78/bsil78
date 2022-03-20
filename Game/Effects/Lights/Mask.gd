extends Node2D

const minpos=32
const maxpos=1472-64

# Called when the node enters the scene tree for the first time.
func _ready():
	#follow_cam()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	#follow_cam()
	pass
	
func follow_cam():
	var player=GameData.current_player
	if player:
		var cam=(player.get_camera() as Camera2D)
		var target_pos=cam.global_position+cam.offset #-Vector2(0,-64)
		if(target_pos.x<minpos):target_pos.x=minpos
		if(target_pos.y<minpos):target_pos.y=minpos
		if(target_pos.x>maxpos):target_pos.x=maxpos
		if(target_pos.y>maxpos):target_pos.y=maxpos
		position=target_pos
		
