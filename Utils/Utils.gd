extends Node


func pressed(event,action):
	if not event is InputEventKey: return
	if event.is_action_pressed(action):
		#DEBUG.push("Pressed "+event.as_text())
		return true
	return false
	
func released(event,action):
	if not event is InputEventKey: return
	if event.is_action_released(action):
		#DEBUG.push("Released "+event.as_text())
		return true
	return false	

func quit(exit_code:int=0):
	get_tree().quit(exit_code)

func choose(choices:Array):
	randomize()
	var choice = min(int(randf()*len(choices)),len(choices)-1)
	return choices[choice]
	
func chance(percent:int)->bool:
	if(percent<0 or percent>100):
		DEBUG.error("Percent must be between 0 and 100 : {}",[percent])
		Utils.quit(-1)
	randomize()
	var roll = randi()  % 101
	return roll<percent



func timer(var delay:float)->SceneTreeTimer:
	return get_tree().create_timer(delay)
	
func play_sound(channel,sounds,volume_db:int=-999):
	if channel:
		var volume=channel.volume_db
		if sounds is Array:
			channel.stream=Utils.choose(sounds) as AudioStream
		else:
			channel.stream=sounds as AudioStream
		if channel.stream==null:
			DEBUG.error("Sound is null : {}",[sounds])
		if volume_db!=-999:channel.volume_db=volume_db
		channel.play()
		channel.volume_db=volume
	
func play_effect_once(effect:PackedScene,effect_node:Node2D,global_pos:Vector2):
	var newEffect:=effect.instance() as Particles2D
	var effect_duration=newEffect.lifetime+newEffect.randomness
	effect_node.add_child(newEffect)
	newEffect.position=newEffect.to_local(global_pos) 
	newEffect.visible=true
	newEffect.emitting=true
	yield(Utils.timer(effect_duration),"timeout")
	if is_instance_valid(effect_node) and is_instance_valid(newEffect):
		effect_node.remove_child(newEffect)
		newEffect.queue_free()
	
		
func rand_animation_track(animPlayer:AnimationPlayer,anim:String,tracks:Dictionary):
	var chosen:String
	var itrack:int
	for key in tracks:
		if tracks[key] is Array:
			if Utils.chance(tracks[key][1]):
				chosen=key
				itrack=tracks[key][0]
				break
		# warning-ignore:narrowing_conversion
		elif Utils.chance(100/len(tracks)):
			chosen=key
			itrack=tracks[key]
			break
	if chosen:
		var theanim:=animPlayer.get_animation(anim) as Animation
		for track in tracks.keys():
			theanim.track_set_enabled(itrack,chosen==track)
		


