extends Control
## Name Picker UI for Depths of the Arkhitekta
## Allows player to choose or randomise a period-accurate 1870s Nigerian male name

signal name_confirmed(player_name: String)

@onready var name_input: LineEdit = $Panel/VBoxContainer/NameInput
@onready var randomise_button: Button = $Panel/VBoxContainer/ButtonContainer/RandomiseButton
@onready var confirm_button: Button = $Panel/VBoxContainer/ButtonContainer/ConfirmButton

const SAVE_PATH := "user://player_data.save"

## Period-accurate Nigerian male names from the 1870s era
## Mix of Yoruba, Igbo, Hausa, and Edo names common during this period
const NIGERIAN_NAMES: Array[String] = [
	# Yoruba names
	"Adebayo",
	"Adewale",
	"Ayodele",
	"Babatunde",
	"Damilola",
	"Folarin",
	"Iyanu",
	"Kayode",
	"Oladele",
	"Olufemi",
	"Olumide",
	"Oluwaseun",
	"Rotimi",
	"Segun",
	"Temitope",
	"Yemi",
	# Igbo names
	"Chukwuemeka",
	"Chibueze",
	"Emeka",
	"Ikechukwu",
	"Kelechi",
	"Nnamdi",
	"Obinna",
	"Okonkwo",
	"Ugochukwu",
	"Chidi",
	# Hausa names
	"Abubakar",
	"Bello",
	"Garba",
	"Ibrahim",
	"Musa",
	"Suleiman",
	"Yakubu",
	# Edo names
	"Osaze",
	"Eghosa",
	"Osagie",
]

const DEFAULT_NAME: String = "Adebayo"

var current_name: String = DEFAULT_NAME


func _ready() -> void:
	name_input.text = DEFAULT_NAME
	current_name = DEFAULT_NAME
	_update_confirm_button_state()


func _on_randomise_button_pressed() -> void:
	var random_name := _get_random_name()
	name_input.text = random_name
	current_name = random_name
	_update_confirm_button_state()
	
	# Small visual feedback
	randomise_button.disabled = true
	await get_tree().create_timer(0.1).timeout
	randomise_button.disabled = false


func _on_confirm_button_pressed() -> void:
	if current_name.strip_edges().is_empty():
		return
	
	_save_player_name(current_name.strip_edges())
	name_confirmed.emit(current_name.strip_edges())
	queue_free()


func _on_name_input_text_changed(new_text: String) -> void:
	current_name = new_text
	_update_confirm_button_state()


func _get_random_name() -> String:
	var available_names := NIGERIAN_NAMES.duplicate()
	
	# Remove current name from pool to ensure we always get a different name
	var current_index := available_names.find(current_name)
	if current_index != -1:
		available_names.remove_at(current_index)
	
	if available_names.is_empty():
		return DEFAULT_NAME
	
	var random_index := randi() % available_names.size()
	return available_names[random_index]


func _update_confirm_button_state() -> void:
	confirm_button.disabled = current_name.strip_edges().is_empty()


func _save_player_name(player_name: String) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var({"player_name": player_name})


## Call this to reset the picker to default state
func reset() -> void:
	name_input.text = DEFAULT_NAME
	current_name = DEFAULT_NAME
	_update_confirm_button_state()


## Call this to set a specific name programmatically
func set_player_name(new_name: String) -> void:
	name_input.text = new_name
	current_name = new_name
	_update_confirm_button_state()


## Returns the currently entered name
func get_current_name() -> String:
	return current_name.strip_edges()


## Check if player has already set their name (for first-run detection)
static func has_saved_name() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Load the saved player name
static func load_saved_name() -> String:
	if not FileAccess.file_exists(SAVE_PATH):
		return ""
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data = file.get_var()
		if data is Dictionary and data.has("player_name"):
			return data["player_name"]
	
	return ""
