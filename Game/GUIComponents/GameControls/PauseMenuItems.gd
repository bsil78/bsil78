extends Panel

const top_left=Vector2.ZERO
const voffset_items=Vector2(0,16)
	
var cur_pos=0
var nxt_pos=0
var max_pos
enum { CONTINUE_LEVEL=0,RESTART_LEVEL,BACK_TO_LEVEL,QUIT_TO_MAIN,QUIT_WHOLE_GAME }
var items=[tr("CONTINUE_LEVEL") ,tr("RESTART_LEVEL"),tr("BACK_TO_LEVEL"),tr("QUIT_TO_MAIN"),tr("QUIT_WHOLE_GAME")]
export(Font) var items_font:Font



func _ready() -> void:
	max_pos=items.size()-1


func _draw()->void:
	var text_height_offsety=Vector2(0,24)
	if nxt_pos!=cur_pos:
		cur_pos=nxt_pos
	draw_rect(Rect2(top_left+Vector2(-8,4+cur_pos*64)+(voffset_items*cur_pos),Vector2(rect_size.x+16,64)),Color(1.0,1.0,0.5,0.5),true)
	var idit=1
	for item in items:
		var item_color=Color(0.5,0.5,0.0)
		if idit-1==cur_pos: item_color=Color.yellow
		var item_strings:Array=items[idit-1].split("\n")
		var line=0
		var base_offsety=Vector2(0,(2-item_strings.size())*16)+voffset_items*(idit-1)
		for item_string in item_strings:
			var line_text:String=item_strings[line]
			var line_size=items_font.get_string_size(line_text).x
			var posx=(rect_size.x-line_size)/2
			var offsetx=Vector2(posx,0)
			var offsety=base_offsety+Vector2(0,(idit-1)*64+line*32)
			draw_string(items_font, top_left+offsetx+offsety+text_height_offsety,line_text,item_color)
			line+=1
		idit+=1
	



func _input(event)->void:
	if $KeyDelay.time_left==0 and event is InputEventKey and event.is_pressed():
		var key_pressed=event.scancode
		if key_pressed==KEY_UP:
			nxt_pos=clamp(nxt_pos-1,0,max_pos)
			$KeyDelay.start()
			update()
			return
		if key_pressed==KEY_DOWN:
			nxt_pos=clamp(nxt_pos+1,0,max_pos)
			$KeyDelay.start()
			update()
			return
		
