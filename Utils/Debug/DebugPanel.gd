extends Panel

export(Font) var aFont

var debug:=DEBUG

func _draw():
	if(DEBUG.panel):
		var i:=0
		for msg in DEBUG.messages:
			draw_string(aFont,Vector2(0,(1+i)*16),str(msg),Color(1,1,1,1))
			i+=1

			
func _process(_delta):
	if(DEBUG.panel): update()
