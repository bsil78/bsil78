extends ViewportContainer

export(Vector2) var offset:=Vector2(96,96)
export(float) var factor:=1.0
const default_pos=Vector2(216,216)

func _ready():
	get_parent().get_node("MaskLayer/FieldOfView").visible=true	

func _process(_delta):
	for pname in GameData.players_names:
		var fowname="{}_FoW".format([pname],"{}")
		var fow=$Viewport.get_node(fowname)
		var player
		var torch_flammed:=false
		if GameData.current_player and GameData.current_player.name==pname:
			player=GameData.current_player
		elif GameData.players.has(pname):
			player = GameData.players[pname]
		if not player:
			fow.visible=false
			#print_debug("{} not visible".format([fowname],'{}'))
		else:
			var torch=player.get_node("Animation/Torch")
			torch_flammed=torch.is_flammed()
				
			if player==GameData.current_player:
				fow.position=default_pos
			else:
				var active_pos=GameData.current_player.position
				var delta_pos=player.position-active_pos
				fow.position= default_pos + delta_pos
			fow.visible=true	
			fow.get_node("Large_FoWHole").visible=torch_flammed
			fow.get_node("Small_FoWHole").visible=!torch_flammed
