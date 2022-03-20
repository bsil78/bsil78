extends CanvasLayer

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$"Panel/WindowDialog/Control/Console messages".pressed=$DebugConfig.console
	$"Panel/WindowDialog/Control/Objects panels".pressed=$DebugConfig.objects
	$"Panel/WindowDialog/Control/Panel messages".pressed=$DebugConfig.panel
	$"Panel/WindowDialog/Control/DebugActivated".pressed=$DebugConfig.active

func _process(_delta):
	if Input.is_action_pressed("ui_accept"):
		start()

func start():
	GameFuncs.init_new_game()

func _on_StartButton_pressed():
	start()


func _on_OpenDebugDialog_pressed():
	$Panel/WindowDialog.popup()


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
