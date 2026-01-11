extends Node
class_name RunManager

## Manages a full roguelike run - map navigation, battles, events

signal run_started
signal run_ended(victory: bool)
signal entered_node(node: MapNodeData)
signal battle_started(fish: Array[FishData])
signal battle_ended(victory: bool)

enum GameState {
	MAP,
	BATTLE,
	EVENT,
	SALVAGE,
	REST,
	MERCHANT,
	GAME_OVER
}

var current_state: GameState = GameState.MAP
var map_manager: MapManager
var boat_hp: int = 3
var max_boat_hp: int = 3

# Player deck
var player_deck: Array[CardData] = []
var player_hand: Array[CardData] = []

# Current area
var current_area: int = 1
var area_names: Array[String] = ["The Shallows", "Flooded Streets", "Cathedral Depths", "The Divine Marrow"]

# Fish pools per area (would be loaded from resources in full game)
var fish_pools: Dictionary = {}


func _ready() -> void:
	_setup_starter_deck()
	_setup_fish_pools()


func _setup_starter_deck() -> void:
	# Create basic starter cards
	var harpoon := CardData.new()
	harpoon.card_name = "Rusty Harpoon"
	harpoon.hook = 2
	harpoon.line = 3
	
	var net := CardData.new()
	net.card_name = "Old Net"
	net.hook = 1
	net.line = 2
	net.sinker = 1
	net.ability = "Stun"
	
	var anchor := CardData.new()
	anchor.card_name = "Anchor"
	anchor.hook = 1
	anchor.line = 4
	
	var line := CardData.new()
	line.card_name = "Fishing Line"
	line.hook = 1
	line.line = 2
	
	player_deck = [harpoon, net, anchor, line, line.duplicate_card()]


func _setup_fish_pools() -> void:
	# Area 1 fish
	var trout := FishData.new()
	trout.fish_name = "Trout"
	trout.max_hp = 3
	trout.attack = 1
	
	var eel := FishData.new()
	eel.fish_name = "Eel"
	eel.max_hp = 4
	eel.attack = 1
	eel.behavior = "Skipper"
	
	var crab := FishData.new()
	crab.fish_name = "Crab"
	crab.max_hp = 5
	crab.attack = 1
	crab.behavior = "Latcher"
	
	fish_pools[1] = {
		"common": [trout],
		"uncommon": [eel, crab],
		"elite": [],
		"boss": []
	}


func start_run() -> void:
	current_state = GameState.MAP
	boat_hp = max_boat_hp
	current_area = 1
	_setup_starter_deck()
	run_started.emit()


func handle_node_selected(node: MapNodeData) -> void:
	entered_node.emit(node)
	
	match node.type:
		MapNodeData.NodeType.COMBAT:
			_start_combat(false)
		MapNodeData.NodeType.ELITE:
			_start_combat(true)
		MapNodeData.NodeType.BOSS:
			_start_boss()
		MapNodeData.NodeType.REST:
			_enter_rest()
		MapNodeData.NodeType.SALVAGE:
			_enter_salvage()
		MapNodeData.NodeType.MYSTERY:
			_enter_mystery()
		MapNodeData.NodeType.MERCHANT:
			_enter_merchant()


func _start_combat(is_elite: bool) -> void:
	current_state = GameState.BATTLE
	
	# Pick fish from pool
	var pool: Dictionary = fish_pools.get(current_area, fish_pools[1])
	var fish_list: Array[FishData] = []
	
	var num_fish: int = 2 if not is_elite else 3
	var fish_source: Array = pool["common"]
	if is_elite and pool["uncommon"].size() > 0:
		fish_source = pool["uncommon"]
	
	for i in num_fish:
		if fish_source.size() > 0:
			var fish: FishData = fish_source[randi() % fish_source.size()]
			fish_list.append(fish)
	
	battle_started.emit(fish_list)


func _start_boss() -> void:
	current_state = GameState.BATTLE
	# TODO: Boss fish
	_start_combat(true)


func _enter_rest() -> void:
	current_state = GameState.REST
	# Heal 1 boat HP
	boat_hp = mini(boat_hp + 1, max_boat_hp)


func _enter_salvage() -> void:
	current_state = GameState.SALVAGE
	# TODO: Salvage screen


func _enter_mystery() -> void:
	current_state = GameState.EVENT
	# TODO: Random event


func _enter_merchant() -> void:
	current_state = GameState.MERCHANT
	# TODO: Shop screen


func on_battle_won() -> void:
	current_state = GameState.MAP
	battle_ended.emit(true)


func on_battle_lost() -> void:
	current_state = GameState.GAME_OVER
	battle_ended.emit(false)
	run_ended.emit(false)


func on_boat_damaged(damage: int) -> void:
	boat_hp -= damage
	if boat_hp <= 0:
		on_battle_lost()


func get_current_area_name() -> String:
	if current_area <= area_names.size():
		return area_names[current_area - 1]
	return "Unknown Waters"


func get_starting_hand() -> Array[CardData]:
	# Return copies of deck cards for battle
	var hand: Array[CardData] = []
	var deck_copy := player_deck.duplicate()
	deck_copy.shuffle()
	
	var hand_size: int = mini(4, deck_copy.size())
	for i in hand_size:
		hand.append(deck_copy[i].duplicate_card())
	
	return hand
