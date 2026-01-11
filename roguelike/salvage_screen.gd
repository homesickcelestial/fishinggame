extends Control
## Salvage Screen - Craft new cards or upgrade existing ones
## First salvage always offers 3 starter tool paths

signal salvage_completed(result: Dictionary)

@onready var title_label: Label = $Panel/VBoxContainer/Title
@onready var salvage_list: VBoxContainer = $Panel/VBoxContainer/SalvageOptions
@onready var deck_list: VBoxContainer = $Panel/VBoxContainer/DeckSection/DeckScroll/DeckList
@onready var result_label: Label = $Panel/VBoxContainer/Result
@onready var done_button: Button = $Panel/VBoxContainer/Done

# STARTER TOOLS (choose 1 of 3 at first salvage)
const STARTER_TOOLS := [
	{
		"name": "Bent Hook",
		"description": "A basic but reliable fishing tool.",
		"card": {"name": "Bent Hook", "hook": 2, "line": 2, "sinker": 0, "ability": "None"},
		"upgrades_to": ["Barbed Hook", "Heavy Hook"]
	},
	{
		"name": "Frayed Net",
		"description": "Catches fish, sometimes stuns them.",
		"card": {"name": "Frayed Net", "hook": 1, "line": 2, "sinker": 1, "ability": "Stun"},
		"upgrades_to": ["Shock Net", "Wide Net"]
	},
	{
		"name": "Rusty Spear",
		"description": "Causes bleeding wounds.",
		"card": {"name": "Rusty Spear", "hook": 2, "line": 1, "sinker": 1, "ability": "Bleed"},
		"upgrades_to": ["Serrated Spear", "Trident"]
	}
]

# UPGRADE PATHS (when you have salvage + a card to upgrade)
const UPGRADE_RECIPES := {
	"Bent Hook": [
		{"name": "Barbed Hook", "hook": 3, "line": 2, "sinker": 1, "ability": "Bleed"},
		{"name": "Heavy Hook", "hook": 2, "line": 4, "sinker": 0, "ability": "None"}
	],
	"Frayed Net": [
		{"name": "Shock Net", "hook": 1, "line": 3, "sinker": 2, "ability": "Stun"},
		{"name": "Wide Net", "hook": 2, "line": 2, "sinker": 1, "ability": "Push"}
	],
	"Rusty Spear": [
		{"name": "Serrated Spear", "hook": 3, "line": 1, "sinker": 2, "ability": "Bleed"},
		{"name": "Trident", "hook": 2, "line": 2, "sinker": 1, "ability": "Pull"}
	]
}

# Generic salvage crafting (for non-starter salvages)
const SALVAGE_OPTIONS := {
	"Scrap Metal": [
		{"name": "Iron Hook", "hook": 2, "line": 3, "sinker": 0, "ability": "None"},
		{"name": "Anchor Weight", "hook": 1, "line": 4, "sinker": 0, "ability": "None"}
	],
	"Old Rope": [
		{"name": "Fishing Line", "hook": 1, "line": 2, "sinker": 0, "ability": "None"},
		{"name": "Lasso", "hook": 1, "line": 2, "sinker": 1, "ability": "Pull"}
	],
	"Fish Guts": [
		{"name": "Chum Bucket", "hook": 0, "line": 1, "sinker": 0, "ability": "Chum"},
		{"name": "Bait Ball", "hook": 1, "line": 1, "sinker": 1, "ability": "Bleed"}
	]
}

var available_salvage: Array[String] = []
var player_deck: Array[CardData] = []
var crafted_cards: Array[CardData] = []
var upgraded_cards: Array[CardData] = []
var is_first_salvage: bool = false


func _ready() -> void:
	visible = false
	done_button.pressed.connect(_on_done)


## Show salvage screen
## If is_starter is true, show the 3 starter tool options
func show_salvage(salvage: Array[String], deck: Array[CardData], is_starter: bool = false) -> void:
	available_salvage = salvage
	player_deck = deck
	crafted_cards.clear()
	upgraded_cards.clear()
	result_label.text = ""
	is_first_salvage = is_starter
	
	_update_display()
	visible = true


func _update_display() -> void:
	# Clear lists
	for child in salvage_list.get_children():
		child.queue_free()
	for child in deck_list.get_children():
		child.queue_free()
	
	if is_first_salvage:
		_show_starter_options()
	else:
		_show_salvage_options()
		_show_upgrade_options()


func _show_starter_options() -> void:
	title_label.text = "🔧 SALVAGE SITE - Choose Your Tool"
	
	var info_label := Label.new()
	info_label.text = "Pick one starter tool. Each can be upgraded later!"
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	salvage_list.add_child(info_label)
	
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	salvage_list.add_child(hbox)
	
	for tool_data in STARTER_TOOLS:
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(180, 220)
		hbox.add_child(panel)
		
		var vbox := VBoxContainer.new()
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.add_theme_constant_override("separation", 8)
		panel.add_child(vbox)
		
		var name_lbl := Label.new()
		name_lbl.text = tool_data.name
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(name_lbl)
		
		var desc_lbl := Label.new()
		desc_lbl.text = tool_data.description
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_lbl.add_theme_font_size_override("font_size", 11)
		vbox.add_child(desc_lbl)
		
		var card_data: Dictionary = tool_data.card
		var stats_lbl := Label.new()
		stats_lbl.text = "H:%d L:%d S:%d" % [card_data.hook, card_data.line, card_data.sinker]
		stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(stats_lbl)
		
		if card_data.ability != "None":
			var ability_lbl := Label.new()
			ability_lbl.text = "[%s]" % card_data.ability
			ability_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ability_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
			vbox.add_child(ability_lbl)
		
		var upgrades_lbl := Label.new()
		upgrades_lbl.text = "Upgrades to:\n%s" % "\n".join(tool_data.upgrades_to)
		upgrades_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		upgrades_lbl.add_theme_font_size_override("font_size", 10)
		upgrades_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		vbox.add_child(upgrades_lbl)
		
		var choose_btn := Button.new()
		choose_btn.text = "Take"
		choose_btn.pressed.connect(_on_starter_chosen.bind(tool_data))
		vbox.add_child(choose_btn)


func _show_salvage_options() -> void:
	title_label.text = "🔧 SALVAGE"
	
	if available_salvage.is_empty():
		var no_salvage := Label.new()
		no_salvage.text = "No salvage available. You can still upgrade cards below!"
		salvage_list.add_child(no_salvage)
		return
	
	for salvage_name in available_salvage:
		var hbox := HBoxContainer.new()
		salvage_list.add_child(hbox)
		
		var label := Label.new()
		label.text = salvage_name + ":"
		label.custom_minimum_size.x = 100
		hbox.add_child(label)
		
		if SALVAGE_OPTIONS.has(salvage_name):
			var options: Array = SALVAGE_OPTIONS[salvage_name]
			for opt in options:
				var btn := Button.new()
				btn.text = "%s (H:%d L:%d)" % [opt.name, opt.hook, opt.line]
				btn.pressed.connect(_on_craft_option.bind(salvage_name, opt))
				hbox.add_child(btn)


func _show_upgrade_options() -> void:
	# Show cards that can be upgraded
	var upgradeable_found := false
	
	for i in player_deck.size():
		var card := player_deck[i]
		if UPGRADE_RECIPES.has(card.card_name):
			if not upgradeable_found:
				var header := Label.new()
				header.text = "— UPGRADEABLE CARDS (costs 1 salvage) —"
				deck_list.add_child(header)
				upgradeable_found = true
			
			var hbox := HBoxContainer.new()
			deck_list.add_child(hbox)
			
			var card_lbl := Label.new()
			card_lbl.text = card.card_name
			card_lbl.custom_minimum_size.x = 120
			hbox.add_child(card_lbl)
			
			var upgrades: Array = UPGRADE_RECIPES[card.card_name]
			for upgrade in upgrades:
				var btn := Button.new()
				btn.text = "→ %s" % upgrade.name
				btn.disabled = available_salvage.is_empty()
				btn.pressed.connect(_on_upgrade_card.bind(i, upgrade))
				hbox.add_child(btn)
	
	if not upgradeable_found:
		var no_upgrades := Label.new()
		no_upgrades.text = "No cards available to upgrade."
		deck_list.add_child(no_upgrades)


func _on_starter_chosen(tool_data: Dictionary) -> void:
	var card_data: Dictionary = tool_data.card
	var card := CardData.new()
	card.card_name = card_data.name
	card.hook = card_data.hook
	card.line = card_data.line
	card.sinker = card_data.sinker
	card.ability = card_data.ability
	
	crafted_cards.append(card)
	is_first_salvage = false
	
	result_label.text = "Acquired: %s!" % card.card_name
	done_button.grab_focus()
	
	# Hide starter options, show confirmation
	for child in salvage_list.get_children():
		child.queue_free()
	
	var done_label := Label.new()
	done_label.text = "You chose: %s\n\nClick Done to continue." % card.card_name
	done_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	salvage_list.add_child(done_label)


func _on_craft_option(salvage_name: String, opt: Dictionary) -> void:
	var card := CardData.new()
	card.card_name = opt.name
	card.hook = opt.hook
	card.line = opt.line
	card.sinker = opt.sinker
	card.ability = opt.ability
	
	crafted_cards.append(card)
	
	# Remove used salvage
	var idx := available_salvage.find(salvage_name)
	if idx >= 0:
		available_salvage.remove_at(idx)
	
	result_label.text = "Crafted: %s!" % card.card_name
	_update_display()


func _on_upgrade_card(deck_index: int, upgrade: Dictionary) -> void:
	if available_salvage.is_empty():
		result_label.text = "No salvage to upgrade!"
		return
	
	var old_card := player_deck[deck_index]
	var old_name := old_card.card_name
	
	# Replace card stats
	old_card.card_name = upgrade.name
	old_card.hook = upgrade.hook
	old_card.line = upgrade.line
	old_card.sinker = upgrade.sinker
	old_card.ability = upgrade.ability
	
	upgraded_cards.append(old_card)
	
	# Use one salvage
	available_salvage.pop_back()
	
	result_label.text = "Upgraded %s → %s!" % [old_name, upgrade.name]
	_update_display()


func _on_done() -> void:
	visible = false
	salvage_completed.emit({
		"crafted": crafted_cards,
		"upgraded": upgraded_cards,
		"was_starter": is_first_salvage
	})
