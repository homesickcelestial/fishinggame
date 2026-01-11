extends Control
## Rewards Screen - Post-battle loot selection

signal rewards_completed(chosen_reward: Dictionary)

@onready var title_label: Label = $Panel/VBoxContainer/Title
@onready var gold_label: Label = $Panel/VBoxContainer/GoldEarned
@onready var card_choices: HBoxContainer = $Panel/VBoxContainer/CardChoices
@onready var skip_button: Button = $Panel/VBoxContainer/Skip

var gold_earned: int = 0
var card_options: Array[CardData] = []
var selected_card: CardData = null

# Card pool for rewards
const REWARD_CARDS := [
	{"name": "Sharpened Hook", "hook": 2, "line": 2, "sinker": 0, "ability": "None"},
	{"name": "Sturdy Line", "hook": 1, "line": 3, "sinker": 0, "ability": "None"},
	{"name": "Shock Net", "hook": 1, "line": 2, "sinker": 1, "ability": "Stun"},
	{"name": "Serrated Edge", "hook": 2, "line": 1, "sinker": 1, "ability": "Bleed"},
	{"name": "Iron Anchor", "hook": 1, "line": 5, "sinker": 0, "ability": "None"},
	{"name": "Chum Pouch", "hook": 0, "line": 1, "sinker": 1, "ability": "Chum"},
	{"name": "Mending Thread", "hook": 1, "line": 2, "sinker": 1, "ability": "Repair"},
	{"name": "Pushing Oar", "hook": 1, "line": 2, "sinker": 1, "ability": "Push"},
	{"name": "Grapple", "hook": 2, "line": 2, "sinker": 1, "ability": "Pull"},
	{"name": "Thick Shield", "hook": 0, "line": 4, "sinker": 1, "ability": "Shield"},
]


func _ready() -> void:
	visible = false
	skip_button.pressed.connect(_on_skip)


func show_rewards(gold: int, is_elite: bool = false) -> void:
	gold_earned = gold
	selected_card = null
	
	# Generate card options
	card_options.clear()
	var pool := REWARD_CARDS.duplicate()
	pool.shuffle()
	
	var num_choices: int = 3 if is_elite else 2
	
	for i in num_choices:
		if i >= pool.size():
			break
		var template: Dictionary = pool[i]
		var card := CardData.new()
		card.card_name = template.name
		card.hook = template.hook
		card.line = template.line
		card.sinker = template.sinker
		card.ability = template.ability
		
		# Elite rewards get +1 to a random stat
		if is_elite:
			match randi() % 3:
				0: card.hook += 1
				1: card.line += 1
				2: card.sinker += 1
		
		card_options.append(card)
	
	_update_display()
	visible = true


func _update_display() -> void:
	title_label.text = "⚔ VICTORY!"
	gold_label.text = "+%d Gold" % gold_earned
	
	# Animate title
	AnimHelper.pop_in(title_label, 0.5)
	AnimHelper.slide_in(gold_label, Vector2(0, -30), 0.4, 0.2)
	
	# Clear card choices
	for child in card_choices.get_children():
		child.queue_free()
	
	# Show card options with staggered animation
	var panels: Array = []
	for card in card_options:
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(150, 180)
		card_choices.add_child(panel)
		
		var vbox := VBoxContainer.new()
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.add_theme_constant_override("separation", 5)
		panel.add_child(vbox)
		
		var name_lbl := Label.new()
		name_lbl.text = card.card_name
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(name_lbl)
		
		var hook_lbl := Label.new()
		hook_lbl.text = "HOOK: %d" % card.hook
		hook_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(hook_lbl)
		
		var line_lbl := Label.new()
		line_lbl.text = "LINE: %d" % card.line
		line_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(line_lbl)
		
		var sinker_lbl := Label.new()
		sinker_lbl.text = "SINKER: %d" % card.sinker
		sinker_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(sinker_lbl)
		
		if card.ability != "None":
			var ability_lbl := Label.new()
			ability_lbl.text = "[%s]" % card.ability
			ability_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vbox.add_child(ability_lbl)
		
		var choose_btn := Button.new()
		choose_btn.text = "Take"
		choose_btn.pressed.connect(_on_card_chosen.bind(card))
		vbox.add_child(choose_btn)
		
		panels.append(panel)
	
	# Animate cards appearing
	AnimHelper.stagger_pop_in(panels, 0.1)


func _on_card_chosen(card: CardData) -> void:
	selected_card = card
	visible = false
	rewards_completed.emit({
		"gold": gold_earned,
		"card": selected_card
	})


func _on_skip() -> void:
	visible = false
	rewards_completed.emit({
		"gold": gold_earned,
		"card": null
	})
