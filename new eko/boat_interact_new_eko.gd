extends Area2D
## Attach to any Area2D to make it an interact zone

@export var target_scene: String = "res://scenes/roguelike/roguelike_game.tscn"

var player_in_range: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("ui_accept"):
		get_tree().change_scene_to_file(target_scene)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_in_range = true


func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_in_range = false
