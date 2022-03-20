tool
extends RichTextLabel

export var text_to_use:="Example"

var centered_yet:=false

func _process(_delta):
	if(!centered_yet):center_text()

func center_text():
	var lines:= text_to_use.split("\n")
	var fontHeight:=get_font("normal_font").get_height()
	var height:=fontHeight*lines.size()
	var parentWidth:int = get_parent().get_rect().size.x
	set_custom_minimum_size(Vector2(parentWidth,height))
	set_anchors_and_margins_preset(Control.PRESET_CENTER)
	clear()
	push_align(RichTextLabel.ALIGN_CENTER)
	add_text(text_to_use.c_unescape())
#	for line in lines:
#		add_text(line)
#		newline()
	

	

