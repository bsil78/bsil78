extends CanvasLayer

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$"Panel/DebugDialog/Control/Console messages".pressed=$DebugConfig.console
	$"Panel/DebugDialog/Control/Objects panels".pressed=$DebugConfig.objects
	$"Panel/DebugDialog/Control/Panel messages".pressed=$DebugConfig.panel
	$"Panel/DebugDialog/Control/DebugActivated".pressed=$DebugConfig.active
	TranslationServer.set_locale("fr")
	set_message_translation(true)
	$Panel/StartButton.text=tr("START")
	
	var font=$Panel/StartButton.get("custom_fonts/font")
	font.size=font.size*(5.0/len($Panel/StartButton.text))
	$Panel/StartButton.set("custom_fonts/font",font)
	
func _process(_delta):
	if Input.is_action_pressed("ui_accept"):
		start()

func start():
	GameFuncs.init_new_game()

func _on_StartButton_pressed():
	start()


func _on_OpenDebugDialog_pressed():
	$Panel/DebugDialog.popup()


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


func _on_OpenCreditsWindow_pressed() -> void:
	$Panel/CreditsDialog.popup()
