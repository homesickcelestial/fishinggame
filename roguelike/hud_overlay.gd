extends Control
## HUD Overlay - Shows player resources on map screen

@onready var gold_label: Label = $TopBar/GoldContainer/GoldLabel
@onready var gold_icon: Label = $TopBar/GoldContainer/GoldIcon
@onready var hp_container: HBoxContainer = $TopBar/HPContainer
@onready var deck_button: Button = $TopBar/DeckButton
@onready var area_label: Label = $TopBar/AreaLabel
@onready var salvage_container: HBoxContainer = $TopBar/SalvageContainer
@onready var salvage_label: Label = $TopBar/SalvageContainer/SalvageLabel

signal deck_pressed

# Cached values for animations
var displayed_gold: int = 0
var target_gold: int = 0


func _ready() -> void:
	deck_button.pressed.connect(func(): deck_pressed.emit())


func _process(delta: float) -> void:
	# Animate gold counter
	if displayed_gold != target_gold:
		var diff := target_gold - displayed_gold
		var change := ceili(absf(diff) * delta * 10)
		change = maxi(change, 1)
		
		if diff > 0:
			displayed_gold = mini(displayed_gold + change, target_gold)
		else:
			displayed_gold = maxi(displayed_gold - change, target_gold)
		
		gold_label.text = str(displayed_gold)
		
		# Pulse effect
		gold_label.scale = Vector2(1.1, 1.1)
		var tween := create_tween()
		tween.tween_property(gold_label, "scale", Vector2.ONE, 0.1)


func update_gold(amount: int, animate: bool = true) -> void:
	target_gold = amount
	if not animate:
		displayed_gold = amount
		gold_label.text = str(amount)


func update_hp(current: int, max_hp: int) -> void:
	# Clear hearts
	for child in hp_container.get_children():
		if child is Label and child.name != "HPIcon":
			child.queue_free()
	
	# Add hearts with animation
	for i in max_hp:
		var heart := Label.new()
		heart.text = "♥" if i < current else "♡"
		heart.add_theme_color_override("font_color", Color.RED if i < current else Color.GRAY)
		
		# Animate in
		heart.modulate.a = 0
		heart.scale = Vector2(0.5, 0.5)
		hp_container.add_child(heart)
		
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(heart, "modulate:a", 1.0, 0.2).set_delay(i * 0.05)
		tween.parallel().tween_property(heart, "scale", Vector2.ONE, 0.3).set_delay(i * 0.05)


func update_area(area_name: String) -> void:
	area_label.text = area_name
	
	# Slide in animation
	area_label.position.x = -200
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(area_label, "position:x", 0.0, 0.5)


func update_salvage(salvage_list: Array) -> void:
	if salvage_list.is_empty():
		salvage_container.visible = false
	else:
		salvage_container.visible = true
		salvage_label.text = "%d items" % salvage_list.size()


func flash_gold(positive: bool = true) -> void:
	var color := Color.GREEN if positive else Color.RED
	gold_label.add_theme_color_override("font_color", color)
	
	var tween := create_tween()
	tween.tween_property(gold_label, "theme_override_colors/font_color", Color.WHITE, 0.5)


func flash_hp() -> void:
	for child in hp_container.get_children():
		if child is Label:
			child.scale = Vector2(1.3, 1.3)
			var tween := create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(child, "scale", Vector2.ONE, 0.2)
