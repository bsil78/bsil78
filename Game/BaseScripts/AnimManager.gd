extends AnimationPlayer

export(PoolStringArray) var loop_anims
export(PoolStringArray) var unstoppable_anims
export(PoolStringArray) var anims_autochaining
export(PoolStringArray) var virtual_anims
export(String) var start_anim
export(PoolStringArray) var debug_anims

var virtual_anims_dic:={}
var current_va:=""
var anims_queue:=[]


func _ready():
	for va in virtual_anims:
		var va_queue:Array=va.split(":")
		virtual_anims_dic[va_queue[0]]=va_queue[1].split(">")
	self.connect("animation_finished",self,"end_of_anim")
	reset()
	
func reset():
	current_va=""
	anims_queue=[]
	clear_queue()
	stop()
	if start_anim:trigger_anim(start_anim)
		
func trigger_anim(anim:String,enforce_same:bool=false)->bool:
	if anim in virtual_anims_dic:
		if !current_va.empty() and current_va==anim and !enforce_same: 
			dbgmsg(anim,"not playing anim %s because same VA playing"%anim)
			return false
		if is_playing() and is_not_loop(anim):
			if current_va in unstoppable_anims:
				anims_queue.push_back(anim)
				dbgmsg(anim,"not playing anim %s because unstoppable VA %s playing"%[anim,current_va])
				return false
			if current_animation in unstoppable_anims:
				anims_queue.push_back(anim)
				dbgmsg(anim,"not playing VA %s because unstoppable anim %s playing"%[anim,current_animation])
				return false
		dbgmsg(anim,"playing anim %s"%anim)
		play_va(anim)
		return true			
	else:
		if current_animation==anim and !enforce_same: 
			dbgmsg(anim,"not playing anim %s because same anim playing"%anim)
			return false
		if current_animation in unstoppable_anims and is_playing():
			anims_queue.push_back(anim)
			dbgmsg(anim,"not playing anim %s because unstoppable anim %s playing"%[anim,current_animation])
			return false
		else:
			dbgmsg(anim,"playing anim %s"%anim)
			play(anim)
			queue_next_anims(anim)
			return true

func is_not_loop(anim):
	if has_animation(anim):
		return !get_animation(anim).loop
	else:
		return not anim in loop_anims

func dbgmsg(anim,msg):
	if anim in debug_anims:print(msg)

func end_of_anim(anim_ended):
	dbgmsg(anim_ended,"anim %s finished"%anim_ended)
	if !get_queue().empty() or is_playing(): return
	current_va=""
	if anims_queue.empty():
		if !debug_anims.empty():print("no anims in queue to play")
		return
	if !debug_anims.empty():print("anims queue : %s"%str(anims_queue))
	var found_next:=false
	var next=""
	while(!found_next and !anims_queue.empty()):
		next=anims_queue.pop_front()
		if next in virtual_anims:
			found_next=true
			for va_anim in virtual_anims_dic[next]:
				if !(is_not_loop(va_anim) or anims_queue.empty()): 
					found_next=false
					break
		else:
			found_next= is_not_loop(next) or anims_queue.empty()
	if found_next and !next.empty():
		dbgmsg(next,"anim %s triggered from queue"%next)
		trigger_anim(next,true)
	else:
		if !debug_anims.empty():
			printerr("no anims queue found to play : %s"%str(anims_queue))

func play_va(va_to_play):
	if is_playing() and is_not_loop(current_animation): 
		if !debug_anims.empty():
			printerr("Currently playing %s, cannot play VA %s"%[current_animation,va_to_play])
		return
	current_va=va_to_play
	var current_va_queue=virtual_anims_dic[va_to_play]
	if len(current_va_queue)>0:
		var first=current_va_queue[0]
		dbgmsg(va_to_play,"playing anim %s of %s"%[first,va_to_play])
		play(first)
	if len(current_va_queue)>1:
		for idx_next in range(1,len(current_va_queue)):
			queue(current_va_queue[idx_next])
		
	
				
func queue_next_anims(anim):
	for chain in anims_autochaining:
		var anims:Array=chain.split(">")			
		var front=anims.pop_front()
		if front==anim:
			for next in anims:
				anims_queue.push_back(next)


