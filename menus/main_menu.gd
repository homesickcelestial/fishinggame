extends Node2D
## Main Menu for Depths of the Arkhitekta

@onready var play_button: Button = $TextureRect/HBoxContainer/Play
@onready var options_button: Button = $TextureRect/HBoxContainer/Options
@onready var quit_button: Button = $TextureRect/HBoxContainer/Quit
@onready var options_menu: Control = $UILayer/OptionsMenu
@onready var starting_form: Node2D = $UILayer/StartingForm
@onready var main_content: TextureRect = $TextureRect


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	options_menu.closed.connect(_on_options_closed)
	
	# Hide starting form initially
	starting_form.visible = false
	
	# Connect to form completion
	starting_form.form_completed.connect(_on_form_completed)


func _on_play_pressed() -> void:
	# Hide main menu content, show starting form
	main_content.visible = false
	starting_form.visible = true


func _on_options_pressed() -> void:
	options_menu.visible = true
	_set_main_buttons_disabled(true)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_options_closed() -> void:
	options_menu.visible = false
	_set_main_buttons_disabled(false)


func _on_form_completed(full_name: String) -> void:
	# Form is done and faded to black, go to game
	get_tree().change_scene_to_file("res://scenes/menus/base.tscn")


func _set_main_buttons_disabled(disabled: bool) -> void:
	play_button.disabled = disabled
	options_button.disabled = disabled
	quit_button.disabled = disabled
