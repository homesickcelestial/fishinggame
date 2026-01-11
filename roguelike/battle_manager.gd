extends Node
class_name BattleManager

signal battle_started
signal turn_changed(is_player_turn: bool)
signal board_updated
signal card_destroyed(column: int)
signal fish_destroyed(column: int)
signal fish_damaged(column: int, damage: int)
signal boat_damaged(new_hp: int)
signal bait_changed(new_bait: int)
signal battle_won
signal battle_lost
signal catch_qte_triggered(column: int, fish_data: FishData)
signal card_drawn(card: CardData)
signal hand_updated

const NUM_COLUMNS: int = 4

# Board state
var player_cards: Array = [null, null, null, null]  # Card instances
var fish_slots: Array = [null, null, null, null]     # Fish instances

# Boat
var boat_hp: int = 3
var max_boat_hp: int = 3

# Turn state
var is_player_turn: bool = true
var battle_active: bool = false
var turn_number: int = 0
var awaiting_qte: bool = false  # True when waiting for QTE resolution
var pending_qte_columns: Array[int] = []  # Columns with fish awaiting QTE

# Hand and deck
var hand: Array[CardData] = []
var draw_pile: Array[CardData] = []
var discard_pile: Array[CardData] = []
var max_hand_size: int = 6
var cards_per_draw: int = 1

# Bait (resource system)
var bait: int = 0
var max_bait: int = 10
var bait_per_turn: int = 1
var starting_bait: int = 1

# Fish queue (visible to player)
var fish_queue: Array[FishData] = []
var fish_per_wave: int = 2

# Sirenling debuff tracking
var sirenling_debuff: int = 0


func start_battle(deck: Array[CardData], enemies: Array[FishData], boat_health: int = 3) -> void:
	# Signal UI to reset before we set up new battle
	battle_started.emit()
	
	# Reset board
	player_cards = [null, null, null, null]
	fish_slots = [null, null, null, null]
	
	# Setup boat
	boat_hp = boat_health
	max_boat_hp = boat_health
	
	# Setup deck
	draw_pile.clear()
	discard_pile.clear()
	hand.clear()
	
	for card in deck:
		draw_pile.append(card.duplicate_card())
	draw_pile.shuffle()
	
	# Setup fish queue
	fish_queue.clear()
	for fish in enemies:
		fish_queue.append(fish)
	
	# Initial setup
	bait = starting_bait
	turn_number = 0
	is_player_turn = true
	battle_active = true
	sirenling_debuff = 0
	awaiting_qte = false
	pending_qte_columns.clear()
	
	# Draw starting hand
	for i in 3:
		_draw_card()
	
	# Spawn initial fish
	_spawn_fish()
	
	board_updated.emit()
	hand_updated.emit()
	bait_changed.emit(bait)
	turn_changed.emit(true)


# --- TURN MANAGEMENT ---

func start_player_turn() -> void:
	turn_number += 1
	is_player_turn = true
	
	# Reset card actions
	for i in NUM_COLUMNS:
		var card = player_cards[i]
		if card:
			card.has_acted = false
	
	# Gain bait
	bait = mini(bait + bait_per_turn, max_bait)
	bait_changed.emit(bait)
	
	# Draw card
	_draw_card()
	
	# Check sirenling presence
	_update_sirenling_debuff()
	
	turn_changed.emit(true)
	board_updated.emit()
	hand_updated.emit()


func end_player_turn() -> void:
	if not is_player_turn:
		return
	
	# Don't end turn while QTE is pending
	if awaiting_qte:
		return
	
	is_player_turn = false
	turn_changed.emit(false)
	
	_process_enemy_turn()


func _process_enemy_turn() -> void:
	# Apply bleed damage first
	for i in NUM_COLUMNS:
		var fish = fish_slots[i]
		if fish and fish.bleed > 0:
			fish.current_hp -= fish.bleed
			fish_damaged.emit(i, fish.bleed)
			if fish.current_hp <= 0:
				awaiting_qte = true
				pending_qte_columns.append(i)
				catch_qte_triggered.emit(i, fish.data)
	
	# Fish attacks - skip fish that are pending QTE (dying)
	for i in NUM_COLUMNS:
		var fish = fish_slots[i]
		if fish == null:
			continue
		
		# Skip fish that are pending catch QTE
		if pending_qte_columns.has(i):
			continue
		
		var fish_data: FishData = fish.data
		
		# Check stunned
		if fish.stunned:
			fish.stunned = false
			continue
		
		# Check burrowed
		if fish.burrowed:
			fish.burrowed = false
			continue
		
		var damage: int = fish_data.attack
		var bonus_line_damage: int = 0
		
		# Latcher deals +1 LINE damage
		if fish_data.behavior == "Latcher":
			bonus_line_damage = 1
		
		# Check for card in front
		var card = player_cards[i]
		if card:
			var card_data: CardData = card.data
			var incoming: int = damage
			
			# Shield reduces damage
			if card_data.ability == "Shield" and card.has_acted:
				incoming = maxi(0, incoming - 1)
			
			card.current_line -= incoming + bonus_line_damage
			
			if card.current_line <= 0:
				_destroy_card(i)
		else:
			# Hit boat
			var boat_damage: int = damage
			if fish_data.behavior == "Jawper":
				boat_damage = 2
			
			boat_hp -= boat_damage
			boat_damaged.emit(boat_hp)
			
			if boat_hp <= 0:
				battle_active = false
				battle_lost.emit()
				return
	
	# Fish behaviors (post-attack)
	_process_fish_behaviors()
	
	# Spawn more fish
	_spawn_fish()
	
	# Check win condition
	if _check_win_condition():
		battle_active = false
		battle_won.emit()
		return
	
	# Start next turn
	start_player_turn()


func _check_win_condition() -> bool:
	for fish in fish_slots:
		if fish != null:
			return false
	return fish_queue.is_empty()


# --- DRAW SYSTEM ---

func _draw_card() -> void:
	if hand.size() >= max_hand_size:
		return
	
	if draw_pile.is_empty():
		_shuffle_discard_into_draw()
	
	if draw_pile.is_empty():
		return
	
	var card: CardData = draw_pile.pop_back()
	hand.append(card)
	card_drawn.emit(card)
	hand_updated.emit()


func _shuffle_discard_into_draw() -> void:
	for card in discard_pile:
		draw_pile.append(card)
	discard_pile.clear()
	draw_pile.shuffle()


func _destroy_card(column: int) -> void:
	var card = player_cards[column]
	if card:
		discard_pile.append(card.data)
	player_cards[column] = null
	card_destroyed.emit(column)


# --- PLAYER ACTIONS ---

func play_card(hand_index: int, column: int) -> bool:
	if not is_player_turn or not battle_active:
		return false
	if column < 0 or column >= NUM_COLUMNS:
		return false
	if player_cards[column] != null:
		return false
	if hand_index < 0 or hand_index >= hand.size():
		return false
	
	var card: CardData = hand[hand_index]
	
	# Check bait cost
	var cost: int = card.hook  # Cost = HOOK value (or could add separate cost field)
	if bait < cost:
		return false
	
	# Pay cost
	bait -= cost
	bait_changed.emit(bait)
	
	# Remove from hand
	hand.remove_at(hand_index)
	
	# Place on board
	player_cards[column] = {
		"data": card,
		"current_line": card.line,
		"has_acted": false
	}
	
	board_updated.emit()
	hand_updated.emit()
	return true


func card_attack(column: int) -> bool:
	if not is_player_turn or not battle_active:
		return false
	
	var card = player_cards[column]
	if card == null or card.has_acted:
		return false
	
	card.has_acted = true
	
	var fish = fish_slots[column]
	if fish == null:
		board_updated.emit()
		return true
	
	# Deal damage
	var damage: int = card.data.hook
	fish.current_hp -= damage
	fish_damaged.emit(column, damage)
	
	# Skipper moves when hit
	var fish_data: FishData = fish.data
	if fish_data.behavior == "Skipper":
		_fish_skip(column)
	
	# Burrower becomes immune
	if fish_data.behavior == "Burrower":
		fish.burrowed = true
	
	# Check death - mark as pending QTE so it can't attack
	if fish.current_hp <= 0:
		awaiting_qte = true
		pending_qte_columns.append(column)
		catch_qte_triggered.emit(column, fish.data)
	
	board_updated.emit()
	return true


func card_move(from_column: int, to_column: int) -> bool:
	if not is_player_turn or not battle_active:
		return false
	
	var card = player_cards[from_column]
	if card == null or card.has_acted:
		return false
	if player_cards[to_column] != null:
		return false
	if absi(from_column - to_column) != 1:
		return false
	
	card.has_acted = true
	player_cards[to_column] = card
	player_cards[from_column] = null
	
	board_updated.emit()
	return true


func card_use_ability(column: int, target_column: int = -1) -> bool:
	if not is_player_turn or not battle_active:
		return false
	
	var card = player_cards[column]
	if card == null or card.has_acted:
		return false
	
	var card_data: CardData = card.data
	if card_data.ability == "None" or card_data.sinker <= 0:
		return false
	
	# Apply sirenling debuff
	var effective_sinker: int = maxi(0, card_data.sinker - sirenling_debuff)
	if effective_sinker <= 0:
		return false
	
	card.has_acted = true
	
	match card_data.ability:
		"Push":
			_ability_push(column, target_column)
		"Pull":
			_ability_pull(column, target_column)
		"Stun":
			_ability_stun(column)
		"Bleed":
			_ability_bleed(column, effective_sinker)
		"Shield":
			pass  # Passive, handled in damage calc
		"Repair":
			_ability_repair(column, target_column, effective_sinker)
	
	board_updated.emit()
	return true


func sacrifice_card(column: int) -> bool:
	if not is_player_turn or not battle_active:
		return false
	
	var card = player_cards[column]
	if card == null:
		return false
	
	# Gain bait from sacrifice
	var bait_gain: int = 1
	if card.data.ability == "Chum":
		bait_gain = 2
	
	bait = mini(bait + bait_gain, max_bait)
	bait_changed.emit(bait)
	
	# Destroy card
	_destroy_card(column)
	
	board_updated.emit()
	return true


# --- ABILITIES ---

func _ability_push(from_col: int, direction: int) -> void:
	var fish = fish_slots[from_col]
	if fish == null:
		return
	var target: int = from_col + direction
	if target < 0 or target >= NUM_COLUMNS:
		return
	if fish_slots[target] != null:
		return
	fish_slots[target] = fish
	fish_slots[from_col] = null


func _ability_pull(to_col: int, from_direction: int) -> void:
	var source: int = to_col + from_direction
	if source < 0 or source >= NUM_COLUMNS:
		return
	var fish = fish_slots[source]
	if fish == null:
		return
	if fish_slots[to_col] != null:
		return
	fish_slots[to_col] = fish
	fish_slots[source] = null


func _ability_stun(column: int) -> void:
	var fish = fish_slots[column]
	if fish:
		fish.stunned = true


func _ability_bleed(column: int, strength: int) -> void:
	var fish = fish_slots[column]
	if fish:
		fish.bleed += strength


func _ability_repair(from_col: int, target_col: int, strength: int) -> void:
	var target = player_cards[target_col]
	if target and absi(from_col - target_col) <= 1:
		target.current_line = mini(target.current_line + strength, target.data.line)


# --- FISH BEHAVIORS ---

func _process_fish_behaviors() -> void:
	for i in range(NUM_COLUMNS - 1, -1, -1):
		var fish = fish_slots[i]
		if fish == null:
			continue
		
		var fish_data: FishData = fish.data
		
		match fish_data.behavior:
			"Leaper":
				_fish_leap(i)


func _fish_skip(from_col: int) -> void:
	# Skipper: moves to adjacent column when hit
	var directions := [1, -1]
	directions.shuffle()
	
	for dir in directions:
		var target: int = from_col + dir
		if target >= 0 and target < NUM_COLUMNS and fish_slots[target] == null:
			fish_slots[target] = fish_slots[from_col]
			fish_slots[from_col] = null
			break


func _fish_leap(from_col: int) -> void:
	# Leaper: jumps to nearest empty column
	for offset in [1, -1, 2, -2, 3, -3]:
		var target: int = from_col + offset
		if target >= 0 and target < NUM_COLUMNS and fish_slots[target] == null:
			fish_slots[target] = fish_slots[from_col]
			fish_slots[from_col] = null
			break


func _update_sirenling_debuff() -> void:
	sirenling_debuff = 0
	for fish in fish_slots:
		if fish and fish.data.behavior == "Sirenling":
			sirenling_debuff += 1


# --- FISH SPAWNING ---

func _spawn_fish() -> void:
	var spawned: int = 0
	
	for i in NUM_COLUMNS:
		if fish_slots[i] == null and not fish_queue.is_empty() and spawned < fish_per_wave:
			var fish_data: FishData = fish_queue.pop_front()
			fish_slots[i] = fish_data.create_instance()
			spawned += 1


func get_fish_queue_preview(count: int = 3) -> Array[FishData]:
	var preview: Array[FishData] = []
	for i in mini(count, fish_queue.size()):
		preview.append(fish_queue[i])
	return preview


# --- QTE RESOLUTION ---

func resolve_catch(column: int, success: bool, _quality: int = 1) -> void:
	var fish = fish_slots[column]
	
	if success:
		# Rewards based on quality
		# 3 = perfect, 2 = good, 1 = rough
		fish_slots[column] = null
		fish_destroyed.emit(column)
	else:
		# Fish escapes - still remove it but no reward
		fish_slots[column] = null
	
	# Clear this column from pending
	var idx := pending_qte_columns.find(column)
	if idx >= 0:
		pending_qte_columns.remove_at(idx)
	
	# Clear awaiting flag if no more pending
	if pending_qte_columns.is_empty():
		awaiting_qte = false
	
	board_updated.emit()
	
	# Check win condition after catching fish
	if _check_win_condition():
		battle_active = false
		battle_won.emit()


# --- GETTERS ---

func get_bait() -> int:
	return bait


func get_hand() -> Array[CardData]:
	return hand


func get_deck_count() -> int:
	return draw_pile.size()


func get_discard_count() -> int:
	return discard_pile.size()
