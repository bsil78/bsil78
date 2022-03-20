extends CanvasLayer

var coin_gained:=0
var world

func _ready():
	world=GameData.world
	world.connect("player_gained_coin",self,"play_coin_gain_for")
	world.connect("level_ready",$Backpack,"update_items")
	
func disconnect_inventory(player):
	print("inventory disconnected of %s"%player.name)
	var inv:Inventory=player.inventory()
	inv.disconnect("inventory_changed",$Backpack,"update_items")
	inv.disconnect("inventory_changed",$PlayerGodSign,"update")
	
func connect_inventory(player):
	print("inventory connected of %s"%player.name)
	var inv:Inventory=player.inventory()
	inv.connect("inventory_changed",$Backpack,"update_items")
	inv.connect("inventory_changed",$PlayerGodSign,"update")

func update_indicators(world,player):
	$GodSign.update_indicator(world)
	$PlayerGodSign.update_indicator(player)
	
func play_coin_gain_for(player):
	var new_coin=$Coin.duplicate()
	coin_gained+=1
	new_coin.name="%s-SP[%s]"%[new_coin.name,coin_gained]
	add_child(new_coin)
	new_coin.global_position =  player.get_global_transform_with_canvas().get_origin()
	var tween:= Tween.new();
	new_coin.add_child(tween)
	tween.interpolate_property(new_coin,"global_position",new_coin.global_position,$PlayerGodSign.rect_global_position+$PlayerGodSign.rect_size/2,1.0,Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
	new_coin.show()
	tween.connect("tween_all_completed",self,"remove_coin",[new_coin])
	tween.start()

func remove_coin(coin):
	coin.hide()
	remove_child(coin)
	coin.queue_free()
