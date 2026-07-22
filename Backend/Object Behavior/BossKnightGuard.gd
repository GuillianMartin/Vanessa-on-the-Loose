extends Area2D

signal died(guard: Area2D)

const KNIGHT_FLY_TEXTURE := preload("res://assets/Flies/knight/knight_fly.png")
const KNIGHT_FLY_DAMAGE_TEXTURE := preload("res://assets/Flies/knight/knight_fly_damage.png")

const KNIGHT_FLY_FRAME_COUNT := 6
const KNIGHT_FLY_DAMAGE_FRAME_COUNT := 4
const KNIGHT_FLY_FRAME_TIME := 0.06
const KNIGHT_FLY_DAMAGE_FRAME_TIME := 0.05

const KNIGHT_SPEED := 520.0
const KNIGHT_PROTECT_SPEED := 900.0
const KNIGHT_HITBOX_RADIUS := 40.0
const KNIGHT_IMAGE_SCALE := Vector2(0.55, 0.55)
const KNIGHT_ROAM_RADIUS := 180.0
const KNIGHT_PROTECT_RADIUS := 55.0
const KNIGHT_BLINK_DURATION := 0.28

var health := 1
var max_health := 1
var movement_bounds := Rect2(Vector2.ZERO, Vector2(1152, 648))
var velocity := Vector2.ZERO
var center_point := Vector2.ZERO
var boss_ref: Node2D
var orbit_angle := 0.0
var sprite_frame_timer := 0.0
var blink_timer := 0.0
var is_blinking := false
var is_dying := false
var is_invulnerable := false
var is_protecting := false
var fan_timer := 0.0
var fan_direction := 0.0

var sprite: Sprite2D
var collision_shape: CollisionShape2D

var sfx_swat: AudioStreamPlayer2D

func _ready() -> void:
	input_pickable = true
	monitoring = true
	monitorable = true
	add_to_group("knight_guards")
	add_to_group("flies")

	if get_parent() != null and get_parent().get_parent() != null:
		sfx_swat = get_parent().get_parent().get_node_or_null("sfx_swat") as AudioStreamPlayer2D

	_ensure_nodes()
	velocity = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * KNIGHT_SPEED
	orbit_angle = randf_range(0.0, TAU)
	blink_timer = 0.0
	_update_sprite_direction()

func configure(bounds: Rect2, boss_position: Vector2, guard_health: int, guard_center: Vector2 = Vector2.ZERO, boss: Node2D = null) -> void:
	movement_bounds = bounds
	max_health = maxi(guard_health, 1)
	health = max_health
	boss_ref = boss
	center_point = guard_center if guard_center != Vector2.ZERO else boss_position
	if is_node_ready():
		_update_health_bar()

func _ensure_nodes() -> void:
	sprite = get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
	sprite.scale = KNIGHT_IMAGE_SCALE
	sprite.z_index = 2
	_set_sprite_state(KNIGHT_FLY_TEXTURE, KNIGHT_FLY_FRAME_COUNT)

	collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		add_child(collision_shape)
	var circle := collision_shape.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
		collision_shape.shape = circle
	circle.radius = KNIGHT_HITBOX_RADIUS

	if not has_node("HealthBar"):
		var bar := ProgressBar.new()
		bar.name = "HealthBar"
		bar.show_percentage = false
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.size = Vector2(52, 7)
		bar.position = Vector2(-26, -50)
		add_child(bar)
		_update_health_bar()

func _process(delta: float) -> void:
	if is_dying:
		return

	if is_blinking:
		_animate_blink(delta)
	elif fan_timer > 0.0:
		_process_fan(delta)
	else:
		_animate_roam(delta)
		if is_protecting:
			_protect(delta)
		else:
			_roam(delta)

func _roam(delta: float) -> void:
	orbit_angle += delta * KNIGHT_ROAM_RADIUS * 0.01
	var orbit_target := center_point + Vector2.RIGHT.rotated(orbit_angle) * KNIGHT_ROAM_RADIUS
	var steering := (orbit_target - global_position).normalized() * KNIGHT_SPEED
	velocity = velocity.lerp(steering, 4.0 * delta)
	position += velocity * delta
	_update_sprite_direction()
	_keep_inside_bounds()

func _protect(delta: float) -> void:
	if boss_ref != null and is_instance_valid(boss_ref):
		center_point = boss_ref.global_position
	orbit_angle += delta * 90.0
	var orbit_target := center_point + Vector2.RIGHT.rotated(orbit_angle) * KNIGHT_PROTECT_RADIUS
	var steering := (orbit_target - global_position).normalized() * KNIGHT_PROTECT_SPEED
	velocity = velocity.lerp(steering, 10.0 * delta)
	position += velocity * delta
	_update_sprite_direction()
	_keep_inside_bounds()

func apply_big_fan(direction: float, _target_x: float, strength: float, duration: float = 1.4) -> void:
	fan_timer = maxf(duration, 0.0)
	fan_direction = direction
	velocity = Vector2(fan_direction * strength, 0.0)

func _process_fan(delta: float) -> void:
	fan_timer -= delta
	position += Vector2(fan_direction * KNIGHT_PROTECT_SPEED, velocity.y * 0.4) * delta
	_update_sprite_direction()
	_keep_inside_bounds()

func _keep_inside_bounds() -> void:
	var margin := minf(KNIGHT_HITBOX_RADIUS * 0.45, 130.0)
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

func set_center_point(new_center: Vector2) -> void:
	center_point = new_center

func play_blink() -> void:
	is_blinking = true
	blink_timer = KNIGHT_BLINK_DURATION
	_set_sprite_state(KNIGHT_FLY_DAMAGE_TEXTURE, KNIGHT_FLY_DAMAGE_FRAME_COUNT)

func _set_sprite_state(texture: Texture2D, frame_count: int) -> void:
	if sprite == null:
		return
	sprite.texture = texture
	sprite.hframes = maxi(frame_count, 1)
	sprite.vframes = 1
	sprite.frame = clampi(0, 0, maxi(frame_count - 1, 0))
	sprite_frame_timer = 0.0
	_update_sprite_direction()

func _animate_blink(delta: float) -> void:
	blink_timer -= delta
	sprite_frame_timer += delta
	if sprite_frame_timer < KNIGHT_FLY_DAMAGE_FRAME_TIME:
		return
	sprite_frame_timer = 0.0
	var next_frame := sprite.frame + 1
	if next_frame >= KNIGHT_FLY_DAMAGE_FRAME_COUNT:
		is_blinking = false
		_set_sprite_state(KNIGHT_FLY_TEXTURE, KNIGHT_FLY_FRAME_COUNT)
		return
	sprite.frame = next_frame

func _animate_roam(delta: float) -> void:
	sprite_frame_timer += delta
	if sprite_frame_timer < KNIGHT_FLY_FRAME_TIME:
		return
	sprite_frame_timer = 0.0
	sprite.frame = (sprite.frame + 1) % KNIGHT_FLY_FRAME_COUNT

func _update_sprite_direction() -> void:
	if sprite == null or absf(velocity.x) < 1.0:
		return
	sprite.flip_h = velocity.x > 0.0

func _update_health_bar() -> void:
	var bar := get_node_or_null("HealthBar") as ProgressBar
	if bar == null:
		return
	bar.max_value = max_health
	bar.value = max(health, 0)
	bar.visible = true

func take_damage(amount: int) -> void:
	if is_dying:
		return

	if is_invulnerable:
		if is_protecting:
			play_blink()
		return

	health -= amount
	if sfx_swat != null:
		sfx_swat.play()
	_update_health_bar()
	play_blink()

	if health <= 0:
		died.emit(self)
		_play_death_animation()

func _play_death_animation() -> void:
	is_dying = true
	input_pickable = false
	if collision_shape != null:
		collision_shape.disabled = true
	var bar := get_node_or_null("HealthBar") as ProgressBar
	if bar != null:
		bar.visible = false
	queue_free()

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if is_dying:
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

func set_invulnerable(value: bool) -> void:
	is_invulnerable = value
	is_protecting = value
	if is_protecting:
		orbit_angle = randf_range(0.0, TAU)
		play_blink()

func intercept_attack(boss_position: Vector2, amount: int) -> void:
	if is_dying:
		return
	global_position = boss_position
	play_blink()
	take_damage(amount)

func _get_swatter() -> Node:
	var swatters := get_tree().get_nodes_in_group("swatters")
	if swatters.is_empty():
		return null
	return swatters[0]
