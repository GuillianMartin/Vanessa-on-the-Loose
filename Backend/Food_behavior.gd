extends Area2D

signal depleted(food: Area2D)

const FOODS_SCRIPT := preload("res://Backend/Object Initialization/Foods.gd")

const CRITICAL_SIZE_MULT := 5
const CRITICAL_FRAME_COUNT := 5
const CRITICAL_FRAME_TIME := 0.1

var base_price := 15.0
var price_label: Label

class FoodConfig:
	var name: String
	var default_texture: Texture2D
	var notgood_texture: Texture2D
	var critical_texture: Texture2D
	var visual_size: float
	var radius: float
	var max_freshness: float
	var spoil_rate: float
	var nutrition: int
	var base_price: float

	func _init(
		food_name: String,
		food_default_texture: Texture2D,
		food_notgood_texture: Texture2D,
		food_critical_texture: Texture2D,
		food_visual_size: float,
		food_radius: float,
		food_max_freshness: float,
		food_spoil_rate: float,
		food_nutrition: int,
		food_base_price: float
	) -> void:
		name = food_name
		default_texture = food_default_texture
		notgood_texture = food_notgood_texture
		critical_texture = food_critical_texture
		visual_size = food_visual_size
		radius = food_radius
		max_freshness = food_max_freshness
		spoil_rate = food_spoil_rate
		nutrition = food_nutrition
		base_price = food_base_price

static func get_food_types() -> Array[FoodConfig]:
	var food_types: Array[FoodConfig] = []
	var foods_data := FOODS_SCRIPT.new().Foods
	for category in foods_data.keys():
		for food_item in foods_data[category]:
			food_types.append(_food_config_from_item(food_item))
	return food_types

static func _food_config_from_item(food_item: Dictionary) -> FoodConfig:
	var attributes := food_item.get("attributes", {}) as Dictionary
	return FoodConfig.new(
		food_item.get("name", ""),
		food_item["default"].texture,
		food_item["notgood"].texture,
		food_item["critical"].texture,
		attributes.get("visual_size", 0.0),
		attributes.get("food_radius", 0.0),
		attributes.get("max_freshness", 0.0),
		attributes.get("spoil_rate", 0.0),
		attributes.get("nutrition", 0),
		attributes.get("base_price", 0.0)
	)

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
	
	if price_label == null:
		price_label = Label.new()
		# Add minimal theme formatting to make it clean
		price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		price_label.add_theme_constant_override("shadow_offset_x", 1)
		price_label.add_theme_constant_override("shadow_offset_y", 1)
		add_child(price_label)

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
	
	# Update the value text dynamically every frame
	if price_label:
		price_label.text = "$%d" % get_current_value()
		# Position it slightly below the freshness health bar
		price_label.position = Vector2(-50, radius + 16.0)
		price_label.custom_minimum_size = Vector2(100, 20)

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

# Call this helper method to get the value dynamically
func get_current_value() -> int:
	var freshness_ratio := freshness / max_freshness
	return int(config.base_price * freshness_ratio)
