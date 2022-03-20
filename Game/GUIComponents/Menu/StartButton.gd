extends Button

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(_delta):
	if Input.is_action_pressed("ui_accept"):
		start()

func _pressed():
	start()

func start():
	GameFuncs.init_new_game()
