extends Node
## Roguelike Game Manager - Full game loop with all features

# Scene references
@onready var map_screen: Control = $MapScreen
@onready var battle_layer: CanvasLayer = $BattleLayer
@onready var battle_scene: Node2D = $BattleLayer/BattleScene
@onready var map_ui: MapUI = $MapScreen
@onready var hud: Control = $UILayer/HUDOverlay
@onready var rest_screen: Control = $UILayer/RestScreen
@onready var salvage_screen: Control = $UILayer/SalvageScreen
@onready var mystery_screen: Control = $UILayer/MysteryScreen
@onready var merchant_screen: Control = $UILayer/MerchantScreen
@onready var rewards_screen: Control = $UILayer/RewardsScreen
@onready var game_over_screen: Control = $UILayer/GameOverScreen
@onready var pause_menu: Control = $PauseLayer/PauseMenu
@onready var tutorial_screen: Control = $TutorialLayer/TutorialScreen
@onready var transition: TransitionManager = $TransitionManager

# Player state
var boat_hp: int = 3
var max_boat_hp: int = 3
var player_deck: Array[CardData] = []
var gold: int = 0
var salvage_inventory: Array[String] = []
var current_area: int = 1

# Run statistics
var nodes_cleared: int = 0
var fish_caught: int = 0
var cards_collected: int = 0

# Current state
var current_node_type: MapNodeData.NodeType
var was_elite_fight: bool = false
var is_loading_save: bool = false

# Fish pools
var fish_pools: Dictionary = {}


func _ready() -> void:
	_setup_fish_pools()
	_connect_signals()
	
	# Check for saved run - handle missing SaveManager autoload
	var has_save := false
	if Engine.has_singleton("SaveManager") or has_node("/root/SaveManager"):
		has_save = SaveManager.has_saved_run()
	else:
		has_save = FileAccess.file_exists("user://current_run.json")
	
	if has_save and not is_loading_save:
		_show_continue_prompt()
	else:
		_start_new_run()


func _connect_signals() -> void:
	# Map
	map_ui.node_clicked.connect(_on_map_node_clicked)
	
	# Battle
	battle_scene.battle_finished.connect(_on_battle_finished)
	
	# Screens
	rest_screen.rest_completed.connect(_on_rest_completed)
	salvage_screen.salvage_completed.connect(_on_salvage_completed)
	mystery_screen.event_completed.connect(_on_mystery_completed)
	merchant_screen.merchant_completed.connect(_on_merchant_completed)
	rewards_screen.rewards_completed.connect(_on_rewards_completed)
	game_over_screen.continue_pressed.connect(_on_game_over_continue)
	
	# UI
	hud.deck_pressed.connect(_show_deck_viewer)
	pause_menu.save_requested.connect(_save_run)
	pause_menu.quit_to_menu.connect(_quit_to_menu)
	
	# Tutorial
	tutorial_screen.tutorial_completed.connect(_on_tutorial_completed)


func _show_continue_prompt() -> void:
	# TODO: Show a proper continue/new game prompt
	# For now, auto-load
	_load_saved_run()


func _start_new_run() -> void:
	_setup_starter_deck()
	boat_hp = 3
	max_boat_hp = 3
	gold = 0
	salvage_inventory.clear()
	current_area = 1
	nodes_cleared = 0
	fish_caught = 0
	cards_collected = 0
	
	# Generate fresh map
	map_ui.generate_new_map()
	
	# Show map first (battle should be hidden)
	_show_map()
	
	_update_hud()
	
	# Show tutorial on first run (overlays on top of map)
	if tutorial_screen.should_show_tutorial():
		tutorial_screen.start_tutorial()


func _on_tutorial_completed() -> void:
	# Map is already visible, tutorial just closes
	pass


func _setup_starter_deck() -> void:
	player_deck.clear()
	
	# Minimal starting deck - player gets main tool from first salvage
	var line := CardData.new()
	line.card_name = "Fishing Line"
	line.hook = 1
	line.line = 2
	player_deck.append(line)
	player_deck.append(line.duplicate_card())
	
	var chum := CardData.new()
	chum.card_name = "Chum Bucket"
	chum.hook = 0
	chum.line = 1
	chum.ability = "Chum"
	player_deck.append(chum)


func _setup_fish_pools() -> void:
	var trout := FishData.new()
	trout.fish_name = "Trout"
	trout.max_hp = 3
	trout.attack = 1
	
	var minnow := FishData.new()
	minnow.fish_name = "Minnow"
	minnow.max_hp = 2
	minnow.attack = 1
	
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
	
	var pike := FishData.new()
	pike.fish_name = "Pike"
	pike.max_hp = 4
	pike.attack = 2
	pike.behavior = "Burrower"
	
	var siren := FishData.new()
	siren.fish_name = "Sirenling"
	siren.max_hp = 3
	siren.attack = 1
	siren.behavior = "Sirenling"
	
	var jawper := FishData.new()
	jawper.fish_name = "Jawper"
	jawper.max_hp = 4
	jawper.attack = 2
	jawper.behavior = "Jawper"
	
	var leaper := FishData.new()
	leaper.fish_name = "Leaper"
	leaper.max_hp = 3
	leaper.attack = 1
	leaper.behavior = "Leaper"
	
	fish_pools = {
		"common": [trout, minnow],
		"uncommon": [eel, crab, pike, leaper],
		"rare": [siren, jawper]
	}


# --- SCREEN MANAGEMENT ---

func _show_map() -> void:
	map_screen.visible = true
	battle_layer.visible = false
	battle_scene.hide_battle()
	hud.visible = true
	_update_hud()


func _show_battle() -> void:
	map_screen.visible = false
	battle_layer.visible = true
	battle_scene.show_battle()
	hud.visible = false  # Hide HUD during battle to avoid overlap


func _update_hud() -> void:
	hud.update_gold(gold)
	hud.update_hp(boat_hp, max_boat_hp)
	hud.update_area("AREA %d: %s" % [current_area, _get_area_name()])
	hud.update_salvage(salvage_inventory)


func _get_area_name() -> String:
	match current_area:
		1: return "The Shallows"
		2: return "The Depths"
		3: return "The Abyss"
		_: return "Unknown Waters"


func _show_deck_viewer() -> void:
	pause_menu.show_pause(player_deck)


# --- MAP NODE HANDLING ---

func _on_map_node_clicked(node: MapNodeData) -> void:
	current_node_type = node.type
	
	match node.type:
		MapNodeData.NodeType.COMBAT:
			was_elite_fight = false
			await transition.fade_to_black(0.3)
			_start_combat(false)
			await transition.fade_from_black(0.3)
		MapNodeData.NodeType.ELITE:
			was_elite_fight = true
			await transition.fade_to_black(0.3)
			_start_combat(true)
			await transition.fade_from_black(0.3)
		MapNodeData.NodeType.BOSS:
			was_elite_fight = true
			await transition.fade_to_black(0.3)
			_start_boss()
			await transition.fade_from_black(0.3)
		MapNodeData.NodeType.REST:
			_handle_rest()
		MapNodeData.NodeType.SALVAGE:
			_handle_salvage()
		MapNodeData.NodeType.MYSTERY:
			_handle_mystery()
		MapNodeData.NodeType.MERCHANT:
			_handle_merchant()


# --- COMBAT ---

func _start_combat(is_elite: bool) -> void:
	var enemies: Array[FishData] = []
	
	# Scale fish count based on nodes cleared (progression)
	# Early game: 1 fish
	# Mid game: 2 fish
	# Late game: 2-3 fish
	var num_fish: int
	if nodes_cleared <= 2:
		# Very early - just 1 easy fish
		num_fish = 1
	elif nodes_cleared <= 4:
		# Early-mid - 1-2 fish
		num_fish = 1 if not is_elite else 2
	elif nodes_cleared <= 6:
		# Mid game - 2 fish
		num_fish = 2
	else:
		# Late game - 2-3 fish
		num_fish = 2 if not is_elite else 3
	
	# Pick fish pool based on elite status and progression
	var pool: Array
	if nodes_cleared <= 3:
		pool = fish_pools["common"]  # Only easy fish early
	elif is_elite:
		pool = fish_pools["uncommon"]
	else:
		# Mix common and uncommon
		pool = fish_pools["common"] + fish_pools["uncommon"]
	
	for i in num_fish:
		var fish: FishData = pool[randi() % pool.size()]
		enemies.append(fish)
	
	# Add rare fish to late elite fights
	if is_elite and nodes_cleared > 5 and randf() > 0.5:
		var rare_pool: Array = fish_pools["rare"]
		enemies.append(rare_pool[randi() % rare_pool.size()])
	
	_show_battle()
	battle_scene.start_battle(_duplicate_deck(), enemies, boat_hp)


func _start_boss() -> void:
	var enemies: Array[FishData] = []
	
	for fish in fish_pools["rare"]:
		enemies.append(fish)
	for fish in fish_pools["uncommon"]:
		if enemies.size() < 4:
			enemies.append(fish)
	
	_show_battle()
	battle_scene.start_battle(_duplicate_deck(), enemies, boat_hp)


func _on_battle_finished(victory: bool, _rewards: Dictionary) -> void:
	if victory:
		boat_hp = battle_scene.get_remaining_boat_hp()
		fish_caught += 1  # Simplified tracking
		
		var gold_reward: int = 10 if not was_elite_fight else 25
		rewards_screen.show_rewards(gold_reward, was_elite_fight)
	else:
		_trigger_game_over()


func _on_rewards_completed(result: Dictionary) -> void:
	gold += result.get("gold", 0)
	
	var card: CardData = result.get("card")
	if card:
		player_deck.append(card)
		cards_collected += 1
	
	if randf() > 0.5:
		var salvage_types := ["Scrap Metal", "Old Rope", "Fish Guts"]
		salvage_inventory.append(salvage_types[randi() % salvage_types.size()])
	
	nodes_cleared += 1
	_save_run()
	
	await transition.fade_to_black(0.3)
	map_ui.on_node_completed()
	_show_map()
	await transition.fade_from_black(0.3)


# --- REST ---

func _handle_rest() -> void:
	rest_screen.show_rest(boat_hp, max_boat_hp, [])


func _on_rest_completed(choice: String) -> void:
	match choice:
		"heal_boat":
			boat_hp = mini(boat_hp + 1, max_boat_hp)
			hud.flash_hp()
		"restore_cards":
			pass
		"skip":
			pass
	
	nodes_cleared += 1
	_save_run()
	map_ui.on_node_completed()
	_update_hud()


# --- SALVAGE ---

func _handle_salvage() -> void:
	# First salvage (nodes_cleared == 0) shows starter tool selection
	var is_first := (nodes_cleared == 0)
	
	if not is_first and salvage_inventory.is_empty():
		# Give some salvage for non-starter salvage sites
		var salvage_types := ["Scrap Metal", "Old Rope", "Fish Guts"]
		salvage_inventory.append(salvage_types[randi() % salvage_types.size()])
		salvage_inventory.append(salvage_types[randi() % salvage_types.size()])
	
	salvage_screen.show_salvage(salvage_inventory, player_deck, is_first)


func _on_salvage_completed(result: Dictionary) -> void:
	var crafted: Array = result.get("crafted", [])
	for card in crafted:
		player_deck.append(card)
		cards_collected += 1
	
	salvage_inventory.clear()
	nodes_cleared += 1
	_save_run()
	map_ui.on_node_completed()
	_update_hud()


# --- MYSTERY ---

func _handle_mystery() -> void:
	mystery_screen.show_event(player_deck)


func _on_mystery_completed(result: Dictionary) -> void:
	var damage: int = result.get("damage", 0)
	var heal: int = result.get("heal", 0)
	var salvage: int = result.get("salvage", 0)
	
	boat_hp -= damage
	if damage > 0:
		hud.flash_hp()
	
	boat_hp = mini(boat_hp + heal, max_boat_hp)
	
	if boat_hp <= 0:
		_trigger_game_over()
		return
	
	var salvage_types := ["Scrap Metal", "Old Rope", "Fish Guts"]
	for i in salvage:
		salvage_inventory.append(salvage_types[randi() % salvage_types.size()])
	
	var new_card: CardData = result.get("new_card")
	if new_card:
		player_deck.append(new_card)
		cards_collected += 1
	
	if result.get("lose_card", false) and player_deck.size() > 3:
		player_deck.pop_back()
	
	if result.get("upgrade_random", false) and not player_deck.is_empty():
		var card: CardData = player_deck[randi() % player_deck.size()]
		match randi() % 3:
			0: card.hook += 1
			1: card.line += 1
			2: card.sinker += 1
	
	nodes_cleared += 1
	_save_run()
	map_ui.on_node_completed()
	_update_hud()


# --- MERCHANT ---

func _handle_merchant() -> void:
	merchant_screen.show_merchant(gold, player_deck)


func _on_merchant_completed(result: Dictionary) -> void:
	gold = result.get("gold", gold)
	player_deck = result.get("deck", player_deck)
	
	hud.update_gold(gold, true)
	
	nodes_cleared += 1
	_save_run()
	map_ui.on_node_completed()
	_update_hud()


# --- GAME OVER ---

func _trigger_game_over() -> void:
	var stats := {
		"gold": gold,
		"nodes_cleared": nodes_cleared,
		"fish_caught": fish_caught,
		"cards_collected": cards_collected,
		"area": current_area,
	}
	
	# Calculate penalty
	stats["final_gold"] = gold / 2
	
	# Record to persistent save
	SaveManager.record_run_end(false, stats)
	
	await transition.fade_to_black(0.3)
	_show_map()
	game_over_screen.show_game_over(stats)
	await transition.fade_from_black(0.3)


func _on_game_over_continue() -> void:
	# Return to base with half gold
	gold = game_over_screen.get_final_gold()
	
	# Reset run but keep some progress
	boat_hp = max_boat_hp
	nodes_cleared = 0
	fish_caught = 0
	
	# Generate new map
	map_ui.generate_new_map()
	
	_update_hud()
	_save_run()


# --- SAVE / LOAD ---

func _save_run() -> void:
	if not (Engine.has_singleton("SaveManager") or has_node("/root/SaveManager")):
		return  # Can't save without SaveManager
	
	var run_data := {
		"boat_hp": boat_hp,
		"max_boat_hp": max_boat_hp,
		"gold": gold,
		"deck": player_deck,
		"salvage": salvage_inventory,
		"current_area": current_area,
		"nodes_cleared": nodes_cleared,
		"fish_caught": fish_caught,
	}
	SaveManager.save_run(run_data)


func _load_saved_run() -> void:
	if not (Engine.has_singleton("SaveManager") or has_node("/root/SaveManager")):
		_start_new_run()
		return
	
	var run_data: Dictionary = SaveManager.load_run()
	
	if run_data.is_empty():
		_start_new_run()
		return
	
	is_loading_save = true
	
	boat_hp = run_data.get("boat_hp", 3)
	max_boat_hp = run_data.get("max_boat_hp", 3)
	gold = run_data.get("gold", 0)
	player_deck = run_data.get("deck", [])
	current_area = run_data.get("current_area", 1)
	nodes_cleared = run_data.get("nodes_cleared", 0)
	fish_caught = run_data.get("fish_caught", 0)
	
	# Handle typed array conversion for salvage
	salvage_inventory.clear()
	var saved_salvage: Array = run_data.get("salvage", [])
	for item in saved_salvage:
		salvage_inventory.append(str(item))
	
	if player_deck.is_empty():
		_setup_starter_deck()
	
	_update_hud()
	_show_map()
	
	is_loading_save = false


func _quit_to_menu() -> void:
	_save_run()
	await transition.fade_to_black(0.5)
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")


# --- UTILITY ---

func _duplicate_deck() -> Array[CardData]:
	var copy: Array[CardData] = []
	for card in player_deck:
		copy.append(card.duplicate_card())
	return copy


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not pause_menu.is_paused and map_screen.visible:
			pause_menu.show_pause(player_deck)
