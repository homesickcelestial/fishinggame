extends Resource
class_name FishData

@export var fish_name: String = "Fish"
@export var max_hp: int = 3
@export var attack: int = 1

@export_enum("None", "Skipper", "Latcher", "Burrower", "Jawper", "Leaper", "Sirenling") var behavior: String = "None"
@export_multiline var description: String = ""

@export var texture: Texture2D


func create_instance() -> Dictionary:
	return {
		"data": self,
		"current_hp": max_hp,
		"stunned": false,
		"burrowed": false,
		"bleed": 0
	}
