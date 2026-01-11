extends Control
## Mystery Events - Random encounters with choices

signal event_completed(result: Dictionary)

@onready var title_label: Label = $Panel/VBoxContainer/Title
@onready var description_label: Label = $Panel/VBoxContainer/Description
@onready var choices_container: VBoxContainer = $Panel/VBoxContainer/Choices
@onready var result_label: Label = $Panel/VBoxContainer/Result
@onready var continue_button: Button = $Panel/VBoxContainer/Continue

# Event definitions
const EVENTS := [
	{
		"id": "drifting_crate",
		"title": "Drifting Crate",
		"description": "You spot a wooden crate floating in the water. It looks waterlogged but intact.",
		"choices": [
			{"text": "Open it carefully", "outcome": "crate_careful"},
			{"text": "Smash it open", "outcome": "crate_smash"},
			{"text": "Leave it", "outcome": "nothing"}
		]
	},
	{
		"id": "strange_fish",
		"title": "Strange Fish",
		"description": "A bizarre fish surfaces next to your boat. It doesn't seem hostile... yet.",
		"choices": [
			{"text": "Try to catch it", "outcome": "fish_catch"},
			{"text": "Feed it some bait", "outcome": "fish_feed"},
			{"text": "Scare it away", "outcome": "nothing"}
		]
	},
	{
		"id": "old_fisherman",
		"title": "The Old Fisherman",
		"description": "A weathered fisherman in a tiny boat approaches. He offers to trade secrets.",
		"choices": [
			{"text": "Trade a card for wisdom", "outcome": "trade_card"},
			{"text": "Ask for a free tip", "outcome": "free_tip"},
			{"text": "Ignore him", "outcome": "nothing"}
		]
	},
	{
		"id": "whirlpool",
		"title": "Minor Whirlpool",
		"description": "A small whirlpool forms nearby. Something glints at its center.",
		"choices": [
			{"text": "Risk reaching in", "outcome": "whirlpool_risk"},
			{"text": "Wait for it to pass", "outcome": "whirlpool_wait"},
			{"text": "Sail away quickly", "outcome": "nothing"}
		]
	},
	{
		"id": "ghost_ship",
		"title": "Ghost Ship",
		"description": "A spectral ship passes silently. The crew stares at you with hollow eyes.",
		"choices": [
			{"text": "Wave at them", "outcome": "ghost_wave"},
			{"text": "Offer tribute (lose 1 card)", "outcome": "ghost_tribute"},
			{"text": "Hide below deck", "outcome": "nothing"}
		]
	}
]

# Outcome results
const OUTCOMES := {
	"crate_careful": {"text": "Inside you find salvage!", "salvage": 1, "damage": 0},
	"crate_smash": {"text": "The crate explodes! You find salvage but take damage.", "salvage": 2, "damage": 1},
	"fish_catch": {"text": "You catch it! It joins your deck as a strange new card.", "card": "Strange Fish", "damage": 0},
	"fish_feed": {"text": "The fish is grateful. Your boat feels lighter.", "heal": 1, "damage": 0},
	"trade_card": {"text": "He takes your card but teaches you a powerful technique.", "upgrade_random": true, "lose_card": true},
	"free_tip": {"text": "He tells you about the waters ahead.", "reveal_map": true, "damage": 0},
	"whirlpool_risk": {"text": "You grab something shiny! But the current damages your boat.", "salvage": 2, "damage": 1},
	"whirlpool_wait": {"text": "The whirlpool subsides, leaving behind some debris.", "salvage": 1, "damage": 0},
	"ghost_wave": {"text": "They wave back... and throw you a ghostly gift!", "card": "Spectral Hook", "damage": 0},
	"ghost_tribute": {"text": "They accept your offering and bless your voyage.", "heal": 2, "lose_card": true},
	"nothing": {"text": "You continue on your way.", "damage": 0}
}

var current_event: Dictionary = {}
var pending_result: Dictionary = {}
var player_deck: Array[CardData] = []


func _ready() -> void:
	visible = false
	continue_button.pressed.connect(_on_continue)
	continue_button.visible = false


func show_event(deck: Array[CardData]) -> void:
	player_deck = deck
	current_event = EVENTS[randi() % EVENTS.size()]
	pending_result = {}
	
	title_label.text = "? " + current_event.title
	description_label.text = current_event.description
	result_label.text = ""
	continue_button.visible = false
	
	_show_choices()
	visible = true


func _show_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()
	
	var choices: Array = current_event.choices
	for i in choices.size():
		var choice: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = choice.text
		btn.pressed.connect(_on_choice_selected.bind(choice.outcome))
		choices_container.add_child(btn)


func _on_choice_selected(outcome_id: String) -> void:
	# Hide choices
	for child in choices_container.get_children():
		child.queue_free()
	
	# Get outcome
	var outcome: Dictionary = OUTCOMES.get(outcome_id, OUTCOMES.nothing)
	
	# Show result text
	result_label.text = outcome.text
	
	# Build result for game
	pending_result = {
		"salvage": outcome.get("salvage", 0),
		"damage": outcome.get("damage", 0),
		"heal": outcome.get("heal", 0),
		"lose_card": outcome.get("lose_card", false),
		"upgrade_random": outcome.get("upgrade_random", false),
		"new_card": null
	}
	
	# Handle special cards
	if outcome.has("card"):
		var card := CardData.new()
		match outcome.card:
			"Strange Fish":
				card.card_name = "Strange Fish"
				card.hook = 2
				card.line = 2
				card.sinker = 1
				card.ability = "Bleed"
			"Spectral Hook":
				card.card_name = "Spectral Hook"
				card.hook = 3
				card.line = 1
				card.sinker = 0
				card.ability = "None"
		pending_result.new_card = card
	
	continue_button.visible = true


func _on_continue() -> void:
	visible = false
	event_completed.emit(pending_result)
