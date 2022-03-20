extends CanvasLayer

var game_id:=1
var game_name={}
var current_old_name

onready var kd:Timer=$KeyDelay
onready var gd:WindowDialog=$Panel/GamesDialog
onready var cd:WindowDialog=$Panel/CreditsDialog
onready var dd:WindowDialog=$Panel/DebugDialog
onready var od:WindowDialog=$Panel/OptionsDialog
onready	var games:ItemList=$Panel/GamesDialog/Control/Games
onready var game_name_popup:PopupDialog=$Panel/GamesDialog/Control/GameNamePopup
onready var game_name_edit:PopupDialog=$Panel/GamesDialog/Control/GameNamePopup/LineEdit
onready var languageLabel:PopupMenu=$Panel/OptionsDialog/Container/Language
onready var languagePopupMenu:PopupMenu=$Panel/OptionsDialog/Container/Language/PopupMenu

const game_edit_validation_key=[ KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE ]
const start_keys=[ KEY_SPACE, KEY_ENTER, KEY_KP_ENTER ]
const close_dialog_keys=[ KEY_SPACE, KEY_BACKSPACE, KEY_ESCAPE]
const languageName={
	"fr":"français",
	"en":"english"
}


var credits_scancode:=KEY_C
var games_scancode:=KEY_G
var options_scancode:=KEY_O

var input_locked:=false

enum DIALOGS { NONE=-1, DBGD=1,CREDSD,GAMESD, OPTIONSD }

func dialog_opened()->int:
	if cd.visible: return DIALOGS.CREDSD
	if gd.visible: return DIALOGS.GAMESD
	if dd.visible: return DIALOGS.DBGD
	if od.visible: return DIALOGS.OPTIONSD
	
	return DIALOGS.NONE

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$"Panel/DebugDialog/Control/Console messages".pressed=$DebugConfig.console
	$"Panel/DebugDialog/Control/Objects panels".pressed=$DebugConfig.objects
	$"Panel/DebugDialog/Control/Panel messages".pressed=$DebugConfig.panel
	$"Panel/DebugDialog/Control/DebugActivated".pressed=$DebugConfig.active
	change_locale("fr")
	game_name_edit.editable=false
	game_name_popup.rect_size=Vector2(190,20)
	game_name_edit.rect_size=Vector2(190,20)
	for ign in range(1,10):
		game_name[ign]=init_game_label(ign)

func init_game_label(id):
	return "<<%s>>"%(tr("GAME_LABEL")%id)

func change_locale(locale):
	TranslationServer.set_locale(locale)
	set_message_translation(true)
	Utils.init_ui_locale($Panel/helpStartButton,10,"ENTER_KEY")
	Utils.init_ui_locale($Panel/StartButton,24,"START")
	Utils.init_ui_locale($Panel/gameLabel,10,"GAME_LABEL",[game_id])
	Utils.init_ui_locale($Panel/OpenCreditsDialog,12,"CREDITS")
	Utils.init_ui_locale($Panel/OpenGamesDialog,12,"GAMES")
	Utils.init_ui_locale($Panel/OpenOptionsDialog,12,"OPTIONS")
	Utils.init_ui_locale(gd,22,"GAMES_TITLE")
	Utils.init_ui_locale(cd,22,"CREDITS_TITLE")
	Utils.init_ui_locale(od.get_node("Container/Title"),22,"OPTIONS_TITLE")
	match locale:
		"fr":
			credits_scancode=KEY_R
			games_scancode=KEY_P
			options_scancode=KEY_O
		_:
			credits_scancode=KEY_C
			games_scancode=KEY_G
			options_scancode=KEY_O
	
func _input(event):

	if event is InputEventKey and event.pressed:
		var key_pressed=event.scancode
#		print("Key pressed : %s"%key_pressed)
		if input_locked: return
		var dialog=dialog_opened()
		if DIALOGS.NONE!=dialog:
			if DIALOGS.GAMESD==dialog:
				if kd.time_left==0:
					var new_id=-1
					if key_pressed==KEY_UP:
						new_id=max(game_id-1,1)
					if key_pressed==KEY_DOWN:
						new_id=min(game_id+1,9)
					if new_id!=-1:
						input_locked=true
						kd.start(0.1)
						update_game(new_id)
						return
				if !game_name_popup.visible:
					for g in range(1,10):
						if key_pressed in [ KEY_0+g,(KEY_F1+g-1),KEY_KP_0+g]:
							update_game(g)
							return
					if kd.time_left==0 and key_pressed in close_dialog_keys:
						game_name_edit.editable=false
						set_game_label(game_id,game_name_edit.text)
						input_locked=true
						kd.start(0.1)
						gd.hide()
						return
					
					if key_pressed in [KEY_ENTER,KEY_KP_ENTER]:
						focus_on_game_name_edit()
						return
				else:
					
					if kd.time_left==0 and key_pressed in game_edit_validation_key:
						input_locked=true
						set_game_label(game_id,game_name_edit.text)
						update_game_label(game_id)
						kd.start(0.1)
						game_name_popup.hide()
						gd.get_close_button().disabled=false
						games.mouse_filter=Control.MOUSE_FILTER_STOP
						return
			else:
				if kd.time_left==0 and key_pressed in close_dialog_keys:
					input_locked=true
					cd.hide()
					dd.hide()
					od.hide()
					languagePopupMenu.hide()
					kd.start(0.5)
					return
		else:
			if key_pressed in start_keys :
				start()
				return
			if key_pressed==KEY_ESCAPE :
				Utils.quit_from(self)
				return
			if key_pressed==credits_scancode:
				_on_OpenCreditsDialog_pressed()
				return
			if key_pressed==games_scancode:
				_on_OpenGamesDialog_pressed()
				return
			if key_pressed==options_scancode:
				_on_OpenOptionsDialog_pressed()
				return
			if $Panel/OpenDebugDialog.visible and key_pressed in [KEY_APOSTROPHE,KEY_TWOSUPERIOR]:
				_on_OpenDebugDialog_pressed()
				return

func set_game_label(id,label):
	if label.empty(): 
		game_name[game_id]=current_old_name
		return
	var new_label=label
	for idg in range(1,10):
		if idg==id: continue
		if game_name[idg]==label:
			new_label=current_old_name
			break
	game_name[id]=new_label
	current_old_name=game_name[id]
	update_title_screen_name()

func set_game_name_edit_position():
	game_name_popup.rect_position=gd.rect_position+Vector2(4,28)
	game_name_popup.rect_position+=Vector2(155,(game_id-1)*30)

func focus_on_game_name_edit(force_show:bool=true):
	var value="" if (game_name[game_id]==init_game_label(game_id)) else game_name[game_id]
	current_old_name=game_name[game_id]
	game_name_edit.text=value
	if force_show:
		set_game_name_edit_position()
		gd.get_close_button().disabled=true
		games.mouse_filter=Control.MOUSE_FILTER_IGNORE
		game_name_edit.editable=true
		game_name_popup.show()
		game_name_edit.grab_focus()
		game_name_edit.caret_position=len(game_name[game_id])
	elif game_name_popup.visible:
		set_game_name_edit_position()
		
func update_game(new_value):
	if game_name_popup.visible:set_game_label(game_id,game_name_edit.text)
	update_game_label(game_id)
	game_id=new_value
	current_old_name=game_name[game_id]
	games.select(game_id-1,true)
	update_title_screen_name()
	focus_on_game_name_edit(false)

func update_title_screen_name():
	$Panel/gameLabel.text = game_key_name(game_id)
	var isInitName:bool=(game_name[game_id]==init_game_label(game_id))
	var titleScreenName="" if isInitName else "(%s)"%game_name[game_id]
	$Panel/gameName.text = titleScreenName

func update_game_label(id):
	games.set_item_text(id-1,game_label(id))	


func game_label(id):
	var gname=game_name[id]
	return "%s : %s"%[game_key_name(id),gname if !gname.empty() else "-"]

func game_key_name(id):
	return tr("GAME_LABEL")%id
			
func start():
	GameFuncs.init_new_game()

func _on_StartButton_pressed():
	start()


func _on_OpenDebugDialog_pressed():
	dd.popup_centered()


func _on_DebugActivated_toggled(button_pressed):
	$DebugConfig.active=button_pressed
	$DebugConfig.update_debug()

func _on_Console_messages_toggled(button_pressed):
	$DebugConfig.console=button_pressed
	$DebugConfig.update_debug()

func _on_Panel_messages_toggled(button_pressed):
	$DebugConfig.panel=button_pressed
	$DebugConfig.update_debug()

func _on_Objects_panels_toggled(button_pressed):
	$DebugConfig.objects=button_pressed
	$DebugConfig.update_debug()


func _on_Debug_Level_toggled(button_pressed: bool) -> void:
	$DebugConfig.debuglevel=button_pressed
	$DebugConfig.update_debug()


func _on_OpenCreditsDialog_pressed() -> void:
	cd.popup_centered()


func _on_OpenGamesDialog_pressed() -> void:
	games.clear()
	for l in range(1,10):
		games.add_item(game_label(l),null,true)
	games.select(game_id-1,true)
	gd.popup_centered()


func _on_KeyDelay_timeout() -> void:
	input_locked=false

func _on_GamesDialog_item_rect_changed() -> void:
	if gd and gd.visible and game_name_edit.visible:
		set_game_name_edit_position()


func _on_Games_item_selected(index: int) -> void:
	update_game(index+1)


func _on_Games_item_activated(_index: int) -> void:
	focus_on_game_name_edit()


func _on_OpenOptionsDialog_pressed() -> void:
	var locale=TranslationServer.get_locale()
	languageLabel.text=tr("LANGUAGE")+languageName[locale]
	od.popup_centered()


func _on_Language_focus_entered() -> void:
	var font:Font=languageLabel.get("custom_fonts/font")
	var languageLabelSize=font.get_string_size(tr("LANGUAGE"))
	var current_locale=TranslationServer.get_locale()
	for idit in range(0,languagePopupMenu.items.size()):
		var is_locale=locale_from_name(languagePopupMenu.get_item_text(idit))==current_locale
		languagePopupMenu.set_item_checked(idit,is_locale)
	languagePopupMenu.popup(Rect2(od.rect_position+languageLabel.rect_position+Vector2(languageLabelSize.x,-languageLabelSize.y),Vector2(od.rect_size.x-languageLabelSize.x,32)))

func locale_from_name(lname):
	for locale in languageName:
		if lname==languageName[locale]:
			return locale
	return "en"
	
func _on_Language_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_Language_focus_entered()


func _on_OptionsOkButton_pressed() -> void:
	od.hide()

func _on_LanguagePopupMenu_id_pressed(id: int) -> void:
	for locale in languageName:
		if languageName[locale]==languagePopupMenu.get_item_text(id):
			change_locale(locale)
			languageLabel.text=tr("LANGUAGE")+languageName[locale]
			return
