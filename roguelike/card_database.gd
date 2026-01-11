extends Node
class_name CardDatabase
## Database of all cards in the game with their stats and image paths
## 
## IMAGE DIRECTORY STRUCTURE:
## res://assets/cards/
##   ├── starter/
##   │   ├── bent_hook.png
##   │   ├── frayed_net.png
##   │   └── rusty_spear.png
##   ├── hooks/
##   │   ├── barbed_hook.png
##   │   ├── heavy_hook.png
##   │   ├── iron_hook.png
##   │   └── anchor_weight.png
##   ├── nets/
##   │   ├── shock_net.png
##   │   ├── wide_net.png
##   │   └── fishing_line.png
##   ├── spears/
##   │   ├── serrated_spear.png
##   │   ├── trident.png
##   │   └── harpoon.png
##   ├── bait/
##   │   ├── chum_bucket.png
##   │   ├── bait_ball.png
##   │   └── lure.png
##   └── special/
##       ├── shield.png
##       ├── repair_kit.png
##       └── lucky_charm.png

## Card definition structure:
## {
##   "name": String,
##   "hook": int,
##   "line": int, 
##   "sinker": int,
##   "ability": String,
##   "ability_description": String,
##   "image_path": String,
##   "rarity": String  # "common", "uncommon", "rare"
## }

const CARDS := {
	# ========== STARTER TOOLS ==========
	"Bent Hook": {
		"name": "Bent Hook",
		"hook": 2,
		"line": 2,
		"sinker": 0,
		"ability": "None",
		"ability_description": "",
		"image_path": "res://assets/cards/starter/bent_hook.png",
		"rarity": "starter"
	},
	"Frayed Net": {
		"name": "Frayed Net",
		"hook": 1,
		"line": 2,
		"sinker": 1,
		"ability": "Stun",
		"ability_description": "Stuns fish for 1 turn when played",
		"image_path": "res://assets/cards/starter/frayed_net.png",
		"rarity": "starter"
	},
	"Rusty Spear": {
		"name": "Rusty Spear",
		"hook": 2,
		"line": 1,
		"sinker": 1,
		"ability": "Bleed",
		"ability_description": "Fish takes 1 damage per turn",
		"image_path": "res://assets/cards/starter/rusty_spear.png",
		"rarity": "starter"
	},
	
	# ========== BASIC CARDS ==========
	"Fishing Line": {
		"name": "Fishing Line",
		"hook": 1,
		"line": 2,
		"sinker": 0,
		"ability": "None",
		"ability_description": "",
		"image_path": "res://assets/cards/nets/fishing_line.png",
		"rarity": "common"
	},
	"Chum Bucket": {
		"name": "Chum Bucket",
		"hook": 0,
		"line": 1,
		"sinker": 1,
		"ability": "Chum",
		"ability_description": "Draw 2 cards when played",
		"image_path": "res://assets/cards/bait/chum_bucket.png",
		"rarity": "common"
	},
	
	# ========== HOOK UPGRADES ==========
	"Barbed Hook": {
		"name": "Barbed Hook",
		"hook": 3,
		"line": 2,
		"sinker": 1,
		"ability": "Bleed",
		"ability_description": "Fish takes 1 damage per turn",
		"image_path": "res://assets/cards/hooks/barbed_hook.png",
		"rarity": "uncommon"
	},
	"Heavy Hook": {
		"name": "Heavy Hook",
		"hook": 2,
		"line": 4,
		"sinker": 0,
		"ability": "None",
		"ability_description": "",
		"image_path": "res://assets/cards/hooks/heavy_hook.png",
		"rarity": "uncommon"
	},
	"Iron Hook": {
		"name": "Iron Hook",
		"hook": 2,
		"line": 3,
		"sinker": 0,
		"ability": "None",
		"ability_description": "",
		"image_path": "res://assets/cards/hooks/iron_hook.png",
		"rarity": "common"
	},
	"Anchor Weight": {
		"name": "Anchor Weight",
		"hook": 1,
		"line": 4,
		"sinker": 0,
		"ability": "None",
		"ability_description": "",
		"image_path": "res://assets/cards/hooks/anchor_weight.png",
		"rarity": "common"
	},
	
	# ========== NET UPGRADES ==========
	"Shock Net": {
		"name": "Shock Net",
		"hook": 1,
		"line": 3,
		"sinker": 2,
		"ability": "Stun",
		"ability_description": "Stuns fish for 1 turn when played",
		"image_path": "res://assets/cards/nets/shock_net.png",
		"rarity": "uncommon"
	},
	"Wide Net": {
		"name": "Wide Net",
		"hook": 2,
		"line": 2,
		"sinker": 1,
		"ability": "Push",
		"ability_description": "Push fish to adjacent lane",
		"image_path": "res://assets/cards/nets/wide_net.png",
		"rarity": "uncommon"
	},
	"Lasso": {
		"name": "Lasso",
		"hook": 1,
		"line": 2,
		"sinker": 1,
		"ability": "Pull",
		"ability_description": "Pull fish from adjacent lane",
		"image_path": "res://assets/cards/nets/lasso.png",
		"rarity": "common"
	},
	
	# ========== SPEAR UPGRADES ==========
	"Serrated Spear": {
		"name": "Serrated Spear",
		"hook": 3,
		"line": 1,
		"sinker": 2,
		"ability": "Bleed",
		"ability_description": "Fish takes 1 damage per turn",
		"image_path": "res://assets/cards/spears/serrated_spear.png",
		"rarity": "uncommon"
	},
	"Trident": {
		"name": "Trident",
		"hook": 2,
		"line": 2,
		"sinker": 1,
		"ability": "Pull",
		"ability_description": "Pull fish from adjacent lane",
		"image_path": "res://assets/cards/spears/trident.png",
		"rarity": "uncommon"
	},
	"Rusty Harpoon": {
		"name": "Rusty Harpoon",
		"hook": 2,
		"line": 3,
		"sinker": 0,
		"ability": "None",
		"ability_description": "",
		"image_path": "res://assets/cards/spears/harpoon.png",
		"rarity": "common"
	},
	
	# ========== BAIT CARDS ==========
	"Bait Ball": {
		"name": "Bait Ball",
		"hook": 1,
		"line": 1,
		"sinker": 1,
		"ability": "Bleed",
		"ability_description": "Fish takes 1 damage per turn",
		"image_path": "res://assets/cards/bait/bait_ball.png",
		"rarity": "common"
	},
	"Shiny Lure": {
		"name": "Shiny Lure",
		"hook": 1,
		"line": 2,
		"sinker": 2,
		"ability": "Taunt",
		"ability_description": "All fish attack this card",
		"image_path": "res://assets/cards/bait/lure.png",
		"rarity": "uncommon"
	},
	
	# ========== SPECIAL CARDS ==========
	"Shield": {
		"name": "Shield",
		"hook": 1,
		"line": 3,
		"sinker": 1,
		"ability": "Shield",
		"ability_description": "Reduce incoming damage by 1 after attacking",
		"image_path": "res://assets/cards/special/shield.png",
		"rarity": "uncommon"
	},
	"Repair Kit": {
		"name": "Repair Kit",
		"hook": 0,
		"line": 1,
		"sinker": 2,
		"ability": "Repair",
		"ability_description": "Restore 1 LINE to adjacent card",
		"image_path": "res://assets/cards/special/repair_kit.png",
		"rarity": "uncommon"
	},
	"Lucky Charm": {
		"name": "Lucky Charm",
		"hook": 1,
		"line": 2,
		"sinker": 1,
		"ability": "Lucky",
		"ability_description": "Gain 1 extra bait when sacrificed",
		"image_path": "res://assets/cards/special/lucky_charm.png",
		"rarity": "rare"
	},
	
	# ========== RARE CARDS ==========
	"Golden Hook": {
		"name": "Golden Hook",
		"hook": 4,
		"line": 3,
		"sinker": 1,
		"ability": "Bleed",
		"ability_description": "Fish takes 1 damage per turn",
		"image_path": "res://assets/cards/hooks/golden_hook.png",
		"rarity": "rare"
	},
	"Storm Net": {
		"name": "Storm Net",
		"hook": 2,
		"line": 3,
		"sinker": 3,
		"ability": "Stun",
		"ability_description": "Stuns ALL fish for 1 turn when played",
		"image_path": "res://assets/cards/nets/storm_net.png",
		"rarity": "rare"
	},
	"Poseidon's Trident": {
		"name": "Poseidon's Trident",
		"hook": 3,
		"line": 3,
		"sinker": 2,
		"ability": "Pull",
		"ability_description": "Pull fish from ANY lane",
		"image_path": "res://assets/cards/spears/poseidon_trident.png",
		"rarity": "rare"
	}
}

## Ability descriptions for UI display
const ABILITY_DESCRIPTIONS := {
	"None": "",
	"Stun": "Stuns fish for 1 turn",
	"Bleed": "Fish takes 1 damage/turn",
	"Push": "Push fish to adjacent lane",
	"Pull": "Pull fish from adjacent lane",
	"Chum": "Draw 2 cards when played",
	"Shield": "-1 incoming damage after attack",
	"Repair": "Restore 1 LINE to ally",
	"Taunt": "All fish attack this card",
	"Lucky": "+1 bait when sacrificed"
}


## Get card data by name
static func get_card(card_name: String) -> Dictionary:
	if CARDS.has(card_name):
		return CARDS[card_name]
	return {}


## Get all cards of a specific rarity
static func get_cards_by_rarity(rarity: String) -> Array:
	var result := []
	for card_name in CARDS:
		if CARDS[card_name].rarity == rarity:
			result.append(CARDS[card_name])
	return result


## Get random card of specific rarity
static func get_random_card(rarity: String = "") -> Dictionary:
	var pool: Array
	if rarity.is_empty():
		pool = CARDS.values()
	else:
		pool = get_cards_by_rarity(rarity)
	
	if pool.is_empty():
		return {}
	return pool[randi() % pool.size()]


## Get reward cards for combat victory (excludes starters)
static func get_reward_pool(include_rare: bool = false) -> Array:
	var pool := []
	pool.append_array(get_cards_by_rarity("common"))
	pool.append_array(get_cards_by_rarity("uncommon"))
	if include_rare:
		pool.append_array(get_cards_by_rarity("rare"))
	return pool


## Create a CardData from database entry
static func create_card_data(card_name: String) -> CardData:
	var data := get_card(card_name)
	if data.is_empty():
		return null
	
	var card := CardData.new()
	card.card_name = data.name
	card.hook = data.hook
	card.line = data.line
	card.sinker = data.sinker
	card.ability = data.ability
	return card


## Get ability description text
static func get_ability_description(ability: String) -> String:
	if ABILITY_DESCRIPTIONS.has(ability):
		return ABILITY_DESCRIPTIONS[ability]
	return ""


## Get all card names
static func get_all_card_names() -> Array:
	return CARDS.keys()
