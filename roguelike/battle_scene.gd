extends Node2D
## Battle Scene - combines boat background with battle UI

signal battle_finished(victory: bool, rewards: Dictionary)

@onready var background: Node2D = $RoguelikeBackground
@onready var ui_layer: CanvasLayer = $UILayer
@onready var battle_board: Control = $UILayer/BattleBoard
@onready var battle_manager: BattleManager = $UILayer/BattleBoard/BattleManager

var current_fish: Array[FishData] = []
var current_deck: Array[CardData] = []
var boat_hp: int = 3


func _ready() -> void:
	# Connect battle end signals
	battle_manager.battle_won.connect(_on_battle_won)
	battle_manager.battle_lost.connect(_on_battle_lost)
	
	# Start hidden - CanvasLayer doesn't inherit visibility from Node2D
	hide_battle()


## Show the battle UI
func show_battle() -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	background.visible = true
	background.process_mode = Node.PROCESS_MODE_INHERIT
	ui_layer.visible = true
	battle_board.visible = true


## Hide the battle UI  
func hide_battle() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	background.visible = false
	background.process_mode = Node.PROCESS_MODE_DISABLED
	ui_layer.visible = false
	battle_board.visible = false


## Call this to start a battle with specific deck and enemies
func start_battle(deck: Array[CardData], enemies: Array[FishData], boat_health: int = 3) -> void:
	current_deck = deck
	current_fish = enemies
	boat_hp = boat_health
	
	show_battle()
	battle_manager.start_battle(deck, enemies, boat_health)


func _on_battle_won() -> void:
	# Calculate rewards based on fish defeated, etc
	var rewards := {
		"victory": true,
		"fish_caught": [],  # Could track this during battle
		"cards_earned": [],
		"reputation": 10
	}
	
	# Delay before emitting to let player see victory message
	await get_tree().create_timer(2.0).timeout
	battle_finished.emit(true, rewards)


func _on_battle_lost() -> void:
	var rewards := {
		"victory": false,
		"fish_caught": [],
		"cards_earned": [],
		"reputation": 0
	}
	
	await get_tree().create_timer(2.0).timeout
	battle_finished.emit(false, rewards)


## Get remaining boat HP after battle
func get_remaining_boat_hp() -> int:
	return battle_manager.boat_hp
