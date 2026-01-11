extends Control
## Game Over Screen - Shows stats, penalizes, returns to base

signal continue_pressed

@onready var title_label: Label = $Panel/VBoxContainer/Title
@onready var message_label: Label = $Panel/VBoxContainer/Message
@onready var stats_container: VBoxContainer = $Panel/VBoxContainer/Stats
@onready var penalty_label: Label = $Panel/VBoxContainer/Penalty
@onready var continue_button: Button = $Panel/VBoxContainer/Continue
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var run_stats: Dictionary = {}


func _ready() -> void:
	visible = false
	continue_button.pressed.connect(_on_continue)
	modulate.a = 0


func show_game_over(stats: Dictionary) -> void:
	run_stats = stats
	
	# Calculate penalties
	var gold_lost: int = stats.get("gold", 0) / 2
	var final_gold: int = stats.get("gold", 0) - gold_lost
	
	# Update display
	title_label.text = "DEFEATED"
	message_label.text = _get_death_message()
	
	# Show stats
	for child in stats_container.get_children():
		child.queue_free()
	
	_add_stat("Nodes Cleared", str(stats.get("nodes_cleared", 0)))
	_add_stat("Fish Caught", str(stats.get("fish_caught", 0)))
	_add_stat("Cards Collected", str(stats.get("cards_collected", 0)))
	_add_stat("Gold Earned", str(stats.get("gold", 0)))
	
	# Penalty
	penalty_label.text = "Lost %d gold (-50%%)" % gold_lost
	
	# Store final values
	run_stats["final_gold"] = final_gold
	
	visible = true
	_play_appear_animation()


func _add_stat(label_text: String, value: String) -> void:
	var hbox := HBoxContainer.new()
	stats_container.add_child(hbox)
	
	var label := Label.new()
	label.text = label_text + ":"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)
	
	var value_label := Label.new()
	value_label.text = value
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(value_label)


func _get_death_message() -> String:
	var messages := [
		"The depths claimed another soul...",
		"Your boat sinks beneath the waves.",
		"The fish were too fierce this time.",
		"A watery grave awaits the unprepared.",
		"The Arkhitekta's waters show no mercy.",
	]
	return messages[randi() % messages.size()]


func _play_appear_animation() -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Fade in background
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
	# Scale panel from small
	var panel := $Panel
	panel.scale = Vector2(0.5, 0.5)
	panel.pivot_offset = panel.size / 2
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.6)
	
	# Slide in stats one by one
	await tween.finished
	
	for i in stats_container.get_child_count():
		var child := stats_container.get_child(i)
		child.modulate.a = 0
		child.position.x = -50
		
		var stat_tween := create_tween()
		stat_tween.set_ease(Tween.EASE_OUT)
		stat_tween.tween_property(child, "modulate:a", 1.0, 0.3)
		stat_tween.parallel().tween_property(child, "position:x", 0.0, 0.3)
		
		await get_tree().create_timer(0.1).timeout


func _on_continue() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	visible = false
	continue_pressed.emit()


func get_final_gold() -> int:
	return run_stats.get("final_gold", 0)
