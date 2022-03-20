extends Node

func quit(exit_code:int):
	get_tree().quit(exit_code)

func choose(choices:Array):
	randomize()
	var choice = randf()*len(choices)
	return choices[choice]
	
func chance(percent:int)->bool:
	if(percent<0 or percent>99):
		printerr("Percent must be between 0 and 99")
		Utils.quit(-1)
	randomize()
	var roll = randi()  % percent
	return roll<percent
	
func timer(var delay:float):
	return get_tree().create_timer(delay)
	
func yield_time(var delay:float):
	set_process(false)
	var timer=timer(delay)
	if !timer:
		print("Erreur de timer")
		Utils.quit(666)
	yield(timer,"timeout")
	set_process(true)
	
