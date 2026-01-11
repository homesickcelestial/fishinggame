extends Control
## Tutorial System - Shows tips on first run or when requested

signal tutorial_completed
signal step_shown(step_id: String)

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/Title
@onready var content_label: Label = $Panel/VBoxContainer/Content
@onready var image_rect: TextureRect = $Panel/VBoxContainer/ImageRect
@onready var progress_label: Label = $Panel/VBoxContainer/Progress
@onready var next_button: Button = $Panel/VBoxContainer/Buttons/Next
@onready var skip_button: Button = $Panel/VBoxContainer/Buttons/Skip
@onready var highlight: ColorRect = $Highlight

const SAVE_KEY := "tutorial_completed"

# Tutorial steps
const STEPS := [
	{
		"id": "welcome",
		"title": "Welcome, Fisher!",
		"content": "Welcome to Hook, Line & Sinker!\n\nYou are a salvager exploring the flooded ruins of the Arkhitekta's crater. Catch fish, build your deck, and survive the depths.",
	},
	{
		"id": "first_salvage",
		"title": "Your First Salvage",
		"content": "You'll start at a Salvage Site where you can choose your first tool.\n\nEach tool has different strengths and can be upgraded later into two different paths. Choose wisely!",
	},
	{
		"id": "map",
		"title": "The Map",
		"content": "Navigate the map by clicking on available nodes (highlighted in green).\n\nNode types:\n⚔ Combat - Fight fish (start easy!)\n⚓ Rest - Heal your boat\n🔧 Salvage - Craft & upgrade cards\n? Mystery - Random events\n💰 Merchant - Buy & sell",
	},
	{
		"id": "combat_basics",
		"title": "Combat Basics",
		"content": "In combat, you play cards to catch fish.\n\nEach card has three stats:\n• HOOK - Damage dealt (also costs this much BAIT)\n• LINE - Card durability\n• SINKER - Ability power\n\nEarly fights have just 1 fish - perfect for learning!",
	},
	{
		"id": "combat_flow",
		"title": "Combat Flow",
		"content": "Cards can only attack fish directly in front of them.\n\n1. Click a hand card, then an empty slot to play it\n2. Click a played card to select it\n3. Click again to attack the fish in front\n4. Click adjacent empty slot to move instead\n\nRight-click a card to sacrifice it for extra BAIT.",
	},
	{
		"id": "catching",
		"title": "Catching Fish",
		"content": "When a fish's HP reaches 0, a catch minigame begins!\n\nHold SPACE to reel in (increases tension).\nRelease to let out line (decreases tension).\n\nKeep the tension in the green zone to fill the catch bar. Don't let it snap or go slack!",
	},
	{
		"id": "upgrades",
		"title": "Upgrades & Salvage",
		"content": "At Salvage sites, you can:\n• Craft new cards from salvage materials\n• Upgrade your starter tool into stronger versions\n\nEach tool has two upgrade paths - experiment to find your favorite!",
	},
	{
		"id": "tips",
		"title": "Final Tips",
		"content": "• Press ESC to pause and view your deck\n• Early fights are easy - use them to learn\n• Upgrade your starter tool when you can\n• Don't be afraid to sacrifice weak cards for bait\n\nGood luck, and may your catches be legendary!",
	}
]

var current_step: int = 0
var is_active: bool = false


func _ready() -> void:
	visible = false
	next_button.pressed.connect(_on_next)
	skip_button.pressed.connect(_on_skip)
	highlight.visible = false
	modulate.a = 0


## Check if tutorial has been completed before
func should_show_tutorial() -> bool:
	# Handle case where SaveManager might not be autoloaded yet
	if not Engine.has_singleton("SaveManager") and not has_node("/root/SaveManager"):
		# Try to check file directly
		if FileAccess.file_exists("user://roguelike_save.json"):
			var file := FileAccess.open("user://roguelike_save.json", FileAccess.READ)
			if file:
				var json := file.get_as_text()
				file.close()
				var parsed = JSON.parse_string(json)
				if parsed is Dictionary:
					return not parsed.get(SAVE_KEY, false)
		return true  # No save file = show tutorial
	
	var save_data: Dictionary = SaveManager.load_game()
	return not save_data.get(SAVE_KEY, false)


## Start the tutorial
func start_tutorial() -> void:
	current_step = 0
	is_active = true
	visible = true
	_show_current_step()
	_animate_in()


## Show a specific tip (can be called anytime)
func show_tip(step_id: String) -> void:
	for i in STEPS.size():
		if STEPS[i].id == step_id:
			current_step = i
			_show_current_step()
			visible = true
			_animate_in()
			return


func _show_current_step() -> void:
	var step: Dictionary = STEPS[current_step]
	
	title_label.text = step.title
	content_label.text = step.content
	progress_label.text = "%d / %d" % [current_step + 1, STEPS.size()]
	
	# Update button text
	if current_step >= STEPS.size() - 1:
		next_button.text = "Finish"
	else:
		next_button.text = "Next"
	
	# Animate content
	content_label.modulate.a = 0
	content_label.position.y = 20
	
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(content_label, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(content_label, "position:y", 0.0, 0.3)
	
	step_shown.emit(step.id)


func _animate_in() -> void:
	panel.scale = Vector2(0.9, 0.9)
	panel.pivot_offset = panel.size / 2
	
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.4)


func _animate_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	visible = false


func _on_next() -> void:
	current_step += 1
	
	if current_step >= STEPS.size():
		_finish_tutorial()
	else:
		_show_current_step()


func _on_skip() -> void:
	_finish_tutorial()


func _finish_tutorial() -> void:
	is_active = false
	
	# Save completion - handle missing SaveManager
	if Engine.has_singleton("SaveManager") or has_node("/root/SaveManager"):
		var save_data: Dictionary = SaveManager.load_game()
		save_data[SAVE_KEY] = true
		SaveManager.save_game(save_data)
	else:
		# Save directly to file
		var save_data := {"tutorial_completed": true}
		if FileAccess.file_exists("user://roguelike_save.json"):
			var file := FileAccess.open("user://roguelike_save.json", FileAccess.READ)
			if file:
				var json := file.get_as_text()
				file.close()
				var parsed = JSON.parse_string(json)
				if parsed is Dictionary:
					save_data = parsed
					save_data[SAVE_KEY] = true
		
		var file := FileAccess.open("user://roguelike_save.json", FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(save_data))
			file.close()
	
	await _animate_out()
	tutorial_completed.emit()


## Highlight a specific area of the screen
func highlight_area(rect: Rect2) -> void:
	highlight.visible = true
	highlight.position = rect.position
	highlight.size = rect.size
	
	# Pulse animation
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(highlight, "modulate:a", 0.3, 0.5)
	tween.tween_property(highlight, "modulate:a", 0.7, 0.5)


func hide_highlight() -> void:
	highlight.visible = false
