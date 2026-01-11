extends Node2D
class_name CardDisplay
## Visual card display - populates the card layout with CardData

signal card_clicked(card_data: CardData)
signal card_right_clicked(card_data: CardData)

# Node references - set in _ready or setup
var back: TextureRect
var front: TextureRect
var name_label: Label
var image: TextureRect
var hook_label: Label
var line_label: Label
var sinker_label: Label
var ability_label: Label
var bait_label: Label

var card_data: CardData
var current_line: int = 0  # For battle display
var is_face_up: bool = true
var is_selectable: bool = true
var is_selected: bool = false
var nodes_cached: bool = false

# Placeholder texture for missing images
var placeholder_texture: Texture2D


func _ready() -> void:
	# Create placeholder texture
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.3, 0.3, 0.4, 1.0))
	placeholder_texture = ImageTexture.create_from_image(img)
	
	_cache_nodes()


func _cache_nodes() -> void:
	if nodes_cached:
		return
	
	back = get_node_or_null("Back")
	front = get_node_or_null("Front")
	
	if front:
		name_label = front.get_node_or_null("VBoxContainer/Name")
		image = front.get_node_or_null("VBoxContainer/Image")
		hook_label = front.get_node_or_null("VBoxContainer/HBoxContainer/Hook")
		line_label = front.get_node_or_null("VBoxContainer/HBoxContainer/Line")
		sinker_label = front.get_node_or_null("VBoxContainer/HBoxContainer/Sinker")
		ability_label = front.get_node_or_null("VBoxContainer/AbilityDesc")
		bait_label = front.get_node_or_null("Bait")
	
	nodes_cached = true


## Set up the card display from CardData
func setup(data: CardData, battle_line: int = -1) -> void:
	card_data = data
	current_line = battle_line if battle_line >= 0 else data.line
	_cache_nodes()
	_update_display()


## Set up from dictionary (for hand display)
func setup_from_dict(data: Dictionary) -> void:
	var cd := CardData.new()
	cd.card_name = data.get("name", "Unknown")
	cd.hook = data.get("hook", 0)
	cd.line = data.get("line", 0)
	cd.sinker = data.get("sinker", 0)
	cd.ability = data.get("ability", "None")
	setup(cd)


## Update the visual display
func _update_display() -> void:
	if card_data == null:
		return
	
	# Make sure nodes are cached
	_cache_nodes()
	
	# Name
	if name_label:
		name_label.text = card_data.card_name
	
	# Stats
	if hook_label:
		hook_label.text = str(card_data.hook)
	if sinker_label:
		sinker_label.text = str(card_data.sinker)
	
	# Line shows current/max in battle
	if line_label:
		if current_line != card_data.line:
			line_label.text = "%d/%d" % [current_line, card_data.line]
		else:
			line_label.text = str(card_data.line)
	
	# Bait cost (equals hook)
	if bait_label:
		bait_label.text = str(card_data.hook)
	
	# Ability description
	if ability_label:
		if card_data.ability != "None" and card_data.ability != "":
			# Try to get description from database, fallback to ability name
			var desc := card_data.ability
			if ClassDB.class_exists("CardDatabase"):
				desc = CardDatabase.get_ability_description(card_data.ability)
			if desc.is_empty():
				desc = card_data.ability
			ability_label.text = desc
		else:
			ability_label.text = ""
	
	# Image - try to load from database
	if image:
		if ClassDB.class_exists("CardDatabase"):
			var db_data: Dictionary = CardDatabase.get_card(card_data.card_name)
			if not db_data.is_empty() and db_data.has("image_path"):
				var tex = load(db_data.image_path)
				if tex:
					image.texture = tex
				else:
					image.texture = placeholder_texture
			else:
				image.texture = placeholder_texture
		else:
			image.texture = placeholder_texture
	
	# Face up/down
	if front:
		front.visible = is_face_up
	if back:
		back.visible = not is_face_up


## Flip the card face up or down
func set_face_up(face_up: bool) -> void:
	is_face_up = face_up
	if front:
		front.visible = is_face_up
	if back:
		back.visible = not is_face_up


## Update line during battle (for damage display)
func update_battle_line(new_line: int) -> void:
	current_line = new_line
	if not line_label:
		return
		
	if current_line != card_data.line:
		line_label.text = "%d/%d" % [current_line, card_data.line]
		# Color code low health
		if current_line <= card_data.line / 2:
			line_label.add_theme_color_override("font_color", Color.YELLOW)
		if current_line <= 1:
			line_label.add_theme_color_override("font_color", Color.RED)
	else:
		line_label.text = str(card_data.line)
		line_label.remove_theme_color_override("font_color")


## Set selected visual state
func set_selected(selected: bool) -> void:
	is_selected = selected
	if selected:
		modulate = Color(1.2, 1.2, 0.8)  # Slight yellow highlight
		scale = Vector2(1.05, 1.05)
	else:
		modulate = Color.WHITE
		scale = Vector2.ONE


## Set whether card can be interacted with
func set_selectable(selectable: bool) -> void:
	is_selectable = selectable
	if not selectable:
		modulate = Color(0.6, 0.6, 0.6)  # Greyed out
	else:
		modulate = Color.WHITE


## Get the card size for layout purposes
func get_card_size() -> Vector2:
	if front:
		return front.size
	return Vector2(254, 348)  # Default card size
