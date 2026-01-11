extends Control
## QTE Catch Minigame - tension bar fishing

signal catch_completed(success: bool, quality: int)  # quality: 0=failed, 1=rough, 2=good, 3=perfect

@onready var tension_bar: ProgressBar = $TensionBar
@onready var target_zone: ColorRect = $TensionBar/TargetZone
@onready var fish_name_label: Label = $FishName
@onready var instruction_label: Label = $Instructions
@onready var timer_bar: ProgressBar = $TimerBar
@onready var catch_progress_bar: ProgressBar = $CatchProgress

## Tension settings
@export var tension_min: float = 0.0
@export var tension_max: float = 100.0
@export var snap_threshold: float = 95.0  # Line snaps above this
@export var slack_threshold: float = 5.0   # Fish escapes below this
@export var target_center: float = 50.0
@export var target_width: float = 30.0  # Width of safe zone

## Fish pull settings
var fish_pull_strength: float = 20.0
var fish_pull_variance: float = 10.0
var fish_behavior: String = "Fighter"  # Fighter, Runner, Diver, Thinker

## Player settings
@export var reel_strength: float = 35.0
@export var passive_decay: float = 5.0  # Tension slowly drops

## Time limit
@export var time_limit: float = 8.0

## State
var tension: float = 50.0
var time_remaining: float = 8.0
var is_active: bool = false
var is_reeling: bool = false
var catch_progress: float = 0.0  # Build up while in target zone
var catch_threshold: float = 100.0

## Fish behavior timers
var behavior_timer: float = 0.0
var current_pull: float = 0.0
var pull_burst: float = 0.0


func _ready() -> void:
	visible = false
	set_process(false)


func start_catch(fish_name: String, difficulty: float = 1.0, behavior: String = "Fighter") -> void:
	fish_name_label.text = fish_name
	fish_behavior = behavior
	
	# Scale difficulty
	fish_pull_strength = 15.0 + (difficulty * 10.0)
	time_limit = 10.0 - (difficulty * 2.0)
	time_limit = maxf(time_limit, 5.0)
	
	# Reset state
	tension = 50.0
	time_remaining = time_limit
	catch_progress = 0.0
	is_active = true
	is_reeling = false
	behavior_timer = 0.0
	current_pull = fish_pull_strength
	pull_burst = 0.0
	
	# Setup UI
	_update_target_zone()
	visible = true
	set_process(true)
	
	instruction_label.text = "HOLD SPACE to reel in!"


func _process(delta: float) -> void:
	if not is_active:
		return
	
	# Update fish behavior
	_update_fish_behavior(delta)
	
	# Fish pulls toward slack (decreases tension)
	var fish_force: float = current_pull + pull_burst
	tension -= fish_force * delta
	
	# Player reeling (increases tension)
	is_reeling = Input.is_action_pressed("ui_accept")
	if is_reeling:
		tension += reel_strength * delta
	else:
		# Passive decay when not reeling
		tension -= passive_decay * delta
	
	# Clamp tension
	tension = clampf(tension, tension_min, tension_max)
	
	# Check fail conditions
	if tension >= snap_threshold:
		_end_catch(false, "LINE SNAPPED!")
		return
	elif tension <= slack_threshold:
		_end_catch(false, "FISH ESCAPED!")
		return
	
	# Check if in target zone
	var in_zone := _is_in_target_zone()
	if in_zone:
		catch_progress += 40.0 * delta
		instruction_label.text = "KEEP IT STEADY!"
		instruction_label.modulate = Color.GREEN
	else:
		catch_progress -= 20.0 * delta
		catch_progress = maxf(catch_progress, 0.0)
		instruction_label.text = "HOLD SPACE to reel in!" if tension < target_center else "RELEASE to let out line!"
		instruction_label.modulate = Color.WHITE
	
	# Check win condition
	if catch_progress >= catch_threshold:
		var quality := _calculate_quality()
		_end_catch(true, "CAUGHT!", quality)
		return
	
	# Update timer
	time_remaining -= delta
	if time_remaining <= 0:
		_end_catch(false, "TIME'S UP!")
		return
	
	# Update UI
	_update_ui()


func _update_fish_behavior(delta: float) -> void:
	behavior_timer -= delta
	
	match fish_behavior:
		"Fighter":
			# Constant strong pull
			current_pull = fish_pull_strength
			pull_burst = 0.0
			
		"Runner":
			# Periodic bursts of speed
			if behavior_timer <= 0:
				behavior_timer = randf_range(1.0, 2.5)
				pull_burst = fish_pull_strength * 1.5 if randf() > 0.5 else 0.0
			if pull_burst > 0:
				pull_burst -= delta * 30.0
				pull_burst = maxf(pull_burst, 0.0)
				
		"Diver":
			# Sudden strong pulls
			if behavior_timer <= 0:
				behavior_timer = randf_range(2.0, 4.0)
				if randf() > 0.6:
					pull_burst = fish_pull_strength * 2.5
			pull_burst = lerpf(pull_burst, 0.0, delta * 3.0)
			
		"Thinker":
			# Erratic, unpredictable
			if behavior_timer <= 0:
				behavior_timer = randf_range(0.3, 1.0)
				current_pull = fish_pull_strength * randf_range(0.3, 1.8)


func _is_in_target_zone() -> bool:
	var zone_min := target_center - (target_width / 2.0)
	var zone_max := target_center + (target_width / 2.0)
	return tension >= zone_min and tension <= zone_max


func _calculate_quality() -> int:
	# Based on how centered tension is and time remaining
	var center_dist := absf(tension - target_center)
	var time_bonus := time_remaining / time_limit
	
	if center_dist < 5.0 and time_bonus > 0.5:
		return 3  # Perfect
	elif center_dist < 10.0 and time_bonus > 0.25:
		return 2  # Good
	else:
		return 1  # Rough


func _end_catch(success: bool, message: String, quality: int = 0) -> void:
	is_active = false
	set_process(false)
	instruction_label.text = message
	instruction_label.modulate = Color.GREEN if success else Color.RED
	
	# Brief delay before emitting signal
	await get_tree().create_timer(1.0).timeout
	visible = false
	catch_completed.emit(success, quality)


func _update_target_zone() -> void:
	# Position the target zone on the progress bar
	var bar_width := tension_bar.size.x
	var zone_start := (target_center - target_width / 2.0) / tension_max
	var zone_width := target_width / tension_max
	
	target_zone.position.x = zone_start * bar_width
	target_zone.size.x = zone_width * bar_width


func _update_ui() -> void:
	tension_bar.value = tension
	timer_bar.value = (time_remaining / time_limit) * 100.0
	catch_progress_bar.value = catch_progress
	
	# Color tension bar based on danger
	if tension > 80.0 or tension < 20.0:
		tension_bar.modulate = Color.RED
	elif tension > 70.0 or tension < 30.0:
		tension_bar.modulate = Color.YELLOW
	else:
		tension_bar.modulate = Color.WHITE
