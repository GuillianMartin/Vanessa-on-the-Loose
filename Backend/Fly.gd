extends Area2D

@onready var sfx_swat: AudioStreamPlayer2D = get_parent().get_parent().get_node_or_null("sfx_swat") as AudioStreamPlayer2D

signal died(fly: Area2D)
signal spawn_requested(position: Vector2)

const FLYING_FLY_TEXTURE := preload("res://assets/Flies/fly_flying.png")
const EATING_FLY_TEXTURE := preload("res://assets/Flies/fly_eating.png")
const FLYING_FRAME_COUNT := 6
const EATING_FRAME_COUNT := 4
const FLYING_FRAME_TIME := 0.055
const EATING_FRAME_TIME := 0.08
const TARGET_REFRESH_TIME := 0.7
const BASE_EAT_DISTANCE := 44.0
const BITE_DAMAGE := 6.0
const BITE_INTERVAL := 0.65
const KNOCKBACK_TIME := 0.28
const MOTHER_SPAWN_BITE_THRESHOLD := 4
const MOTHER_SPAWN_CHANCE := 0.45

class FlyBehavior:
	var name: String
	var max_health: int
	var speed: float
	var image_scale: Vector2
	var tint: Color
	var hitbox_radius: float
	var health_bar_width: float
	var health_bar_y: float
	var knockback_strength: float
	var eat_time_limit: float
	var can_spawn: bool

	func _init(
		behavior_name: String,
		behavior_health: int,
		behavior_speed: float,
		behavior_image_scale: Vector2,
		behavior_tint: Color,
		behavior_hitbox_radius: float,
		behavior_health_bar_width: float,
		behavior_health_bar_y: float,
		behavior_knockback_strength: float,
		behavior_eat_time_limit: float,
		behavior_can_spawn: bool = false
	) -> void:
		name = behavior_name
		max_health = behavior_health
		speed = behavior_speed
		image_scale = behavior_image_scale
		tint = behavior_tint
		hitbox_radius = behavior_hitbox_radius
		health_bar_width = behavior_health_bar_width
		health_bar_y = behavior_health_bar_y
		knockback_strength = behavior_knockback_strength
		eat_time_limit = behavior_eat_time_limit
		can_spawn = behavior_can_spawn

static func get_behavior_list(include_mother: bool = true) -> Array[FlyBehavior]:
	var behaviors: Array[FlyBehavior] = [
		FlyBehavior.new("Normal", 2, 120.0, Vector2(0.68, 0.60), Color.WHITE, 48.0, 72.0, -66.0, 360.0, 2.4),
		FlyBehavior.new("Fast", 2, 230.0, Vector2(0.58, 0.52), Color(1.0, 0.95, 0.55), 42.0, 66.0, -60.0, 430.0, 1.5),
		FlyBehavior.new("Tank", 5, 75.0, Vector2(0.96, 0.84), Color(1.0, 0.62, 0.62), 72.0, 92.0, -92.0, 290.0, 3.2),
	]

	if include_mother:
		behaviors.append(get_mother_behavior())

	return behaviors

static func get_mother_behavior() -> FlyBehavior:
	return FlyBehavior.new("Mother", 4, 95.0, Vector2(0.88, 0.76), Color(0.75, 1.0, 0.78), 66.0, 88.0, -86.0, 320.0, 3.0, true)

var behavior: FlyBehavior
var health := 1
var movement_bounds := Rect2(Vector2.ZERO, Vector2(1152, 648))
var velocity := Vector2.ZERO
var target_food: Node2D
var target_refresh_timer := 0.0
var bite_timer := 0.0
var knockback_timer := 0.0
var clicks_until_scare := 1
var click_streak := 0
var bites_since_spawn := 0
var sprite_frame_timer := 0.0
var eating_time := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var health_bar: ProgressBar

func _ready() -> void:
	input_pickable = true
	add_to_group("flies") # added line for disgust meter
	
	monitoring = true
	monitorable = true
	
	if behavior == null:
		configure(get_random_behavior(), movement_bounds)
	else:
		_apply_behavior()

func get_random_behavior(include_mother: bool = true) -> FlyBehavior:
	return get_behavior_list(include_mother).pick_random()

func get_forced_mother_behavior() -> FlyBehavior:
	return get_mother_behavior()

func configure(new_behavior: FlyBehavior, bounds: Rect2) -> void:
	behavior = new_behavior
	movement_bounds = bounds
	health = behavior.max_health
	clicks_until_scare = randi_range(1, 3)
	click_streak = 0
	bites_since_spawn = 0
	eating_time = 0.0
	velocity = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * behavior.speed

	if is_node_ready():
		_apply_behavior()

func _apply_behavior() -> void:
	_set_flying_sprite()
	sprite.scale = behavior.image_scale
	sprite.modulate = behavior.tint
	_update_sprite_direction()

	var shape := collision_shape.shape as CircleShape2D
	if shape != null:
		shape.radius = behavior.hitbox_radius

	_setup_health_bar()
	health_bar.size = Vector2(behavior.health_bar_width, 8)
	health_bar.position = Vector2(-health_bar.size.x * 0.5, behavior.health_bar_y)
	_update_health_bar()

func _setup_health_bar() -> void:
	if health_bar != null:
		return

	health_bar = ProgressBar.new()
	health_bar.show_percentage = false
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(health_bar)

func _process(delta: float) -> void:
	if sprite.texture == FLYING_FLY_TEXTURE:
		_animate_sprite(delta, FLYING_FRAME_COUNT, FLYING_FRAME_TIME)
	elif sprite.texture == EATING_FLY_TEXTURE:
		_animate_sprite(delta, EATING_FRAME_COUNT, EATING_FRAME_TIME)

	if knockback_timer > 0.0:
		knockback_timer -= delta
		position += velocity * delta
		_update_sprite_direction()
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

func _animate_flying(delta: float) -> void:
	_animate_sprite(delta, FLYING_FRAME_COUNT, FLYING_FRAME_TIME)

func _animate_sprite(delta: float, frame_count: int, frame_time: float) -> void:
	sprite_frame_timer += delta
	if sprite_frame_timer < frame_time:
		return

	sprite_frame_timer = 0.0
	sprite.frame = (sprite.frame + 1) % frame_count

func _wander(delta: float) -> void:
	position += velocity * delta
	_update_sprite_direction()

func _move_to_food(delta: float) -> void:
	var to_food := target_food.global_position - global_position
	var distance := to_food.length()
	var eat_distance := _get_eat_distance()
	if distance > eat_distance:
		velocity = velocity.lerp(to_food.normalized() * behavior.speed, 5.0 * delta)
		position += velocity * delta
		eating_time = 0.0
		_update_sprite_direction()
		_set_flying_sprite()
		return

	velocity = velocity.lerp(Vector2.ZERO, 8.0 * delta)
	_set_eating_sprite()
	eating_time += delta
	bite_timer -= delta
	if bite_timer <= 0.0:
		bite_timer = BITE_INTERVAL
		var healing: int = target_food.call("eat", BITE_DAMAGE)
		if healing > 0:
			health = mini(health + healing, behavior.max_health)
			_update_health_bar()
			_try_spawn_from_food()

	if eating_time >= behavior.eat_time_limit:
		_leave_food()

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
		_set_flying_sprite()

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var swatter := _get_swatter()
		if swatter != null and not swatter.call("can_attack"):
			return

		take_damage(1)

func take_damage(amount: int) -> void:
	health -= amount
	click_streak += 1
	if sfx_swat != null:
		sfx_swat.play()
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
	eating_time = 0.0
	_set_flying_sprite()

	var direction := Vector2.RIGHT.rotated(randf_range(0.0, TAU))
	if _is_food_valid(target_food):
		direction = (global_position - target_food.global_position).normalized()
		if direction == Vector2.ZERO:
			direction = Vector2.RIGHT.rotated(randf_range(0.0, TAU))

	velocity = direction * behavior.knockback_strength
	_update_sprite_direction()

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

func _set_flying_sprite() -> void:
	if sprite.texture == FLYING_FLY_TEXTURE:
		return

	sprite.texture = FLYING_FLY_TEXTURE
	sprite.hframes = FLYING_FRAME_COUNT
	sprite.vframes = 1
	sprite.frame = 0
	sprite_frame_timer = 0.0

func _set_eating_sprite() -> void:
	if sprite.texture == EATING_FLY_TEXTURE:
		return

	sprite.texture = EATING_FLY_TEXTURE
	sprite.hframes = EATING_FRAME_COUNT
	sprite.vframes = 1
	sprite.frame = 0
	sprite_frame_timer = 0.0

func _update_sprite_direction() -> void:
	if absf(velocity.x) < 1.0:
		return

	sprite.flip_h = velocity.x > 0.0

func _leave_food() -> void:
	eating_time = 0.0
	target_food = null
	target_refresh_timer = TARGET_REFRESH_TIME
	velocity = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * behavior.speed
	_update_sprite_direction()
	_set_flying_sprite()

func _get_swatter() -> Node:
	var swatters := get_tree().get_nodes_in_group("swatters")
	if swatters.is_empty():
		return null

	return swatters[0]
