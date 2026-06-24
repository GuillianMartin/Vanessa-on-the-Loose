extends Area2D

signal depleted(food: Area2D)

const FOODS_SCRIPT := preload("res://Backend/Object Initialization/Foods_Attributes.gd")
const FOOD_SPAWN_TEXTURE := preload("res://assets/effects/food_spawn.png")
const FOOD_SPOIL_TEXTURE := preload("res://assets/effects/food_spoil.png")

const CRITICAL_SIZE_MULT := 5
const CRITICAL_FRAME_COUNT := 5
const CRITICAL_FRAME_TIME := 0.1

const SPAWN_FRAME_COUNT := 8
const SPAWN_DURATION := 1.0
const SPAWN_FRAME_TIME := SPAWN_DURATION / SPAWN_FRAME_COUNT

const SPOIL_FRAME_COUNT := 22
const SPOIL_DURATION := 1.2
const SPOIL_FRAME_TIME := SPOIL_DURATION / SPOIL_FRAME_COUNT

var price_label: Label

class FoodConfig:
	var name: String
	var category: String
	var default_texture: Texture2D
	var notgood_texture: Texture2D
	var critical_texture: Texture2D
	var visual_size: float
	var radius: float
	var max_freshness: float
	var spoil_rate: float
	var nutrition: int
	var base_market_price: float
	var base_sell_price: float
	var market_price: float
	var sell_price: float
	var tint: Color

	func _init(
		food_name: String,
		food_category: String,
		food_default_texture: Texture2D,
		food_notgood_texture: Texture2D,
		food_critical_texture: Texture2D,
		food_visual_size: float,
		food_radius: float,
		food_max_freshness: float,
		food_spoil_rate: float,
		food_nutrition: int,
		food_base_market_price: float,
		food_base_sell_price: float,
		food_tint: Color = Color.WHITE
	) -> void:
		name = food_name
		category = food_category
		default_texture = food_default_texture
		notgood_texture = food_notgood_texture
		critical_texture = food_critical_texture
		visual_size = food_visual_size
		radius = food_radius
		max_freshness = food_max_freshness
		spoil_rate = food_spoil_rate
		nutrition = food_nutrition
		base_market_price = food_base_market_price
		base_sell_price = food_base_sell_price
		market_price = food_base_market_price
		sell_price = food_base_sell_price
		tint = food_tint

static func get_food_types() -> Array[FoodConfig]:
	var food_types: Array[FoodConfig] = []
	var foods_data := FOODS_SCRIPT.new().Foods
	for category in foods_data.keys():
		for food_item in foods_data[category]:
			food_types.append(_food_config_from_item(category, food_item))
	return food_types

static func _food_config_from_item(category: String, food_item: Dictionary) -> FoodConfig:
	var attributes := food_item.get("attributes", {}) as Dictionary
	var base_market_price := float(attributes.get("base_price", 0.0))
	return FoodConfig.new(
		str(food_item.get("name", "")),
		category,
		food_item["default"].texture,
		food_item["notgood"].texture,
		food_item["critical"].texture,
		float(attributes.get("visual_size", 0.0)),
		float(attributes.get("food_radius", 0.0)),
		float(attributes.get("max_freshness", 0.0)),
		float(attributes.get("spoil_rate", 0.0)),
		int(attributes.get("nutrition", 0)),
		base_market_price,
		ceilf(base_market_price * 1.32),
		attributes.get("tint", Color.WHITE)
	)

static func get_random_config() -> FoodConfig:
	return get_food_types().pick_random()

static func get_random_config_for_category(category: String = "") -> FoodConfig:
	var food_types := get_food_types()
	if category == "":
		return food_types.pick_random()

	var matching: Array[FoodConfig] = []
	for food_type in food_types:
		if food_type.category == category:
			matching.append(food_type)

	if matching.is_empty():
		return food_types.pick_random()

	return matching.pick_random()

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

var spawn_animation_sprite: Sprite2D
var spawn_animation_timer := 0.0
var is_spawning := false

var spoil_animation_sprite: Sprite2D
var spoil_animation_timer := 0.0
var is_spoiling := false

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

func apply_market_modifiers(market_price_multiplier: float, sell_price_multiplier: float, spoil_multiplier: float) -> void:
	if config == null:
		return

	config.market_price = ceilf(config.base_market_price * market_price_multiplier)
	config.sell_price = ceilf(config.base_sell_price * sell_price_multiplier)
	config.spoil_rate = config.spoil_rate * spoil_multiplier
	spoil_rate = config.spoil_rate
	_update_visuals()

func get_stock_cost() -> int:
	if config == null:
		return 0

	return int(ceilf(config.market_price))

func eat(amount: float) -> int:
	if freshness <= 0.0:
		return 0

	freshness = maxf(freshness - amount, 0.0)
	_animate_critical(0.0)
	_update_visuals()

	if freshness <= 0.0:
		_play_spoil_animation()

	return nutrition

func get_radius() -> float:
	return radius

func _process(delta: float) -> void:
	_update_spawn_animation(delta)
	_update_spoil_animation(delta)
	
	if freshness <= 0.0:
		return

	freshness = maxf(freshness - spoil_rate * delta, 0.0)
	_animate_critical(delta)
	_update_visuals()

	if freshness <= 0.0:
		_play_spoil_animation()
		return

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
	_play_spawn_animation()

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

	if spawn_animation_sprite == null:
		spawn_animation_sprite = Sprite2D.new()
		spawn_animation_sprite.texture = FOOD_SPAWN_TEXTURE
		spawn_animation_sprite.hframes = SPAWN_FRAME_COUNT
		spawn_animation_sprite.vframes = 1
		spawn_animation_sprite.frame = 0
		spawn_animation_sprite.centered = true
		spawn_animation_sprite.visible = false
		add_child(spawn_animation_sprite)

	if spoil_animation_sprite == null:
		spoil_animation_sprite = Sprite2D.new()
		spoil_animation_sprite.texture = FOOD_SPOIL_TEXTURE
		spoil_animation_sprite.hframes = SPOIL_FRAME_COUNT
		spoil_animation_sprite.vframes = 1
		spoil_animation_sprite.frame = 0
		spoil_animation_sprite.centered = true
		spoil_animation_sprite.visible = false
		add_child(spoil_animation_sprite)

func _update_visuals() -> void:
	if sprite == null or freshness_bar == null:
		return

	var ratio := 0.0
	if max_freshness > 0.0:
		ratio = clampf(freshness / max_freshness, 0.0, 1.0)

	_update_food_sprite()
	sprite.modulate = config.tint
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
	return int(config.sell_price * freshness_ratio)

func _play_spawn_animation() -> void:
	is_spawning = true
	spawn_animation_timer = 0.0
	if spawn_animation_sprite != null:
		spawn_animation_sprite.visible = true
		spawn_animation_sprite.frame = 0
		# Scale spawn animation to match food size
		_scale_animation_sprite(spawn_animation_sprite, config.visual_size)

func _update_spawn_animation(delta: float) -> void:
	if not is_spawning or spawn_animation_sprite == null:
		return

	spawn_animation_timer += delta
	
	# Calculate which frame we should be on
	var frame_index := int((spawn_animation_timer / SPAWN_FRAME_TIME))
	
	if frame_index >= SPAWN_FRAME_COUNT:
		# Animation finished
		is_spawning = false
		spawn_animation_sprite.visible = false
		return

	spawn_animation_sprite.frame = frame_index

func _play_spoil_animation() -> void:
	is_spoiling = true
	spoil_animation_timer = 0.0
	if spoil_animation_sprite != null:
		spoil_animation_sprite.visible = true
		spoil_animation_sprite.frame = 0
		# Scale spoil animation to match food size
		_scale_animation_sprite(spoil_animation_sprite, config.visual_size)

func _update_spoil_animation(delta: float) -> void:
	if not is_spoiling or spoil_animation_sprite == null:
		return

	spoil_animation_timer += delta
	
	# Calculate which frame we should be on
	var frame_index := int((spoil_animation_timer / SPOIL_FRAME_TIME))
	
	if frame_index >= SPOIL_FRAME_COUNT:
		# Animation finished, emit depleted signal and queue for deletion
		is_spoiling = false
		spoil_animation_sprite.visible = false
		depleted.emit(self)
		queue_free()
		return

	spoil_animation_sprite.frame = frame_index

func _scale_animation_sprite(anim_sprite: Sprite2D, target_size: float) -> void:
	if anim_sprite.texture == null:
		return

	var texture_size := anim_sprite.texture.get_size()
	if texture_size.y <= 0:
		return
	
	# For sprite sheets, get the size of one frame
	var frame_width := texture_size.x / anim_sprite.hframes
	var frame_height := texture_size.y / anim_sprite.vframes
	var longest_side: float = maxf(frame_width, frame_height)
	
	if longest_side <= 0.0:
		return

	anim_sprite.scale = Vector2.ONE * (target_size / longest_side)
