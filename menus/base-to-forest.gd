extends Area2D

@export_file("*.tscn") var target_scene_path: String = ""  ## Path to scene (e.g. "res://scenes/menus/forest.tscn")
@export var target_spawn_name: String = ""  ## Name of the Marker2D in the NEW scene to spawn at

func _ready():
	body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	if not body.is_in_group("player"):
		return
	
	# Use call_deferred to avoid physics query flush errors
	call_deferred("_do_scene_transition")


func _do_scene_transition():
	if target_scene_path.is_empty():
		push_error("target_scene_path is not set!")
		return
	
	# Store spawn point name so the new scene can use it
	if target_spawn_name != "":
		get_tree().set_meta("spawn_point", target_spawn_name)
	
	get_tree().change_scene_to_file(target_scene_path)
