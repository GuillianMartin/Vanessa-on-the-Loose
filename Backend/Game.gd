extends Node2D

const FLY_SCENE := preload("res://Objects/Fly.tscn")
const FOOD_SCRIPT := preload("res://Backend/Food_behavior.gd")
const CUSTOMER_HAND_SCRIPT := preload("res://Backend/CustomerHand.gd")
const SWATTER_SCRIPT := preload("res://Backend/Swatter.gd")
const SWATTER_DEFAULT_TEXTURE := preload("res://assets/weapon/swatter/swatter_default.png")
const SWATTER_ATTACK_TEXTURE := preload("res://assets/weapon/swatter/swatter_attack.png")

const ROUND_FLY_COUNT := 20
const ROUND_FOOD_COUNT := 15
const TOP_SAFE_AREA := 72.0
const EDGE_PADDING := 70.0
const FOOD_GAP := 10.0
const FOOD_PLACEMENT_ATTEMPTS := 500
const SWATTER_ATTACK_FRAMES := 4
const SWATTER_ATTACK_FRAME_TIME := 0.045
const SWATTER_OFFSET := Vector2(34, 34)
const CUSTOMER_SPAWN_MIN_TIME := 1.2
const CUSTOMER_SPAWN_MAX_TIME := 3.2
const MAX_ACTIVE_CUSTOMERS := 5

# --- New Gameplay Mode Parameters ---
const GAME_DURATION_SECONDS := 180.0 # 3 Minutes match clock
var game_timer := 0.0

var current_money := 0
var money_goal := 150
var buyers_remaining := 25

var score := 0
var flies_left := 0
var round_active := false

# Platter placement memory tracking storage
var active_placed_food_records: Array[Dictionary] = []

var food_container: Node2D
var fly_container: Node2D
var customer_container: Node2D
var container_area: Area2D
var container_polygon: CollisionPolygon2D
var hud_layer: CanvasLayer
var menu_layer: CanvasLayer

# --- HUD Nodes ---
var score_label: Label
var flies_label: Label
var money_label: Label
var buyers_label: Label
var match_timer_label: Label # Added for clock tracking
var menu_title: Label
var result_label: Label
var play_button: Button
var swatter_layer: CanvasLayer
var swatter_sprite: Sprite2D
var swatter_entity: Node
var swatter_energy_bar: ProgressBar
var global_patience_bar: ProgressBar
var swatter_energy_label: Label
var swatter_attack_timer := 0.0
var swatter_frame_timer := 0.0
var customer_spawn_timer := 0.0

func _ready() -> void:
	randomize()
	_build_game_nodes()
	_build_swatter()
	_build_hud()
	_build_menu()
	_show_menu()

func _process(delta: float) -> void:
	if not round_active:
		return
		
	_update_swatter(delta)
	_update_customer_spawns(delta)
	_process_match_clock(delta)
	_maintain_food_loop()
	_maintain_fly_loop()

func _input(event: InputEvent) -> void:
	if not round_active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_start_swatter_attack()

func _process_match_clock(delta: float) -> void:
	game_timer -= delta
	_update_hud()
	
	if game_timer <= 0.0:
		if current_money >= money_goal:
			_show_menu(score, true)
		else:
			_show_menu(score, false)

func _maintain_food_loop() -> void:
	# Automatically spawns a food item back if count drops below threshold
	if _get_active_food_count() < 4:
		_spawn_single_food_loop()

func _maintain_fly_loop() -> void:
	# Only spawn reinforcements if the board drops to critically low fly levels
	if flies_left < 5:
		var bounds := _get_fly_bounds()
		for i in range(4):
			_spawn_fly(
				Vector2(randf_range(bounds.position.x, bounds.end.x), randf_range(bounds.position.y, bounds.end.y)),
				bounds,
				false
			)
			flies_left += 1
		_update_hud()

func _build_game_nodes() -> void:
	var background := get_node_or_null("Sprite2D") as Sprite2D
	if background != null:
		background.z_index = -30

	container_area = get_node_or_null("Container") as Area2D
	if container_area != null:
		container_area.z_index = -10
		container_polygon = container_area.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D

	food_container = Node2D.new()
	food_container.name = "Food"
	food_container.z_index = 0
	add_child(food_container)

	fly_container = Node2D.new()
	fly_container.name = "Flies"
	fly_container.z_index = 20
	add_child(fly_container)

	customer_container = Node2D.new()
	customer_container.name = "Customers"
	customer_container.z_index = 30
	add_child(customer_container)

func _build_swatter() -> void:
	swatter_entity = SWATTER_SCRIPT.new()
	swatter_entity.name = "SwatterEnergy"
	swatter_entity.connect("energy_changed", _on_swatter_energy_changed)
	add_child(swatter_entity)

	swatter_layer = CanvasLayer.new()
	swatter_layer.name = "Swatter"
	swatter_layer.layer = 100
	add_child(swatter_layer)

	swatter_sprite = Sprite2D.new()
	swatter_sprite.texture = SWATTER_DEFAULT_TEXTURE
	swatter_sprite.centered = false
	swatter_sprite.offset = -SWATTER_OFFSET
	swatter_sprite.visible = false
	swatter_layer.add_child(swatter_sprite)

func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "HUD"
	add_child(hud_layer)

	var top_bar := PanelContainer.new()
	top_bar.name = "TopBar"
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 48
	hud_layer.add_child(top_bar)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	top_bar.add_child(margin)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	margin.add_child(row)

	score_label = Label.new()
	score_label.text = "Score: 0"
	score_label.custom_minimum_size = Vector2(100, 0)
	row.add_child(score_label)

	flies_label = Label.new()
	flies_label.text = "Flies: 0"
	flies_label.custom_minimum_size = Vector2(90, 0)
	row.add_child(flies_label)

	money_label = Label.new()
	money_label.text = "Money: $0/$150"
	money_label.custom_minimum_size = Vector2(150, 0)
	row.add_child(money_label)

	buyers_label = Label.new()
	buyers_label.text = "Buyers Left: 10"
	buyers_label.custom_minimum_size = Vector2(130, 0)
	row.add_child(buyers_label)

	match_timer_label = Label.new()
	match_timer_label.text = "Time: 3:00"
	match_timer_label.custom_minimum_size = Vector2(110, 0)
	row.add_child(match_timer_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	swatter_energy_label = Label.new()
	swatter_energy_label.text = "Energy"
	row.add_child(swatter_energy_label)

	swatter_energy_bar = ProgressBar.new()
	swatter_energy_bar.show_percentage = false
	swatter_energy_bar.custom_minimum_size = Vector2(140, 12)
	swatter_energy_bar.max_value = 100.0
	swatter_energy_bar.value = 100.0
	row.add_child(swatter_energy_bar)

func _build_menu() -> void:
	menu_layer = CanvasLayer.new()
	menu_layer.name = "Menu"
	add_child(menu_layer)

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.45)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 230)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)

	menu_title = Label.new()
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_title.text = "Bangaw"
	content.add_child(menu_title)

	result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.text = ""
	content.add_child(result_label)

	play_button = Button.new()
	play_button.text = "Play"
	play_button.custom_minimum_size = Vector2(180, 44)
	play_button.pressed.connect(_start_round)
	content.add_child(play_button)

func _show_menu(final_score: int = -1, victory: bool = false) -> void:
	round_active = false
	_set_swatter_active(false)
	menu_layer.visible = true
	hud_layer.visible = false
	fly_container.visible = false
	_clear_flies()
	_clear_food()
	_clear_customers()

	if victory:
		menu_title.text = "Victory!"
		result_label.text = "Target Met! Earned: $%d\nFlies Swatted: %d" % [current_money, final_score]
		play_button.text = "Play Again"
	elif final_score >= 0:
		menu_title.text = "Game Over"
		result_label.text = "Time ran out! Earned: $%d\nGoal: $%d" % [current_money, money_goal]
		play_button.text = "Try Again"
	else:
		menu_title.text = "Bangaw"
		result_label.text = ""
		play_button.text = "Play"

func _start_round() -> void:
	score = 0
	current_money = 0
	buyers_remaining = 15
	flies_left = ROUND_FLY_COUNT
	game_timer = GAME_DURATION_SECONDS
	active_placed_food_records.clear()
	customer_spawn_timer = randf_range(CUSTOMER_SPAWN_MIN_TIME, CUSTOMER_SPAWN_MAX_TIME)
	
	swatter_entity.call("reset")
	round_active = true
	_set_swatter_active(true)
	menu_layer.visible = false
	hud_layer.visible = true
	food_container.visible = true
	fly_container.visible = true
	customer_container.visible = true
	_update_hud()
	_spawn_food()
	_spawn_flies()

func _spawn_flies() -> void:
	_clear_flies()
	var bounds := _get_fly_bounds()
	for _index in range(ROUND_FLY_COUNT):
		_spawn_fly(
			Vector2(randf_range(bounds.position.x, bounds.end.x), randf_range(bounds.position.y, bounds.end.y)),
			bounds,
			false,
			_index == 0
		)

func _get_fly_bounds() -> Rect2:
	var viewport_size := get_viewport_rect().size
	return Rect2(
		Vector2(EDGE_PADDING, TOP_SAFE_AREA + EDGE_PADDING),
		Vector2(max(viewport_size.x - EDGE_PADDING * 2.0, 1.0), max(viewport_size.y - TOP_SAFE_AREA - EDGE_PADDING * 2.0, 1.0))
	)

func _spawn_fly(spawn_position: Vector2, bounds: Rect2, include_mother: bool, force_mother: bool = false) -> void:
	var fly = FLY_SCENE.instantiate()
	fly.position = Vector2(clampf(spawn_position.x, bounds.position.x, bounds.end.x), clampf(spawn_position.y, bounds.position.y, bounds.end.y))
	var new_behavior = fly.get_forced_mother_behavior() if force_mother else fly.get_random_behavior(include_mother)
	fly.configure(new_behavior, bounds)
	fly.died.connect(_on_fly_died)
	fly.spawn_requested.connect(_on_fly_spawn_requested)
	fly_container.add_child(fly)

func _spawn_food() -> void:
	_clear_food()
	var polygon := _get_container_polygon_global()
	if polygon.size() < 3: return

	for _index in range(ROUND_FOOD_COUNT):
		_spawn_single_food_loop()

func _spawn_single_food_loop() -> void:
	var polygon := _get_container_polygon_global()
	var config = FOOD_SCRIPT.get_random_config()
	
	for _attempt in range(FOOD_PLACEMENT_ATTEMPTS):
		var candidate := _get_random_point_in_polygon(polygon, config.radius)
		if _is_food_position_clear(candidate, config.radius, polygon, active_placed_food_records):
			var food := FOOD_SCRIPT.new() as Node2D
			food.position = candidate
			food.call("configure", config)
			food.connect("depleted", _on_food_depleted)
			food_container.add_child(food)
			
			active_placed_food_records.append({
				"node_ref": food,
				"position": candidate,
				"radius": config.radius,
			})
			break

func _clear_flies() -> void:
	if fly_container:
		for child in fly_container.get_children(): child.queue_free()

func _clear_food() -> void:
	if food_container:
		for child in food_container.get_children(): child.queue_free()

func _clear_customers() -> void:
	if customer_container:
		for child in customer_container.get_children(): child.queue_free()

func _on_food_depleted(food_node: Area2D) -> void:
	# Clean out dead records from space checking
	active_placed_food_records = active_placed_food_records.filter(func(item): return is_instance_valid(item["node_ref"]) and item["node_ref"] != food_node)

func _on_fly_died(_fly: Area2D) -> void:
	if not round_active: return
	score += 1
	flies_left -= 1
	if swatter_entity != null:
		swatter_entity.call("register_fly_kill")
	_update_hud()

func _on_fly_spawn_requested(spawn_position: Vector2) -> void:
	if not round_active: return
	var bounds := _get_fly_bounds()
	var offset := Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(70.0, 120.0)
	_spawn_fly(spawn_position + offset, bounds, false)
	flies_left += 1
	_update_hud()

func _update_hud() -> void:
	if score_label: score_label.text = "Score: %d" % score
	if flies_label: flies_label.text = "Flies: %d" % flies_left
	if money_label: money_label.text = "Money: $%d/$%d" % [current_money, money_goal]
	if buyers_label: buyers_label.text = "Buyers Left: %d" % buyers_remaining
	
	if match_timer_label:
		var minutes := int(maxf(game_timer, 0.0)) / 60
		var seconds := int(maxf(game_timer, 0.0)) % 60
		match_timer_label.text = "Time: %d:%02d" % [minutes, seconds]

func _update_customer_spawns(delta: float) -> void:
	if not round_active or customer_container == null: return
	customer_spawn_timer -= delta
	if customer_spawn_timer <= 0.0:
		_spawn_customer_hand()
		customer_spawn_timer = randf_range(CUSTOMER_SPAWN_MIN_TIME, CUSTOMER_SPAWN_MAX_TIME)

func _spawn_customer_hand() -> void:
	if _get_active_customer_count() >= MAX_ACTIVE_CUSTOMERS or buyers_remaining <= 0:
		return

	var foods = food_container.get_children()
	if foods.is_empty(): return

	var random_food = foods.pick_random() as Node2D
	var viewport_size := get_viewport_rect().size
	var start_position := Vector2(randf_range(viewport_size.x * 0.4, viewport_size.x * 0.8), -80.0)

	var hand = CUSTOMER_HAND_SCRIPT.new() as Area2D
	hand.call("configure", start_position, random_food)
	hand.connect("swatted", _on_customer_swatted)
	hand.connect("finished", _on_buyer_transaction_finished)
	customer_container.add_child(hand)
	
	_update_hud()

func _on_buyer_transaction_finished(hand_node: Area2D, status: String, payout: int) -> void:
	if status == "success":
		current_money += payout
		# Clean table position data structures
		active_placed_food_records = active_placed_food_records.filter(
			func(item): return is_instance_valid(item["node_ref"]) and item["node_ref"] != hand_node.target_food
		)
	elif status == "disgusted":
		# Only penalize the remaining pool if you completely push them away with swats/flies!
		buyers_remaining = max(buyers_remaining - 1, 0)

	_update_hud()

	# Game endings checking
	if current_money >= money_goal:
		_show_menu(score, true)
	elif buyers_remaining <= 0 and _get_active_customer_count() == 0:
		_show_menu(score, current_money >= money_goal)

func _on_customer_swatted(_hand: Area2D) -> void:
	if swatter_entity != null:
		swatter_entity.call("hit_customer")

func _on_swatter_energy_changed(energy: float, max_energy: float) -> void:
	if swatter_energy_bar:
		swatter_energy_bar.max_value = max_energy
		swatter_energy_bar.value = energy

func _get_active_customer_count() -> int:
	if customer_container == null: return 0
	var count := 0
	for customer in customer_container.get_children():
		if not customer.is_queued_for_deletion(): count += 1
	return count

func _get_container_polygon_global() -> PackedVector2Array:
	var points := PackedVector2Array()
	if container_polygon == null: return points
	for point in container_polygon.polygon:
		points.append(container_polygon.to_global(point))
	return points

func _get_random_point_in_polygon(polygon: PackedVector2Array, radius: float = 0.0) -> Vector2:
	var bounds := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon: bounds = bounds.expand(point)
	for _attempt in range(80):
		var point := Vector2(randf_range(bounds.position.x + radius, bounds.end.x - radius), randf_range(bounds.position.y + radius, bounds.end.y - radius))
		if _is_circle_inside_polygon(point, radius, polygon): return point
	return bounds.get_center()

func _is_food_position_clear(candidate: Vector2, candidate_radius: float, polygon: PackedVector2Array, placed_food: Array[Dictionary]) -> bool:
	if not _is_circle_inside_polygon(candidate, candidate_radius, polygon): return false
	for placed in placed_food:
		if not is_instance_valid(placed["node_ref"]): continue
		var minimum_distance := candidate_radius + float(placed["radius"]) + FOOD_GAP
		if candidate.distance_to(placed["position"]) < minimum_distance: return false
	return true

func _is_circle_inside_polygon(center: Vector2, radius: float, polygon: PackedVector2Array) -> bool:
	if not Geometry2D.is_point_in_polygon(center, polygon): return false
	for step in range(8):
		var edge_point := center + Vector2.RIGHT.rotated(TAU * float(step) / 8.0) * radius
		if not Geometry2D.is_point_in_polygon(edge_point, polygon): return false
	return true

func _set_swatter_active(active: bool) -> void:
	if swatter_sprite == null: return
	swatter_sprite.visible = active
	if active:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		swatter_sprite.global_position = get_viewport().get_mouse_position()
		_show_default_swatter()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _update_swatter(delta: float) -> void:
	if swatter_sprite == null or not swatter_sprite.visible: return
	swatter_sprite.global_position = get_viewport().get_mouse_position()
	if swatter_attack_timer <= 0.0: return
	swatter_attack_timer -= delta
	swatter_frame_timer -= delta
	if swatter_frame_timer <= 0.0:
		swatter_frame_timer = SWATTER_ATTACK_FRAME_TIME
		swatter_sprite.frame = mini(swatter_sprite.frame + 1, SWATTER_ATTACK_FRAMES - 1)
	if swatter_attack_timer <= 0.0: _show_default_swatter()

func _start_swatter_attack() -> void:
	if swatter_sprite == null or swatter_entity == null: return
	if not swatter_entity.call("can_attack") or not swatter_entity.call("swat"): return

	swatter_sprite.texture = SWATTER_ATTACK_TEXTURE
	swatter_sprite.hframes = SWATTER_ATTACK_FRAMES
	swatter_sprite.vframes = 1
	swatter_sprite.frame = 0
	swatter_attack_timer = SWATTER_ATTACK_FRAMES * SWATTER_ATTACK_FRAME_TIME
	swatter_frame_timer = SWATTER_ATTACK_FRAME_TIME

func _show_default_swatter() -> void:
	swatter_sprite.texture = SWATTER_DEFAULT_TEXTURE
	swatter_sprite.hframes = 1
	swatter_sprite.vframes = 1
	swatter_sprite.frame = 0
	swatter_attack_timer = 0.0
	swatter_frame_timer = 0.0

func _get_active_food_count(excluded_food: Node = null) -> int:
	if food_container == null: return 0
	var count := 0
	for food in food_container.get_children():
		if food == excluded_food or food.is_queued_for_deletion(): continue
		count += 1
	return count
