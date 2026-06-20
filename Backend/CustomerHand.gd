extends Area2D

signal swatted(hand: Area2D)
signal finished(hand: Area2D)

const DEFAULT_TEXTURE := preload("res://assets/customer/default_customer/hand_default.png")
const DAMAGE_TEXTURE := preload("res://assets/customer/default_customer/hand_damage.png")
const HAND_SCALE := Vector2(0.7, 0.7)
const HIT_RADIUS := 48.0
const SPEED := 280.0
const DAMAGE_SHOW_TIME := 0.25

var target_position := Vector2.ZERO
var velocity := Vector2.ZERO
var hit := false
var damage_timer := 0.0

var sprite: Sprite2D
var collision_shape: CollisionShape2D

func _ready() -> void:
	input_pickable = true
	_ensure_nodes()

func configure(start_position: Vector2, end_position: Vector2) -> void:
	position = start_position
	target_position = end_position
	var direction := (target_position - position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.LEFT
	velocity = direction * SPEED

	if is_node_ready():
		_ensure_nodes()

func _process(delta: float) -> void:
	if hit:
		damage_timer -= delta
		position += Vector2.UP * SPEED * 0.7 * delta
		if damage_timer <= 0.0:
			finished.emit(self)
			queue_free()
		return

	position += velocity * delta
	if position.distance_to(target_position) <= maxf(SPEED * delta, 12.0):
		finished.emit(self)
		queue_free()

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if hit:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var swatter := _get_swatter()
		if swatter == null or not swatter.call("can_attack"):
			return

		hit = true
		damage_timer = DAMAGE_SHOW_TIME
		sprite.texture = DAMAGE_TEXTURE
		swatted.emit(self)

func _ensure_nodes() -> void:
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.texture = DEFAULT_TEXTURE
		sprite.scale = HAND_SCALE
		add_child(sprite)

	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = HIT_RADIUS
		collision_shape.shape = circle
		add_child(collision_shape)

func _get_swatter() -> Node:
	var swatters := get_tree().get_nodes_in_group("swatters")
	if swatters.is_empty():
		return null

	return swatters[0]
