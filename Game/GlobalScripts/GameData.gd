extends Node

var current_level := 0
const max_levels := 2
var transition_state :int = GameEnums.TRANSITION_STATUS.NONE
var current_player:Node2D=null
var players:={}
var players_slots:={"PlayerOne":1,"PlayerTwo":2}
var players_saves:={}
var world:Node2D=null

const players_names:=["PlayerOne","PlayerTwo"]
const MAX_HIT_DISTANCE=38


export(int) var startLevel := 1
export(float,0.1,1,0.1) var ground_friction:=0.5
export(int,8,64,8) var cell_size:=32
export(int,1,10,1) var long_transition_delay:=7
export(int,1,10,1) var short_transition_delay:=3


func _ready():
	GameData.long_transition_delay=self.long_transition_delay
	GameData.short_transition_delay=self.short_transition_delay
	GameData.cell_size=self.cell_size
	GameData.ground_friction=self.ground_friction
	GameData.startLevel=self.startLevel
