extends Control
## Battle Board UI - handles display and player interaction

const CardDisplayScene = preload("res://scenes/roguelike/card layout.tscn")

@onready var battle_manager: BattleManager = $BattleManager
@onready var fish_row: HBoxContainer = $BoardContainer/FishRow
@onready var player_row: HBoxContainer = $BoardContainer/PlayerRow
@onready var hand_container: HBoxContainer = $HandContainer
@onready var hp_label: Label = $BoardContainer/BoatHP/HPLabel
@onready var turn_label: Label = $TurnLabel
@onready var end_turn_button: Button = $EndTurnButton
@onready var bait_label: Label = $BaitContainer/BaitLabel
@onready var deck_label: Label = $DeckContainer/DeckLabel
@onready var queue_container: HBoxContainer = $QueueContainer
@onready var catch_minigame: Control = $CatchMinigame

var fish_slots: Array[Panel] = []
var card_slots: Array[Panel] = []

# Track card display instances for updates
var card_displays: Array = [null, null, null, null]
var hand_displays: Array = []

var selected_hand_card: int = -1
var selected_board_card: int = -1
var awaiting_qte_column: int = -1

# Card scale for slots (cards are ~254x348, slots are 150x160)
const CARD_SCALE := 0.45

# Colors for slot backgrounds
const COLOR_EMPTY := Color(0.15, 0.18, 0.22, 1.0)
const COLOR_FISH := Color(0.4, 0.2, 0.2, 1.0)
const COLOR_FISH_STUNNED := Color(0.5, 0.5, 0.2, 1.0)
const COLOR_FISH_BURROWED := Color(0.3, 0.25, 0.2, 1.0)
const COLOR_SELECTED := Color(0.3, 0.5, 0.3, 1.0)
const COLOR_HIGHLIGHT := Color(0.4, 0.4, 0.2, 1.0)
const COLOR_CANT_AFFORD := Color(0.5, 0.2, 0.2, 1.0)


func _ready() -> void:
	# Get slot references
	for i in 4:
		fish_slots.append(fish_row.get_node("FishSlot%d" % i) as Panel)
		card_slots.append(player_row.get_node("CardSlot%d" % i) as Panel)
	
	# Connect battle manager signals
	battle_manager.battle_started.connect(_on_battle_started)
	battle_manager.board_updated.connect(_on_board_updated)
	battle_manager.turn_changed.connect(_on_turn_changed)
	battle_manager.boat_damaged.connect(_on_boat_damaged)
	battle_manager.bait_changed.connect(_on_bait_changed)
	battle_manager.hand_updated.connect(_on_hand_updated)
	battle_manager.card_destroyed.connect(_on_card_destroyed)
	battle_manager.fish_destroyed.connect(_on_fish_destroyed)
	battle_manager.fish_damaged.connect(_on_fish_damaged)
	battle_manager.battle_won.connect(_on_battle_won)
	battle_manager.battle_lost.connect(_on_battle_lost)
	battle_manager.catch_qte_triggered.connect(_on_catch_qte)
	
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	
	# Connect catch minigame
	catch_minigame.catch_completed.connect(_on_catch_completed)
	
	# Setup slot click handling
	for i in 4:
		fish_slots[i].gui_input.connect(_on_fish_slot_input.bind(i))
		card_slots[i].gui_input.connect(_on_card_slot_input.bind(i))
	
	# Initialize display
	_reset_slots()
	_update_fish_display()
	_update_card_display()
	_update_hand_display()


## Called when a new battle starts - reset all visuals
func _on_battle_started() -> void:
	_reset_slots()


## Reset all slot visuals - call at start of each battle
func _reset_slots() -> void:
	for slot in fish_slots:
		slot.visible = true
		slot.modulate = Color.WHITE
		slot.scale = Vector2.ONE
		slot.self_modulate = COLOR_EMPTY
		for child in slot.get_children():
			child.queue_free()
	
	for slot in card_slots:
		slot.visible = true
		slot.modulate = Color.WHITE
		slot.scale = Vector2.ONE
		slot.self_modulate = COLOR_EMPTY
		for child in slot.get_children():
			child.queue_free()
	
	# Clear card display references
	card_displays = [null, null, null, null]
	hand_displays.clear()
	
	# Reset UI state
	selected_hand_card = -1
	selected_board_card = -1
	end_turn_button.disabled = false


# NOTE: Test function kept for debugging, not called in production
#func _start_test_battle() -> void:
#	pass


func _on_board_updated() -> void:
	_update_fish_display()
	_update_card_display()
	_update_queue_display()


func _on_hand_updated() -> void:
	_update_hand_display()
	_update_deck_display()


func _update_fish_display() -> void:
	for i in 4:
		var slot := fish_slots[i]
		var fish = battle_manager.fish_slots[i]
		
		# Clear existing
		for child in slot.get_children():
			child.queue_free()
		
		if fish == null:
			slot.self_modulate = COLOR_EMPTY
		else:
			# Color based on status
			if fish.stunned:
				slot.self_modulate = COLOR_FISH_STUNNED
			elif fish.burrowed:
				slot.self_modulate = COLOR_FISH_BURROWED
			else:
				slot.self_modulate = COLOR_FISH
			
			var fish_data: FishData = fish.data
			
			var vbox := VBoxContainer.new()
			vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
			vbox.add_theme_constant_override("separation", 2)
			slot.add_child(vbox)
			
			var name_lbl := Label.new()
			name_lbl.text = fish_data.fish_name
			name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_lbl.add_theme_font_size_override("font_size", 14)
			vbox.add_child(name_lbl)
			
			var hp_lbl := Label.new()
			hp_lbl.text = "HP: %d/%d" % [fish.current_hp, fish_data.max_hp]
			hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			if fish.current_hp <= fish_data.max_hp / 2:
				hp_lbl.add_theme_color_override("font_color", Color.YELLOW)
			vbox.add_child(hp_lbl)
			
			var atk_lbl := Label.new()
			atk_lbl.text = "ATK: %d" % fish_data.attack
			atk_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vbox.add_child(atk_lbl)
			
			if fish_data.behavior != "None":
				var beh_lbl := Label.new()
				beh_lbl.text = "[%s]" % fish_data.behavior
				beh_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				beh_lbl.add_theme_font_size_override("font_size", 11)
				vbox.add_child(beh_lbl)
			
			# Status effects
			var status_text := ""
			if fish.stunned:
				status_text += "STUNNED "
			if fish.burrowed:
				status_text += "BURROWED "
			if fish.bleed > 0:
				status_text += "BLEED:%d" % fish.bleed
			
			if not status_text.is_empty():
				var status_lbl := Label.new()
				status_lbl.text = status_text
				status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				status_lbl.add_theme_font_size_override("font_size", 10)
				status_lbl.add_theme_color_override("font_color", Color.ORANGE)
				vbox.add_child(status_lbl)


func _update_card_display() -> void:
	for i in 4:
		var slot := card_slots[i]
		var card = battle_manager.player_cards[i]
		
		# Clear existing children
		for child in slot.get_children():
			child.queue_free()
		card_displays[i] = null
		
		if card == null:
			slot.self_modulate = COLOR_EMPTY
			if selected_hand_card >= 0:
				slot.self_modulate = COLOR_HIGHLIGHT
		else:
			slot.self_modulate = Color.WHITE  # Let card handle its own colors
			
			var card_data: CardData = card.data
			
			# Create card display
			var card_display: Node2D = CardDisplayScene.instantiate()
			card_display.scale = Vector2(CARD_SCALE, CARD_SCALE)
			card_display.position = Vector2(10, 10)  # Offset inside slot
			slot.add_child(card_display)
			card_displays[i] = card_display
			
			# Setup the card
			card_display.setup(card_data, card.current_line)
			
			# Visual states
			if i == selected_board_card:
				card_display.set_selected(true)
			elif card.has_acted:
				card_display.modulate = Color(0.7, 0.7, 0.7)  # Dim acted cards


func _update_hand_display() -> void:
	for child in hand_container.get_children():
		child.queue_free()
	hand_displays.clear()
	
	var current_bait := battle_manager.get_bait()
	
	for i in battle_manager.hand.size():
		var card: CardData = battle_manager.hand[i]
		var cost: int = card.hook
		var can_afford: bool = current_bait >= cost
		
		# Create a container for the card
		var card_container := Control.new()
		card_container.custom_minimum_size = Vector2(120, 160)
		card_container.gui_input.connect(_on_hand_card_input.bind(i))
		hand_container.add_child(card_container)
		
		# Create card display
		var card_display: Node2D = CardDisplayScene.instantiate()
		card_display.scale = Vector2(CARD_SCALE, CARD_SCALE)
		card_display.position = Vector2(5, 5)
		card_container.add_child(card_display)
		hand_displays.append(card_display)
		
		# Setup the card
		card_display.setup(card)
		
		# Visual states
		if i == selected_hand_card:
			card_display.set_selected(true)
		elif not can_afford:
			card_display.modulate = Color(0.5, 0.3, 0.3)  # Red tint for unaffordable


func _update_queue_display() -> void:
	for child in queue_container.get_children():
		child.queue_free()
	
	var preview := battle_manager.get_fish_queue_preview(3)
	
	for fish_data in preview:
		var lbl := Label.new()
		lbl.text = "%s (%d)" % [fish_data.fish_name, fish_data.max_hp]
		lbl.add_theme_font_size_override("font_size", 12)
		queue_container.add_child(lbl)


func _update_deck_display() -> void:
	deck_label.text = "Deck: %d | Discard: %d" % [battle_manager.get_deck_count(), battle_manager.get_discard_count()]


func _update_hp_display() -> void:
	var hearts := ""
	for i in battle_manager.boat_hp:
		hearts += "♥"
	for i in battle_manager.max_boat_hp - battle_manager.boat_hp:
		hearts += "♡"
	hp_label.text = hearts


func _on_turn_changed(is_player: bool) -> void:
	if is_player:
		turn_label.text = "YOUR TURN"
		end_turn_button.disabled = false
	else:
		turn_label.text = "ENEMY TURN"
		end_turn_button.disabled = true


func _on_boat_damaged(_new_hp: int) -> void:
	_update_hp_display()


func _on_bait_changed(new_bait: int) -> void:
	bait_label.text = "Bait: %d" % new_bait


func _on_card_destroyed(column: int) -> void:
	var slot := card_slots[column]
	# Animate contents, not the slot itself
	for child in slot.get_children():
		AnimHelper.die(child, 0.4)


func _on_fish_destroyed(column: int) -> void:
	var slot := fish_slots[column]
	# Animate contents, not the slot itself
	for child in slot.get_children():
		AnimHelper.die(child, 0.5)


func _on_fish_damaged(column: int, damage: int) -> void:
	var slot := fish_slots[column]
	AnimHelper.take_damage(slot)
	
	# Floating damage number
	AnimHelper.floating_number(self, slot.global_position + Vector2(75, 40), "-%d" % damage, Color.RED)


func _on_battle_won() -> void:
	turn_label.text = "VICTORY!"
	end_turn_button.disabled = true


func _on_battle_lost() -> void:
	turn_label.text = "DEFEAT..."
	end_turn_button.disabled = true


func _on_catch_qte(column: int, fish_data: FishData) -> void:
	awaiting_qte_column = column
	
	# Determine difficulty and behavior
	var difficulty: float = 1.0
	var behavior: String = "Fighter"
	
	match fish_data.behavior:
		"Skipper":
			behavior = "Runner"
		"Burrower":
			behavior = "Diver"
		"Sirenling":
			behavior = "Thinker"
	
	difficulty = fish_data.max_hp / 3.0
	
	catch_minigame.start_catch(fish_data.fish_name, difficulty, behavior)


func _on_catch_completed(success: bool, quality: int) -> void:
	battle_manager.resolve_catch(awaiting_qte_column, success, quality)
	awaiting_qte_column = -1


func _on_end_turn_pressed() -> void:
	selected_hand_card = -1
	selected_board_card = -1
	battle_manager.end_player_turn()


func _on_hand_card_input(event: InputEvent, card_index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if selected_hand_card == card_index:
			selected_hand_card = -1
		else:
			selected_hand_card = card_index
			selected_board_card = -1
		_on_board_updated()
		_on_hand_updated()


func _on_card_slot_input(event: InputEvent, column: int) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	if not battle_manager.is_player_turn:
		return
	
	var card = battle_manager.player_cards[column]
	
	# Right click to sacrifice
	if event.button_index == MOUSE_BUTTON_RIGHT and card != null:
		battle_manager.sacrifice_card(column)
		selected_board_card = -1
		_on_board_updated()
		_on_hand_updated()
		return
	
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	
	# Play card from hand
	if selected_hand_card >= 0:
		if battle_manager.play_card(selected_hand_card, column):
			selected_hand_card = -1
		_on_board_updated()
		_on_hand_updated()
		return
	
	# Attack with selected card
	if selected_board_card == column and card != null:
		battle_manager.card_attack(column)
		selected_board_card = -1
		_on_board_updated()
		return
	
	# Move selected card
	if selected_board_card >= 0 and card == null:
		if battle_manager.card_move(selected_board_card, column):
			selected_board_card = -1
		_on_board_updated()
		return
	
	# Select board card
	if card != null and not card.has_acted:
		selected_board_card = column
		selected_hand_card = -1
	else:
		selected_board_card = -1
	
	_on_board_updated()
	_on_hand_updated()


func _on_fish_slot_input(event: InputEvent, column: int) -> void:
	# Could be used for targeting abilities
	pass
