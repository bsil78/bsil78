extends Node2D

var _bptween:Tween
var selected_item:int
var _bp_open:Panel
var _bpviewport:Viewport
var _bpview:ViewportContainer
var _bp_open_content:TextureRect
var _bphelp:Label
var _labels:={}
var is_open:=false

enum ITEMS { NONE=-1,MEDKIT=1,TORCH,FOOD,SODA }

var help_text:Dictionary={ ITEMS.MEDKIT: 
									{ 
									true: "Il faut peut-être se soigner ? [M]/[1]", 
									false:"Pas de medkit !"
									},
							ITEMS.TORCH:
									{
										true:"On n'aime pas être dans le noir ? [T]/[2]",
										false:"Pas de torche !"
									},
							ITEMS.FOOD:
									{
										true:"La faim est proche ? [E]/[3]",
										false:"Pas de repas !"
									},
							ITEMS.SODA:
									{
										true:"On s'en jette un petit dans le gosier ? [D]/[4]",
										false:"Pas de boisson !"
									}	
									
						}


func _ready():
	_bptween=$Tween
	_bphelp=$BackpackOpen/Help
	_bp_open=$BackpackOpen
	_bp_open.rect_size=Vector2(0,48)
	_bp_open.hide()
	_bp_open.get_node("ItemsSensors").hide()
	_bpviewport=$View/Viewport
	_bpview=$View
	_bpviewport.size=Vector2(1,64)
	_bpview.hide()
	_labels[ITEMS.MEDKIT]=_bpviewport.get_node("Items/MedkitCount")
	_labels[ITEMS.TORCH]=_bpviewport.get_node("Items/TorchCount")
	_labels[ITEMS.FOOD]=_bpviewport.get_node("Items/FoodCount")
	_labels[ITEMS.SODA]=_bpviewport.get_node("Items/SodasCount")
	
func _process(_delta):
	
	if Input.is_action_just_pressed("ui_inventory"):
		if _bp_open.visible:
			close()
		else:
			open()
			
	for i in range(1,5):
		var action:="ui_use_item{}".format([i],"{}")
		if Input.is_action_just_pressed(action):use_item(i)

	
func open():
	if _bptween.is_active() or is_open: return
	is_open=true
	_bptween.remove_all()
	_bptween.interpolate_property(_bp_open,"rect_size",Vector2(0,48),Vector2(184,48),0.5,Tween.TRANS_SINE)
	_bptween.interpolate_property(_bpviewport,"size",Vector2(0,32),Vector2(168,32),0.5,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT,0.01)
	_bp_open.show()
	_bpview.show()
	_bptween.start()
	

func close():
	if _bptween.is_active() or !is_open: return
	is_open=false
	hide_help_item()
	_bp_open.get_node("ItemsSensors").hide()
	_bptween.remove_all()
	_bptween.interpolate_property(_bp_open,"rect_size",Vector2(184,48),Vector2(0,48),0.5,Tween.TRANS_SINE,0.01)
	_bptween.interpolate_property(_bpviewport,"size",Vector2(168,32),Vector2(0,32),0.5,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
	_bptween.start()


func backpack_mouse_entered():
	open()

func backpack_mouse_clicked(_viewport, event:InputEventMouse, _shape_idx):
	if event.button_mask&BUTTON_LEFT:close()

func bptween_completed():
	if !is_open:
		_bp_open.hide()
		_bpview.hide()
	else:
		_bp_open.rect_size=Vector2(184,48)
		_bpviewport.size=Vector2(168,32)
		_bp_open.get_node("ItemsSensors").show()


func hide_help_item():
	_bphelp.text=""
	selected_item=ITEMS.NONE

func click_item(_viewport, event:InputEventMouse, _shape_idx,item):
	if event.button_mask&BUTTON_LEFT:use_item(item)

func use_item(item:int):
	if GameData.current_player:
		match item:
			ITEMS.MEDKIT:GameData.current_player.use_medkit()
			ITEMS.TORCH:GameData.current_player.use_torch()
			ITEMS.FOOD:GameData.current_player.consume_food()
			ITEMS.SODA:GameData.current_player.consume_soda()
				

func show_help_item(item):
	if GameData.current_player and player_item_count(item)>0:
		_bphelp.text=help_text[item][true]
	else:
		_bphelp.text=help_text[item][false]
	selected_item=item

func update_items():
	if GameData.current_player and is_instance_valid(self):
		for item in range(1,5):
			_labels[item].text=str(player_item_count(item))

func player_item_count(item):
	if GameData.current_player:
		var inv=GameData.current_player.get_node("Inventory")
		match item:
			ITEMS.MEDKIT:return inv.medkit
			ITEMS.TORCH:return inv.torch
			ITEMS.FOOD:return inv.food
			ITEMS.SODA:return inv.sodas

