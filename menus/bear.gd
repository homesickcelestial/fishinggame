extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var salmon: TextureRect = $Salmon

func _ready() -> void:
	# Make sure we start with default animation and salmon hidden
	animated_sprite.play("default")
	salmon.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Player entered - show open mouth and salmon
		animated_sprite.play("open mouth")
		salmon.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Player left - return to default and hide salmon
		animated_sprite.play("default")
		salmon.visible = false
