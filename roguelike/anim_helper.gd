extends Node
class_name AnimHelper
## Animation Helper - Beautiful, expressive, fluid animations
## Use as static methods or add as autoload

# --- EASING PRESETS ---

const EASE_BOUNCE := {"ease": Tween.EASE_OUT, "trans": Tween.TRANS_BOUNCE}
const EASE_ELASTIC := {"ease": Tween.EASE_OUT, "trans": Tween.TRANS_ELASTIC}
const EASE_BACK := {"ease": Tween.EASE_OUT, "trans": Tween.TRANS_BACK}
const EASE_SMOOTH := {"ease": Tween.EASE_IN_OUT, "trans": Tween.TRANS_CUBIC}
const EASE_SNAP := {"ease": Tween.EASE_OUT, "trans": Tween.TRANS_EXPO}


# --- APPEAR / DISAPPEAR ---

## Pop in with scale bounce
static func pop_in(node: CanvasItem, duration: float = 0.4, delay: float = 0.0) -> Tween:
	node.scale = Vector2.ZERO
	node.modulate.a = 0
	
	if node is Control:
		var ctrl := node as Control
		ctrl.pivot_offset = ctrl.size / 2
	
	var tween := node.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "scale", Vector2.ONE, duration).set_delay(delay)
	tween.parallel().tween_property(node, "modulate:a", 1.0, duration * 0.5).set_delay(delay)
	
	return tween


## Pop out with scale
static func pop_out(node: CanvasItem, duration: float = 0.3) -> Tween:
	var tween := node.create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "scale", Vector2.ZERO, duration)
	tween.parallel().tween_property(node, "modulate:a", 0.0, duration * 0.7)
	
	return tween


## Fade in smoothly
static func fade_in(node: CanvasItem, duration: float = 0.3, delay: float = 0.0) -> Tween:
	node.modulate.a = 0
	
	var tween := node.create_tween()
	tween.tween_property(node, "modulate:a", 1.0, duration).set_delay(delay)
	
	return tween


## Fade out smoothly
static func fade_out(node: CanvasItem, duration: float = 0.3) -> Tween:
	var tween := node.create_tween()
	tween.tween_property(node, "modulate:a", 0.0, duration)
	
	return tween


## Slide in from direction
static func slide_in(node: CanvasItem, from: Vector2, duration: float = 0.4, delay: float = 0.0) -> Tween:
	var target_pos: Vector2 = node.position
	node.position = target_pos + from
	node.modulate.a = 0
	
	var tween := node.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(node, "position", target_pos, duration).set_delay(delay)
	tween.parallel().tween_property(node, "modulate:a", 1.0, duration * 0.5).set_delay(delay)
	
	return tween


## Slide out to direction
static func slide_out(node: CanvasItem, to: Vector2, duration: float = 0.3) -> Tween:
	var target_pos: Vector2 = node.position + to
	
	var tween := node.create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(node, "position", target_pos, duration)
	tween.parallel().tween_property(node, "modulate:a", 0.0, duration * 0.7)
	
	return tween


# --- EMPHASIS ---

## Attention-grabbing pulse
static func pulse(node: CanvasItem, scale: float = 1.2, duration: float = 0.3) -> Tween:
	if node is Control:
		var ctrl := node as Control
		ctrl.pivot_offset = ctrl.size / 2
	
	var tween := node.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(node, "scale", Vector2.ONE * scale, duration * 0.3)
	tween.tween_property(node, "scale", Vector2.ONE, duration * 0.7)
	
	return tween


## Shake for impact or error
static func shake(node: CanvasItem, intensity: float = 10.0, duration: float = 0.4) -> Tween:
	var original: Vector2 = node.position
	var tween := node.create_tween()
	
	var steps := int(duration / 0.05)
	for i in steps:
		var progress := float(i) / steps
		var current_intensity := intensity * (1.0 - progress)
		var offset := Vector2(
			randf_range(-current_intensity, current_intensity),
			randf_range(-current_intensity, current_intensity)
		)
		tween.tween_property(node, "position", original + offset, 0.05)
	
	tween.tween_property(node, "position", original, 0.05)
	
	return tween


## Bounce up and down
static func bounce(node: CanvasItem, height: float = 20.0, duration: float = 0.5) -> Tween:
	var original: Vector2 = node.position
	
	var tween := node.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(node, "position:y", original.y - height, duration * 0.4)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(node, "position:y", original.y, duration * 0.4)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(node, "position:y", original.y, duration * 0.2)
	
	return tween


## Wobble rotation
static func wobble(node: CanvasItem, angle: float = 10.0, duration: float = 0.5) -> Tween:
	var tween := node.create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	tween.tween_property(node, "rotation_degrees", angle, duration * 0.25)
	tween.tween_property(node, "rotation_degrees", -angle, duration * 0.25)
	tween.tween_property(node, "rotation_degrees", angle * 0.5, duration * 0.25)
	tween.tween_property(node, "rotation_degrees", 0.0, duration * 0.25)
	
	return tween


# --- COLOR EFFECTS ---

## Flash a color
static func flash_color(node: CanvasItem, color: Color, duration: float = 0.2) -> Tween:
	var original: Color = node.modulate
	
	var tween := node.create_tween()
	tween.tween_property(node, "modulate", color, duration * 0.3)
	tween.tween_property(node, "modulate", original, duration * 0.7)
	
	return tween


## Damage flash (red)
static func damage_flash(node: CanvasItem, duration: float = 0.3) -> Tween:
	return flash_color(node, Color(1.5, 0.5, 0.5), duration)


## Heal flash (green)
static func heal_flash(node: CanvasItem, duration: float = 0.3) -> Tween:
	return flash_color(node, Color(0.5, 1.5, 0.5), duration)


## Highlight flash (yellow)
static func highlight_flash(node: CanvasItem, duration: float = 0.3) -> Tween:
	return flash_color(node, Color(1.5, 1.5, 0.5), duration)


# --- COMBAT ANIMATIONS ---

## Attack lunge forward
static func attack_lunge(node: CanvasItem, direction: Vector2 = Vector2.UP, distance: float = 30.0, duration: float = 0.3) -> Tween:
	var original: Vector2 = node.position
	var target: Vector2 = original + direction.normalized() * distance
	
	var tween := node.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.tween_property(node, "position", target, duration * 0.3)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(node, "position", original, duration * 0.7)
	
	return tween


## Take damage - shake and flash
static func take_damage(node: CanvasItem) -> void:
	damage_flash(node)
	shake(node, 8.0, 0.3)


## Die - shrink and fade
static func die(node: CanvasItem, duration: float = 0.5) -> Tween:
	if node is Control:
		var ctrl := node as Control
		ctrl.pivot_offset = ctrl.size / 2
	
	var tween := node.create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "scale", Vector2.ZERO, duration)
	tween.parallel().tween_property(node, "modulate:a", 0.0, duration)
	tween.parallel().tween_property(node, "rotation_degrees", randf_range(-30, 30), duration)
	
	return tween


# --- CARD ANIMATIONS ---

## Draw card from deck
static func draw_card(node: CanvasItem, from: Vector2, to: Vector2, duration: float = 0.4, delay: float = 0.0) -> Tween:
	node.position = from
	node.scale = Vector2(0.3, 0.3)
	node.modulate.a = 0
	node.rotation_degrees = randf_range(-20, 20)
	
	if node is Control:
		var ctrl := node as Control
		ctrl.pivot_offset = ctrl.size / 2
	
	var tween := node.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "position", to, duration).set_delay(delay)
	tween.parallel().tween_property(node, "scale", Vector2.ONE, duration).set_delay(delay)
	tween.parallel().tween_property(node, "modulate:a", 1.0, duration * 0.5).set_delay(delay)
	tween.parallel().tween_property(node, "rotation_degrees", 0.0, duration).set_delay(delay)
	
	return tween


## Play card to board
static func play_card(node: CanvasItem, to: Vector2, duration: float = 0.3) -> Tween:
	if node is Control:
		var ctrl := node as Control
		ctrl.pivot_offset = ctrl.size / 2
	
	var tween := node.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "position", to, duration)
	tween.parallel().tween_property(node, "scale", Vector2(1.1, 1.1), duration * 0.5)
	tween.tween_property(node, "scale", Vector2.ONE, duration * 0.5)
	
	return tween


# --- NUMBER ANIMATIONS ---

## Floating damage number
static func floating_number(parent: Node, position: Vector2, value: String, color: Color = Color.WHITE, duration: float = 1.0) -> void:
	var label := Label.new()
	label.text = value
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 24)
	label.position = position
	label.z_index = 100
	parent.add_child(label)
	
	var tween := label.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", position.y - 50, duration)
	tween.parallel().tween_property(label, "modulate:a", 0.0, duration)
	
	tween.finished.connect(func(): label.queue_free())


# --- STAGGERED ANIMATIONS ---

## Animate array of nodes with stagger
static func stagger_pop_in(nodes: Array, delay_per: float = 0.05) -> void:
	for i in nodes.size():
		var node: CanvasItem = nodes[i]
		pop_in(node, 0.4, i * delay_per)


## Animate array with slide
static func stagger_slide_in(nodes: Array, from: Vector2, delay_per: float = 0.05) -> void:
	for i in nodes.size():
		var node: CanvasItem = nodes[i]
		slide_in(node, from, 0.4, i * delay_per)
