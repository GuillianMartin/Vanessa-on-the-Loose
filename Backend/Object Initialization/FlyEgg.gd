extends Area2D

signal hatched(position: Vector2, behavior_name: String)

const IDLE_TEXTURE := preload("res://assets/Flies/mother_fly/egg_idle.png")
const HATCH_TEXTURE := preload("res://assets/Flies/mother_fly/egg_hatch.png")
const IDLE_FRAME_COUNT := 4
const HATCH_FRAME_COUNT := 13
const IDLE_FRAME_TIME := 0.12
const HATCH_FRAME_TIME := 0.06
const EGG_RADIUS := 22.0

var health := 1
var max_health := 1
var hatch_options: Array[String] = []
var hatch_timer := 0.0
var frame_timer := 0.0
var hatching := false
var food_parent: Node2D = null
var egg_damage_per_second := 0.5
var parent_name := ""
const KNIGHT_GUARD_HATCH_CHANCE := 0.08

var sprite: Sprite2D
var collision_shape: CollisionShape2D
var health_bar: ProgressBar
var damage_label: Label

func configure(new_health: int, new_hatch_options: Array[String], parent_food: Node2D = null, parent: String = "") -> void:
	max_health = maxi(new_health, 1)
	health = max_health
	hatch_options.clear()
	for option in new_hatch_options:
		hatch_options.append(option)
	hatch_timer = randf_range(3.0, 5.0)
	food_parent = parent_food
	parent_name = parent

func _ready() -> void:
	input_pickable = true
	monitoring = true
	monitorable = true
	z_index = 6
	add_to_group("fly_eggs")
	_ensure_nodes()
	_play_ease_in()

func _process(delta: float) -> void:
	if hatching:
		_update_hatch(delta)
		return

	if food_parent != null and is_instance_valid(food_parent) and food_parent.has_method("eat"):
		food_parent.call("eat", egg_damage_per_second * delta)

	hatch_timer -= delta
	_animate_idle(delta)
	if hatch_timer <= 0.0:
		_start_hatch()

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if hatching:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var swatter := _get_swatter()
		if swatter != null:
			var swat_is_active := swatter.has_method("is_swat_active") and bool(swatter.call("is_swat_active"))
			if not swat_is_active and not swatter.call("swat"):
				return

		var damage_amount := 1
		if swatter != null and swatter.has_method("get_damage"):
			damage_amount = int(swatter.call("get_damage"))
		_take_damage(damage_amount)

func _take_damage(amount: int) -> void:
	health -= amount
	_update_health_bar()
	if health <= 0:
		_play_ease_out()

func _ensure_nodes() -> void:
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.texture = IDLE_TEXTURE
		sprite.hframes = IDLE_FRAME_COUNT
		sprite.vframes = 1
		sprite.scale = Vector2(0.55, 0.55)
		add_child(sprite)

	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = EGG_RADIUS
		collision_shape.shape = circle
		add_child(collision_shape)

	if health_bar == null:
		health_bar = ProgressBar.new()
		health_bar.show_percentage = false
		health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		health_bar.custom_minimum_size = Vector2(44, 6)
		health_bar.position = Vector2(-22, -32)
		add_child(health_bar)
	_update_health_bar()

	if damage_label == null:
		damage_label = Label.new()
		damage_label.text = "-%.1f" % egg_damage_per_second
		damage_label.add_theme_color_override("font_color", Color.RED)
		damage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		damage_label.position = Vector2(-20, -48)
		add_child(damage_label)

func _update_health_bar() -> void:
	if health_bar == null:
		return
	health_bar.max_value = max_health
	health_bar.value = max(health, 0)

func _animate_idle(delta: float) -> void:
	frame_timer += delta
	if frame_timer < IDLE_FRAME_TIME:
		return
	frame_timer = 0.0
	sprite.frame = (sprite.frame + 1) % IDLE_FRAME_COUNT

func _start_hatch() -> void:
	hatching = true
	frame_timer = 0.0
	if health_bar != null:
		health_bar.visible = false
	if collision_shape != null:
		collision_shape.disabled = true
	sprite.texture = HATCH_TEXTURE
	sprite.hframes = HATCH_FRAME_COUNT
	sprite.frame = 0

func _update_hatch(delta: float) -> void:
	frame_timer += delta
	if frame_timer < HATCH_FRAME_TIME:
		return
	frame_timer = 0.0
	var next_frame := sprite.frame + 1
	if next_frame >= HATCH_FRAME_COUNT:
		var behavior_name := "Normal"
		if not hatch_options.is_empty():
			behavior_name = hatch_options.pick_random()
		if parent_name == "Boss" and randf() <= KNIGHT_GUARD_HATCH_CHANCE:
			behavior_name = "KnightGuard"
		hatched.emit(global_position, behavior_name)
		queue_free()
		return
	sprite.frame = next_frame

func _play_ease_in() -> void:
	if sprite == null:
		return
	var target_scale := sprite.scale
	sprite.scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(sprite, "scale", target_scale, 0.12)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

func _play_ease_out() -> void:
	input_pickable = false
	if collision_shape != null:
		collision_shape.disabled = true
	if health_bar != null:
		health_bar.visible = false
	if damage_label != null:
		damage_label.visible = false
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.12)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.finished.connect(queue_free)

func _get_swatter() -> Node:
	var swatters := get_tree().get_nodes_in_group("swatters")
	if swatters.is_empty():
		return null
	return swatters[0]
