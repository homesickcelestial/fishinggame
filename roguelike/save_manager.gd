extends Node
## Save Manager - Handles all save/load operations
## Add as autoload: Project Settings > Autoload > save_manager.gd as "SaveManager"

const SAVE_PATH := "user://roguelike_save.json"
const RUN_SAVE_PATH := "user://current_run.json"
const SETTINGS_PATH := "user://settings.json"

signal save_completed
signal load_completed
signal run_saved
signal run_loaded


## --- PERSISTENT SAVE (across runs) ---

func save_game(data: Dictionary) -> void:
	var json := JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json)
		file.close()
		save_completed.emit()


func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return _get_default_save()
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return _get_default_save()
	
	var json := file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(json)
	if parsed is Dictionary:
		load_completed.emit()
		return parsed
	
	return _get_default_save()


func _get_default_save() -> Dictionary:
	return {
		"total_gold": 0,
		"total_runs": 0,
		"best_area": 0,
		"fish_caught": 0,
		"tutorial_completed": false,
		"unlocked_cards": [],
	}


## --- RUN SAVE (current run state) ---

func save_run(run_data: Dictionary) -> void:
	# Convert CardData to dictionaries
	var deck_data: Array = []
	for card in run_data.get("deck", []):
		if card is CardData:
			deck_data.append(_card_to_dict(card))
		elif card is Dictionary:
			deck_data.append(card)
	
	var save_data := {
		"boat_hp": run_data.get("boat_hp", 3),
		"max_boat_hp": run_data.get("max_boat_hp", 3),
		"gold": run_data.get("gold", 0),
		"deck": deck_data,
		"salvage": run_data.get("salvage", []),
		"current_area": run_data.get("current_area", 1),
		"nodes_cleared": run_data.get("nodes_cleared", 0),
		"fish_caught": run_data.get("fish_caught", 0),
		"map_state": run_data.get("map_state", {}),
		"timestamp": Time.get_unix_time_from_system(),
	}
	
	var json := JSON.stringify(save_data, "\t")
	var file := FileAccess.open(RUN_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json)
		file.close()
		run_saved.emit()


func load_run() -> Dictionary:
	if not FileAccess.file_exists(RUN_SAVE_PATH):
		return {}
	
	var file := FileAccess.open(RUN_SAVE_PATH, FileAccess.READ)
	if not file:
		return {}
	
	var json := file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(json)
	if not parsed is Dictionary:
		return {}
	
	# Convert deck back to CardData
	var deck: Array[CardData] = []
	for card_dict in parsed.get("deck", []):
		deck.append(_dict_to_card(card_dict))
	parsed["deck"] = deck
	
	run_loaded.emit()
	return parsed


func has_saved_run() -> bool:
	return FileAccess.file_exists(RUN_SAVE_PATH)


func delete_run_save() -> void:
	if FileAccess.file_exists(RUN_SAVE_PATH):
		DirAccess.remove_absolute(RUN_SAVE_PATH)


## --- SETTINGS ---

func save_settings(settings: Dictionary) -> void:
	var json := JSON.stringify(settings, "\t")
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json)
		file.close()


func load_settings() -> Dictionary:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return _get_default_settings()
	
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not file:
		return _get_default_settings()
	
	var json := file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(json)
	if parsed is Dictionary:
		return parsed
	
	return _get_default_settings()


func _get_default_settings() -> Dictionary:
	return {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"fullscreen": false,
		"screen_shake": true,
	}


## --- CONVERSION HELPERS ---

func _card_to_dict(card: CardData) -> Dictionary:
	return {
		"name": card.card_name,
		"hook": card.hook,
		"line": card.line,
		"sinker": card.sinker,
		"ability": card.ability,
		"description": card.description,
	}


func _dict_to_card(data: Dictionary) -> CardData:
	var card := CardData.new()
	card.card_name = data.get("name", "Unknown")
	card.hook = data.get("hook", 1)
	card.line = data.get("line", 1)
	card.sinker = data.get("sinker", 0)
	card.ability = data.get("ability", "None")
	card.description = data.get("description", "")
	return card


## --- STATISTICS ---

func record_run_end(victory: bool, stats: Dictionary) -> void:
	var save_data := load_game()
	
	save_data["total_runs"] = save_data.get("total_runs", 0) + 1
	save_data["fish_caught"] = save_data.get("fish_caught", 0) + stats.get("fish_caught", 0)
	
	if victory:
		var area: int = stats.get("area", 1)
		if area > save_data.get("best_area", 0):
			save_data["best_area"] = area
	
	# Add remaining gold (after penalty if loss)
	save_data["total_gold"] = save_data.get("total_gold", 0) + stats.get("final_gold", 0)
	
	save_game(save_data)
	delete_run_save()
