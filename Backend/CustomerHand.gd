extends Area2D

signal swatted(hand: Area2D)
# Emits a status string: "success" (bought), "disgusted" (lost patience), or "depleted" (food disappeared)
signal finished(hand: Area2D, status: String, payout: int)

const DEFAULT_TEXTURE := preload("res://assets/customer/default_customer/hand_default.png")
const DAMAGE_TEXTURE := preload("res://assets/customer/default_customer/hand_damage.png")
const HAND_SCALE := Vector2(0.7, 0.7)
const HIT_RADIUS := 48.0
const SPEED := 280.0
const DAMAGE_SHOW_TIME := 0.25 

const MAX_PATIENCE := 100.0
const PATIENCE_LOSS_FROM_SWAT := 20.0       
const PATIENCE_LOSS_PER_FLY_SECOND := 1.0   
const REACH_THRESHOLD := 15.0

var target_position := Vector2.ZERO
var velocity := Vector2.ZERO
var leaving := false
var damage_timer := 0.0
var leave_status := "" # Stores how they left

var patience := MAX_PATIENCE                
var target_food: Node2D = null
var has_reached_target := false
var flash_hurt_timer := 0.0

var sprite: Sprite2D
var collision_shape: CollisionShape2D
var local_patience_bar: ProgressBar 

func _ready() -> void:
	input_pickable = true
	monitoring = true
	monitorable = true
	_ensure_nodes()
	add_to_group("customers")

func configure(start_position: Vector2, food_node: Node2D) -> void:
	position = start_position
	target_food = food_node
	
	if is_instance_valid(target_food):
		target_position = target_food.global_position
	else:
		target_position = position

	var direction := (target_position - position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.LEFT
	velocity = direction * SPEED

	if is_node_ready():
		_ensure_nodes()

func _process(delta: float) -> void:
	if local_patience_bar:
		local_patience_bar.value = patience
		var fill_sb = local_patience_bar.get_theme_stylebox("fill") as StyleBoxFlat
		if fill_sb:
			if patience > 50.0:
				fill_sb.bg_color = Color(0.2, 0.8, 0.2)
			elif patience > 25.0:
				fill_sb.bg_color = Color(0.9, 0.6, 0.1)
			else:
				fill_sb.bg_color = Color(0.8, 0.1, 0.1)

	if flash_hurt_timer > 0.0:
		flash_hurt_timer -= delta
		if flash_hurt_timer <= 0.0 and not leaving:
			sprite.texture = DEFAULT_TEXTURE

	if not leaving:
		_process_fly_contamination(delta)

	# Moving back up off-screen
	if leaving:
		damage_timer -= delta
		position += Vector2.UP * SPEED * 0.9 * delta
		if damage_timer <= 0.0:
			queue_free()
		return

	# Pathing toward food
	if not has_reached_target:
		position += velocity * delta
		
		if not is_instance_valid(target_food):
			_trigger_leave("depleted", 0)
			return

		if position.distance_to(target_position) <= maxf(SPEED * delta, REACH_THRESHOLD):
			has_reached_target = true
			_complete_transaction()

func _process_fly_contamination(delta: float) -> void:
	var fly_count := 0
	for area in get_overlapping_areas():
		# 1. Check if it's explicitly in our designated group
		var is_fly_group := area.is_in_group("flies")
		
		# 2. Check if the object's class script path points to our fly logic
		var is_fly_script := false
		if area.get_script() and area.get_script().resource_path.to_lower().contains("fly"):
			is_fly_script = true
			
		if is_fly_group or is_fly_script:
			fly_count += 1

	if fly_count > 0:
		# Directly ticks down patience based on current local nesting pests
		decrease_patience(PATIENCE_LOSS_PER_FLY_SECOND * fly_count * delta)

func decrease_patience(amount: float) -> void:
	if leaving:
		return
	patience = maxf(patience - amount, 0.0)

	var game_root = get_tree().current_scene
	if game_root and game_root.has_method("_update_hud"):
		game_root.call("_update_hud")

	if patience <= 0.0:
		_trigger_leave("disgusted", 0)

func _trigger_leave(status: String, payout: int) -> void:
	if leaving: return
	leaving = true
	leave_status = status
	damage_timer = DAMAGE_SHOW_TIME * 2.5
	sprite.texture = DAMAGE_TEXTURE if status == "disgusted" else DEFAULT_TEXTURE
	
	# Emit completion stats immediately so Game.gd updates right away
	finished.emit(self, status, payout)

func _complete_transaction() -> void:
	if is_instance_valid(target_food):
		var product_value: int = target_food.call("get_current_value")
		var satisfaction_modifier := patience / MAX_PATIENCE
		var final_payout := int(float(product_value) * satisfaction_modifier)

		var food_container = target_food.get_parent()
		if food_container:
			food_container.remove_child(target_food)
			add_child(target_food)
			target_food.position = Vector2.ZERO 
			if target_food.has_node("CollisionShape2D"):
				target_food.get_node("CollisionShape2D").disabled = true
			if target_food.get_node_or_null("ProgressBar"):
				target_food.get_node("ProgressBar").visible = false
			if target_food.get_node_or_null("Label"):
				target_food.get_node("Label").visible = false

		# Start moving up with the food item safely, marked as "success"
		_trigger_leave("success", final_payout)
	else:
		_trigger_leave("depleted", 0)

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if leaving:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var swatter := _get_swatter()
		if swatter == null or not swatter.call("can_attack"):
			return

		swatted.emit(self)
		sprite.texture = DAMAGE_TEXTURE
		flash_hurt_timer = DAMAGE_SHOW_TIME
		decrease_patience(PATIENCE_LOSS_FROM_SWAT)

func _ensure_nodes() -> void:
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.texture = DEFAULT_TEXTURE
		sprite.scale = HAND_SCALE
		add_child(sprite)

	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = HIT_RADIUS
		collision_shape.shape = circle
		add_child(collision_shape)

	if local_patience_bar == null:
		local_patience_bar = ProgressBar.new()
		local_patience_bar.max_value = MAX_PATIENCE
		local_patience_bar.value = MAX_PATIENCE
		local_patience_bar.show_percentage = false
		local_patience_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		local_patience_bar.custom_minimum_size = Vector2(50, 6)
		local_patience_bar.position = Vector2(-25, -70)
		
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.2, 0.8, 0.2)
		local_patience_bar.add_theme_stylebox_override("fill", sb)
		add_child(local_patience_bar)

func _get_swatter() -> Node:
	var swatters := get_tree().get_nodes_in_group("swatters")
	if swatters.is_empty():
		return null
	return swatters[0]
