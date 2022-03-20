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

enum ITEMS { NONE=-1,ANKH=1,TORCH,FOOD,JAR }

var SCAN_CODE_ITEM={
	"fr":{ 
		ITEMS.ANKH:[KEY_A,KEY_1,KEY_KP_1,KEY_F1],
		ITEMS.TORCH:[KEY_T,KEY_2,KEY_KP_2,KEY_F2],
		ITEMS.FOOD:[KEY_M,KEY_R,KEY_3,KEY_KP_3,KEY_F3],
		ITEMS.JAR:[KEY_J,KEY_B,KEY_4,KEY_KP_4,KEY_F4]
	},
	"en":{ 
		ITEMS.ANKH:[KEY_A,KEY_1,KEY_KP_1,KEY_F1],
		ITEMS.TORCH:[KEY_T,KEY_2,KEY_KP_2,KEY_F2],
		ITEMS.FOOD:[KEY_E,KEY_M,KEY_3,KEY_KP_3,KEY_F3],
		ITEMS.JAR:[KEY_J,KEY_D,KEY_4,KEY_KP_4,KEY_F4]
	}

}

var help_text:Dictionary={ ITEMS.ANKH: 
									{ 
									true: "Ankh [A][1][F1] : il faut peut-être se soigner ?", 
									false:"Pas d'Ankh !"
									},
							ITEMS.TORCH:
									{
										true:"Torch [T][2][F2] : on n'aime pas etre dans le noir ?",
										false:"Pas de torche !"
									},
							ITEMS.FOOD:
									{
										true:"Repas [R][M][3][F3] : La faim est proche ? ",
										false:"Pas de repas !"
									},
							ITEMS.JAR:
									{
										true:"Jarre [J][B][4][F4] : on s'en jette un petit dans le gosier ? ",
										false:"Pas de jarre !"
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
	_labels[ITEMS.ANKH]=_bpviewport.get_node("Items/AnkhCount")
	_labels[ITEMS.TORCH]=_bpviewport.get_node("Items/TorchCount")
	_labels[ITEMS.FOOD]=_bpviewport.get_node("Items/FoodCount")
	_labels[ITEMS.JAR]=_bpviewport.get_node("Items/JarCount")
	
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var key_pressed=event.scancode
		if key_pressed in [KEY_TAB,KEY_I]:
			if _bp_open.visible:
				close()
			else:
				open()
			return
		
		for i in SCAN_CODE_ITEM[TranslationServer.get_locale()]:
			if key_pressed in SCAN_CODE_ITEM[TranslationServer.get_locale()][i]:use_item(i)

		

	
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
# warning-ignore:narrowing_conversion
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
			ITEMS.ANKH:GameData.current_player.use_ankh()
			ITEMS.TORCH:GameData.current_player.use_torch()
			ITEMS.FOOD:GameData.current_player.consume_food()
			ITEMS.JAR:GameData.current_player.consume_jar()
				

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
		var inv=GameData.current_player.inventory()
		match item:
			ITEMS.ANKH:return inv.ankh
			ITEMS.TORCH:return inv.torch
			ITEMS.FOOD:return inv.food
			ITEMS.JAR:return inv.jar

