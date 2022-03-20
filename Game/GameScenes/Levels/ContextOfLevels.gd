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

func fill(the_size:int):
	$OuterWalls.clear()
	$CommonFloor.clear()
	for i in range(0,the_size):
		for m in range(1,marge+1):
			outerwall(the_size,i,m)
		for j in range(0,the_size):
			$CommonFloor.set_cell(i,j,floorTile())
	corner(Vector2(-marge,-marge))
	corner(Vector2(the_size,-marge))
	corner(Vector2(the_size,the_size))
	corner(Vector2(-marge,the_size))
	$CommonFloor.update_dirty_quadrants()
	$OuterWalls.update_dirty_quadrants()
	var rect:Rect2=$OuterWalls.get_used_rect()
	$OuterWalls_Shadows.set_position($OuterWalls.global_position+$OuterWalls.cell_size*Vector2(-marge,-marge))
	$OuterWalls_Shadows.set_size(rect.size*$OuterWalls.cell_size)

func outerwall(the_size,i,decal):
	$OuterWalls.set_cell(i,-decal,outerTile())
	$OuterWalls.set_cell(the_size+decal-1,i,outerTile())
	$OuterWalls.set_cell(the_size-i-1,the_size+decal-1,outerTile())
	$OuterWalls.set_cell(-decal,the_size-i-1,outerTile())
	
func corner(offset:Vector2):
	for x in range(0,marge):
		for y in range(0,marge):
			$OuterWalls.set_cell(offset.x+x,offset.y+y,outerTile())

func outerTile():
	randomize()
	var tiles:Array=$OuterWalls.tile_set.get_tiles_ids()
	tiles.shuffle()
	return tiles[0]

func floorTile():
	randomize()
	var tiles:Array=$CommonFloor.tile_set.get_tiles_ids()
	tiles.shuffle()
	return tiles[0]	
