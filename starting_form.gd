extends Node2D
## Starting form - name entry with signature

signal form_completed(full_name: String)

@onready var full_paper: TextureRect = $"Full Paper"
@onready var name_input: LineEdit = $"Full Paper/NameInput"
@onready var dice_button: TextureButton = $"Full Paper/DiceButton"
@onready var signature_button: Button = $"Full Paper/Signature"
@onready var fade_rect: ColorRect = $FadeRect

const SAVE_PATH := "user://player_data.save"

## 20 Yoruba male names
const YORUBA_NAMES: Array[String] = [
	"Adebayo",
	"Adewale",
	"Oluwatobi",
	"Olumide",
	"Babatunde",
	"Ayodeji",
	"Olufemi",
	"Temitope",
	"Kayode",
	"Oluwaseun",
	"Adetola",
	"Oladele",
	"Folarin",
	"Adeyemi",
	"Olayinka",
	"Adekunle",
	"Olamide",
	"Damilola",
	"Segun",
	"Rotimi",
]

## Nigerian surnames
const SURNAMES: Array[String] = [
	"Abiodun",
]

const DEFAULT_NAME: String = "Adebayo"

var current_name: String = DEFAULT_NAME
var current_surname: String = ""
var scroll_position: float = 0.0
var max_scroll: float = 0.0
var is_signed: bool = false

## Scroll settings
const SCROLL_SPEED: float = 20.0
const SCROLL_SPEED_FAST: float = 40.0
const SCROLL_SMOOTH: float = 12.0

var target_scroll: float = 0.0


func _ready() -> void:
	# Set default name
	name_input.text = DEFAULT_NAME
	current_name = DEFAULT_NAME
	
	# Pick a random surname
	current_surname = SURNAMES[randi() % SURNAMES.size()]
	
	# Clear signature button text
	signature_button.text = ""
	
	# Connect signals
	dice_button.pressed.connect(_on_dice_pressed)
	signature_button.pressed.connect(_on_signature_pressed)
	name_input.text_changed.connect(_on_name_changed)
	
	# Remove dark backgrounds from inputs
	_clear_input_backgrounds()
	
	# Calculate max scroll based on paper size
	var paper_height: float = full_paper.texture.get_height() if full_paper.texture else 3000.0
	var screen_height: float = get_viewport().get_visible_rect().size.y
	max_scroll = maxf(0.0, paper_height - screen_height)
	
	# Setup fade rect (create if not exists)
	_setup_fade_rect()


func _setup_fade_rect() -> void:
	if not has_node("FadeRect"):
		fade_rect = ColorRect.new()
		fade_rect.name = "FadeRect"
		fade_rect.color = Color(0, 0, 0, 0)
		fade_rect.z_index = 100
		fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(fade_rect)
	else:
		fade_rect = $FadeRect
	
	# Make sure it ignores mouse
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _clear_input_backgrounds() -> void:
	# Make LineEdit transparent
	var style_empty := StyleBoxEmpty.new()
	name_input.add_theme_stylebox_override("normal", style_empty)
	name_input.add_theme_stylebox_override("focus", style_empty)
	name_input.add_theme_stylebox_override("read_only", style_empty)
	
	# Make signature button transparent
	signature_button.add_theme_stylebox_override("normal", style_empty)
	signature_button.add_theme_stylebox_override("hover", style_empty)
	signature_button.add_theme_stylebox_override("pressed", style_empty)
	signature_button.add_theme_stylebox_override("focus", style_empty)


func _process(delta: float) -> void:
	if is_signed:
		return
	
	# Smooth scroll
	scroll_position = lerpf(scroll_position, target_scroll, SCROLL_SMOOTH * delta)
	full_paper.position.y = -scroll_position


func _input(event: InputEvent) -> void:
	if is_signed:
		return
	
	var speed: float = SCROLL_SPEED_FAST if Input.is_key_pressed(KEY_SHIFT) else SCROLL_SPEED
	
	# Mouse wheel scrolling
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_scroll = clampf(target_scroll + speed, 0.0, max_scroll)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_scroll = clampf(target_scroll - speed, 0.0, max_scroll)
	
	# Arrow key scrolling
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_DOWN or event.keycode == KEY_S:
			target_scroll = clampf(target_scroll + speed, 0.0, max_scroll)
		elif event.keycode == KEY_UP or event.keycode == KEY_W:
			target_scroll = clampf(target_scroll - speed, 0.0, max_scroll)
		elif event.keycode == KEY_PAGEDOWN:
			target_scroll = clampf(target_scroll + speed * 3, 0.0, max_scroll)
		elif event.keycode == KEY_PAGEUP:
			target_scroll = clampf(target_scroll - speed * 3, 0.0, max_scroll)
		elif event.keycode == KEY_HOME:
			target_scroll = 0.0
		elif event.keycode == KEY_END:
			target_scroll = max_scroll


func _on_dice_pressed() -> void:
	var new_name := _get_random_name()
	name_input.text = new_name
	current_name = new_name
	
	# Also randomize surname
	current_surname = SURNAMES[randi() % SURNAMES.size()]


func _on_name_changed(new_text: String) -> void:
	current_name = new_text


func _on_signature_pressed() -> void:
	if is_signed:
		return
	
	var final_name := current_name.strip_edges()
	if final_name.is_empty():
		final_name = DEFAULT_NAME
	
	# Set signature text
	var full_name := "%s %s" % [final_name, current_surname]
	signature_button.text = full_name
	is_signed = true
	
	# Save
	_save_player_name(full_name)
	
	# Wait then fade
	await get_tree().create_timer(2.0).timeout
	await _fade_to_black()
	
	form_completed.emit(full_name)


func _get_random_name() -> String:
	var available := YORUBA_NAMES.duplicate()
	
	# Remove current to ensure different name
	var idx := available.find(current_name)
	if idx != -1:
		available.remove_at(idx)
	
	if available.is_empty():
		return DEFAULT_NAME
	
	return available[randi() % available.size()]


func _fade_to_black() -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 1.0)
	await tween.finished


func _save_player_name(full_name: String) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var parts := full_name.split(" ")
		file.store_var({
			"player_name": parts[0] if parts.size() > 0 else full_name,
			"full_name": full_name,
			"surname": current_surname
		})


## Check if player already has saved name
static func has_saved_name() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Load saved player name
static func load_saved_name() -> String:
	if not FileAccess.file_exists(SAVE_PATH):
		return ""
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data = file.get_var()
		if data is Dictionary:
			return data.get("full_name", data.get("player_name", ""))
	return ""
