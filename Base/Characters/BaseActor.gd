extends "res://Base/Objects/OverworldObject.gd"

onready var sprite = $Pivot/Sprite

enum DIR { NONE, UP, DOWN, LEFT, RIGHT }
enum FLIP {  NONE, H, V , BOTH , KEEP }
# Allow changing the default facing direction in editor
export(DIR) var dir = DIR.DOWN

# Here you can set which frames represent facing direction
export(int) var down_frame = 0
export(int) var up_frame = 8
export(int) var right_frame = 4
export(int) var left_frame = 4
export(String) var walk_up_anim="walk_up"
export(String) var walk_down_anim="walk_down"
export(String) var walk_right_anim="walk_horiz"
export(String) var walk_left_anim="walk_horiz"
export(FLIP) var onLeftFlip:=FLIP.H
export(FLIP) var onRightFlip:=FLIP.NONE
export(FLIP) var onUpFlip:=FLIP.NONE
export(FLIP) var onDownFlip:=FLIP.NONE
export(FLIP) var onIdleFlip:=FLIP.NONE

export(bool) var force_y_as_z_index:=false

var walk_anim:String =walk_down_anim


func _ready():
	# Set up z index here and simply match it to the y value
	# This allows moving characters like the player to be drawn over
	# a sprite when "in front," but if they move behind that character
	# it will correctly update (sort y order for non-cells)
	if force_y_as_z_index:
		z_as_relative = false
		set_z_index(int(position.y))

# Actor targets a position to move to
func target_position(move_vector:Vector2)->void:
	update_facing(move_vector)
	if move_vector!=Vector2.ZERO:
		var target = overworld.request_move(self, move_vector)
		#print(self.name+" target "+str(target))
		# Whether we can move or not, update our facing first
		if target!=Vector2.ZERO:
			move_to(target)
		else:
			bump()

# Change how the character is facing.
func update_facing(direction:Vector2)->void:
	dir=DIR.NONE
	if direction.x == 1:
		sprite.frame = right_frame
		dir = DIR.RIGHT
	elif direction.x == -1:
		sprite.frame = left_frame
		dir = DIR.LEFT
	elif direction.y == 1:
		sprite.frame = down_frame
		dir = DIR.DOWN
	elif direction.y == -1:
		sprite.frame = up_frame
		dir = DIR.UP
	if not ( dir==DIR.NONE and onIdleFlip==FLIP.KEEP ):
		sprite.flip_h = flip(FLIP.H,dir)
		sprite.flip_v = flip(FLIP.V,dir)

func flip(flip_type,direction)->bool:
	if flip_type!=FLIP.H and flip_type!=FLIP.V:
		printerr("flip type not supported")
		return false
	var flipProp=onIdleFlip
	match direction:
		DIR.LEFT:
			flipProp=onLeftFlip
		DIR.RIGHT:
			flipProp=onRightFlip
		DIR.UP:
			flipProp=onUpFlip
		DIR.DOWN:
			flipProp=onDownFlip
	if flipProp==FLIP.KEEP:
		if flip_type==FLIP.H:
			return sprite.flip_h
		if flip_type==FLIP.V:
			return sprite.flip_v	
	return flipProp==flip_type or flipProp==FLIP.BOTH
		
# Smoothly moves actor to target position
func move_to(target_position):
	#print(self.name+" move to "+str(target_position))
	# Begin movement. Actor is non-interactive while moving.
	set_process(false)
	process_movement_animation()

	# Move the node to the target cell instantly,
	# and animate the sprite moving from the start to the target cell
	var move_direction = (target_position - position).normalized()
	var current_pos = - move_direction * overworld.cell_size
	# Keep the pivot where it is, because we are about to move the whole
	# transform and it will cause a glitchy animation where the sprite warps
	# for a single frame to the target location (with the transform) and then
	# smoothly animates after
	$Pivot.position = current_pos
	# Move the pivot point from the current position to 0,0
	# (relative to parent transform) basically just catch up with the parent
	$AnimationPlayer.play(walk_anim)
	$Tween.interpolate_property($Pivot, "position", current_pos, Vector2(),
			$AnimationPlayer.current_animation_length, Tween.TRANS_LINEAR,
			Tween.EASE_IN)
	position = target_position
	# This is basically a "sort y order" option for children (non-cells)
	set_z_index(int(position.y))
	$Tween.start()

	# Stop the function execution until the animation finished
	yield($AnimationPlayer,"animation_finished")
	# Movement complete. Actor is again "interactive"
	set_process(true)

# Define what an actor should do if it is interacted with in the child class.
func interact_with(object:Node2D):
	print(self.name+" is an Actor with no interact defined for "+object.name)
	bump()

# Failure to move function.
func bump()->void:
	#print(self.name+" bump")
	$AnimationPlayer.play("bump")
	yield($AnimationPlayer,"animation_finished")
	#print(self.name+" process again")
		

# Movement animation processing
func process_movement_animation():
	match dir:
		DIR.UP:
			walk_anim=walk_up_anim
		DIR.DOWN:
			walk_anim=walk_down_anim
		DIR.LEFT:
			walk_anim=walk_left_anim
		DIR.RIGHT:
			walk_anim=walk_right_anim
			
# Make a vector of the direction we're facing, then ask the grid to interact
# with whatever is there
func activate_object():
	var direction_of_interaction = Vector2((int(dir == DIR.RIGHT) - int(
			dir == DIR.LEFT)), (int(dir == DIR.DOWN) - int(dir == DIR.UP)))
	overworld.request_interaction(self, direction_of_interaction)
