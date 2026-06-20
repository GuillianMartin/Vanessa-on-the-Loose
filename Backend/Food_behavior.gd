extends Area2D

signal depleted(food: Area2D)

const MEAT_TEXTURE := preload("res://assets/Foods/Meat/meat1.png")
const CARROT_TEXTURE := preload("res://assets/Foods/Vegetable/carrot.png")
const CABBAGE_TEXTURE := preload("res://assets/Foods/Vegetable/cabbage.png")
const food_size_mult := 1.2

class FoodConfig:
	var name: String
	var texture: Texture2D
	var visual_size: float
	var max_freshness: float
	var spoil_rate: float
	var nutrition: int
	var radius: float

	func _init(
		food_name: String,
		food_texture: Texture2D,
		food_visual_size: float,
		food_max_freshness: float,
		food_spoil_rate: float,
		food_nutrition: int,
		food_radius: float
	) -> void:
		name = food_name
		texture = food_texture
		visual_size = food_visual_size
		max_freshness = food_max_freshness
		spoil_rate = food_spoil_rate
		nutrition = food_nutrition
		radius = food_radius

static func get_food_types() -> Array[FoodConfig]:
	return [
		FoodConfig.new("Meat", MEAT_TEXTURE, 118.0 * food_size_mult, 120.0, 0.9, 2, 58.0 * food_size_mult),
		FoodConfig.new("Carrot", CARROT_TEXTURE, 100.0 * food_size_mult, 95.0, 1.25, 1, 50.0 * food_size_mult),
		FoodConfig.new("Cabbage", CABBAGE_TEXTURE, 100.0 * food_size_mult, 105.0, 1.05, 1, 50.0 * food_size_mult),
	]

static func get_random_config() -> FoodConfig:
	return get_food_types().pick_random()

var config: FoodConfig
var max_freshness := 100.0
var freshness := 100.0
var spoil_rate := 1.25
var nutrition := 1
var radius := 48.0

var sprite: Sprite2D
var collision_shape: CollisionShape2D
var freshness_bar: ProgressBar

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
	sprite.texture = config.texture
	_scale_sprite_to_size(config.visual_size)

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

	sprite.modulate = Color(0.55 + ratio * 0.45, 0.55 + ratio * 0.45, 0.55 + ratio * 0.45, 1.0)
	freshness_bar.max_value = max_freshness
	freshness_bar.value = freshness
	freshness_bar.visible = true
