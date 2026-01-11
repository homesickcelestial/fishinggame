extends Control
## Options Menu for Depths of the Arkhitekta

signal closed

@onready var master_slider: HSlider = $Panel/VBoxContainer/MasterSlider
@onready var music_slider: HSlider = $Panel/VBoxContainer/MusicSlider
@onready var sfx_slider: HSlider = $Panel/VBoxContainer/SFXSlider
@onready var fullscreen_check: CheckButton = $Panel/VBoxContainer/FullscreenContainer/FullscreenCheck


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_load_current_settings()


func _load_current_settings() -> void:
	master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	music_slider.value = _get_bus_volume_linear("Music")
	sfx_slider.value = _get_bus_volume_linear("SFX")
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN


func _get_bus_volume_linear(bus_name: String) -> float:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return 1.0
	return db_to_linear(AudioServer.get_bus_volume_db(bus_idx))


func _on_master_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(value))


func _on_music_volume_changed(value: float) -> void:
	var bus_idx := AudioServer.get_bus_index("Music")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))


func _on_sfx_volume_changed(value: float) -> void:
	var bus_idx := AudioServer.get_bus_index("SFX")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_back_button_pressed() -> void:
	closed.emit()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
