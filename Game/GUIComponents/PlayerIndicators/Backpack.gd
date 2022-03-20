extends Panel

var selected_item:String

func _ready():
	$Backpack_opened.rect_size=Vector2(0,48)
	$Backpack_opened.visible=false
	$ViewportContainer/Viewport.size=Vector2(1,64)
	$ViewportContainer.visible=false

	
func _process(_delta):
	if GameData.current_player and is_instance_valid(self):
		$ViewportContainer/Viewport/ColorRect/Control/BackPack_Content/MedkitCount.text=str(GameData.current_player.inventory.medkit)
		$ViewportContainer/Viewport/ColorRect/Control/BackPack_Content/TorchCount.text=str(GameData.current_player.inventory.torch)
		$ViewportContainer/Viewport/ColorRect/Control/BackPack_Content/FoodCount.text=str(GameData.current_player.inventory.food)
		$ViewportContainer/Viewport/ColorRect/Control/BackPack_Content/SodasCount.text=str(GameData.current_player.inventory.sodas)
	
	if Input.is_action_just_pressed("ui_inventory"):
		if $Backpack_opened.visible:
			close()
		else:
			open()
			
	for i in range(1,5):
		var action:="ui_use_item{}".format({0:i},"{}")
		if Input.is_action_just_pressed(action):use_item(i)

	
func open():
	if $Backpack_opened.visible or $Tween.is_active(): return
	$Tween.remove_all()
	$Tween.interpolate_property($Backpack_opened,"rect_size",Vector2(0,48),Vector2(184,48),0.5,Tween.TRANS_SINE)
	$Tween.interpolate_property($ViewportContainer/Viewport,"size",Vector2(0,32),Vector2(168,32),0.5,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT,0.01)
	$Backpack_opened.visible=true
	$ViewportContainer.visible=true
	$Tween.start()

func close():
	if not $Backpack_opened.visible or $Tween.is_active(): return
	$Tween.remove_all()
	$Tween.interpolate_property($Backpack_opened,"rect_size",Vector2(184,48),Vector2(0,48),0.5,Tween.TRANS_SINE,0.01)
	$Tween.interpolate_property($ViewportContainer/Viewport,"size",Vector2(168,32),Vector2(0,32),0.5,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
	$Tween.start()

func _on_mouse_entered():
	open()


func _on_Backpack_mouse_detector_input_event(viewport, event:InputEventMouse, shape_idx):
	if event.button_mask&BUTTON_LEFT:
		close()

func _on_Tween_tween_all_completed():
	if $Backpack_opened.rect_size<Vector2(50,48):
		$Backpack_opened.visible=false
		$ViewportContainer.visible=false
	else:
		$Backpack_opened.rect_size=Vector2(184,48)
		$ViewportContainer/Viewport.size=Vector2(168,32)



func _on_Item1_mouse_entered():
	if GameData.current_player and GameData.current_player.inventory.medkit>0:
		$Backpack_opened/Help.text="Il faut peut-être se soigner ? [M]/[1]"
	else:
		$Backpack_opened/Help.text="Pas de medkit !"
	selected_item="Medkit"

func _on_Item1_mouse_exited():
	$Backpack_opened/Help.text=""
	selected_item=""

func _on_Item2_mouse_entered():
	if GameData.current_player and GameData.current_player.inventory.torch>0:
		$Backpack_opened/Help.text="On n'aime pas être dans le noir ? [T]/[2]"
	else:
		$Backpack_opened/Help.text="Pas de torche !"
	selected_item="Torch"

func _on_Item2_mouse_exited():
	$Backpack_opened/Help.text=""
	selected_item=""
	
func _on_Item3_mouse_entered():
	if GameData.current_player and GameData.current_player.inventory.food>0:
		$Backpack_opened/Help.text="La faim est proche ? [E]/[3]"
	else:
		$Backpack_opened/Help.text="Pas de repas !"
	selected_item="Food"

func _on_Item3_mouse_exited():
	$Backpack_opened/Help.text=""
	selected_item=""
	
func _on_Item4_mouse_entered():
	if GameData.current_player and GameData.current_player.inventory.food>0:
		$Backpack_opened/Help.text="On s'en jette un petit dans le gosier ? [D]/[4]"
	else:
		$Backpack_opened/Help.text="Pas de boisson !"
	selected_item="Soda"

func _on_Item4_mouse_exited():
	$Backpack_opened/Help.text=""
	selected_item=""


func use_item(index:int):
	match index:
		1:GameData.current_player.use_medkit()
		2:GameData.current_player.use_torch()
		3:GameData.current_player.consume_food()
		4:GameData.current_player.consume_soda()
				
func _on_Item1_input_event(viewport, event:InputEventMouse, shape_idx):
	if GameData.current_player and event.button_mask&BUTTON_LEFT:
			use_item(1)


func _on_Item2_input_event(viewport, event:InputEventMouse, shape_idx):
	if GameData.current_player and event.button_mask&BUTTON_LEFT:
			use_item(2)


func _on_Item3_input_event(viewport, event:InputEventMouse, shape_idx):
	if GameData.current_player and event.button_mask&BUTTON_LEFT:
			use_item(3)
			
func _on_Item4_input_event(viewport, event:InputEventMouse, shape_idx):
	if GameData.current_player and event.button_mask&BUTTON_LEFT:
			use_item(4)


