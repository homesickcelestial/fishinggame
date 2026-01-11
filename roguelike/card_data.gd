extends Resource
class_name CardData

@export var card_name: String = "Card"
@export var hook: int = 1  # Damage
@export var line: int = 2  # Health/durability
@export var sinker: int = 0  # Effect power

@export_enum("None", "Push", "Pull", "Stun", "Bleed", "Shield", "Repair", "Chum") var ability: String = "None"
@export_multiline var description: String = ""

@export var texture: Texture2D


func duplicate_card() -> CardData:
	var copy := CardData.new()
	copy.card_name = card_name
	copy.hook = hook
	copy.line = line
	copy.sinker = sinker
	copy.ability = ability
	copy.description = description
	copy.texture = texture
	return copy
