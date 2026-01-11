extends Control
## Deck Viewer - View all cards in your deck

signal closed

@onready var title_label: Label = $Panel/VBoxContainer/Header/Title
@onready var card_count_label: Label = $Panel/VBoxContainer/Header/CardCount
@onready var card_grid: GridContainer = $Panel/VBoxContainer/ScrollContainer/CardGrid
@onready var close_button: Button = $Panel/VBoxContainer/Close
@onready var sort_button: Button = $Panel/VBoxContainer/Header/SortButton

var current_deck: Array[CardData] = []
var sort_mode: int = 0  # 0=name, 1=hook, 2=line, 3=ability

const SORT_NAMES := ["Name", "HOOK", "LINE", "Ability"]


func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close)
	sort_button.pressed.connect(_on_sort)
	modulate.a = 0


func show_deck(deck: Array[CardData]) -> void:
	current_deck = deck
	_update_display()
	visible = true
	_animate_open()


func _update_display() -> void:
	card_count_label.text = "%d cards" % current_deck.size()
	sort_button.text = "Sort: %s" % SORT_NAMES[sort_mode]
	
	# Clear grid
	for child in card_grid.get_children():
		child.queue_free()
	
	# Sort deck
	var sorted_deck := current_deck.duplicate()
	match sort_mode:
		0: sorted_deck.sort_custom(_sort_by_name)
		1: sorted_deck.sort_custom(_sort_by_hook)
		2: sorted_deck.sort_custom(_sort_by_line)
		3: sorted_deck.sort_custom(_sort_by_ability)
	
	# Create card displays
	for i in sorted_deck.size():
		var card: CardData = sorted_deck[i]
		var card_panel := _create_card_panel(card, i)
		card_grid.add_child(card_panel)


func _create_card_panel(card: CardData, index: int) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(140, 180)
	
	# Animate in with delay
	panel.modulate.a = 0
	panel.scale = Vector2(0.8, 0.8)
	panel.pivot_offset = Vector2(70, 90)
	
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2).set_delay(index * 0.03)
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.25).set_delay(index * 0.03)
	
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	
	# Card name
	var name_lbl := Label.new()
	name_lbl.text = card.card_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(name_lbl)
	
	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)
	
	# Stats
	var hook_lbl := Label.new()
	hook_lbl.text = "HOOK: %d" % card.hook
	hook_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hook_lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.6))
	vbox.add_child(hook_lbl)
	
	var line_lbl := Label.new()
	line_lbl.text = "LINE: %d" % card.line
	line_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line_lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	vbox.add_child(line_lbl)
	
	var sinker_lbl := Label.new()
	sinker_lbl.text = "SINKER: %d" % card.sinker
	sinker_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sinker_lbl.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	vbox.add_child(sinker_lbl)
	
	# Ability
	if card.ability != "None":
		var ability_lbl := Label.new()
		ability_lbl.text = "[%s]" % card.ability
		ability_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ability_lbl.add_theme_font_size_override("font_size", 12)
		ability_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
		vbox.add_child(ability_lbl)
	
	return panel


func _sort_by_name(a: CardData, b: CardData) -> bool:
	return a.card_name < b.card_name


func _sort_by_hook(a: CardData, b: CardData) -> bool:
	return a.hook > b.hook


func _sort_by_line(a: CardData, b: CardData) -> bool:
	return a.line > b.line


func _sort_by_ability(a: CardData, b: CardData) -> bool:
	return a.ability < b.ability


func _on_sort() -> void:
	sort_mode = (sort_mode + 1) % 4
	_update_display()


func _animate_open() -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)


func _on_close() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	visible = false
	closed.emit()


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_close()
