extends Control
## Rest Screen - Heal boat or restore card durability

signal rest_completed(choice: String)

@onready var title_label: Label = $Panel/VBoxContainer/Title
@onready var description_label: Label = $Panel/VBoxContainer/Description
@onready var boat_hp_label: Label = $Panel/VBoxContainer/BoatHP
@onready var heal_boat_button: Button = $Panel/VBoxContainer/Options/HealBoat
@onready var restore_card_button: Button = $Panel/VBoxContainer/Options/RestoreCard
@onready var skip_button: Button = $Panel/VBoxContainer/Skip
@onready var card_list: VBoxContainer = $Panel/VBoxContainer/CardList

var boat_hp: int = 3
var max_boat_hp: int = 3
var damaged_cards: Array = []  # Array of {card: CardData, current_line: int}


func _ready() -> void:
	visible = false
	heal_boat_button.pressed.connect(_on_heal_boat)
	restore_card_button.pressed.connect(_on_restore_card)
	skip_button.pressed.connect(_on_skip)


func show_rest(current_boat_hp: int, max_hp: int, cards_with_damage: Array) -> void:
	boat_hp = current_boat_hp
	max_boat_hp = max_hp
	damaged_cards = cards_with_damage
	
	_update_display()
	visible = true


func _update_display() -> void:
	boat_hp_label.text = "Boat HP: %d / %d" % [boat_hp, max_boat_hp]
	
	# Heal boat option
	if boat_hp < max_boat_hp:
		heal_boat_button.disabled = false
		heal_boat_button.text = "Repair Boat (+1 HP)"
	else:
		heal_boat_button.disabled = true
		heal_boat_button.text = "Boat at full health"
	
	# Restore card option
	if damaged_cards.is_empty():
		restore_card_button.disabled = true
		restore_card_button.text = "No damaged cards"
	else:
		restore_card_button.disabled = false
		restore_card_button.text = "Restore a Card's LINE"
	
	# Show damaged cards
	for child in card_list.get_children():
		child.queue_free()
	
	for card_info in damaged_cards:
		var card: CardData = card_info.card
		var current: int = card_info.current_line
		var lbl := Label.new()
		lbl.text = "%s - LINE: %d/%d" % [card.card_name, current, card.line]
		if current < card.line:
			lbl.add_theme_color_override("font_color", Color.YELLOW)
		card_list.add_child(lbl)


func _on_heal_boat() -> void:
	visible = false
	rest_completed.emit("heal_boat")


func _on_restore_card() -> void:
	# For simplicity, restore all damaged cards
	visible = false
	rest_completed.emit("restore_cards")


func _on_skip() -> void:
	visible = false
	rest_completed.emit("skip")
