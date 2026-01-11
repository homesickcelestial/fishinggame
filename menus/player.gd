extends CharacterBody2D
## Player character controller for Depths of the Arkhitekta
## Horizontal movement only with momentum and smooth camera follow

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

## Movement settings
@export var max_speed: float = 1000.0
@export var acceleration: float = 1900.0
@export var friction: float = 1900.0

## Camera settings
@export var camera_smoothing: float = 5.0

var camera: Camera2D


func _ready() -> void:
	# Get camera from scene (not as child, so it can lag behind)
	camera = get_tree().get_first_node_in_group("main_camera")
	if camera:
		camera.make_current()


func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_update_animation()
	move_and_slide()
	_update_camera(delta)


func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_axis("ui_left", "ui_right")
	
	if input_dir != 0:
		# Accelerate toward max speed
		velocity.x = move_toward(velocity.x, input_dir * max_speed, acceleration * delta)
	else:
		# Apply friction when no input
		velocity.x = move_toward(velocity.x, 0, friction * delta)


func _update_animation() -> void:
	# Flip sprite based on direction
	if velocity.x > 10:
		sprite.flip_h = false
	elif velocity.x < -10:
		sprite.flip_h = true
	
	# Switch between idle and walk
	if abs(velocity.x) > 10:
		if sprite.animation != "walk":
			sprite.play("walk")
	else:
		if sprite.animation != "default":
			sprite.play("default")


func _update_camera(delta: float) -> void:
	if camera:
		# Smooth camera follow with lag
		camera.global_position = camera.global_position.lerp(global_position, camera_smoothing * delta)
