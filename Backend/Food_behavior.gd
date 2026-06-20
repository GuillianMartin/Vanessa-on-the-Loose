extends Area2D

signal depleted(food: Area2D)

const MEAT_DEFAULT_PATH := "res://assets/Foods/Meat/default.png"
const CARROT_DEFAULT_PATH := "res://assets/Foods/Vegetable/carrot/default.png"
const CARROT_NOTGOOD_PATH := "res://assets/Foods/Vegetable/carrot/notgood.png"
const CARROT_CRITICAL_PATH := "res://assets/Foods/Vegetable/carrot/critical.png"
const CABBAGE_DEFAULT_PATH := "res://assets/Foods/Vegetable/cabbage/default.png"
const CABBAGE_NOTGOOD_PATH := "res://assets/Foods/Vegetable/cabbage/notgood.png"
const CABBAGE_CRITICAL_PATH := "res://assets/Foods/Vegetable/cabbage/critical.png"
const TOMATO_DEFAULT_PATH := "res://assets/Foods/Vegetable/tomato/default.png"
const TOMATO_NOTGOOD_PATH := "res://assets/Foods/Vegetable/tomato/notgood.png"
const TOMATO_CRITICAL_PATH := "res://assets/Foods/Vegetable/tomato/critical.png"
const FOOD_SIZE_MULT := 1.2
const CRITICAL_SIZE_MULT := 5
const CRITICAL_FRAME_COUNT := 5
const CRITICAL_FRAME_TIME := 0.1

class FoodConfig:
	var name: String
	var default_texture: Texture2D
	var notgood_texture: Texture2D
	var critical_texture: Texture2D
	var visual_size: float
	var max_freshness: float
	var spoil_rate: float
	var nutrition: int
	var radius: float

	func _init(
		food_name: String,
		food_default_texture: Texture2D,
		food_notgood_texture: Texture2D,
		food_critical_texture: Texture2D,
		food_visual_size: float,
		food_max_freshness: float,
		food_spoil_rate: float,
		food_nutrition: int,
		food_radius: float
	) -> void:
		name = food_name
		default_texture = food_default_texture
		notgood_texture = food_notgood_texture
		critical_texture = food_critical_texture
		visual_size = food_visual_size
		max_freshness = food_max_freshness
		spoil_rate = food_spoil_rate
		nutrition = food_nutrition
		radius = food_radius

static func get_food_types() -> Array[FoodConfig]:
	return [
		FoodConfig.new("Meat", _load_texture(MEAT_DEFAULT_PATH), null, null, 118.0 * FOOD_SIZE_MULT, 120.0, 0.9, 2, 58.0 * FOOD_SIZE_MULT),
		FoodConfig.new("Carrot", _load_texture(CARROT_DEFAULT_PATH), _load_texture(CARROT_NOTGOOD_PATH), _load_texture(CARROT_CRITICAL_PATH), 100.0 * FOOD_SIZE_MULT, 95.0, 1.25, 1, 50.0 * FOOD_SIZE_MULT),
		FoodConfig.new("Cabbage", _load_texture(CABBAGE_DEFAULT_PATH), _load_texture(CABBAGE_NOTGOOD_PATH), _load_texture(CABBAGE_CRITICAL_PATH), 100.0 * FOOD_SIZE_MULT, 105.0, 1.05, 1, 50.0 * FOOD_SIZE_MULT),
		FoodConfig.new("Tomato", _load_texture(TOMATO_DEFAULT_PATH), _load_texture(TOMATO_NOTGOOD_PATH), _load_texture(TOMATO_CRITICAL_PATH), 96.0 * FOOD_SIZE_MULT, 90.0, 1.2, 1, 48.0 * FOOD_SIZE_MULT),
	]

static func get_random_config() -> FoodConfig:
	return get_food_types().pick_random()

static func _load_texture(path: String) -> Texture2D:
	var resource := load(path)
	if resource is Texture2D:
		return resource as Texture2D

	return null

var config: FoodConfig
var max_freshness := 100.0
var freshness := 100.0
var spoil_rate := 1.25
var nutrition := 1
var radius := 48.0

var sprite: Sprite2D
var collision_shape: CollisionShape2D
var freshness_bar: ProgressBar
var current_state := ""
var critical_frame_timer := 0.0

func _ready() -> void:
	add_to_group("foods")
	input_pickable = false
	_ensure_nodes()
	if config == null:
		configure(get_random_config())
	else:
		_apply_config()

func configure(new_config: FoodConfig) -> void:
	config = new_config
	_apply_config()

func eat(amount: float) -> int:
	if freshness <= 0.0:
		return 0

	freshness = maxf(freshness - amount, 0.0)
	_animate_critical(0.0)
	_update_visuals()

	if freshness <= 0.0:
		depleted.emit(self)
		queue_free()

	return nutrition

func get_radius() -> float:
	return radius

func _process(delta: float) -> void:
	if freshness <= 0.0:
		return

	freshness = maxf(freshness - spoil_rate * delta, 0.0)
	_animate_critical(delta)
	_update_visuals()

	if freshness <= 0.0:
		depleted.emit(self)
		queue_free()

func _apply_config() -> void:
	if config == null:
		return

	max_freshness = config.max_freshness
	freshness = max_freshness
	spoil_rate = config.spoil_rate
	nutrition = config.nutrition
	radius = config.radius

	_ensure_nodes()
	_update_food_sprite(true)

	var circle := collision_shape.shape as CircleShape2D
	if circle != null:
		circle.radius = radius

	freshness_bar.size = Vector2(maxf(radius * 1.15, 54.0), 6)
	freshness_bar.position = Vector2(-freshness_bar.size.x * 0.5, radius + 8.0)
	_update_visuals()

func _scale_sprite_to_size(target_size: float) -> void:
	if sprite.texture == null:
		return

	var texture_size := sprite.texture.get_size()
	var longest_side: float = maxf(texture_size.x, texture_size.y)
	if longest_side <= 0.0:
		return

	sprite.scale = Vector2.ONE * (target_size / longest_side)

func _ensure_nodes() -> void:
	if sprite == null:
		sprite = Sprite2D.new()
		add_child(sprite)

	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = radius
		collision_shape.shape = circle
		add_child(collision_shape)

	if freshness_bar == null:
		freshness_bar = ProgressBar.new()
		freshness_bar.show_percentage = false
		freshness_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(freshness_bar)

func _update_visuals() -> void:
	if sprite == null or freshness_bar == null:
		return

	var ratio := 0.0
	if max_freshness > 0.0:
		ratio = clampf(freshness / max_freshness, 0.0, 1.0)

	_update_food_sprite()
	sprite.modulate = Color.WHITE
	freshness_bar.max_value = max_freshness
	freshness_bar.value = freshness
	freshness_bar.visible = true

func _update_food_sprite(force: bool = false) -> void:
	if config == null or sprite == null:
		return

	var ratio := 0.0
	if max_freshness > 0.0:
		ratio = clampf(freshness / max_freshness, 0.0, 1.0)

	var next_state := "default"
	var next_texture := config.default_texture
	if ratio <= 0.2 and config.critical_texture != null:
		next_state = "critical"
		next_texture = config.critical_texture
	elif ratio <= 0.5 and config.notgood_texture != null:
		next_state = "notgood"
		next_texture = config.notgood_texture

	if not force and current_state == next_state:
		return

	current_state = next_state
	sprite.texture = next_texture
	sprite.hframes = CRITICAL_FRAME_COUNT if current_state == "critical" else 1
	sprite.vframes = 1
	sprite.frame = 0
	critical_frame_timer = 0.0
	var target_size := config.visual_size
	if current_state == "critical":
		target_size *= CRITICAL_SIZE_MULT
	_scale_sprite_to_size(target_size)

func _animate_critical(delta: float) -> void:
	if current_state != "critical":
		return

	critical_frame_timer += delta
	if critical_frame_timer < CRITICAL_FRAME_TIME:
		return

	critical_frame_timer = 0.0
	sprite.frame = (sprite.frame + 1) % CRITICAL_FRAME_COUNT
