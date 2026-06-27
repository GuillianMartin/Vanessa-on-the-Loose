extends Node2D

const FLY_SCENE := preload("res://Objects/Fly.tscn")
const FOOD_SCRIPT := preload("res://Backend/Food_behavior.gd")
const CUSTOMER_HAND_SCRIPT := preload("res://Backend/CustomerHand.gd")
const SWATTER_SCRIPT := preload("res://Backend/Swatter.gd")
const MARKET_PROGRESSION := preload("res://Backend/MarketProgression.gd")
const SWATTER_DEFAULT_TEXTURE := preload("res://assets/weapon/swatter/swatter_default.png")
const SWATTER_ATTACK_TEXTURE := preload("res://assets/weapon/swatter/swatter_attack.png")

const BASE_FOOD_COUNT := 5
const TOP_SAFE_AREA := 72.0
const EDGE_PADDING := 30.0
const FOOD_GAP := 5.0
const FOOD_PLACEMENT_ATTEMPTS := 500
const SWATTER_ATTACK_FRAMES := 4
const SWATTER_ATTACK_FRAME_TIME := 0.045
const SWATTER_OFFSET := Vector2(34, 34)
const MAX_ACTIVE_CUSTOMERS := 5
const UPGRADE_MONEY_RESERVE := 500
const LEFTOVER_FOOD_FLY_BONUS_PER_KILL := 0.01

var game_timer := 0.0
var market_day := 1
var difficulty_level := 1
var current_money := 0
var reputation := 100
var customer_satisfaction := 100
var score := 0
var flies_left := 0
var day_active := false
var menu_state := "start"

var total_flies_killed := 0
var total_customers_served := 0
var day_money_start := 0
var day_money_earned := 0
var day_stock_spent := 0
var day_leftover_earned := 0
var day_initial_flies := 0
var day_flies_killed := 0
var day_customers_served := 0
var day_reputation_start := 0
var active_market_event := {}
var daily_price_roll := 1.0
var rush_active := false
var rush_timer := 0.0
var rush_check_timer := 0.0

var active_placed_food_records: Array[Dictionary] = []

var food_container: Node2D
var fly_container: Node2D
var customer_container: Node2D
var container_area: Area2D
var container_polygon: CollisionPolygon2D
var container_sprite: Sprite2D
var background_sprite: Sprite2D
var background_animation_timer := 0.0
var background_animation_duration := 0.0
var background_frame_count := 1
var container_animation_timer := 0.0
var container_animation_duration := 0.0
var container_frame_count := 1
var hud_layer: CanvasLayer
var menu_layer: CanvasLayer

var day_label: Label
var market_label: Label
var flies_label: Label
var money_label: Label
var reputation_label: Label
var satisfaction_label: Label
var match_timer_label: Label
var rush_label: Label
var upgrade_label: Label
var upgrade_buttons := {}
var menu_title: Label
var result_label: Label
var play_button: Button
var swatter_layer: CanvasLayer
var swatter_sprite: Sprite2D
var swatter_entity: Node
var swatter_energy_bar: ProgressBar
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
	_show_start_menu()

func _process(delta: float) -> void:
	if not day_active:
		return

	_update_swatter(delta)
	_update_rush_hour(delta)
	_update_customer_spawns(delta)
	_process_day_clock(delta)
	_maintain_food_loop()
	_maintain_fly_loop()
	_update_background_animation(delta)

func _input(event: InputEvent) -> void:
	if not day_active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_start_swatter_attack()

func _process_day_clock(delta: float) -> void:
	game_timer -= delta
	if game_timer <= 0.0:
		_complete_day()
		return

	_update_hud()

func _maintain_food_loop() -> void:
	if _get_active_food_count() < _get_target_food_count():
		_spawn_single_food_loop()

func _maintain_fly_loop() -> void:
	var desired_floor: int = maxi(5, int(ceil(float(MARKET_PROGRESSION.get_fly_count(market_day, active_market_event)) * 0.45)))
	if flies_left >= desired_floor:
		return

	var bounds := _get_fly_bounds()
	var spawn_count: int = mini(4, desired_floor - flies_left)
	for _index in range(spawn_count):
		_spawn_fly(
			Vector2(randf_range(bounds.position.x, bounds.end.x), randf_range(bounds.position.y, bounds.end.y)),
			bounds,
			true
		)
		flies_left += 1
	_update_hud()

func _build_game_nodes() -> void:
	background_sprite = get_node_or_null("BackgroundVegetable") as Sprite2D

	container_area = get_node_or_null("Container") as Area2D
	if container_area != null:
		container_area.z_index = -10
		container_polygon = container_area.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
		container_sprite = container_area.get_node_or_null("ContainerVegetable") as Sprite2D

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
	top_bar.offset_bottom = 54
	hud_layer.add_child(top_bar)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	top_bar.add_child(margin)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	margin.add_child(row)

	day_label = _make_hud_label("Day 1", 70)
	row.add_child(day_label)

	market_label = _make_hud_label("Market", 185)
	row.add_child(market_label)

	money_label = _make_hud_label("Money: $0", 112)
	row.add_child(money_label)

	reputation_label = _make_hud_label("Rep: 100", 86)
	row.add_child(reputation_label)

	satisfaction_label = _make_hud_label("Sat: 100", 82)
	row.add_child(satisfaction_label)

	flies_label = _make_hud_label("Flies: 0", 76)
	row.add_child(flies_label)

	match_timer_label = _make_hud_label("Time: 5:00", 92)
	row.add_child(match_timer_label)

	rush_label = _make_hud_label("", 78)
	row.add_child(rush_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	swatter_energy_label = Label.new()
	swatter_energy_label.text = "Energy"
	row.add_child(swatter_energy_label)

	swatter_energy_bar = ProgressBar.new()
	swatter_energy_bar.show_percentage = false
	swatter_energy_bar.custom_minimum_size = Vector2(130, 12)
	swatter_energy_bar.max_value = 100.0
	swatter_energy_bar.value = 100.0
	row.add_child(swatter_energy_bar)

	_build_upgrade_panel()

func _make_hud_label(text: String, width: float) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(width, 0)
	return label

func _build_upgrade_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "UpgradePanel"
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.offset_left = 12
	panel.offset_top = -126
	panel.offset_right = 342
	panel.offset_bottom = -12
	hud_layer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)

	upgrade_label = Label.new()
	upgrade_label.text = "Upgrades"
	content.add_child(upgrade_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	content.add_child(row)

	for upgrade_name in ["damage", "speed", "energy"]:
		var button := Button.new()
		button.custom_minimum_size = Vector2(96, 34)
		button.pressed.connect(_on_upgrade_pressed.bind(upgrade_name))
		row.add_child(button)
		upgrade_buttons[upgrade_name] = button

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
	panel.custom_minimum_size = Vector2(430, 285)
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
	play_button.custom_minimum_size = Vector2(190, 44)
	play_button.pressed.connect(_on_menu_button_pressed)
	content.add_child(play_button)

func _show_start_menu() -> void:
	menu_state = "start"
	day_active = false
	_set_swatter_active(false)
	menu_layer.visible = true
	hud_layer.visible = false
	fly_container.visible = false
	food_container.visible = false
	customer_container.visible = false
	_clear_flies()
	_clear_food()
	_clear_customers()
	menu_title.text = "Bangaw Fly Market"
	result_label.text = "Run a stall, protect the food, earn profit, and survive as many market days as possible."
	play_button.text = "Start Market"

func _on_menu_button_pressed() -> void:
	if menu_state == "continue":
		_start_day()
	else:
		_start_new_run()

func _start_new_run() -> void:
	market_day = 1
	difficulty_level = 1
	current_money = MARKET_PROGRESSION.STARTING_MONEY
	reputation = MARKET_PROGRESSION.STARTING_REPUTATION
	customer_satisfaction = MARKET_PROGRESSION.STARTING_SATISFACTION
	score = 0
	total_flies_killed = 0
	total_customers_served = 0
	if swatter_entity != null and swatter_entity.has_method("reset_upgrades"):
		swatter_entity.call("reset_upgrades")
	_start_day()

func _start_day() -> void:
	active_market_event = MARKET_PROGRESSION.get_market_event(market_day)
	difficulty_level = MARKET_PROGRESSION.get_difficulty_level(market_day)
	daily_price_roll = MARKET_PROGRESSION.get_daily_price_roll()
	day_money_start = current_money
	day_money_earned = 0
	day_stock_spent = 0
	day_leftover_earned = 0
	day_flies_killed = 0
	day_customers_served = 0
	day_reputation_start = reputation
	game_timer = MARKET_PROGRESSION.DAY_DURATION_SECONDS
	flies_left = MARKET_PROGRESSION.get_fly_count(market_day, active_market_event)
	day_initial_flies = flies_left
	rush_active = false
	rush_timer = 0.0
	rush_check_timer = randf_range(18.0, 45.0)
	active_placed_food_records.clear()
	customer_spawn_timer = _get_next_customer_spawn_time()

	swatter_entity.call("reset")
	swatter_entity.call("set_day", market_day)
	day_active = true
	_set_swatter_active(true)
	menu_layer.visible = false
	hud_layer.visible = true
	food_container.visible = true
	fly_container.visible = true
	customer_container.visible = true
	_apply_market_visuals()
	_update_hud()
	_spawn_food()
	if day_active:
		_spawn_flies()

func _complete_day() -> void:
	day_active = false
	_set_swatter_active(false)
	day_leftover_earned = _sell_leftover_food()
	_clear_flies()
	_clear_food()
	_clear_customers()

	var net_profit := current_money - day_money_start
	var reputation_change := reputation - day_reputation_start
	menu_state = "continue"
	menu_layer.visible = true
	hud_layer.visible = false
	menu_title.text = "Day %d Complete" % market_day
	result_label.text = "Money earned: $%d\nLeftover stock: $%d\nStock bought: $%d\nNet profit: $%d\nFlies killed: %d\nCustomers served: %d\nMarket Reputation: %+d" % [
		day_money_earned,
		day_leftover_earned,
		day_stock_spent,
		net_profit,
		day_flies_killed,
		day_customers_served,
		reputation_change
	]
	market_day += 1
	play_button.text = "Start Day %d" % market_day

func _sell_leftover_food() -> int:
	if food_container == null:
		return 0

	var fly_bonus_multiplier := 1.0 + float(day_flies_killed) * LEFTOVER_FOOD_FLY_BONUS_PER_KILL
	var payout := 0
	for food in food_container.get_children():
		if food == null or food.is_queued_for_deletion():
			continue
		if not food.has_method("get_fresh_sell_value"):
			continue
		var fresh_value := int(food.call("get_fresh_sell_value"))
		payout += int(ceilf(float(fresh_value) * fly_bonus_multiplier))

	current_money += payout
	day_money_earned += payout
	return payout

func _game_over(reason: String) -> void:
	if not day_active:
		return

	day_active = false
	_set_swatter_active(false)
	_clear_flies()
	_clear_food()
	_clear_customers()
	menu_state = "game_over"
	menu_layer.visible = true
	hud_layer.visible = false
	menu_title.text = "Game Over"
	result_label.text = "%s\nReached Day %d\nMoney: $%d\nReputation: %d\nSatisfaction: %d\nFlies swatted: %d" % [
		reason,
		market_day,
		current_money,
		reputation,
		customer_satisfaction,
		total_flies_killed
	]
	play_button.text = "Restart Market"

func _spawn_flies() -> void:
	_clear_flies()
	var bounds := _get_fly_bounds()
	for _index in range(flies_left):
		_spawn_fly(
			Vector2(randf_range(bounds.position.x, bounds.end.x), randf_range(bounds.position.y, bounds.end.y)),
			bounds,
			true
		)

func _get_fly_bounds() -> Rect2:
	var viewport_size := get_viewport_rect().size
	return Rect2(
		Vector2(EDGE_PADDING, TOP_SAFE_AREA + EDGE_PADDING),
		Vector2(max(viewport_size.x - EDGE_PADDING * 2.0, 1.0), max(viewport_size.y - TOP_SAFE_AREA - EDGE_PADDING * 2.0, 1.0))
	)

func _spawn_fly(spawn_position: Vector2, bounds: Rect2, include_mother: bool, force_mother: bool = false, forced_behavior_name: String = "") -> void:
	var fly = FLY_SCENE.instantiate()
	fly.position = Vector2(clampf(spawn_position.x, bounds.position.x, bounds.end.x), clampf(spawn_position.y, bounds.position.y, bounds.end.y))
	var new_behavior = fly.get_forced_mother_behavior(market_day, active_market_event) if force_mother else fly.get_random_behavior(include_mother, market_day, active_market_event)
	if not forced_behavior_name.is_empty():
		new_behavior = fly.get_behavior_by_name(forced_behavior_name, market_day, active_market_event)
	fly.configure(new_behavior, bounds)
	fly.died.connect(_on_fly_died)
	fly.spawn_requested.connect(_on_fly_spawn_requested)
	fly_container.add_child(fly)

func _spawn_food() -> void:
	_clear_food()
	var polygon := _get_container_polygon_global()
	if polygon.size() < 3:
		return

	for _index in range(_get_target_food_count()):
		if not _spawn_single_food_loop():
			return

func _spawn_single_food_loop() -> bool:
	var polygon := _get_container_polygon_global()
	var preferred_category := str(active_market_event.get("food_category", ""))
	var config = FOOD_SCRIPT.get_random_config_for_category(preferred_category)
	var food := FOOD_SCRIPT.new() as Node2D
	food.call("configure", config)
	_apply_food_economy(food)
	var stock_cost: int = food.call("get_stock_cost")

	if current_money < stock_cost:
		food.free()
		current_money = 0
		_game_over("Money ran out buying food stock.")
		return false

	for _attempt in range(FOOD_PLACEMENT_ATTEMPTS):
		var candidate := _get_random_point_in_polygon(polygon, config.radius)
		if _is_food_position_clear(candidate, config.radius, polygon, active_placed_food_records):
			current_money -= stock_cost
			day_stock_spent += stock_cost
			food.position = candidate
			food.connect("depleted", _on_food_depleted)
			food_container.add_child(food)
			active_placed_food_records.append({
				"node_ref": food,
				"position": candidate,
				"radius": config.radius,
			})
			_check_loss_conditions()
			if not day_active:
				return false
			_update_hud()
			return true

	food.free()
	return false

func _apply_food_economy(food: Node2D) -> void:
	var config = food.get("config")
	if config == null:
		return

	var category: String = config.category
	var market_multiplier := MARKET_PROGRESSION.get_market_price_multiplier(market_day, daily_price_roll, active_market_event, category)
	var sell_multiplier := MARKET_PROGRESSION.get_sell_price_multiplier(market_day, active_market_event, category)
	var spoil_multiplier := MARKET_PROGRESSION.get_food_spoil_multiplier(active_market_event)
	food.call("apply_market_modifiers", market_multiplier, sell_multiplier, spoil_multiplier)

func _clear_flies() -> void:
	if fly_container:
		for child in fly_container.get_children():
			child.queue_free()

func _clear_food() -> void:
	if food_container:
		for child in food_container.get_children():
			child.queue_free()
	active_placed_food_records.clear()

func _clear_customers() -> void:
	if customer_container:
		for child in customer_container.get_children():
			child.queue_free()

func _on_food_depleted(food_node: Area2D) -> void:
	active_placed_food_records = active_placed_food_records.filter(func(item): return is_instance_valid(item["node_ref"]) and item["node_ref"] != food_node)
	_adjust_reputation(-10)
	_adjust_satisfaction(-4)
	_check_loss_conditions()

func _on_fly_died(_fly: Area2D) -> void:
	if not day_active:
		return
	score += 1
	total_flies_killed += 1
	day_flies_killed += 1
	flies_left = maxi(flies_left - 1, 0)
	if swatter_entity != null:
		swatter_entity.call("register_fly_kill")
	_update_hud()

func _on_fly_spawn_requested(spawn_position: Vector2, behavior_name: String = "") -> void:
	if not day_active:
		return
	var bounds := _get_fly_bounds()
	var offset := Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(70.0, 120.0)
	_spawn_fly(spawn_position + offset, bounds, false, false, behavior_name)
	flies_left += 1
	_update_hud()

func _update_hud() -> void:
	if day_label:
		day_label.text = "Day %d" % market_day
	if market_label:
		market_label.text = str(active_market_event.get("name", "Market"))
	if flies_label:
		flies_label.text = "Flies: %d" % flies_left
	if money_label:
		money_label.text = "Money: $%d" % current_money
	if reputation_label:
		reputation_label.text = "Rep: %d" % reputation
	if satisfaction_label:
		satisfaction_label.text = "Sat: %d" % customer_satisfaction
	if rush_label:
		rush_label.text = "Rush" if rush_active else ""

	if match_timer_label:
		var minutes := int(maxf(game_timer, 0.0)) / 60
		var seconds := int(maxf(game_timer, 0.0)) % 60
		match_timer_label.text = "Time: %d:%02d" % [minutes, seconds]

	_update_upgrade_buttons()

func _update_upgrade_buttons() -> void:
	if swatter_entity == null:
		return

	if upgrade_label:
		upgrade_label.text = "Upgrades  |  Keep $%d Reserve" % UPGRADE_MONEY_RESERVE

	var display_names := {
		"damage": "Damage",
		"speed": "Speed",
		"energy": "Energy",
	}
	for upgrade_name in upgrade_buttons.keys():
		var button := upgrade_buttons[upgrade_name] as Button
		var cost := int(swatter_entity.call("get_upgrade_cost", upgrade_name))
		button.text = "%s\n$%d" % [display_names[upgrade_name], cost]
		button.disabled = not _can_afford_upgrade(cost) or not day_active

func _update_customer_spawns(delta: float) -> void:
	if not day_active or customer_container == null:
		return
	customer_spawn_timer -= delta
	if customer_spawn_timer <= 0.0:
		_spawn_customer_hand()
		customer_spawn_timer = _get_next_customer_spawn_time()

func _spawn_customer_hand() -> void:
	if _get_active_customer_count() >= MAX_ACTIVE_CUSTOMERS:
		return

	var foods = food_container.get_children()
	if foods.is_empty():
		return

	var random_food = foods.pick_random() as Node2D
	var viewport_size := get_viewport_rect().size
	var start_position := Vector2(randf_range(viewport_size.x * 0.4, viewport_size.x * 0.8), -80.0)
	var patience_multiplier := (1.65 if rush_active else 1.0) + float(market_day - 1) * 0.015
	var payout_multiplier := 1.5 if rush_active else 1.0
	var customer_patience := MARKET_PROGRESSION.get_customer_patience(day_initial_flies)

	var hand = CUSTOMER_HAND_SCRIPT.new() as Area2D
	hand.call("configure", start_position, random_food, patience_multiplier, payout_multiplier, customer_patience)
	hand.connect("swatted", _on_customer_swatted)
	hand.connect("finished", _on_buyer_transaction_finished)
	customer_container.add_child(hand)
	_update_hud()

func _on_buyer_transaction_finished(hand_node: Area2D, status: String, payout: int) -> void:
	if status == "success":
		current_money += payout
		day_money_earned += payout
		day_customers_served += 1
		total_customers_served += 1
		_adjust_reputation(2)
		_adjust_satisfaction(2)
		active_placed_food_records = active_placed_food_records.filter(
			func(item): return is_instance_valid(item["node_ref"]) and item["node_ref"] != hand_node.target_food
		)
	elif status == "disgusted":
		_adjust_reputation(-5)
		_adjust_satisfaction(-12)
	elif status == "depleted":
		_adjust_satisfaction(-5)

	_check_loss_conditions()
	_update_hud()

func _on_customer_swatted(_hand: Area2D) -> void:
	if swatter_entity != null:
		swatter_entity.call("hit_customer")
	_adjust_satisfaction(-3)
	_check_loss_conditions()

func _on_swatter_energy_changed(energy: float, max_energy: float) -> void:
	if swatter_energy_bar:
		swatter_energy_bar.max_value = max_energy
		swatter_energy_bar.value = energy

func _on_upgrade_pressed(upgrade_name: String) -> void:
	if swatter_entity == null or not day_active:
		return

	var cost := int(swatter_entity.call("get_upgrade_cost", upgrade_name))
	if not _can_afford_upgrade(cost):
		return

	current_money -= cost
	swatter_entity.call("upgrade", upgrade_name)
	_check_loss_conditions()
	_update_hud()

func _can_afford_upgrade(cost: int) -> bool:
	return current_money - cost >= UPGRADE_MONEY_RESERVE

func _update_rush_hour(delta: float) -> void:
	if rush_active:
		rush_timer -= delta
		if rush_timer <= 0.0:
			rush_active = false
		return

	rush_check_timer -= delta
	if rush_check_timer > 0.0:
		return

	if MARKET_PROGRESSION.should_start_rush(market_day):
		rush_active = true
		rush_timer = MARKET_PROGRESSION.get_rush_duration(market_day)
	rush_check_timer = randf_range(35.0, 70.0)

func _get_next_customer_spawn_time() -> float:
	var bounds := MARKET_PROGRESSION.get_customer_spawn_bounds(market_day, active_market_event, rush_active)
	return randf_range(bounds.x, bounds.y)

func _adjust_reputation(amount: int) -> void:
	reputation = clampi(reputation + amount, 0, 150)

func _adjust_satisfaction(amount: int) -> void:
	customer_satisfaction = clampi(customer_satisfaction + amount, 0, 150)

func _check_loss_conditions() -> void:
	if not day_active:
		return
	if current_money <= 0:
		_game_over("Money reached $0.")
	elif customer_satisfaction <= 0:
		_game_over("Customer satisfaction reached 0.")
	elif reputation <= 0:
		_game_over("Market reputation reached 0.")

func _get_active_customer_count() -> int:
	if customer_container == null:
		return 0
	var count := 0
	for customer in customer_container.get_children():
		if not customer.is_queued_for_deletion():
			count += 1
	return count

func _get_target_food_count() -> int:
	return mini(BASE_FOOD_COUNT + int(floor(float(market_day - 1) / 6.0)), 8)

func _apply_market_visuals() -> void:
	var event_tint: Color = active_market_event.get("tint", Color.WHITE)
	background_sprite = _show_named_sprite(self, str(active_market_event.get("background_node", "BackgroundVegetable")), event_tint)
	_configure_event_sprite(background_sprite, "background")

	if container_area != null:
		container_sprite = _show_named_sprite(container_area, str(active_market_event.get("container_node", "ContainerVegetable")), event_tint)
		_configure_event_sprite(container_sprite, "container")

func _show_named_sprite(parent: Node, sprite_name: String, tint: Color) -> Sprite2D:
	var selected_sprite: Sprite2D = null
	for child in parent.get_children():
		if child is Sprite2D:
			var sprite := child as Sprite2D
			var should_show := sprite.name == sprite_name
			sprite.visible = should_show
			if should_show:
				sprite.modulate = tint
				selected_sprite = sprite
	return selected_sprite

func _configure_event_sprite(sprite: Sprite2D, sprite_type: String) -> void:
	if sprite == null:
		return

	var texture_path := str(active_market_event.get("%s_path" % sprite_type, ""))
	if texture_path != "":
		var loaded_texture = load(texture_path)
		if loaded_texture != null:
			sprite.texture = loaded_texture

	var hframes := int(active_market_event.get("%s_hframes" % sprite_type, 1))
	var vframes := int(active_market_event.get("%s_vframes" % sprite_type, 1))
	sprite.hframes = max(hframes, 1)
	sprite.vframes = max(vframes, 1)
	sprite.frame = int(active_market_event.get("%s_start_frame" % sprite_type, 0))

	if sprite_type == "background":
		background_frame_count = max(1, sprite.hframes * sprite.vframes)
		background_animation_duration = float(active_market_event.get("background_animation_duration", 0.0))
		background_animation_timer = 0.0
	elif sprite_type == "container":
		container_frame_count = max(1, sprite.hframes * sprite.vframes)
		container_animation_duration = float(active_market_event.get("container_animation_duration", 0.0))
		container_animation_timer = 0.0

func _update_background_animation(delta: float) -> void:
	if background_sprite != null and background_sprite.visible and background_sprite.hframes > 1 and background_animation_duration > 0.0:
		background_animation_timer += delta
		while background_animation_timer >= background_animation_duration:
			background_animation_timer -= background_animation_duration
			background_sprite.frame = (background_sprite.frame + 1) % background_frame_count

	if container_sprite != null and container_sprite.visible and container_sprite.hframes > 1 and container_animation_duration > 0.0:
		container_animation_timer += delta
		while container_animation_timer >= container_animation_duration:
			container_animation_timer -= container_animation_duration
			container_sprite.frame = (container_sprite.frame + 1) % container_frame_count

func _get_container_polygon_global() -> PackedVector2Array:
	var points := PackedVector2Array()
	if container_polygon == null:
		return points
	for point in container_polygon.polygon:
		points.append(container_polygon.to_global(point))
	return points

func _get_random_point_in_polygon(polygon: PackedVector2Array, radius: float = 0.0) -> Vector2:
	var bounds := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		bounds = bounds.expand(point)
	for _attempt in range(80):
		var point := Vector2(randf_range(bounds.position.x + radius, bounds.end.x - radius), randf_range(bounds.position.y + radius, bounds.end.y - radius))
		if _is_circle_inside_polygon(point, radius, polygon):
			return point
	return bounds.get_center()

func _is_food_position_clear(candidate: Vector2, candidate_radius: float, polygon: PackedVector2Array, placed_food: Array[Dictionary]) -> bool:
	if not _is_circle_inside_polygon(candidate, candidate_radius, polygon):
		return false
	for placed in placed_food:
		if not is_instance_valid(placed["node_ref"]):
			continue
		var minimum_distance := candidate_radius + float(placed["radius"]) + FOOD_GAP
		if candidate.distance_to(placed["position"]) < minimum_distance:
			return false
	return true

func _is_circle_inside_polygon(center: Vector2, radius: float, polygon: PackedVector2Array) -> bool:
	if not Geometry2D.is_point_in_polygon(center, polygon):
		return false
	for step in range(8):
		var edge_point := center + Vector2.RIGHT.rotated(TAU * float(step) / 8.0) * radius
		if not Geometry2D.is_point_in_polygon(edge_point, polygon):
			return false
	return true

func _set_swatter_active(active: bool) -> void:
	if swatter_sprite == null:
		return
	swatter_sprite.visible = active
	if active:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		swatter_sprite.global_position = get_viewport().get_mouse_position()
		_show_default_swatter()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _update_swatter(delta: float) -> void:
	if swatter_sprite == null or not swatter_sprite.visible:
		return
	swatter_sprite.global_position = get_viewport().get_mouse_position()
	if swatter_attack_timer <= 0.0:
		return
	swatter_attack_timer -= delta
	swatter_frame_timer -= delta
	if swatter_frame_timer <= 0.0:
		swatter_frame_timer = SWATTER_ATTACK_FRAME_TIME
		swatter_sprite.frame = mini(swatter_sprite.frame + 1, SWATTER_ATTACK_FRAMES - 1)
	if swatter_attack_timer <= 0.0:
		_show_default_swatter()

func _start_swatter_attack() -> void:
	if swatter_sprite == null or swatter_entity == null:
		return
	var swat_is_active := swatter_entity.has_method("is_swat_active") and bool(swatter_entity.call("is_swat_active"))
	if not swat_is_active and not swatter_entity.call("swat"):
		return

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
	if food_container == null:
		return 0
	var count := 0
	for food in food_container.get_children():
		if food == excluded_food or food.is_queued_for_deletion():
			continue
		count += 1
	return count
