extends Node

var played_effects:={}

static func pressed(event,action):
	if not event is InputEventKey: return
	if event.is_action_pressed(action):
		#DEBUG.push("Pressed "+event.as_text())
		return true
	return false
	
static func released(event,action):
	if not event is InputEventKey: return
	if event.is_action_released(action):
		#DEBUG.push("Released "+event.as_text())
		return true
	return false	

func quit(exit_code:int=0):
	get_tree().quit(exit_code)

static func choose(choices:Array):
	randomize()
	var choice = min(int(randf()*len(choices)),len(choices)-1)
	return choices[choice]
	
static func chance(percent:int)->bool:
	if(percent<0 or percent>100):
		DEBUG.error("Percent must be between 0 and 100 : %s"%percent)
		Utils.quit(-1)
	randomize()
	var roll = randi()  % 101
	return roll<percent



func timer(var delay:float)->SceneTreeTimer:
	return get_tree().create_timer(delay)
	
func play_sound(channel,sounds=null,volume_db:int=-999,pitch_scale:int=-999):
	if channel:
		var new_channel=channel.duplicate()
		randomize()
		new_channel.name="%s-DUP-%s"%[new_channel.name,randi()%99999]
		GameData.world.effects_node().add_child(new_channel)
		if sounds:
			if sounds is Array:
				new_channel.stream=Utils.choose(sounds) as AudioStream
			else:
				new_channel.stream=sounds as AudioStream
		if new_channel.stream==null:
			DEBUG.error("Sound is null : %s"%sounds)
			new_channel.queue_free()
		else:
			if volume_db>0.0:new_channel.volume_db=volume_db
			if pitch_scale>0.0:new_channel.pitch_scale=pitch_scale
			new_channel.play()
			new_channel.connect("finished",new_channel,"queue_free")
			return new_channel
	return null
			 
func play_effect_once(effect,effect_node:Node2D,global_pos:Vector2):
	var effect_duration
	var effect_to_play=effect
	if effect is Particles2D:
		#print("playing effect %s"%effect.name)
		effect_duration=effect.lifetime+effect.randomness
		if effect_node.find_node(effect.name,true,false):
			effect_to_play=effect.duplicate()
			randomize()
			effect_to_play.name="%s-DUP-%s"%[effect_to_play.name,randi()%99999]
		effect_node.add_child(effect_to_play)
		effect_to_play.position=effect_node.to_local(global_pos) 
		effect_to_play.visible=true
		effect_to_play.emitting=true
		played_effects[effect_to_play]=effect_node	
	Utils.timer(effect_duration).connect("timeout",self,"remove_effect",[effect_to_play,true if effect!=effect_to_play else false])

func remove_effect(effect:Node2D,queue:bool):
	if(is_instance_valid(effect)):
		played_effects[effect].remove_child(effect)
	if is_instance_valid(effect) and queue:effect.queue_free()
		
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
# warning-ignore:integer_division
		elif Utils.chance(100/len(tracks)):
			chosen=key
			itrack=tracks[key]
			break
	if chosen:
		var theanim:=animPlayer.get_animation(anim) as Animation
		for track in tracks.keys():
			theanim.track_set_enabled(itrack,chosen==track)
		


