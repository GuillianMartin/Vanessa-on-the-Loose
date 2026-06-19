extends Area2D

signal died(fly: Area2D)

class FlyBehavior:
	var name: String
	var max_health: int
	var speed: float
	var visual_scale: Vector2
	var tint: Color

	func _init(
		behavior_name: String,
		behavior_health: int,
		behavior_speed: float,
		behavior_scale: Vector2,
		behavior_tint: Color
	) -> void:
		name = behavior_name
		max_health = behavior_health
		speed = behavior_speed
		visual_scale = behavior_scale
		tint = behavior_tint

var behavior: FlyBehavior
var health: int = 1
var movement_bounds := Rect2(Vector2.ZERO, Vector2(1152, 648))
var velocity := Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var health_bar: ProgressBar

func _ready() -> void:
	input_pickable = true
	if behavior == null:
		configure(get_random_behavior(), movement_bounds)
	else:
		_apply_behavior()

func get_random_behavior() -> FlyBehavior:
	var behaviors: Array[FlyBehavior] = [
		FlyBehavior.new("Normal", 1, 120.0, Vector2(0.08, 0.07), Color.WHITE),
		FlyBehavior.new("Fast", 1, 230.0, Vector2(0.07, 0.06), Color(1.0, 0.95, 0.55)),
		FlyBehavior.new("Tank", 4, 75.0, Vector2(0.12, 0.105), Color(1.0, 0.62, 0.62)),
	]
	return behaviors.pick_random()

func configure(new_behavior: FlyBehavior, bounds: Rect2) -> void:
	behavior = new_behavior
	movement_bounds = bounds
	health = behavior.max_health
	velocity = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * behavior.speed

	if is_node_ready():
		_apply_behavior()

func _apply_behavior() -> void:
	sprite.scale = behavior.visual_scale
	sprite.modulate = behavior.tint

	var shape := collision_shape.shape as CircleShape2D
	if shape != null:
		shape.radius = 48.0 * max(behavior.visual_scale.x / 0.08, behavior.visual_scale.y / 0.07)

	_setup_health_bar()
	_update_health_bar()

func _setup_health_bar() -> void:
	if health_bar != null:
		return

	health_bar = ProgressBar.new()
	health_bar.show_percentage = false
	health_bar.size = Vector2(72, 8)
	health_bar.position = Vector2(-36, -58)
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(health_bar)

func _process(delta: float) -> void:
	position += velocity * delta

	if position.x < movement_bounds.position.x or position.x > movement_bounds.end.x:
		velocity.x *= -1.0
		position.x = clampf(position.x, movement_bounds.position.x, movement_bounds.end.x)
	if position.y < movement_bounds.position.y or position.y > movement_bounds.end.y:
		velocity.y *= -1.0
		position.y = clampf(position.y, movement_bounds.position.y, movement_bounds.end.y)

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		take_damage(1)

func take_damage(amount: int) -> void:
	health -= amount
	_update_health_bar()

	if health <= 0:
		died.emit(self)
		queue_free()

func _update_health_bar() -> void:
	if health_bar == null:
		return

	health_bar.max_value = behavior.max_health
	health_bar.value = max(health, 0)
	health_bar.visible = true
