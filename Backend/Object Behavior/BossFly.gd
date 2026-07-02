extends Area2D

signal died(fly: Area2D)
signal spawn_requested(position: Vector2, behavior_name: String)

const BOSS_ATTRIBUTES_SCRIPT := preload("res://Backend/Object Initialization/BossFly_Attritbutes.gd")

const STATE_FLYING := "flying"
const STATE_EATING := "eating"
const STATE_POISON := "poison"
const STATE_SHOCKWAVE := "shockwave"
const STATE_STUN := "boss_stun"
const STATE_REVIVE := "boss_revive"
const STATE_SUMMON := "boss_summon"
const STATE_KILL := "boss_kill"

const FLYING_FRAME_TIME := 0.055
const EATING_FRAME_TIME := 0.08
const ATTACK_FRAME_TIME := 0.065
const STUN_DURATION := 2.0
const REVIVE_FRAME_TIME := 0.055
const EFFECT_FRAME_TIME := 0.045

const TARGET_REFRESH_TIME := 0.7
const BASE_EAT_DISTANCE := 72.0
const BITE_DAMAGE := 12.0
const BITE_INTERVAL := 0.65
const BOSS_HEALTH_PER_BAR := 20
const BOSS_SPEED := 86.0
const BOSS_IMAGE_SCALE := Vector2(0.72, 0.72)
const BOSS_HITBOX_RADIUS := 86.0
const BOSS_HEALTH_BAR_WIDTH := 170.0
const BOSS_HEALTH_BAR_HEIGHT := 7.0
const BOSS_HEALTH_BAR_Y := -132.0
const KNOCKBACK_TIME := 0.2
const KNOCKBACK_STRENGTH := 260.0
const ATTACK_MIN_TIME := 3.8
const ATTACK_MAX_TIME := 7.0
const SHOCKWAVE_TRIGGER_FRAME := 5
const POISON_TRIGGER_FRAME := 8
const POISON_FOOD_DAMAGE_RATIO := 0.6
const SHOCKWAVE_CUSTOMER_DAMAGE_RATIO := 0.35
const SUMMON_COUNT := 5

var boss_assets: Dictionary = {}
var movement_bounds := Rect2(Vector2.ZERO, Vector2(1152, 648))
var velocity := Vector2.ZERO
var target_food: Node2D
var target_refresh_timer := 0.0
var bite_timer := 0.0
var eating_time := 0.0
var knockback_timer := 0.0
var attack_cooldown := 0.0

var life_bar_count := 3
var life_bar_count_was_forced := false
var current_life_bar := 0
var current_health := BOSS_HEALTH_PER_BAR
var is_dying := false
var is_invulnerable := false
var stun_timer := 0.0

var current_state := STATE_FLYING
var sprite_frame_timer := 0.0
var attack_effect_played := false

var poison_effect_timer := 0.0
var poison_effect_playing := false
var shockwave_effect_timer := 0.0
var shockwave_effect_playing := false

var sprite: Sprite2D
var collision_shape: CollisionShape2D
var health_bar_container: VBoxContainer
var health_bars: Array[ProgressBar] = []
var poison_effect_sprite: Sprite2D
var shockwave_effect_sprite: Sprite2D
var sfx_swat: AudioStreamPlayer2D

func _ready() -> void:
	input_pickable = true
	monitoring = true
	monitorable = true
	add_to_group("flies")
	add_to_group("boss_flies")

	if get_parent() != null and get_parent().get_parent() != null:
		sfx_swat = get_parent().get_parent().get_node_or_null("sfx_swat") as AudioStreamPlayer2D
	_load_boss_assets()
	_ensure_nodes()
	if life_bar_count_was_forced:
		_rebuild_health_bars()
	else:
		_roll_life_bars()
	current_life_bar = life_bar_count - 1
	current_health = BOSS_HEALTH_PER_BAR
	attack_cooldown = randf_range(ATTACK_MIN_TIME, ATTACK_MAX_TIME)
	velocity = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * BOSS_SPEED
	_set_state(STATE_FLYING, true)
	_update_health_bars()

func configure(bounds: Rect2, forced_life_bar_count: int = 0) -> void:
	movement_bounds = bounds
	if forced_life_bar_count > 0:
		life_bar_count = clampi(forced_life_bar_count, 3, 6)
		life_bar_count_was_forced = true
		current_life_bar = life_bar_count - 1
		current_health = BOSS_HEALTH_PER_BAR
		if is_node_ready():
			_rebuild_health_bars()
			_update_health_bars()

func _load_boss_assets() -> void:
	var boss_data := BOSS_ATTRIBUTES_SCRIPT.new().BossFlies
	var boss_list: Array = boss_data.get("Boss", [])
	if not boss_list.is_empty():
		boss_assets = boss_list[0]

func _roll_life_bars() -> void:
	var roll := randf()
	if roll < 0.4:
		life_bar_count = 3
	elif roll < 0.7:
		life_bar_count = 4
	elif roll < 0.9:
		life_bar_count = 5
	else:
		life_bar_count = 6
	_rebuild_health_bars()

func _ensure_nodes() -> void:
	sprite = get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
	sprite.scale = BOSS_IMAGE_SCALE
	sprite.z_index = 2

	collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		add_child(collision_shape)
	var circle := collision_shape.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
		collision_shape.shape = circle
	circle.radius = BOSS_HITBOX_RADIUS

	if health_bar_container == null:
		health_bar_container = VBoxContainer.new()
		health_bar_container.name = "LifeBars"
		health_bar_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		health_bar_container.position = Vector2(-BOSS_HEALTH_BAR_WIDTH * 0.5, BOSS_HEALTH_BAR_Y)
		health_bar_container.custom_minimum_size = Vector2(BOSS_HEALTH_BAR_WIDTH, BOSS_HEALTH_BAR_HEIGHT * 6.0)
		add_child(health_bar_container)

	if poison_effect_sprite == null:
		poison_effect_sprite = _make_effect_sprite("PoisonEffect", "poison_effect")
		add_child(poison_effect_sprite)

	if shockwave_effect_sprite == null:
		shockwave_effect_sprite = _make_effect_sprite("ShockwaveEffect", "shockwave_effect")
		add_child(shockwave_effect_sprite)

func _make_effect_sprite(node_name: String, asset_key: String) -> Sprite2D:
	var effect_sprite := Sprite2D.new()
	effect_sprite.name = node_name
	effect_sprite.texture = _get_texture(asset_key)
	effect_sprite.hframes = _get_frame_count(asset_key)
	effect_sprite.vframes = 1
	effect_sprite.frame = 0
	effect_sprite.centered = true
	effect_sprite.visible = false
	effect_sprite.z_index = 1
	effect_sprite.position = Vector2(0.0, 28.0)
	_scale_effect_sprite(effect_sprite, BOSS_HITBOX_RADIUS * 3.0)
	return effect_sprite

func _rebuild_health_bars() -> void:
	if health_bar_container == null:
		return

	for bar in health_bars:
		if is_instance_valid(bar):
			bar.queue_free()
	health_bars.clear()

	for _index in range(life_bar_count):
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.custom_minimum_size = Vector2(BOSS_HEALTH_BAR_WIDTH, BOSS_HEALTH_BAR_HEIGHT)
		bar.max_value = BOSS_HEALTH_PER_BAR
		bar.value = BOSS_HEALTH_PER_BAR
		health_bar_container.add_child(bar)
		health_bars.append(bar)

func _process(delta: float) -> void:
	_update_effect_animations(delta)

	if is_dying:
		if _animate_state(delta, STATE_KILL, ATTACK_FRAME_TIME, false):
			queue_free()
		return

	if current_state == STATE_STUN:
		stun_timer -= delta
		_animate_state(delta, STATE_STUN, ATTACK_FRAME_TIME, true)
		if stun_timer <= 0.0:
			_set_state(STATE_REVIVE, true)
		return

	if current_state == STATE_REVIVE:
		if _animate_state(delta, STATE_REVIVE, REVIVE_FRAME_TIME, false):
			_finish_revive()
		return

	if current_state in [STATE_POISON, STATE_SHOCKWAVE, STATE_SUMMON]:
		_process_attack_state(delta)
		return

	if current_state == STATE_FLYING:
		_animate_state(delta, STATE_FLYING, FLYING_FRAME_TIME, true)
	elif current_state == STATE_EATING:
		_animate_state(delta, STATE_EATING, EATING_FRAME_TIME, true)

	_process_attack_cooldown(delta)
	if current_state in [STATE_POISON, STATE_SHOCKWAVE, STATE_SUMMON]:
		return

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

func _process_attack_state(delta: float) -> void:
	var finished := _animate_state(delta, current_state, ATTACK_FRAME_TIME, false)
	if current_state == STATE_SHOCKWAVE and not attack_effect_played and sprite.frame >= SHOCKWAVE_TRIGGER_FRAME:
		attack_effect_played = true
		_play_shockwave_effect()
		_damage_customers()
	elif current_state == STATE_POISON and not attack_effect_played and sprite.frame >= POISON_TRIGGER_FRAME:
		attack_effect_played = true
		_play_poison_effect()
		_damage_foods()
	elif current_state == STATE_SUMMON and not attack_effect_played and sprite.frame >= maxi(int(_get_frame_count(STATE_SUMMON) / 2), 0):
		attack_effect_played = true
		_summon_flies()

	if finished:
		attack_cooldown = randf_range(ATTACK_MIN_TIME, ATTACK_MAX_TIME)
		_set_state(STATE_FLYING, true)

func _process_attack_cooldown(delta: float) -> void:
	attack_cooldown -= delta
	if attack_cooldown > 0.0:
		return

	var choices: Array[String] = []
	if not get_tree().get_nodes_in_group("customers").is_empty():
		choices.append(STATE_SHOCKWAVE)
	if not get_tree().get_nodes_in_group("foods").is_empty():
		choices.append(STATE_POISON)
	choices.append(STATE_SUMMON)

	attack_cooldown = randf_range(ATTACK_MIN_TIME, ATTACK_MAX_TIME)
	if choices.is_empty() or randf() > 0.72:
		return

	_set_state(choices.pick_random(), true)

func _animate_state(delta: float, state_name: String, frame_time: float, loop: bool) -> bool:
	var frame_count := _get_frame_count(state_name)
	if frame_count <= 1:
		return not loop

	sprite_frame_timer += delta
	if sprite_frame_timer < frame_time:
		return false

	sprite_frame_timer = 0.0
	if loop:
		sprite.frame = (sprite.frame + 1) % frame_count
		return false

	sprite.frame += 1
	if sprite.frame >= frame_count:
		sprite.frame = frame_count - 1
		return true

	return false

func _set_state(state_name: String, force: bool = false) -> void:
	if not force and current_state == state_name:
		return

	current_state = state_name
	sprite.texture = _get_texture(state_name)
	sprite.hframes = _get_frame_count(state_name)
	sprite.vframes = 1
	sprite.frame = 0
	sprite_frame_timer = 0.0
	attack_effect_played = false
	_update_sprite_direction()

func _move_to_food(delta: float) -> void:
	var to_food := target_food.global_position - global_position
	var distance := to_food.length()
	if distance > _get_eat_distance():
		velocity = velocity.lerp(to_food.normalized() * BOSS_SPEED, 5.0 * delta)
		position += velocity * delta
		eating_time = 0.0
		_update_sprite_direction()
		_set_state(STATE_FLYING)
		return

	velocity = velocity.lerp(Vector2.ZERO, 8.0 * delta)
	_set_state(STATE_EATING)
	eating_time += delta
	bite_timer -= delta
	if bite_timer <= 0.0:
		bite_timer = BITE_INTERVAL
		if target_food.has_method("eat"):
			target_food.call("eat", BITE_DAMAGE)

	if eating_time >= 2.0:
		_leave_food()

func _wander(delta: float) -> void:
	position += velocity * delta
	_update_sprite_direction()
	_set_state(STATE_FLYING)

func _keep_inside_bounds() -> void:
	var margin := minf(BOSS_HITBOX_RADIUS * 0.45, 130.0)
	var min_x := movement_bounds.position.x + margin
	var max_x := maxf(movement_bounds.end.x - margin, min_x)
	var min_y := movement_bounds.position.y + margin
	var max_y := maxf(movement_bounds.end.y - margin, min_y)

	if position.x < min_x or position.x > max_x:
		velocity.x *= -1.0
		position.x = clampf(position.x, min_x, max_x)
	if position.y < min_y or position.y > max_y:
		velocity.y *= -1.0
		position.y = clampf(position.y, min_y, max_y)

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if is_invulnerable or is_dying:
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
		take_damage(damage_amount)

func take_damage(amount: int) -> void:
	if is_invulnerable or is_dying:
		return

	current_health -= amount
	if sfx_swat != null:
		sfx_swat.play()
	_update_health_bars()

	if current_health <= 0:
		_deplete_life_bar()
		return

	_start_knockback()

func _deplete_life_bar() -> void:
	current_health = 0
	_update_health_bars()

	if current_life_bar <= 0:
		died.emit(self)
		_play_death_animation()
		return

	current_life_bar -= 1
	is_invulnerable = true
	input_pickable = false
	stun_timer = STUN_DURATION
	velocity = Vector2.ZERO
	_set_state(STATE_STUN, true)

func _finish_revive() -> void:
	current_health = BOSS_HEALTH_PER_BAR
	is_invulnerable = false
	input_pickable = true
	_update_health_bars()
	_set_state(STATE_FLYING, true)

func _play_death_animation() -> void:
	is_dying = true
	is_invulnerable = true
	input_pickable = false
	velocity = Vector2.ZERO
	if collision_shape != null:
		collision_shape.disabled = true
	if health_bar_container != null:
		health_bar_container.visible = false
	_set_state(STATE_KILL, true)

func _update_health_bars() -> void:
	for index in range(health_bars.size()):
		var bar := health_bars[index]
		bar.max_value = BOSS_HEALTH_PER_BAR
		if index < current_life_bar:
			bar.value = BOSS_HEALTH_PER_BAR
		elif index == current_life_bar:
			bar.value = clampi(current_health, 0, BOSS_HEALTH_PER_BAR)
		else:
			bar.value = 0

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

	var choice_count := mini(valid_foods.size(), 3)
	return valid_foods[randi_range(0, choice_count - 1)]

func _is_food_valid(food: Variant) -> bool:
	if food == null or not is_instance_valid(food) or not (food is Node2D):
		return false
	return (food as Node2D).is_inside_tree()

func _damage_foods() -> void:
	for food in get_tree().get_nodes_in_group("foods"):
		if not is_instance_valid(food) or not food.has_method("eat"):
			continue
		var max_freshness_value = food.get("max_freshness")
		var max_freshness := float(max_freshness_value) if max_freshness_value != null else 100.0
		food.call("eat", max_freshness * POISON_FOOD_DAMAGE_RATIO)

func _damage_customers() -> void:
	for customer in get_tree().get_nodes_in_group("customers"):
		if not is_instance_valid(customer) or not customer.has_method("decrease_patience"):
			continue
		var max_patience_value = customer.get("max_patience")
		var max_patience := float(max_patience_value) if max_patience_value != null else 100.0
		customer.call("decrease_patience", max_patience * SHOCKWAVE_CUSTOMER_DAMAGE_RATIO)

func _summon_flies() -> void:
	for _index in range(SUMMON_COUNT):
		spawn_requested.emit(global_position, "")

func _play_poison_effect() -> void:
	poison_effect_playing = true
	poison_effect_timer = 0.0
	poison_effect_sprite.frame = 0
	poison_effect_sprite.visible = true

func _play_shockwave_effect() -> void:
	shockwave_effect_playing = true
	shockwave_effect_timer = 0.0
	shockwave_effect_sprite.frame = 0
	shockwave_effect_sprite.visible = true

func _update_effect_animations(delta: float) -> void:
	if poison_effect_playing:
		poison_effect_timer += delta
		var poison_frame := int(poison_effect_timer / EFFECT_FRAME_TIME)
		if poison_frame >= poison_effect_sprite.hframes:
			poison_effect_playing = false
			poison_effect_sprite.visible = false
		else:
			poison_effect_sprite.frame = poison_frame

	if shockwave_effect_playing:
		shockwave_effect_timer += delta
		var shockwave_frame := int(shockwave_effect_timer / EFFECT_FRAME_TIME)
		if shockwave_frame >= shockwave_effect_sprite.hframes:
			shockwave_effect_playing = false
			shockwave_effect_sprite.visible = false
		else:
			shockwave_effect_sprite.frame = shockwave_frame

func _scale_effect_sprite(effect_sprite: Sprite2D, target_size: float) -> void:
	if effect_sprite.texture == null:
		return

	var texture_size := effect_sprite.texture.get_size()
	var frame_width := texture_size.x / maxi(effect_sprite.hframes, 1)
	var frame_height := texture_size.y / maxi(effect_sprite.vframes, 1)
	var longest_side := maxf(frame_width, frame_height)
	if longest_side <= 0.0:
		return

	effect_sprite.scale = Vector2.ONE * (target_size / longest_side)

func _start_knockback() -> void:
	knockback_timer = KNOCKBACK_TIME
	eating_time = 0.0
	_set_state(STATE_FLYING)

	var direction := Vector2.RIGHT.rotated(randf_range(0.0, TAU))
	if _is_food_valid(target_food):
		direction = (global_position - target_food.global_position).normalized()
		if direction == Vector2.ZERO:
			direction = Vector2.RIGHT.rotated(randf_range(0.0, TAU))

	velocity = direction * KNOCKBACK_STRENGTH
	_update_sprite_direction()

func _leave_food() -> void:
	eating_time = 0.0
	target_food = null
	target_refresh_timer = TARGET_REFRESH_TIME
	velocity = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * BOSS_SPEED
	_update_sprite_direction()
	_set_state(STATE_FLYING)

func _get_eat_distance() -> float:
	return maxf(BASE_EAT_DISTANCE, BOSS_HITBOX_RADIUS * 0.55)

func _get_texture(asset_key: String) -> Texture2D:
	var asset = boss_assets.get(asset_key)
	if asset == null:
		return null
	return asset.texture

func _get_frame_count(asset_key: String) -> int:
	var asset = boss_assets.get(asset_key)
	if asset == null:
		return 1
	return maxi(int(asset.frame_count), 1)

func _update_sprite_direction() -> void:
	if sprite == null or absf(velocity.x) < 1.0:
		return
	sprite.flip_h = velocity.x > 0.0

func _get_swatter() -> Node:
	var swatters := get_tree().get_nodes_in_group("swatters")
	if swatters.is_empty():
		return null
	return swatters[0]
