extends Control
class_name MapUI

signal node_clicked(node: MapNodeData)

@onready var map_manager: MapManager = $MapManager
@onready var map_container: Control = $MapContainer
@onready var lines_container: Control = $MapContainer/Lines
@onready var nodes_container: Control = $MapContainer/Nodes
@onready var area_label: Label = $AreaLabel

const NODE_SIZE := Vector2(60, 60)
const ROW_SPACING: float = 100.0
const COL_SPACING: float = 150.0
const MAP_OFFSET := Vector2(960, 600)  # Center of screen, bottom

# Node colors
const COLOR_AVAILABLE := Color(0.3, 0.7, 0.3, 1.0)
const COLOR_COMPLETED := Color(0.4, 0.4, 0.4, 1.0)
const COLOR_LOCKED := Color(0.2, 0.2, 0.25, 1.0)
const COLOR_CURRENT := Color(0.8, 0.7, 0.2, 1.0)

const TYPE_COLORS := {
	MapNodeData.NodeType.COMBAT: Color(0.7, 0.3, 0.3),
	MapNodeData.NodeType.ELITE: Color(0.8, 0.2, 0.4),
	MapNodeData.NodeType.SALVAGE: Color(0.4, 0.5, 0.7),
	MapNodeData.NodeType.REST: Color(0.3, 0.6, 0.4),
	MapNodeData.NodeType.MYSTERY: Color(0.6, 0.4, 0.7),
	MapNodeData.NodeType.MERCHANT: Color(0.7, 0.6, 0.3),
	MapNodeData.NodeType.BOSS: Color(0.9, 0.3, 0.3),
}

var node_buttons: Dictionary = {}  # node_id -> Button


func _ready() -> void:
	map_manager.player_moved.connect(_on_player_moved)
	map_manager.map_completed.connect(_on_map_completed)
	
	# Generate and display map
	generate_new_map()


## Generate a fresh map (called at start and after game over)
func generate_new_map() -> void:
	map_manager.generate_new_map()
	_build_map_display()


func _build_map_display() -> void:
	# Clear existing
	for child in lines_container.get_children():
		child.queue_free()
	for child in nodes_container.get_children():
		child.queue_free()
	node_buttons.clear()
	
	# Calculate positions for each node
	var positions: Dictionary = {}  # node_id -> Vector2
	var num_rows := map_manager.get_num_rows()
	
	for row in num_rows:
		var row_nodes := map_manager.get_nodes_in_row(row)
		var num_cols := row_nodes.size()
		
		for i in row_nodes.size():
			var node := row_nodes[i]
			# Center the row horizontally
			var x_offset: float = (i - (num_cols - 1) / 2.0) * COL_SPACING
			var y_offset: float = -row * ROW_SPACING  # Negative because Y increases downward
			
			positions[node.node_id] = MAP_OFFSET + Vector2(x_offset, y_offset)
	
	# Draw connection lines first (behind nodes)
	for node in map_manager.nodes:
		var start_pos: Vector2 = positions[node.node_id]
		for conn_id in node.connections:
			var end_pos: Vector2 = positions[conn_id]
			_draw_connection_line(start_pos, end_pos, node, map_manager.get_map_node(conn_id))
	
	# Create node buttons
	for node in map_manager.nodes:
		var pos: Vector2 = positions[node.node_id]
		_create_node_button(node, pos)
	
	_update_node_states()


func _draw_connection_line(start: Vector2, end: Vector2, from_node: MapNodeData, to_node: MapNodeData) -> void:
	var line := Line2D.new()
	line.add_point(start)
	line.add_point(end)
	line.width = 3.0
	
	# Color based on availability
	if from_node.completed and to_node.available:
		line.default_color = COLOR_AVAILABLE
	elif from_node.completed:
		line.default_color = COLOR_COMPLETED
	else:
		line.default_color = COLOR_LOCKED
	
	line.default_color.a = 0.5
	lines_container.add_child(line)


func _create_node_button(node: MapNodeData, pos: Vector2) -> void:
	var button := Button.new()
	button.custom_minimum_size = NODE_SIZE
	button.position = pos - NODE_SIZE / 2
	
	# Set text to icon
	button.text = node.get_type_icon()
	button.add_theme_font_size_override("font_size", 24)
	
	# Connect click
	button.pressed.connect(_on_node_button_pressed.bind(node.node_id))
	
	# Tooltip
	button.tooltip_text = node.get_type_name()
	
	nodes_container.add_child(button)
	node_buttons[node.node_id] = button


func _update_node_states() -> void:
	for node_id in node_buttons:
		var button: Button = node_buttons[node_id]
		var node := map_manager.get_map_node(node_id)
		
		var base_color: Color = TYPE_COLORS.get(node.type, Color.WHITE)
		
		if node_id == map_manager.current_node_id:
			# Current node
			button.modulate = COLOR_CURRENT
			button.disabled = true
		elif node.completed:
			# Completed
			button.modulate = COLOR_COMPLETED
			button.disabled = true
		elif node.available:
			# Available to travel
			button.modulate = base_color
			button.disabled = false
		else:
			# Locked
			button.modulate = COLOR_LOCKED
			button.disabled = true
	
	# Update lines
	_rebuild_lines()


func _rebuild_lines() -> void:
	# Clear and redraw lines with updated colors
	for child in lines_container.get_children():
		child.queue_free()
	
	var positions: Dictionary = {}
	for node_id in node_buttons:
		var button: Button = node_buttons[node_id]
		positions[node_id] = button.position + NODE_SIZE / 2
	
	for node in map_manager.nodes:
		if not positions.has(node.node_id):
			continue
		var start_pos: Vector2 = positions[node.node_id]
		for conn_id in node.connections:
			if not positions.has(conn_id):
				continue
			var end_pos: Vector2 = positions[conn_id]
			_draw_connection_line(start_pos, end_pos, node, map_manager.get_map_node(conn_id))


func _on_node_button_pressed(node_id: int) -> void:
	if map_manager.can_travel_to(node_id):
		map_manager.travel_to(node_id)


func _on_player_moved(node: MapNodeData) -> void:
	_update_node_states()
	node_clicked.emit(node)


func _on_map_completed() -> void:
	area_label.text = "AREA COMPLETE!"


## Called externally when node encounter is finished
func on_node_completed() -> void:
	map_manager.complete_current_node()
	_update_node_states()


## Get current node for external systems
func get_current_node() -> MapNodeData:
	return map_manager.get_current_node()
