extends Node

export(Vector2) var offset:=Vector2(96,96)
export(float) var factor:=1.0
const default_pos=Vector2(248,248)
const torch_path="Animation/Torch"
const large_fow_subpath="Large_FoWHole"
const small_fow_subpath="Small_FoWHole"

func _ready():
	$FixedMask_LightOff.show()
	$FixedMask.hide()
	$Letters.hide()
	$FieldOfView.show()	

func _process(_delta):
	var activep=GameData.current_player
	if is_instance_valid(activep):
		show_active_fow(activep)
		for pname in GameData.players_names:
			if pname==activep.name: continue
			if GameData.players.has(pname):
				show_inactive_fow(GameData.players[pname])
				return
	else:
		hide_active_fow()
	hide_inactive_fow()
		
				
func show_active_fow(player:Node2D):
	var torch=player.get_node(torch_path)
	$FogOfWar/Viewport/Active_FoW.position=default_pos
	$FogOfWar/Viewport/Active_FoW.get_node(large_fow_subpath).visible=torch.is_flammed()
	$FogOfWar/Viewport/Active_FoW.get_node(small_fow_subpath).visible=!torch.is_flammed()
	$FogOfWar/Viewport/Active_FoW.show()
	$FixedMask.visible=torch.is_flammed()
	$Letters.visible=torch.is_flammed()
	$FixedMask_LightOff.visible=!torch.is_flammed()

func show_inactive_fow(player:Node2D):
	var torch=player.get_node(torch_path)
	var active_pos=GameData.current_player.position
	var delta_pos=player.position-active_pos
	$FogOfWar/Viewport/Inactive_FoW.position= default_pos + delta_pos
	$FogOfWar/Viewport/Inactive_FoW.get_node(large_fow_subpath).visible=torch.is_flammed()
	$FogOfWar/Viewport/Inactive_FoW.show()

func hide_inactive_fow():
	$FogOfWar/Viewport/Inactive_FoW.hide()

func hide_active_fow():
	$FogOfWar/Viewport/Active_FoW.hide()
