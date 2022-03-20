extends Node

var played_effects:={}
var IMAP:Array


func _ready()->void:
	IMAP=InputMap.get_actions()

func quit(exit_code:int=0):
	Utils.get_tree().quit(exit_code)

func input_from_event(event)->Dictionary:
	
	var detected:={
		key_pressed=-1,
		pad_button=-1,
		axis=-1,
		axis_val=-1.0,
		action_pressed="",
		action_released=""
	}
	
	if event.is_action_type():
		if event.is_pressed():
			if event is InputEventAction:
				detected.action_pressed=event.action
			else:
				for action in IMAP:
					if Input.is_action_just_pressed(action):
						detected.action_pressed=action
						break
		else:
			if event is InputEventAction:
				detected.action_released=event.action
			else:
				for action in IMAP:
					if Input.is_action_just_released(action):
						detected.action_released=action
						break
		
	if event.is_pressed():
		if event is InputEventKey and event.pressed:
			detected.key_pressed=event.scancode
		
		if event is InputEventJoypadButton and event.pressed:
			detected.pad_button=event.button_index
			
		if event is InputEventJoypadMotion:
			detected.axis=event.axis
			detected.axis_val=event.axis_value
		
#	if !(event is InputEventMouse or event is InputEventScreenTouch):
#		print("Input : %s\n%s"%[event,detected])
	
	#print("InputEvent : %s"%event.as_text())
	
	return detected

func quit_from(node,exit_code:int=0):
	node.get_tree().quit(exit_code)

func quit_pause_from(node):
	node.get_tree().paused=false

static func choose(choices:Array):
	randomize()
	var choice = min(int(randf()*len(choices)),len(choices)-1)
	return choices[choice]
	
static func chance(percent:int)->bool:
	if(percent<0):
		DEBUG.error("Percent must be greater than 0 : %s"%percent)
		Utils.quit(-1)
	randomize()
	var roll = randi()  % 101
	return roll<percent

func init_ui_locale(control:Control,base_size,translation_key,args=null):
	var text=tr(translation_key)
	var title_font_path="custom_fonts/title_font"
	var has_title=control.has_method("set_title")
	var font_path=title_font_path if has_title else "custom_fonts/font"
	if  has_title: 
		control.set_title(text)
	else:
		control.text=text
	if args:control.text=control.text%args
	var locale=TranslationServer.get_locale()
	var new_size=base_size
	var font:DynamicFont=control.get(font_path)
	if locale!="en":
		TranslationServer.set_locale("en")
		var text_in_en=tr(translation_key)
		if args:text_in_en=text_in_en%args
		TranslationServer.set_locale(locale)
		new_size=(base_size*len(text_in_en))/(len(text)-1)
	font.size=new_size
	control.set(font_path,font)

func timer(var delay:float,node=null)->SceneTreeTimer:
	if node:
		return node.get_tree().create_timer(delay)
	else:
		return Utils.get_tree().create_timer(delay)

# givenChannel ~AudioStreamPlayer is mandatory
# sounds can be Array or AudioStream or null (channel should have stream to play then)
func play_sound(givenChannel,sounds=null,volume_db:int=-999,pitch_scale:float=-999.0,effectsNode=null):
	if !givenChannel:
		print_debug("Should provide some AudioStreamPlayer compatible object")
		return null
	# channel provided :	
	var isInWorld=(GameData.world!=null)
	var channel=givenChannel
	var effectsNodeToUse=effectsNode
	if !effectsNodeToUse and isInWorld:effectsNodeToUse=GameData.world.effects_node()
	if effectsNodeToUse:
		channel=channel.duplicate()
		channel.name="%s-DUP-%s"%[channel.name,randi()%99999]
		effectsNodeToUse.add_child(channel)
	if sounds:
		if sounds is Array:
			channel.stream=Utils.choose(sounds) as AudioStream
		else:
			channel.stream=sounds as AudioStream
	elif channel.stream==null:
		print_debug("Should provide some AudioStream in channel or as argument")
	if channel.stream==null:
		DEBUG.error("Sound is null : %s"%sounds)
		if effectsNodeToUse:channel.queue_free()
	else:
		if volume_db!=-999:channel.volume_db=volume_db
		if pitch_scale!=-999.0:channel.pitch_scale=pitch_scale
		channel.play()
		var ogg:=channel.stream as AudioStreamOGGVorbis
		var loop:=ogg and ogg.loop
		if effectsNodeToUse:
			if !loop:
				channel.connect("finished",channel,"queue_free")
				return null
			else:
				return channel
		else:
			return givenChannel
	
			 
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
		


