extends Node2D
## Water drawn in front of the boat (semi-transparent)

@export var water_color_front: Color = Color(0.1, 0.18, 0.26, 0.5)
@export var foam_color_front: Color = Color(0.45, 0.5, 0.55, 0.5)

var main: RoguelikeBackground


func _ready() -> void:
	main = get_parent() as RoguelikeBackground


func _draw() -> void:
	if not main:
		return
	
	var pixel_size := main.pixel_size
	var num_columns := main.num_columns
	var time := main.time
	var wave_speed := main.wave_speed
	
	# Front wave layer - offset and different rhythm
	for i in num_columns:
		var x := i * pixel_size
		var base_y := main.wave_heights[i]
		
		# Offset wave for front layer
		var front_offset := sin((x * 0.025) + (time * wave_speed * 1.6)) * 12.0
		front_offset += sin((x * 0.04) + (time * wave_speed * 2.2)) * 6.0
		var front_y := base_y + 8 + front_offset
		
		# Front water
		draw_rect(Rect2(x, front_y, pixel_size, 35), water_color_front)
		
		# Front foam
		if i > 0 and i < num_columns - 1 and i % 2 == 0:
			var prev := main.wave_heights[i - 1]
			var curr := main.wave_heights[i]
			if curr < prev:
				draw_rect(Rect2(x, front_y - pixel_size, pixel_size * 2, pixel_size * 2), foam_color_front)
