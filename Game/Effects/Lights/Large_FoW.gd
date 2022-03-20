extends Sprite


var playerPivot:Position2D

func _ready():
	playerPivot=null

func _process(_delta):
	if !GameData.player:
		return
	if !playerPivot:
		for obj in GameData.player.get_children():
			if obj.name=="Pivot":
				playerPivot=obj
				break
	if playerPivot:
		position=playerPivot.global_position
	
