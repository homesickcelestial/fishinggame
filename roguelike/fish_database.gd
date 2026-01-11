extends Node
class_name FishDatabase
## Database of all fish in the game with their stats and image paths
##
## IMAGE DIRECTORY STRUCTURE:
## res://assets/fish/
##   ├── shallows/
##   │   ├── minnow.png
##   │   ├── trout.png
##   │   ├── perch.png
##   │   └── bass.png
##   ├── depths/
##   │   ├── eel.png
##   │   ├── crab.png
##   │   ├── anglerfish.png
##   │   └── jellyfish.png
##   ├── abyss/
##   │   ├── shark.png
##   │   ├── octopus.png
##   │   ├── leviathan.png
##   │   └── kraken.png
##   └── special/
##       ├── sirenling.png
##       ├── treasure_fish.png
##       └── ghost_fish.png

## Fish definition structure:
## {
##   "name": String,
##   "max_hp": int,
##   "attack": int,
##   "behavior": String,
##   "behavior_description": String,
##   "image_path": String,
##   "area": int,  # Which area this fish appears in (1, 2, 3)
##   "rarity": String  # "common", "uncommon", "rare", "boss"
## }

const FISH := {
	# ========== AREA 1: THE SHALLOWS ==========
	"Minnow": {
		"name": "Minnow",
		"max_hp": 2,
		"attack": 1,
		"behavior": "Normal",
		"behavior_description": "No special behavior",
		"image_path": "res://assets/fish/shallows/minnow.png",
		"area": 1,
		"rarity": "common"
	},
	"Trout": {
		"name": "Trout",
		"max_hp": 3,
		"attack": 1,
		"behavior": "Normal",
		"behavior_description": "No special behavior",
		"image_path": "res://assets/fish/shallows/trout.png",
		"area": 1,
		"rarity": "common"
	},
	"Perch": {
		"name": "Perch",
		"max_hp": 3,
		"attack": 1,
		"behavior": "Skipper",
		"behavior_description": "Moves to adjacent lane when hit",
		"image_path": "res://assets/fish/shallows/perch.png",
		"area": 1,
		"rarity": "common"
	},
	"Bass": {
		"name": "Bass",
		"max_hp": 4,
		"attack": 2,
		"behavior": "Normal",
		"behavior_description": "No special behavior",
		"image_path": "res://assets/fish/shallows/bass.png",
		"area": 1,
		"rarity": "uncommon"
	},
	
	# ========== AREA 2: THE DEPTHS ==========
	"Eel": {
		"name": "Eel",
		"max_hp": 4,
		"attack": 1,
		"behavior": "Skipper",
		"behavior_description": "Moves to adjacent lane when hit",
		"image_path": "res://assets/fish/depths/eel.png",
		"area": 2,
		"rarity": "common"
	},
	"Crab": {
		"name": "Crab",
		"max_hp": 5,
		"attack": 1,
		"behavior": "Latcher",
		"behavior_description": "Deals +1 LINE damage to cards",
		"image_path": "res://assets/fish/depths/crab.png",
		"area": 2,
		"rarity": "common"
	},
	"Anglerfish": {
		"name": "Anglerfish",
		"max_hp": 4,
		"attack": 2,
		"behavior": "Burrower",
		"behavior_description": "Becomes immune after being hit once",
		"image_path": "res://assets/fish/depths/anglerfish.png",
		"area": 2,
		"rarity": "uncommon"
	},
	"Jellyfish": {
		"name": "Jellyfish",
		"max_hp": 3,
		"attack": 1,
		"behavior": "Sirenling",
		"behavior_description": "+1 bait cost for cards while alive",
		"image_path": "res://assets/fish/depths/jellyfish.png",
		"area": 2,
		"rarity": "uncommon"
	},
	
	# ========== AREA 3: THE ABYSS ==========
	"Shark": {
		"name": "Shark",
		"max_hp": 6,
		"attack": 2,
		"behavior": "Jawper",
		"behavior_description": "Deals 2 damage to boat instead of 1",
		"image_path": "res://assets/fish/abyss/shark.png",
		"area": 3,
		"rarity": "common"
	},
	"Octopus": {
		"name": "Octopus",
		"max_hp": 5,
		"attack": 1,
		"behavior": "Latcher",
		"behavior_description": "Deals +1 LINE damage to cards",
		"image_path": "res://assets/fish/abyss/octopus.png",
		"area": 3,
		"rarity": "common"
	},
	"Giant Squid": {
		"name": "Giant Squid",
		"max_hp": 7,
		"attack": 2,
		"behavior": "Burrower",
		"behavior_description": "Becomes immune after being hit once",
		"image_path": "res://assets/fish/abyss/giant_squid.png",
		"area": 3,
		"rarity": "uncommon"
	},
	
	# ========== SPECIAL FISH ==========
	"Sirenling": {
		"name": "Sirenling",
		"max_hp": 3,
		"attack": 1,
		"behavior": "Sirenling",
		"behavior_description": "+1 bait cost for cards while alive",
		"image_path": "res://assets/fish/special/sirenling.png",
		"area": 1,
		"rarity": "rare"
	},
	"Treasure Fish": {
		"name": "Treasure Fish",
		"max_hp": 2,
		"attack": 0,
		"behavior": "Skipper",
		"behavior_description": "Moves to adjacent lane when hit. Drops extra gold!",
		"image_path": "res://assets/fish/special/treasure_fish.png",
		"area": 1,
		"rarity": "rare"
	},
	"Ghost Fish": {
		"name": "Ghost Fish",
		"max_hp": 4,
		"attack": 1,
		"behavior": "Burrower",
		"behavior_description": "Becomes immune after being hit once",
		"image_path": "res://assets/fish/special/ghost_fish.png",
		"area": 2,
		"rarity": "rare"
	},
	
	# ========== BOSSES ==========
	"King Salmon": {
		"name": "King Salmon",
		"max_hp": 10,
		"attack": 2,
		"behavior": "Normal",
		"behavior_description": "The ruler of the Shallows",
		"image_path": "res://assets/fish/shallows/king_salmon.png",
		"area": 1,
		"rarity": "boss"
	},
	"Leviathan": {
		"name": "Leviathan",
		"max_hp": 15,
		"attack": 3,
		"behavior": "Jawper",
		"behavior_description": "Ancient terror of the Depths",
		"image_path": "res://assets/fish/depths/leviathan.png",
		"area": 2,
		"rarity": "boss"
	},
	"Kraken": {
		"name": "Kraken",
		"max_hp": 20,
		"attack": 3,
		"behavior": "Latcher",
		"behavior_description": "The final challenge of the Abyss",
		"image_path": "res://assets/fish/abyss/kraken.png",
		"area": 3,
		"rarity": "boss"
	}
}

## Behavior descriptions for UI display
const BEHAVIOR_DESCRIPTIONS := {
	"Normal": "",
	"Skipper": "Moves when hit",
	"Burrower": "Immune after first hit",
	"Latcher": "+1 LINE damage",
	"Sirenling": "+1 bait cost",
	"Jawper": "2 damage to boat"
}


## Get fish data by name
static func get_fish(fish_name: String) -> Dictionary:
	if FISH.has(fish_name):
		return FISH[fish_name]
	return {}


## Get all fish for a specific area
static func get_fish_by_area(area: int) -> Array:
	var result := []
	for fish_name in FISH:
		if FISH[fish_name].area == area:
			result.append(FISH[fish_name])
	return result


## Get all fish of a specific rarity
static func get_fish_by_rarity(rarity: String) -> Array:
	var result := []
	for fish_name in FISH:
		if FISH[fish_name].rarity == rarity:
			result.append(FISH[fish_name])
	return result


## Get fish pool for an area (common + uncommon, optionally rare)
static func get_area_pool(area: int, include_rare: bool = false) -> Array:
	var result := []
	for fish_name in FISH:
		var fish: Dictionary = FISH[fish_name]
		if fish.area <= area:  # Include fish from current and earlier areas
			if fish.rarity == "common" or fish.rarity == "uncommon":
				result.append(fish)
			elif include_rare and fish.rarity == "rare":
				result.append(fish)
	return result


## Get boss for an area
static func get_area_boss(area: int) -> Dictionary:
	for fish_name in FISH:
		var fish: Dictionary = FISH[fish_name]
		if fish.area == area and fish.rarity == "boss":
			return fish
	return {}


## Create a FishData from database entry
static func create_fish_data(fish_name: String) -> FishData:
	var data := get_fish(fish_name)
	if data.is_empty():
		return null
	
	var fish := FishData.new()
	fish.fish_name = data.name
	fish.max_hp = data.max_hp
	fish.attack = data.attack
	fish.behavior = data.behavior
	return fish


## Get random fish from area pool
static func get_random_fish(area: int, include_rare: bool = false) -> Dictionary:
	var pool := get_area_pool(area, include_rare)
	if pool.is_empty():
		return {}
	return pool[randi() % pool.size()]


## Get behavior description text
static func get_behavior_description(behavior: String) -> String:
	if BEHAVIOR_DESCRIPTIONS.has(behavior):
		return BEHAVIOR_DESCRIPTIONS[behavior]
	return ""


## Get all fish names
static func get_all_fish_names() -> Array:
	return FISH.keys()
