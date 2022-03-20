tool
extends Node2D

var size:=0
var target_size:=20
const marge:= 5
export(bool) var debug:=false

func _process(_delta):
	
	if get_parent() and get_parent().name.matchn("*Level*"):
		target_size=get_parent().size
	
	if debug:
		$Camera2D.make_current()
	
	if target_size!=size:
			fill(target_size)
			size=target_size	

func _input(event):
	if debug:
		if event is InputEventMouseMotion:
			$Camera2D.position=$Camera2D.position+(event as InputEventMouseMotion).relative

func fill(size:int):
	$OuterWalls.clear()
	$CommonFloor.clear()
	for i in range(0,size):
		for m in range(1,marge+1):
			outerwall(size,i,m)
		for j in range(0,size):
			$CommonFloor.set_cell(i,j,0)
	corner(Vector2(-marge,-marge))
	corner(Vector2(size,-marge))
	corner(Vector2(size,size))
	corner(Vector2(-marge,size))
	$CommonFloor.update_dirty_quadrants()
	$OuterWalls.update_dirty_quadrants()
	var rect:Rect2=$OuterWalls.get_used_rect()
	$OuterWalls_Shadows.set_position($OuterWalls.global_position+$OuterWalls.cell_size*Vector2(-marge,-marge))
	$OuterWalls_Shadows.set_size(rect.size*$OuterWalls.cell_size)

func outerwall(size,i,decal):
	$OuterWalls.set_cell(i,-decal,1)
	$OuterWalls.set_cell(size+decal-1,i,1)
	$OuterWalls.set_cell(size-i-1,size+decal-1,1)
	$OuterWalls.set_cell(-decal,size-i-1,1)
	
func corner(offset:Vector2):
	for x in range(0,marge):
		for y in range(0,marge):
			$OuterWalls.set_cell(offset.x+x,offset.y+y,1)
