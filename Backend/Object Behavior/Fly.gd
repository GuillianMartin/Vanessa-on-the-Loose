extends Area2D

@onready var sfx_swat: AudioStreamPlayer2D = get_parent().get_parent().get_node_or_null("sfx_swat") as AudioStreamPlayer2D

signal died(fly: Area2D)
signal spawn_requested(position: Vector2, behavior_name: String)

const FLY_ATTRIBUTES_SCRIPT := preload("res://Backend/Object Initialization/Fly_Attirbutes.gd")
const FLY_EGG_SCRIPT := preload("res://Backend/Object Initialization/FlyEgg.gd")

const KILL_SPRITE_TEXTURE := preload("res://assets/effects/fly_kill.png")

const FLYING_FRAME_COUNT := 6
const EATING_FRAME_COUNT := 4
const FLYING_FRAME_TIME := 0.055
const EATING_FRAME_TIME := 0.08

const KILL_SPRITE_FRAME_COUNT := 6
const KILL_SPRITE_FRAME_TIME := 0.08
const TARGET_REFRESH_TIME := 0.7
const BASE_EAT_DISTANCE := 44.0
const BITE_DAMAGE := 6.0
const BITE_INTERVAL := 0.65
const EGG_FOOD_GROUP := "fly_eggs"
const KNOCKBACK_TIME := 0.28
const BLINK_MIN_TIME := 1.6
const BLINK_MAX_TIME := 3.2

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
	var bite_damage_multiplier: float
	var unlock_day: int
	var flying_texture: Texture2D
	var eating_texture: Texture2D
	var flying_frame_count: int
	var eating_frame_count: int

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
		behavior_can_spawn: bool = false,
		behavior_bite_damage_multiplier: float = 1.0,
		behavior_unlock_day: int = 1,
		behavior_flying_texture: Texture2D = null,
		behavior_eating_texture: Texture2D = null,
		behavior_flying_frame_count: int = FLYING_FRAME_COUNT,
		behavior_eating_frame_count: int = EATING_FRAME_COUNT
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
		bite_damage_multiplier = behavior_bite_damage_multiplier
		unlock_day = behavior_unlock_day
		flying_texture = behavior_flying_texture
		eating_texture = behavior_eating_texture
		flying_frame_count = behavior_flying_frame_count
		eating_frame_count = behavior_eating_frame_count

static func get_behavior_list(include_mother: bool = true, day: int = 1, event: Dictionary = {}) -> Array[FlyBehavior]:
	var behaviors := _get_all_behaviors()
	var unlocked: Array[FlyBehavior] = []
	for candidate in behaviors:
		var is_spawner_type := candidate.name == "Mother" or candidate.name == "Queen"
		if candidate.name == "Queen" and day % 10 != 0:
			continue
		if candidate.unlock_day <= day and (include_mother or not is_spawner_type):
			unlocked.append(_scaled_behavior_for_day(candidate, day, event))

	return unlocked

static func get_mother_behavior() -> FlyBehavior:
	for candidate in _get_all_behaviors():
		if candidate.name == "Mother":
			return candidate

	return _get_fallback_behavior()

static func get_behavior_by_name(behavior_name: String, day: int = 1, event: Dictionary = {}) -> FlyBehavior:
	for candidate in _get_all_behaviors():
		if candidate.name == behavior_name:
			return _scaled_behavior_for_day(candidate, day, event)

	return _scaled_behavior_for_day(_get_fallback_behavior(), day, event)

static func get_hatch_options_for_parent(parent_name: String, _day: int = 1) -> Array[String]:
	if parent_name == "Mother":
		return ["Swarm", "Normal"]

	var options: Array[String] = []
	for candidate in _get_all_behaviors():
		if candidate.name == "Queen":
			continue
		options.append(candidate.name)
	return options

static func _get_all_behaviors() -> Array[FlyBehavior]:
	var behaviors: Array[FlyBehavior] = []
	var flies_data := FLY_ATTRIBUTES_SCRIPT.new().Flies
	for category in flies_data.keys():
		for fly_item in flies_data[category]:
			behaviors.append(_behavior_from_item(fly_item))
	return behaviors

static func _behavior_from_item(fly_item: Dictionary) -> FlyBehavior:
	var attributes := fly_item.get("attributes", {}) as Dictionary
	var flying_asset = fly_item.get("flying")
	var eating_asset = fly_item.get("eating")
	var image_scale: Vector2 = attributes.get("image_scale", Vector2.ONE)
	var tint: Color = attributes.get("tint", Color.WHITE)
	var flying_texture: Texture2D = flying_asset.texture if flying_asset != null else null
	var eating_texture: Texture2D = eating_asset.texture if eating_asset != null else null
	var flying_frame_count := int(flying_asset.frame_count) if flying_asset != null else FLYING_FRAME_COUNT
	var eating_frame_count := int(eating_asset.frame_count) if eating_asset != null else EATING_FRAME_COUNT
	return FlyBehavior.new(
		str(attributes.get("name", fly_item.get("name", ""))),
		int(attributes.get("max_health", 1)),
		float(attributes.get("speed", 100.0)),
		image_scale,
		tint,
		float(attributes.get("hitbox_radius", 48.0)),
		float(attributes.get("health_bar_width", 52.0)),
		float(attributes.get("health_bar_y", -66.0)),
		float(attributes.get("knockback_strength", 320.0)),
		float(attributes.get("eat_time_limit", 2.4)),
		bool(attributes.get("can_spawn", false)),
		float(attributes.get("bite_damage_multiplier", 1.0)),
		int(attributes.get("unlock_day", 1)),
		flying_texture,
		eating_texture,
		flying_frame_count,
		eating_frame_count
	)

static func _scaled_behavior_for_day(base_behavior: FlyBehavior, day: int, event: Dictionary) -> FlyBehavior:
	var health_multiplier := float(event.get("fly_health_multiplier", 1.0))
	var speed_multiplier := float(event.get("fly_speed_multiplier", 1.0))
	return FlyBehavior.new(
		base_behavior.name,
		int(ceilf(float(base_behavior.max_health) * health_multiplier + float(day) * 0.15)),
		(base_behavior.speed + float(day) * 3.0) * speed_multiplier,
		base_behavior.image_scale,
		base_behavior.tint,
		base_behavior.hitbox_radius,
		base_behavior.health_bar_width,
		base_behavior.health_bar_y,
		base_behavior.knockback_strength,
		maxf(base_behavior.eat_time_limit - float(day) * 0.01, 0.85),
		base_behavior.can_spawn,
		base_behavior.bite_damage_multiplier,
		base_behavior.unlock_day,
		base_behavior.flying_texture,
		base_behavior.eating_texture,
		base_behavior.flying_frame_count,
		base_behavior.eating_frame_count
	)

static func _get_fallback_behavior() -> FlyBehavior:
	var behaviors := _get_all_behaviors()
	if behaviors.is_empty():
		return FlyBehavior.new("Normal", 2, 120.0, Vector2(0.48, 0.40), Color.WHITE, 48.0, 52.0, -66.0, 360.0, 2.4)

	return behaviors[0]

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
var is_dying := false
var death_frame_index := 0
var blink_timer := 0.0

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

func get_random_behavior(include_mother: bool = true, day: int = 1, event: Dictionary = {}) -> FlyBehavior:
	var behaviors := get_behavior_list(include_mother, day, event)
	if behaviors.is_empty():
		return _scaled_behavior_for_day(_get_fallback_behavior(), day, event)

	var fly_weights := event.get("fly_weights", {}) as Dictionary
	var weighted: Array[FlyBehavior] = []
	for candidate in behaviors:
		var weight := int(fly_weights.get(candidate.name, 1))
		for _index in range(maxi(weight, 1)):
			weighted.append(candidate)

	return weighted.pick_random()

func get_forced_mother_behavior(day: int = 1, event: Dictionary = {}) -> FlyBehavior:
	return _scaled_behavior_for_day(get_mother_behavior(), day, event)

func configure(new_behavior: FlyBehavior, bounds: Rect2) -> void:
	behavior = new_behavior
	movement_bounds = bounds
	health = behavior.max_health
	clicks_until_scare = randi_range(1, 3)
	click_streak = 0
	bites_since_spawn = 0
	eating_time = 0.0
	blink_timer = randf_range(BLINK_MIN_TIME, BLINK_MAX_TIME)
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
	if is_dying:
		_animate_death_sprite(delta)
		return

	if sprite.texture == _get_flying_texture():
		_animate_sprite(delta, _get_flying_frame_count(), FLYING_FRAME_TIME)
	elif sprite.texture == _get_eating_texture():
		_animate_sprite(delta, _get_eating_frame_count(), EATING_FRAME_TIME)

	if knockback_timer > 0.0:
		knockback_timer -= delta
		position += velocity * delta
		_update_sprite_direction()
		_keep_inside_bounds()
		if knockback_timer <= 0.0:
			target_food = null
			target_refresh_timer = 0.0
		return

	if behavior != null and behavior.name == "Blink":
		_process_blink(delta)

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

func _animate_death_sprite(delta: float) -> void:
	sprite_frame_timer += delta
	if sprite_frame_timer < KILL_SPRITE_FRAME_TIME:
		return

	sprite_frame_timer = 0.0
	death_frame_index += 1
	if death_frame_index >= KILL_SPRITE_FRAME_COUNT:
		queue_free()
		return

	sprite.frame = death_frame_index

func _play_death_animation() -> void:
	is_dying = true
	death_frame_index = 0
	target_food = null
	velocity = Vector2.ZERO
	knockback_timer = 0.0
	input_pickable = false
	if collision_shape != null:
		collision_shape.disabled = true
	if health_bar != null:
		health_bar.visible = false

	sprite.texture = KILL_SPRITE_TEXTURE
	sprite.hframes = KILL_SPRITE_FRAME_COUNT
	sprite.vframes = 1
	sprite.frame = 0
	sprite_frame_timer = 0.0

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
	if behavior.can_spawn:
		_try_lay_eggs_on_food()
		if eating_time >= 0.35:
			_leave_food()
		return

	bite_timer -= delta
	if bite_timer <= 0.0:
		bite_timer = BITE_INTERVAL
		var bite_damage := BITE_DAMAGE * behavior.bite_damage_multiplier
		var healing: int = target_food.call("eat", bite_damage)
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
		if swatter != null:
			var swat_is_active := swatter.has_method("is_swat_active") and bool(swatter.call("is_swat_active"))
			if not swat_is_active and not swatter.call("swat"):
				return

		var damage_amount := 1
		if swatter != null and swatter.has_method("get_damage"):
			damage_amount = int(swatter.call("get_damage"))
		take_damage(damage_amount)

func take_damage(amount: int) -> void:
	health -= amount
	click_streak += 1
	if sfx_swat != null:
		sfx_swat.play()
	_update_health_bar()

	if health <= 0:
		died.emit(self)
		_play_death_animation()
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

	spawn_requested.emit(global_position, "")

func _try_lay_eggs_on_food() -> void:
	if not _is_food_valid(target_food):
		return

	var max_eggs := 3 if behavior.name == "Queen" else 1
	var current_eggs := _get_food_egg_count(target_food)
	if current_eggs >= max_eggs:
		return

	var eggs_to_lay := max_eggs - current_eggs
	var hatch_options := get_hatch_options_for_parent(behavior.name, behavior.unlock_day)
	for _index in range(eggs_to_lay):
		var egg := FLY_EGG_SCRIPT.new() as Area2D
		egg.call("configure", behavior.max_health, hatch_options, target_food)
		egg.add_to_group(EGG_FOOD_GROUP)
		target_food.add_child(egg)
		var offset := Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(10.0, 30.0)
		egg.global_position = target_food.global_position + offset
		var game_root := get_tree().current_scene
		if game_root != null and game_root.has_method("_on_fly_spawn_requested"):
			egg.connect("hatched", Callable(game_root, "_on_fly_spawn_requested"))

func _get_food_egg_count(food: Node2D) -> int:
	var count := 0
	for child in food.get_children():
		if child.is_in_group(EGG_FOOD_GROUP):
			count += 1
	return count

func _process_blink(delta: float) -> void:
	blink_timer -= delta
	if blink_timer > 0.0:
		return

	blink_timer = randf_range(BLINK_MIN_TIME, BLINK_MAX_TIME)
	if _is_food_valid(target_food) and global_position.distance_to(target_food.global_position) <= _get_eat_distance() * 1.4:
		return

	var blink_offset := Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(90.0, 160.0)
	position += blink_offset
	_keep_inside_bounds()

func _get_flying_texture() -> Texture2D:
	if behavior != null:
		return behavior.flying_texture
	return null

func _get_eating_texture() -> Texture2D:
	if behavior != null:
		return behavior.eating_texture
	return null

func _get_flying_frame_count() -> int:
	if behavior != null:
		return behavior.flying_frame_count
	return FLYING_FRAME_COUNT

func _get_eating_frame_count() -> int:
	if behavior != null:
		return behavior.eating_frame_count
	return EATING_FRAME_COUNT

func _set_flying_sprite() -> void:
	var desired_texture := _get_flying_texture()
	if sprite.texture == desired_texture:
		return

	sprite.texture = desired_texture
	sprite.hframes = _get_flying_frame_count()
	sprite.vframes = 1
	sprite.frame = 0
	sprite_frame_timer = 0.0

func _set_eating_sprite() -> void:
	var desired_texture := _get_eating_texture()
	if sprite.texture == desired_texture:
		return

	sprite.texture = desired_texture
	sprite.hframes = _get_eating_frame_count()
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
