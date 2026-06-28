extends Area2D

signal swatted(hand: Area2D)
# Emits a status string: "success" (bought), "disgusted" (lost patience), or "depleted" (food disappeared)
signal finished(hand: Area2D, status: String, payout: int)

const DEFAULT_TEXTURE := preload("res://assets/customer/default_customer/hand_default.png")
const DAMAGE_TEXTURE := preload("res://assets/customer/default_customer/hand_damage.png")
const HAND_CLOSED_TEXTURE := preload("res://assets/customer/default_customer/hand_closed.png")
const HAND_SCALE := Vector2(1.5, 1.5)
var FOOD_CARRY_OFFSET := Vector2(0, (DEFAULT_TEXTURE.get_height() * 0.5))
const DAMAGE_SHOW_TIME := 0.25 
const SPEED := 280.0
const BASE_MAX_PATIENCE := 100.0
const PATIENCE_LOSS_FROM_SWAT_RATIO := 0.0  # based original 0.5
const PATIENCE_LOSS_PER_FLY_SECOND := 0.0    # based original 8.0
const REACH_THRESHOLD := -2.0

const CUSTOMER_HAND_ASSET_SCRIPT := preload("res://Backend/Object Initialization/CustomerHand_Attributes.gd")
var customer_hand_assets: Dictionary = {}

var target_position := FOOD_CARRY_OFFSET
var velocity := Vector2.ZERO
var leaving := false
var damage_timer := 2.0
var leave_status := "" # Stores how they left

var max_patience := BASE_MAX_PATIENCE
var patience := BASE_MAX_PATIENCE
var target_food: Node2D = null
var has_reached_target := false
var flash_hurt_timer := 0.0
var patience_drain_multiplier := 1.0
var payout_multiplier := 1.0

var customer_asset: Object = null
var hand_scale := HAND_SCALE
var sfx_player: AudioStreamPlayer2D

var sprite: Sprite2D
var collision_shape: CollisionShape2D
var local_patience_bar: ProgressBar 

func _ready() -> void:
	input_pickable = true
	monitoring = true
	monitorable = true
	if customer_hand_assets.is_empty():
		var asset_holder = CUSTOMER_HAND_ASSET_SCRIPT.new()
		if asset_holder:
			var loaded_assets = asset_holder.get("Customers")
			if typeof(loaded_assets) == TYPE_DICTIONARY:
				customer_hand_assets = loaded_assets
		if customer_hand_assets.is_empty():
			customer_hand_assets = {}
	_pick_random_customer_asset()
	_ensure_nodes()
	add_to_group("customers")

func configure(start_position: Vector2, food_node: Node2D, new_patience_drain_multiplier: float = 1.0, new_payout_multiplier: float = 1.0, new_max_patience: float = BASE_MAX_PATIENCE) -> void:
	position = start_position
	target_food = food_node
	patience_drain_multiplier = new_patience_drain_multiplier
	payout_multiplier = new_payout_multiplier
	max_patience = maxf(new_max_patience, 1.0)
	patience = max_patience
	
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
		

func _get_hitbox_extents(node: Node2D) -> Vector2:
	var food_cs := node.get_node_or_null("CollisionShape2D")
	if food_cs and food_cs.shape:
		if food_cs.shape is RectangleShape2D:
			return food_cs.shape.extents / 3.0
			
		if food_cs.shape is CircleShape2D:
			var temp = food_cs.shape.radius / 3.0
			return Vector2(temp, temp)
	return Vector2.ZERO

func _pick_random_customer_asset() -> void:
	if customer_asset != null:
		return

	var keys: Array = customer_hand_assets.keys()
	if keys.is_empty():
		return

	customer_asset = customer_hand_assets[keys[randi() % keys.size()]]
	if customer_asset and customer_asset.scale != Vector2.ZERO:
		hand_scale = customer_asset.scale

func _process(delta: float) -> void:
	if local_patience_bar:
		local_patience_bar.max_value = max_patience
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
			sprite.texture = customer_asset.default_texture if customer_asset and customer_asset.default_texture else DEFAULT_TEXTURE

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

		# Use the target food hitbox for reach checks, not just the food center.
		var reach_check_distance: float = maxf(SPEED * delta, REACH_THRESHOLD)
		var hand_half_size: Vector2 = _get_hitbox_extents(self)
		if hand_half_size == Vector2.ZERO and collision_shape and collision_shape.shape:
			hand_half_size = Vector2(collision_shape.shape.extents.x, collision_shape.shape.extents.y) if collision_shape.shape is RectangleShape2D else Vector2.ZERO
		var food_half_size: Vector2 = Vector2.ZERO
		if is_instance_valid(target_food):
			food_half_size = _get_hitbox_extents(target_food)
		var x_distance: float = abs(position.x - target_position.x)
		var y_distance: float = abs(position.y - target_position.y)
		if x_distance <= hand_half_size.x + food_half_size.x and y_distance <= hand_half_size.y + food_half_size.y + reach_check_distance:
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
		decrease_patience(PATIENCE_LOSS_PER_FLY_SECOND * fly_count * patience_drain_multiplier * delta)

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
	if status == "disgusted":
		sprite.texture = customer_asset.damage_texture if customer_asset and customer_asset.damage_texture else DAMAGE_TEXTURE
	elif status == "success":
		sprite.texture = customer_asset.closed_texture if customer_asset and customer_asset.closed_texture else HAND_CLOSED_TEXTURE
	else:
		sprite.texture = customer_asset.default_texture if customer_asset and customer_asset.default_texture else DEFAULT_TEXTURE
	
	# Emit completion stats immediately so Game.gd updates right away
	finished.emit(self, status, payout)

func _complete_transaction() -> void:
	if is_instance_valid(target_food):
		var product_value: int = target_food.call("get_current_value")
		var satisfaction_modifier := patience / max_patience
		var final_payout := int(float(product_value) * satisfaction_modifier * payout_multiplier)

		var food_container = target_food.get_parent()
		if food_container:
			food_container.remove_child(target_food)
			target_food.remove_from_group("foods")
			target_food.z_index = -1
			add_child(target_food)
			target_food.position = FOOD_CARRY_OFFSET
			if target_food.has_node("CollisionShape2D"):
				target_food.get_node("CollisionShape2D").disabled = true
			if target_food.get_node_or_null("ProgressBar"):
				target_food.get_node("ProgressBar").visible = false
			if target_food.get_node_or_null("Label"):
				target_food.get_node("Label").visible = false

		# Show the closed hand texture while carrying the food
		sprite.texture = customer_asset.closed_texture if customer_asset and customer_asset.closed_texture else HAND_CLOSED_TEXTURE
		_trigger_leave("success", final_payout)
	else:
		_trigger_leave("depleted", 0)

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if leaving:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var swatter := _get_swatter()
		if swatter == null:
			return
		var swat_is_active := swatter.has_method("is_swat_active") and bool(swatter.call("is_swat_active"))
		if not swat_is_active and not swatter.call("swat"):
			return

		swatted.emit(self)
		sprite.texture = customer_asset.damage_texture if customer_asset and customer_asset.damage_texture else DAMAGE_TEXTURE
		if sfx_player and sfx_player.stream:
			sfx_player.play()
		flash_hurt_timer = DAMAGE_SHOW_TIME
		decrease_patience(max_patience * PATIENCE_LOSS_FROM_SWAT_RATIO)

func _ensure_nodes() -> void:
	_pick_random_customer_asset()

	if sprite == null:
		sprite = Sprite2D.new()
		if customer_asset and customer_asset.default_texture:
			sprite.texture = customer_asset.default_texture
		else:
			sprite.texture = DEFAULT_TEXTURE
		sprite.scale = hand_scale
		add_child(sprite)

	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		# Size the rectangle from the hand texture, applying the hand scale
		var texture_source: Texture2D = customer_asset.default_texture if customer_asset and customer_asset.default_texture else DEFAULT_TEXTURE
		var tex_size: Vector2 = texture_source.get_size()
		var scaled_size: Vector2 = tex_size * hand_scale
		rect.extents = scaled_size / 2.0
		collision_shape.shape = rect
		add_child(collision_shape)

	if sfx_player == null:
		sfx_player = AudioStreamPlayer2D.new()
		if customer_asset and customer_asset.hit_sfx_path != "":
			sfx_player.stream = load(customer_asset.hit_sfx_path)
		add_child(sfx_player)

	if local_patience_bar == null:
		local_patience_bar = ProgressBar.new()
		local_patience_bar.max_value = max_patience
		local_patience_bar.value = patience
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
