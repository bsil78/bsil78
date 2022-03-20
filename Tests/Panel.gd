extends Panel

export(Font) var aFont
export(bool) var debug:=false

func _draw():
	if(debug):
		var player=$"../../Player"
		var i:=0
		for msg in DEBUG.messages:
			draw_string(aFont,Vector2(0,(1+i)*16),str(msg),Color(1,1,1,0.5))
			i+=1

			
func _process(delta):
	if(debug): update()
