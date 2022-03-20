extends "res://Game/BaseScripts/BreakableBlock.gd"

func hit(from:Node2D,amount:int)->bool:
	if !from.is_actor(GameEnums.ACTORS.ANY_PLAYER): return false
	var done=.hit(from,amount)
	if !done: return false
	$BlockBackground.frame=19
	if !is_alive():
		if GameData.players.size()<2:
			if GameData.players_saves.empty():
				var missing_name
				for pname in GameData.players_names:
					if pname!=GameData.current_player:
						missing_name=pname
						break
				var new_player=GameFuncs.instanciate_player(missing_name)
				GameData.players[missing_name]=new_player
				new_player.position=position
				remove_from_world()
	return true
