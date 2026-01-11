extends CanvasLayer
## Custom cursor that follows mouse and changes based on context

@onready var body: CharacterBody2D = $CharacterBody2D
@onready var sprite: AnimatedSprite2D = $CharacterBody2D/AnimatedSprite2D

var is_clicking: bool = false


func _ready() -> void:
	# Hide the system cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# Start with default cursor
	sprite.play("default")
	
	# Ensure highest layer
	layer = 128
	
	# Make sure cursor doesn't block mouse events
	body.set_process_input(false)
	body.input_pickable = false


func _process(_delta: float) -> void:
	# Follow mouse position (use viewport coords for CanvasLayer)
	body.position = get_viewport().get_mouse_position()
	
	# Check what we're hovering if not clicking
	if not is_clicking:
		_update_cursor_state()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_clicking = true
			sprite.play("click")
		else:
			is_clicking = false
			_update_cursor_state()


func _update_cursor_state() -> void:
	var viewport := get_viewport()
	var hovered := viewport.gui_get_hovered_control()
	
	if hovered:
		var ctrl_class := hovered.get_class()
		if ctrl_class == "LineEdit" or ctrl_class == "TextEdit":
			sprite.play("text")
			return
		elif hovered is BaseButton:
			sprite.play("pointer")
			return
	
	sprite.play("default")


func _exit_tree() -> void:
	# Restore system cursor when this is removed
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
