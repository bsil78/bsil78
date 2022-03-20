tool
extends RichTextLabel

export var text_to_use:="Example"

func center_text():
	var lines:= text_to_use.split("\\n")
	var fontHeight:=get_font("normal_font").get_height()
	var height:=fontHeight*lines.size()
	var parentWidth:int = get_parent().get_rect().size.x
	set_custom_minimum_size(Vector2(parentWidth,height))
	set_anchors_and_margins_preset(Control.PRESET_CENTER)
	clear()
	push_align(RichTextLabel.ALIGN_CENTER)
	for line in lines:
		add_text(line)
		newline()
	

	

