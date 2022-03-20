extends "res://Game/Blocks/ExplodableBlocks/ExplodableBlock.gd"

func behaviors()->Array:
	var bhvs:=.behaviors().duplicate(true)
	bhvs.append(GameEnums.BEHAVIORS.EXPLODER)
	return bhvs

