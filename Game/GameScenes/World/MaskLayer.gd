extends Node

export(Vector2) var offset:=Vector2(32,32)
export(float) var factor:=1.0
const large_fow_subpath="Large_FoWHole"
const small_fow_subpath="Small_FoWHole"
const player_center_offset=Vector2(16,16)
const large_fow_half_size=Vector2(200,200)
const screen_center=Vector2(320,320)

func _ready():
	$FixedMask_LightOff.show()
	$FixedMask.hide()
	$Letters.hide()
	$FieldOfView.show()	
	update()

func update():
	var activep=GameData.current_player
	if is_instance_valid(activep):
		show_active_fow(activep)
		for player in GameData.world.players():
			if player.name==activep.name: continue
			show_inactive_fow(player)
			return
	else:
		hide_active_fow()
	hide_inactive_fow()
		
				
func show_active_fow(player:Node2D):
	var torch=player.torch()
	$FogOfWar/Viewport/Active_FoW.position=Vector2(24,40)
	$FogOfWar/Viewport/Active_FoW.get_node(large_fow_subpath).visible=torch.is_flammed()
	$FogOfWar/Viewport/Active_FoW.get_node(small_fow_subpath).visible=!torch.is_flammed()
	$FogOfWar/Viewport/Active_FoW.show()
	$FixedMask.visible=torch.is_flammed()
	$Letters.visible=torch.is_flammed()
	$FixedMask_LightOff.visible=!torch.is_flammed()

func show_inactive_fow(player:Node2D):
	var torch=player.torch()
	var active_pos=GameData.current_player.position
	var delta_pos=player.position-active_pos
	var active_fow_pos=Vector2(24,40) #large_fow_half_size + player_center_offset+offset
	$FogOfWar/Viewport/Inactive_FoW.position=  active_fow_pos +delta_pos 
	$FogOfWar/Viewport/Inactive_FoW.get_node(large_fow_subpath).visible=torch.is_flammed()
	$FogOfWar/Viewport/Inactive_FoW.show()

func camera_origin(player)->Vector2:
	return player.get_camera().get_viewport_transform().origin

func hide_inactive_fow():
	$FogOfWar/Viewport/Inactive_FoW.hide()

func hide_active_fow():
	$FogOfWar/Viewport/Active_FoW.hide()
