extends Area2D

signal died(fly: Area2D)
signal spawn_requested(position: Vector2)

const DEFAULT_FLY_TEXTURE := preload("res://assets/Flies/default_fly.png")
const EATING_FLY_TEXTURE := preload("res://assets/Flies/eating_fly.png")
const TARGET_REFRESH_TIME := 0.7
const HITBOX_BASE_SCALE := Vector2(0.10, 0.0875)
const BASE_EAT_DISTANCE := 44.0
const BITE_DAMAGE := 10.0
const BITE_INTERVAL := 0.65
const KNOCKBACK_TIME := 0.28
const MOTHER_SPAWN_BITE_THRESHOLD := 4
const MOTHER_SPAWN_CHANCE := 0.45
const SIZE_MULTIPLIER := 4.2

class FlyBehavior:
	var name: String
	var max_health: int
	var speed: float
	var visual_scale: Vector2
	var tint: Color
	var knockback_strength: float
	var can_spawn: bool

	func _init(
		behavior_name: String,
		behavior_health: int,
		behavior_speed: float,
		behavior_scale: Vector2,
		behavior_tint: Color,
		behavior_knockback_strength: float,
		behavior_can_spawn: bool = false
	) -> void:
		name = behavior_name
		max_health = behavior_health
		speed = behavior_speed
		visual_scale = behavior_scale
		tint = behavior_tint
		knockback_strength = behavior_knockback_strength
		can_spawn = behavior_can_spawn

var behavior: FlyBehavior
var health: int = 1
var movement_bounds := Rect2(Vector2.ZERO, Vector2(1152, 648))
var velocity := Vector2.ZERO
var target_food: Node2D
var target_refresh_timer := 0.0
var bite_timer := 0.0
var knockback_timer := 0.0
var clicks_until_scare := 1
var click_streak := 0
var bites_since_spawn := 0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var health_bar: ProgressBar

func _ready() -> void:
	input_pickable = true
	if behavior == null:
		configure(get_random_behavior(), movement_bounds)
	else:
		_apply_behavior()

func get_random_behavior(include_mother: bool = true) -> FlyBehavior:
	var behaviors: Array[FlyBehavior] = [
		FlyBehavior.new("Normal", 2, 120.0, Vector2(0.10, 0.0875), Color.WHITE, 360.0),
		FlyBehavior.new("Fast", 2, 230.0, Vector2(0.0875, 0.075), Color(1.0, 0.95, 0.55), 430.0),
		FlyBehavior.new("Tank", 5, 75.0, Vector2(0.15, 0.13125), Color(1.0, 0.62, 0.62), 290.0),
	]

	if include_mother:
		behaviors.append(get_mother_behavior())

	return behaviors.pick_random()

func get_mother_behavior() -> FlyBehavior:
	return FlyBehavior.new("Mother", 4, 95.0, Vector2(0.1375, 0.11875), Color(0.75, 1.0, 0.78), 320.0, true)

func configure(new_behavior: FlyBehavior, bounds: Rect2) -> void:
	behavior = new_behavior
	movement_bounds = bounds
	health = behavior.max_health
	clicks_until_scare = randi_range(1, 3)
	click_streak = 0
	bites_since_spawn = 0
	velocity = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * behavior.speed

	if is_node_ready():
		_apply_behavior()

func _apply_behavior() -> void:
	sprite.texture = DEFAULT_FLY_TEXTURE
	sprite.scale = behavior.visual_scale * SIZE_MULTIPLIER
	sprite.modulate = behavior.tint

	var shape := collision_shape.shape as CircleShape2D
	if shape != null:
		shape.radius = 48.0 * max(behavior.visual_scale.x / HITBOX_BASE_SCALE.x, behavior.visual_scale.y / HITBOX_BASE_SCALE.y)

	_setup_health_bar()
	if shape != null:
		health_bar.size = Vector2(maxf(shape.radius * 1.5, 72.0), 8)
		health_bar.position = Vector2(-health_bar.size.x * 0.5, -shape.radius - 18.0)
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
	if knockback_timer > 0.0:
		knockback_timer -= delta
		position += velocity * delta
		_keep_inside_bounds()
		if knockback_timer <= 0.0:
			target_food = null
			target_refresh_timer = 0.0
		return

	target_refresh_timer -= delta
	if not _is_food_valid(target_food) or target_refresh_timer <= 0.0:
		target_food = _pick_food_target()
		target_refresh_timer = TARGET_REFRESH_TIME

	if _is_food_valid(target_food):
		_move_to_food(delta)
	else:
		_wander(delta)

	_keep_inside_bounds()

func _wander(delta: float) -> void:
	position += velocity * delta

func _move_to_food(delta: float) -> void:
	var to_food := target_food.global_position - global_position
	var distance := to_food.length()
	var eat_distance := _get_eat_distance()
	if distance > eat_distance:
		velocity = velocity.lerp(to_food.normalized() * behavior.speed, 5.0 * delta)
		position += velocity * delta
		sprite.texture = DEFAULT_FLY_TEXTURE
		return

	velocity = velocity.lerp(Vector2.ZERO, 8.0 * delta)
	sprite.texture = EATING_FLY_TEXTURE
	bite_timer -= delta
	if bite_timer <= 0.0:
		bite_timer = BITE_INTERVAL
		var healing: int = target_food.call("eat", BITE_DAMAGE)
		if healing > 0:
			health = mini(health + healing, behavior.max_health)
			_update_health_bar()
			_try_spawn_from_food()

func _keep_inside_bounds() -> void:
	var margin: float = minf(_get_collision_radius() * 0.45, 130.0)
	var min_x := movement_bounds.position.x + margin
	var max_x: float = maxf(movement_bounds.end.x - margin, min_x)
	var min_y := movement_bounds.position.y + margin
	var max_y: float = maxf(movement_bounds.end.y - margin, min_y)

	if position.x < min_x or position.x > max_x:
		velocity.x *= -1.0
		position.x = clampf(position.x, min_x, max_x)
	if position.y < min_y or position.y > max_y:
		velocity.y *= -1.0
		position.y = clampf(position.y, min_y, max_y)
	if knockback_timer <= 0.0 and target_food == null:
		sprite.texture = DEFAULT_FLY_TEXTURE

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		take_damage(1)

func take_damage(amount: int) -> void:
	health -= amount
	click_streak += 1
	_update_health_bar()

	if health <= 0:
		died.emit(self)
		queue_free()
		return

	if click_streak >= clicks_until_scare:
		_start_knockback()

func _update_health_bar() -> void:
	if health_bar == null:
		return

	health_bar.max_value = behavior.max_health
	health_bar.value = max(health, 0)
	health_bar.visible = true

func _pick_food_target() -> Node2D:
	var foods := get_tree().get_nodes_in_group("foods")
	var valid_foods: Array[Node2D] = []
	for food in foods:
		if _is_food_valid(food) and food is Node2D:
			valid_foods.append(food as Node2D)

	if valid_foods.is_empty():
		return null

	valid_foods.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
	)

	var choice_count: int = mini(valid_foods.size(), 3)
	return valid_foods[randi_range(0, choice_count - 1)]

func _is_food_valid(food: Variant) -> bool:
	if food == null or not is_instance_valid(food) or not (food is Node2D):
		return false

	return (food as Node2D).is_inside_tree()

func _start_knockback() -> void:
	click_streak = 0
	clicks_until_scare = randi_range(1, 3)
	knockback_timer = KNOCKBACK_TIME
	sprite.texture = DEFAULT_FLY_TEXTURE

	var direction := Vector2.RIGHT.rotated(randf_range(0.0, TAU))
	if _is_food_valid(target_food):
		direction = (global_position - target_food.global_position).normalized()
		if direction == Vector2.ZERO:
			direction = Vector2.RIGHT.rotated(randf_range(0.0, TAU))

	velocity = direction * behavior.knockback_strength

func _get_eat_distance() -> float:
	return maxf(BASE_EAT_DISTANCE, _get_collision_radius() * 0.55)

func _get_collision_radius() -> float:
	var shape := collision_shape.shape as CircleShape2D
	if shape == null:
		return 0.0

	return shape.radius

func _try_spawn_from_food() -> void:
	if not behavior.can_spawn:
		return

	bites_since_spawn += 1
	if bites_since_spawn < MOTHER_SPAWN_BITE_THRESHOLD:
		return

	bites_since_spawn = 0
	if randf() <= MOTHER_SPAWN_CHANCE:
		spawn_requested.emit(global_position)
