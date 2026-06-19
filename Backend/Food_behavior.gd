extends Area2D

signal depleted(food: Area2D)

const BASE_SIZE := 88.0

var max_freshness := 100.0
var freshness := 100.0
var spoil_rate := 1.25
var nutrition := 1
var radius := 38.0

var sprite: Sprite2D
var collision_shape: CollisionShape2D
var freshness_bar: ProgressBar

func _ready() -> void:
	add_to_group("foods")
	input_pickable = false
	_ensure_nodes()
	_update_visuals()

func configure(food_texture: Texture2D, new_max_freshness: float = 100.0, new_spoil_rate: float = 1.25) -> void:
	max_freshness = new_max_freshness
	freshness = max_freshness
	spoil_rate = new_spoil_rate
	_ensure_nodes()

	sprite.texture = food_texture
	if food_texture != null:
		var texture_size := food_texture.get_size()
		var longest_side: float = maxf(texture_size.x, texture_size.y)
		if longest_side > 0.0:
			var visual_scale := BASE_SIZE / longest_side
			sprite.scale = Vector2.ONE * visual_scale
			radius = BASE_SIZE * 0.5

	var circle := collision_shape.shape as CircleShape2D
	if circle != null:
		circle.radius = radius

	_update_visuals()

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
		freshness_bar.size = Vector2(58, 6)
		freshness_bar.position = Vector2(-29, 34)
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
