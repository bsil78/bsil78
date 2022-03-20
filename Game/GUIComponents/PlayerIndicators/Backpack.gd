extends Control

onready var _bptween:=$Tween
onready var _bp_open:=$BackpackOpen
onready var _bphelp:=$BackpackOpen/Help
onready var _bp_open_content:=$BackpackOpen/Content
onready var _bp_items:=$BackpackOpen/Content/Items
onready var select_effect=$BackpackOpen/Content/Items/Selection 

var _labels:={}

class BackPackItem:
	var order:int
	var enum_id:int
	var name:String
	var scan_codes_by_locale:Dictionary
	var help:Dictionary
	
	func _init(porder,penum_id,pname,pscancodes,phelp):
		self.order=porder
		self.enum_id=penum_id
		self.name=pname
		self.scan_codes_by_locale=pscancodes
		self.help=phelp
	
	
	static func by_order(porder)->BackPackItem:
		for item in items():
			if item.order==porder: return item
		print_debug("Bad item order : %s"%porder)
		return null
		
	static func by_enum(penum_id)->BackPackItem:
		for item in items():
			if item.enum_id==penum_id: return item
		print_debug("Bad item : %s"%penum_id)
		return null
		
	static func by_name(pname)->BackPackItem:
		for item in items():
			if item.name==pname: return item
		print_debug("Bad item name : %s"%pname)
		return null

	func use():
		if player_count()>0:
			match enum_id:
				GameEnums.ITEMS.ANKH:GameData.current_player.use_ankh()
				GameEnums.ITEMS.TORCH:GameData.current_player.use_torch()
				GameEnums.ITEMS.FOOD:GameData.current_player.consume_food()
				GameEnums.ITEMS.JAR:GameData.current_player.consume_jar()
				_: print_debug("Bad item : %s"%enum_id)

	func player_count()->int:
		if GameData.current_player:
			var inv=GameData.current_player.inventory()
			match enum_id:
				GameEnums.ITEMS.ANKH:return inv.ankh
				GameEnums.ITEMS.TORCH:return inv.torch
				GameEnums.ITEMS.FOOD:return inv.food
				GameEnums.ITEMS.JAR:return inv.jar
				_: print_debug("Bad item : %s"%enum_id)
		return 0
		
	static func items()->Array:
		return [
		
			BackPackItem.new(0,GameEnums.ITEMS.ANKH,"ANKH",
							 { 	"fr": [KEY_A,KEY_1,KEY_KP_1,KEY_F1], 
								"en": [KEY_A,KEY_1,KEY_KP_1,KEY_F1] },
							 { 
								true: "Ankh [A][1][F1] : il faut peut-être se soigner ?", 
								false:"Pas d'Ankh !"
							 } ),
							
			BackPackItem.new(1,GameEnums.ITEMS.TORCH,"TORCH",
							 { 	"fr": [KEY_T,KEY_2,KEY_KP_2,KEY_F2], 
								"en": [KEY_T,KEY_2,KEY_KP_2,KEY_F2] },
							 {
								true:"Torch [T][2][F2] : on n'aime pas etre dans le noir ?",
								false:"Pas de torche !"
							 } ),
								
			BackPackItem.new(2,GameEnums.ITEMS.FOOD,"FOOD",
							 { 	"fr": [KEY_M,KEY_R,KEY_3,KEY_KP_3,KEY_F3], 
								"en": [KEY_E,KEY_M,KEY_3,KEY_KP_3,KEY_F3] },
							 {
								true:"Repas [R][M][3][F3] : La faim est proche ? ",
								false:"Pas de repas !"
							 } ),
								
			BackPackItem.new(3,GameEnums.ITEMS.JAR,"JAR",
							 { 	"fr": [KEY_J,KEY_B,KEY_4,KEY_KP_4,KEY_F4], 
								"en": [KEY_J,KEY_D,KEY_4,KEY_KP_4,KEY_F4] },
							 {
								true:"Jarre [J][B][4][F4] : on s'en jette un petit dans le gosier ? ",
								false:"Pas de jarre !"
							 } )
		]
		
	static func first_item():
		return items()[0]
	
	static func last_item():
		return items()[3]
			
const PAD_INV_SELECT=[JOY_XBOX_A]
const PAD_INV_LEFT=[JOY_L,JOY_L2,JOY_L3]
const PAD_INV_RIGHT=[JOY_R,JOY_R2,JOY_R3]
const PAD_INV_OPEN = [ JOY_XBOX_Y]
const PAD_INV_CLOSE = [ JOY_XBOX_B, JOY_XBOX_Y ]


var is_ready=false
var is_open:=false
var select_effect_zero_position
var selected_item:BackPackItem=null


func _ready():
	_bp_open.hide()
	disable_items_buttons()
	_labels[GameEnums.ITEMS.ANKH]=find_node("AnkhCount",true,false)
	_labels[GameEnums.ITEMS.TORCH]=find_node("TorchCount",true,false)
	_labels[GameEnums.ITEMS.FOOD]=find_node("FoodCount",true,false)
	_labels[GameEnums.ITEMS.JAR]=find_node("JarCount",true,false)
	select_effect_zero_position=select_effect.rect_position
	unselect_item()
	is_ready=true
	
func _input(event: InputEvent) -> void:
	var input=Utils.input_from_event(event)
	
	#print("Backpack open %s"%_bp_open.visible)
	
	if _bp_open.visible:
		
		for item in BackPackItem.items():
			if input.key_pressed in item.scan_codes_by_locale[TranslationServer.get_locale()]:item.use()
		
		if input.key_pressed in [KEY_TAB,KEY_I] or input.pad_button in PAD_INV_CLOSE : 
			close()
			return
		if input.pad_button in PAD_INV_SELECT and selected_item:
			selected_item.use()
			unselect_item()
			close()
			return
		
		var max_order=BackPackItem.items().size()-1
		var selecting:BackPackItem=null
		if input.pad_button in PAD_INV_LEFT:
			if !selected_item:
				selecting=BackPackItem.last_item()
			else:
				selecting=BackPackItem.by_order(wrapi(selected_item.order-1,0,max_order+1))
		if input.pad_button in PAD_INV_RIGHT:
			if !selected_item:
				selecting=BackPackItem.first_item()
			else:
				selecting=BackPackItem.by_order(wrapi(selected_item.order+1,0,max_order+1))
		if selecting: 
			select_item(selecting.name)
			return	
		
	else:
		var open_action_pressed=input.key_pressed in [KEY_TAB,KEY_I] or input.pad_button in PAD_INV_OPEN
		var right_inv_pressed=input.pad_button in PAD_INV_RIGHT
		var left_inv_pressed=input.pad_button in PAD_INV_LEFT
		var with_item
		if left_inv_pressed:with_item=BackPackItem.last_item().name
		if right_inv_pressed:with_item=BackPackItem.first_item().name
		if open_action_pressed or right_inv_pressed or left_inv_pressed:open(with_item)

			
func open(with_item=null):
	if _bptween.is_active() or is_open or !GameData.current_player: return
	update_items()
	is_open=true
	_bptween.remove_all()
	_bptween.interpolate_property(_bp_open,"rect_size",Vector2(0,48),Vector2(184,48),0.5,Tween.TRANS_SINE)
	_bptween.interpolate_property(_bp_open_content,"rect_size",Vector2(0,32),Vector2(168,32),0.5,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT,0.01)
	if with_item:_bptween.connect("tween_all_completed",self,"select_item",[with_item],CONNECT_ONESHOT)
	_bp_open.show()
	_bptween.start()
	

func close():
	if _bptween.is_active() or !is_open: return
	is_open=false
	unselect_item()
	disable_items_buttons()
	_bptween.remove_all()
# warning-ignore:narrowing_conversion
	_bptween.interpolate_property(_bp_open,"rect_size",Vector2(184,48),Vector2(0,48),0.5,Tween.TRANS_SINE,0.01)
	_bptween.interpolate_property(_bp_open_content,"rect_size",Vector2(168,32),Vector2(0,32),0.5,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
	_bptween.start()


func backpack_mouse_clicked(_viewport, event:InputEvent, _shape_idx):
	if event is InputEventMouseButton and event.button_mask&BUTTON_LEFT:close()

func bptween_completed():
	if !is_open:
		_bp_open.hide()
	else:
		_bp_open.rect_size=Vector2(184,48)
		_bp_open_content.rect_size=Vector2(168,32)
		enable_items_buttons()


func disable_items_buttons():
	for node in _bp_items.get_children():
		if node.name.match("Item?"):
			(node as BaseButton).disabled=true 
	
func enable_items_buttons():
	for node in _bp_items.get_children():
		if node.name.match("Item?"):
			(node as BaseButton).disabled=false 

func unselect_item():
	_bphelp.text=""
	select_effect.hide()
	selected_item=null
	
func click_item(_viewport, event:InputEvent, _shape_idx,item_name:String):
	if event is InputEventMouseButton and event.button_mask&BUTTON_LEFT:
		var item=BackPackItem.by_name(item_name)
		if item:item.use()

#func use_item(item_name:String):
#	var item=BackPackItem.by_name(item_name)
#	if item:item.use()
				

func select_item(item_name:String):
	var item=BackPackItem.by_name(item_name)
	if !item or !is_instance_valid(GameData.current_player):
		unselect_item()
		return
	selected_item=item
	var own_one:bool=selected_item.player_count()>0
	_bphelp.text=selected_item.help[own_one]
	select_effect.rect_position=select_effect_zero_position+Vector2(40,0)*item.order
	select_effect.show()
	
func update_items():
	if is_ready:
		if GameData.current_player and is_instance_valid(self):
			for item in BackPackItem.items():
				_labels[item.enum_id].text=str(item.player_count())
