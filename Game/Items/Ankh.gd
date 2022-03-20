extends Node2D

export(bool) var is_block:=false

var hit_points:=50

func _ready():
	if is_block:
		$BlockBackground.show()
	else:
		$BlockBackground.hide()

func hit(who:Node2D,amount:int):
	if is_block:
		hit_points=max(0,hit_points-amount)
		if hit_points==0:
			GameFuncs.remove_from_world(self)
			#play block explode anim
	else:
		pass

func try_use_with(who:Node2D):
	if who.name.matchn("Player*"):
		who.refill_life()
		GameFuncs.remove_from_world(self)
	return false
