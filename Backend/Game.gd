extends Node2D

signal financial_reports_generated(day_end_report: Dictionary, pre_day_forecast: Dictionary)

const FLY_SCENE := preload("res://Objects/Fly.tscn")
const BOSS_FLY_SCRIPT := preload("res://Backend/Object Behavior/BossFly.gd")
const FOOD_SCRIPT := preload("res://Backend/Object Behavior/Food.gd")
const CUSTOMER_HAND_SCRIPT := preload("res://Backend/Object Behavior/CustomerHand.gd")
const SWATTER_SCRIPT := preload("res://Backend/Swatter.gd")
const MARKET_PROGRESSION := preload("res://Backend/MarketProgression.gd")
const REWARD_MANAGER := preload("res://Backend/RewardManager.gd")
const SWATTER_DEFAULT_TEXTURE := preload("res://assets/weapon/swatter/swatter_default.png")
const SWATTER_ATTACK_TEXTURE := preload("res://assets/weapon/swatter/swatter_attack.png")
const RESULT_CONTAINER_TEXTURE := preload("res://assets/ui_container/result_container.png")
const RESULT_FLIP_TEXTURE := preload("res://assets/ui_container/result_flip.png")
const FINANCIAL_BUTTON_TEXTURE := preload("res://assets/buttons/financial_button.png")
const START_BUTTON_TEXTURE := preload("res://assets/buttons/start_button.png")

const BASE_FOOD_COUNT := 8
const TOP_SAFE_AREA := 72.0
const EDGE_PADDING := 30.0
const FOOD_GAP := 1.0
const FOOD_PLACEMENT_ATTEMPTS := 500
const SWATTER_ATTACK_FRAMES := 4
const SWATTER_ATTACK_FRAME_TIME := 0.045
const SWATTER_OFFSET := Vector2(34, 34)
const MAX_ACTIVE_CUSTOMERS := 5
const MAX_DEBT_LIMIT: int = -500
const MAX_BANKRUPTCY_STRIKES: int = 3
const RESULT_FRAME_SIZE := Vector2(723, 483)
const RESULT_FLIP_FRAME_COUNT := 17
const RESULT_FLIP_FPS := 15.0
const RESULT_BUTTON_FRAME_SIZE := Vector2(330, 70)
const RESULT_TEXT_AREA_POSITION := Vector2(182, 62)
const RESULT_TEXT_AREA_SIZE := Vector2(477, 294)
const RESULT_BUTTON_POSITION := Vector2(275, 390)
const RESULT_TEXT_COLOR := Color("#5D371E")

var icon_paths := {
	"damage": "res://assets/icon/Upgrades/damage.png",
	"speed": "res://assets/icon/Upgrades/speed.png",
	"energy": "res://assets/icon/Upgrades/energy.png",
}

var game_timer := 0.0
var market_day := 1
var difficulty_level := 1
var current_money := 0
var boss_round_active := false
var boss_round_pending := false
var bankruptcy_strikes: int = 0
var is_bankrupt := false
var reputation := 100
var customer_satisfaction := 100
var score := 0
var flies_left := 0
var day_active := false
var menu_state := "start"

var total_flies_killed := 0
var total_customers_served := 0
var day_money_start := 0
var day_gross_sales := 0
var day_money_earned := 0
var day_stock_spent := 0
var day_leftover_earned := 0
var day_fly_reward := 0
var day_initial_flies := 0
var day_flies_killed := 0
var day_customers_served := 0
var day_reputation_start := 0
var active_market_event := {}
var daily_price_roll := 1.0
var rush_active := false
var rush_timer := 0.0
var rush_check_timer := 0.0
var current_day_report := {}
var next_day_forecast := {}
var prepared_restock_plan := {}
var bankruptcy_strike_forecast_day := -1
var restock_costs_prepaid := false

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
var swatted_label: Label
var money_label: Label
var reputation_label: Label
var satisfaction_label: Label
var match_timer_label: Label
var rush_label: Label
var upgrade_label: Label
var upgrade_buttons := {}
var default_menu_panel: PanelContainer
var result_art_root: Control
var result_texture_rect: TextureRect
var result_motion_root: Control
var result_content: VBoxContainer
var result_title_label: Label
var result_body_label: Label
var result_warning_label: Label
var financial_button: TextureButton
var result_start_button: TextureButton
var result_transition_active := false
var menu_title: Label
var result_label: Label
var forecast_warning_label: Label
var play_button: Button
var swatter_layer: CanvasLayer
var swatter_sprite: Sprite2D
var swatter_entity: Node
var swatter_energy_bar: ProgressBar
var swatter_energy_label: Label
var boss_health_label: Label
var boss_health_bar: ProgressBar
var swatter_attack_timer := 0.0
var swatter_frame_timer := 0.0
var customer_spawn_timer := 0.0
var screen_shake_timer := 0.0
var screen_shake_duration := 0.0
var screen_shake_strength := 0.0
var base_scene_position := Vector2.ZERO

func _ready() -> void:
	randomize()
	base_scene_position = position
	_build_game_nodes()
	_build_swatter()
	_build_hud()
	_build_menu()
	_show_start_menu()

func _process(delta: float) -> void:
	_update_screen_shake(delta)
	if not day_active:
		return

	_update_swatter(delta)
	_update_rush_hour(delta)
	_update_customer_spawns(delta)
	_process_day_clock(delta)
	_maintain_food_loop()
	if boss_round_active:
		_update_background_animation(delta)
		return
	_maintain_fly_loop()
	_update_background_animation(delta)

func _input(event: InputEvent) -> void:
	if not day_active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_start_swatter_attack()

func _process_day_clock(delta: float) -> void:
	if boss_round_active:
		_update_hud()
		return

	game_timer -= delta
	if game_timer <= 0.0:
		_complete_day()
		return

	_update_hud()

func _maintain_food_loop() -> void:
	if _get_active_food_count() < _get_target_food_count():
		_spawn_single_food_loop()

func _maintain_fly_loop() -> void:
	if boss_round_active:
		return

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

	money_label = _make_hud_label("Money: ₱0", 112)
	row.add_child(money_label)

	reputation_label = _make_hud_label("Rep: 100", 86)
	row.add_child(reputation_label)

	satisfaction_label = _make_hud_label("Sat: 100", 82)
	row.add_child(satisfaction_label)

	flies_label = _make_hud_label("Flies: 0", 76)
	row.add_child(flies_label)

	swatted_label = _make_hud_label("Swatted: 0", 96)
	row.add_child(swatted_label)

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

	var boss_row := HBoxContainer.new()
	boss_row.name = "BossHealth"
	boss_row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	boss_row.offset_left = 360
	boss_row.offset_top = 58
	boss_row.offset_right = -360
	boss_row.offset_bottom = 88
	boss_row.alignment = BoxContainer.ALIGNMENT_CENTER
	boss_row.visible = false
	hud_layer.add_child(boss_row)

	boss_health_label = _make_hud_label("Boss Lives: 5/5", 150)
	boss_row.add_child(boss_health_label)

	boss_health_bar = ProgressBar.new()
	boss_health_bar.show_percentage = false
	boss_health_bar.custom_minimum_size = Vector2(260, 14)
	boss_health_bar.max_value = 10.0
	boss_health_bar.value = 10.0
	boss_row.add_child(boss_health_bar)

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
		button.custom_minimum_size = Vector2(96, 72)
		button.pressed.connect(_on_upgrade_pressed.bind(upgrade_name))
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	default_menu_panel = panel
	panel.custom_minimum_size = Vector2(560, 430)
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
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	result_label.text = ""
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.custom_minimum_size = Vector2(480, 0)
	content.add_child(result_label)

	forecast_warning_label = Label.new()
	forecast_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	forecast_warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	forecast_warning_label.custom_minimum_size = Vector2(480, 0)
	forecast_warning_label.visible = false
	content.add_child(forecast_warning_label)

	play_button = Button.new()
	play_button.text = "Play"
	play_button.custom_minimum_size = Vector2(190, 44)
	play_button.pressed.connect(_on_menu_button_pressed)
	content.add_child(play_button)

	_build_result_art_menu()

func _build_result_art_menu() -> void:
	result_art_root = Control.new()
	result_art_root.visible = false
	result_art_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(result_art_root)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_art_root.add_child(center)

	var board := Control.new()
	board.custom_minimum_size = RESULT_FRAME_SIZE
	center.add_child(board)

	result_texture_rect = TextureRect.new()
	result_texture_rect.texture = RESULT_CONTAINER_TEXTURE
	result_texture_rect.custom_minimum_size = RESULT_FRAME_SIZE
	result_texture_rect.size = RESULT_FRAME_SIZE
	result_texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	board.add_child(result_texture_rect)

	result_motion_root = Control.new()
	result_motion_root.position = Vector2.ZERO
	result_motion_root.size = RESULT_FRAME_SIZE
	result_motion_root.clip_contents = true
	board.add_child(result_motion_root)

	var text_margin := MarginContainer.new()
	text_margin.position = RESULT_TEXT_AREA_POSITION
	text_margin.size = RESULT_TEXT_AREA_SIZE
	text_margin.clip_contents = true
	text_margin.add_theme_constant_override("margin_left", 0)
	text_margin.add_theme_constant_override("margin_right", 0)
	text_margin.add_theme_constant_override("margin_top", 0)
	text_margin.add_theme_constant_override("margin_bottom", 0)
	result_motion_root.add_child(text_margin)

	var content := VBoxContainer.new()
	result_content = content
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	text_margin.add_child(content)

	result_title_label = Label.new()
	result_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_title_label.add_theme_color_override("font_color", RESULT_TEXT_COLOR)
	result_title_label.add_theme_font_size_override("font_size", 20)
	content.add_child(result_title_label)

	result_body_label = Label.new()
	result_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	result_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_body_label.add_theme_color_override("font_color", RESULT_TEXT_COLOR)
	result_body_label.add_theme_font_size_override("font_size", 18)
	result_body_label.custom_minimum_size = Vector2(RESULT_TEXT_AREA_SIZE.x, 0)
	content.add_child(result_body_label)

	result_warning_label = Label.new()
	result_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_warning_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_warning_label.add_theme_color_override("font_color", RESULT_TEXT_COLOR)
	result_warning_label.add_theme_font_size_override("font_size", 18)
	result_warning_label.custom_minimum_size = Vector2(RESULT_TEXT_AREA_SIZE.x, 0)
	result_warning_label.visible = false
	content.add_child(result_warning_label)

	financial_button = TextureButton.new()
	financial_button.position = RESULT_BUTTON_POSITION
	financial_button.texture_normal = _get_button_frame(FINANCIAL_BUTTON_TEXTURE, 0)
	financial_button.texture_hover = _get_button_frame(FINANCIAL_BUTTON_TEXTURE, 1)
	financial_button.texture_pressed = _get_button_frame(FINANCIAL_BUTTON_TEXTURE, 1)
	financial_button.ignore_texture_size = true
	financial_button.custom_minimum_size = RESULT_BUTTON_FRAME_SIZE
	financial_button.size = RESULT_BUTTON_FRAME_SIZE
	financial_button.pressed.connect(_on_menu_button_pressed)
	board.add_child(financial_button)

	result_start_button = TextureButton.new()
	result_start_button.position = RESULT_BUTTON_POSITION
	result_start_button.texture_normal = _get_button_frame(START_BUTTON_TEXTURE, 0)
	result_start_button.texture_hover = _get_button_frame(START_BUTTON_TEXTURE, 1)
	result_start_button.texture_pressed = _get_button_frame(START_BUTTON_TEXTURE, 1)
	result_start_button.ignore_texture_size = true
	result_start_button.custom_minimum_size = RESULT_BUTTON_FRAME_SIZE
	result_start_button.size = RESULT_BUTTON_FRAME_SIZE
	result_start_button.pressed.connect(_on_menu_button_pressed)
	result_start_button.visible = false
	board.add_child(result_start_button)

func _get_button_frame(atlas: Texture2D, frame_index: int) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = Rect2(RESULT_BUTTON_FRAME_SIZE.x * frame_index, 0, RESULT_BUTTON_FRAME_SIZE.x, RESULT_BUTTON_FRAME_SIZE.y)
	return texture

func _get_result_flip_frame(frame_index: int) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = RESULT_FLIP_TEXTURE
	texture.region = Rect2(RESULT_FRAME_SIZE.x * frame_index, 0, RESULT_FRAME_SIZE.x, RESULT_FRAME_SIZE.y)
	return texture

func _show_default_menu_panel() -> void:
	if default_menu_panel:
		default_menu_panel.visible = true
	if result_art_root:
		result_art_root.visible = false
	result_transition_active = false

func _show_result_art_panel() -> void:
	if default_menu_panel:
		default_menu_panel.visible = false
	if result_art_root:
		result_art_root.visible = true
	if result_texture_rect:
		result_texture_rect.texture = RESULT_CONTAINER_TEXTURE
	if result_motion_root:
		result_motion_root.position = Vector2.ZERO
		result_motion_root.modulate.a = 1.0

func _show_start_menu() -> void:
	menu_state = "start"
	day_active = false
	boss_round_active = false
	boss_round_pending = false
	_set_swatter_active(false)
	_set_boss_health_visible(false)
	menu_layer.visible = true
	hud_layer.visible = false
	fly_container.visible = false
	food_container.visible = false
	customer_container.visible = false
	_clear_flies()
	_clear_food()
	_clear_customers()
	_show_default_menu_panel()
	menu_title.text = "Bangaw Fly Market"
	result_label.text = "Run a stall, protect the food, earn profit, and survive as many market days as possible."
	if forecast_warning_label:
		forecast_warning_label.visible = false
	play_button.text = "Start Market"

func _on_menu_button_pressed() -> void:
	if result_transition_active:
		return

	match menu_state:
		"day_end_summary":
			_play_forecast_transition()
		"pre_day_forecast":
			_start_day()
		"start", "game_over":
			_start_new_run()
		_:
			_start_new_run()

func _start_new_run() -> void:
	market_day = 1
	difficulty_level = 1
	boss_round_active = false
	boss_round_pending = false
	current_money = MARKET_PROGRESSION.STARTING_MONEY
	bankruptcy_strikes = 0
	is_bankrupt = false
	current_day_report = {}
	next_day_forecast = {}
	prepared_restock_plan = {}
	bankruptcy_strike_forecast_day = -1
	restock_costs_prepaid = false
	reputation = MARKET_PROGRESSION.STARTING_REPUTATION
	customer_satisfaction = MARKET_PROGRESSION.STARTING_SATISFACTION
	score = 0
	total_flies_killed = 0
	total_customers_served = 0
	if swatter_entity != null and swatter_entity.has_method("reset_upgrades"):
		swatter_entity.call("reset_upgrades")
	_start_day()

func _start_day() -> void:
	var starting_boss_round := boss_round_pending
	var used_prepared_restock_plan := not starting_boss_round and _has_prepared_restock_plan(market_day)
	boss_round_active = starting_boss_round
	active_market_event = MARKET_PROGRESSION.get_market_event(market_day)
	difficulty_level = MARKET_PROGRESSION.get_difficulty_level(market_day)
	if used_prepared_restock_plan:
		active_market_event = prepared_restock_plan["market_event"] as Dictionary
		daily_price_roll = float(prepared_restock_plan["daily_price_roll"])
		current_money = int(next_day_forecast.get("final_starting_capital", current_money))
	else:
		daily_price_roll = MARKET_PROGRESSION.get_daily_price_roll()
	is_bankrupt = current_money < 0
	restock_costs_prepaid = used_prepared_restock_plan or boss_round_active
	day_money_start = current_money
	day_gross_sales = 0
	day_money_earned = 0
	day_stock_spent = 0
	day_leftover_earned = 0
	day_fly_reward = 0
	day_flies_killed = 0
	day_customers_served = 0
	day_reputation_start = reputation
	game_timer = 999999.0 if boss_round_active else MARKET_PROGRESSION.DAY_DURATION_SECONDS
	flies_left = 0 if boss_round_active else MARKET_PROGRESSION.get_fly_count(market_day, active_market_event)
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
	if forecast_warning_label:
		forecast_warning_label.visible = false
	hud_layer.visible = true
	food_container.visible = true
	fly_container.visible = true
	customer_container.visible = true
	if _check_debt_limit("Maximum debt reached."):
		restock_costs_prepaid = false
		return
	_apply_market_visuals()
	_update_hud()
	_spawn_food()
	if used_prepared_restock_plan:
		prepared_restock_plan = {}
	restock_costs_prepaid = false
	_update_bankruptcy_state()
	if day_active:
		if boss_round_active:
			_spawn_boss_fight()
		else:
			_spawn_flies()

func _complete_day() -> void:
	if boss_round_active:
		_complete_boss_round()
		return

	day_active = false
	_set_swatter_active(false)
	day_leftover_earned = _sell_leftover_food()
	day_fly_reward = REWARD_MANAGER.calculate_fly_reward(day_flies_killed)
	current_money += day_fly_reward
	day_money_earned += day_fly_reward
	_clear_flies()
	_clear_food()
	_clear_customers()

	var completed_market_day := market_day
	current_day_report = generate_day_end_report()
	if is_bankrupt and current_money < 0:
		_game_over_from_day_end("Bankruptcy was not recovered before market close.")
		return

	boss_round_pending = _is_boss_day(completed_market_day)
	market_day += 1
	next_day_forecast = generate_pre_day_forecast()
	financial_reports_generated.emit(current_day_report, next_day_forecast)
	if bool(next_day_forecast.get("is_bankruptcy_state", false)) and bankruptcy_strikes >= MAX_BANKRUPTCY_STRIKES:
		market_day = completed_market_day
		_game_over_from_day_end("Bankruptcy strike limit reached.")
		return

	_show_day_end_summary_screen(completed_market_day)

func _sell_leftover_food() -> int:
	if food_container == null:
		return 0

	var payout := 0
	for food in food_container.get_children():
		if food == null or food.is_queued_for_deletion():
			continue
		if not food.has_method("get_fresh_sell_value"):
			continue
		var fresh_value := int(food.call("get_fresh_sell_value"))
		payout += fresh_value

	current_money += payout
	day_money_earned += payout
	return payout

func _game_over(reason: String) -> void:
	if not day_active:
		return

	_show_game_over(reason)

func _game_over_from_day_end(reason: String) -> void:
	_show_game_over(reason)

func _show_game_over(reason: String) -> void:
	day_active = false
	boss_round_active = false
	boss_round_pending = false
	is_bankrupt = current_money < 0
	_set_swatter_active(false)
	_set_boss_health_visible(false)
	_clear_flies()
	_clear_food()
	_clear_customers()
	menu_state = "game_over"
	menu_layer.visible = true
	hud_layer.visible = false
	_show_default_menu_panel()
	if forecast_warning_label:
		forecast_warning_label.visible = false
	menu_title.text = "Game Over"
	result_label.text = "%s\nReached Day %d\nMoney: ₱%d\nReputation: %d\nSatisfaction: %d\nFlies swatted: %d" % [
		reason,
		market_day,
		current_money,
		reputation,
		customer_satisfaction,
		total_flies_killed
	]
	play_button.text = "Restart Market"

func _update_bankruptcy_state() -> void:
	pass

func generate_day_end_report() -> Dictionary:
	return {
		"gross_sales": day_gross_sales,
		"leftover_stock_value": day_leftover_earned,
		"customers_served": day_customers_served,
		"market_reputation": reputation,
		"market_reputation_change": reputation - day_reputation_start,
		"flies_killed": day_flies_killed,
		"fly_bounty_bonus": day_fly_reward,
		"stock_costs": day_stock_spent,
		"total_wallet_end_of_day": current_money,
	}

func generate_pre_day_forecast() -> Dictionary:
	var restock_plan := _prepare_restock_plan(market_day)
	prepared_restock_plan = restock_plan
	var carried_over_wallet := current_money
	var expected_restock_cost := int(restock_plan["expected_restock_cost"])
	var final_starting_capital := carried_over_wallet - expected_restock_cost
	var is_bankruptcy_state := final_starting_capital < 0
	if is_bankruptcy_state and bankruptcy_strike_forecast_day != market_day:
		bankruptcy_strikes += 1
		bankruptcy_strike_forecast_day = market_day
	is_bankrupt = is_bankruptcy_state
	return {
		"carried_over_wallet": carried_over_wallet,
		"expected_restock_cost": expected_restock_cost,
		"final_starting_capital": final_starting_capital,
		"is_bankruptcy_state": is_bankruptcy_state,
		"bankruptcy_strikes": bankruptcy_strikes,
	}

func _show_day_end_summary_screen(completed_market_day: int) -> void:
	menu_state = "day_end_summary"
	menu_layer.visible = true
	hud_layer.visible = false
	_show_result_art_panel()
	if forecast_warning_label:
		forecast_warning_label.visible = false

	result_title_label.text = "Day %d Complete" % completed_market_day
	result_body_label.text = "--- TODAY'S PERFORMANCE ---\nCustomers Served: %d\nMarket Reputation: %d (%+d)\nFlies Swatted: %d\n\n--- FINANCIALS ---\nGross Sales: +%s\nLeftover Stock Sold: +%s\nFly Bounty: +%s\n(Minus) Stock Costs: -%s\nTotal End of Day Wallet: %s" % [
		_report_int(current_day_report, "customers_served"),
		_report_int(current_day_report, "market_reputation"),
		_report_int(current_day_report, "market_reputation_change"),
		_report_int(current_day_report, "flies_killed"),
		_format_peso(_report_int(current_day_report, "gross_sales")),
		_format_peso(_report_int(current_day_report, "leftover_stock_value")),
		_format_peso(_report_int(current_day_report, "fly_bounty_bonus")),
		_format_peso(_report_int(current_day_report, "stock_costs")),
		_format_peso(_report_int(current_day_report, "total_wallet_end_of_day")),
	]
	result_warning_label.visible = false
	_apply_result_text_fit(result_body_label.text, false)
	financial_button.visible = true
	financial_button.disabled = false
	result_start_button.visible = false
	play_button.text = "Next: Financial Forecast"

func _show_pre_day_forecast_screen(animate_intro := false) -> void:
	menu_state = "pre_day_forecast"
	menu_layer.visible = true
	hud_layer.visible = false
	_show_result_art_panel()

	result_title_label.text = "Day %d Forecast" % market_day
	result_body_label.text = "--- TOMORROW'S FORECAST ---\nCarried Over Wallet: %s\nExpected Restock Cost: -%s\nStarting Capital for Tomorrow: %s" % [
		_format_peso(_report_int(next_day_forecast, "carried_over_wallet")),
		_format_peso(_report_int(next_day_forecast, "expected_restock_cost")),
		_format_peso(_report_int(next_day_forecast, "final_starting_capital")),
	]

	if forecast_warning_label:
		forecast_warning_label.visible = false
		if bool(next_day_forecast.get("is_bankruptcy_state", false)):
			var strike_count := int(next_day_forecast.get("bankruptcy_strikes", bankruptcy_strikes))
			forecast_warning_label.text = "⚠️ WARNING: BANKRUPTCY IMMINENT! (Strike %d of %d)" % [strike_count, MAX_BANKRUPTCY_STRIKES]
			forecast_warning_label.add_theme_color_override("font_color", Color(1.0, 0.12, 0.08))
		else:
			forecast_warning_label.text = "Finances Stable"
			forecast_warning_label.add_theme_color_override("font_color", Color(0.18, 0.72, 0.30))

	play_button.text = "Start Day %d" % market_day
	if bool(next_day_forecast.get("is_bankruptcy_state", false)):
		var strike_count := int(next_day_forecast.get("bankruptcy_strikes", bankruptcy_strikes))
		result_warning_label.text = "WARNING: BANKRUPTCY IMMINENT! (Strike %d of %d)" % [strike_count, MAX_BANKRUPTCY_STRIKES]
	else:
		result_warning_label.text = "Finances Stable"
	result_warning_label.add_theme_color_override("font_color", RESULT_TEXT_COLOR)
	result_warning_label.visible = true
	_apply_result_text_fit(result_body_label.text, true)
	financial_button.visible = false
	result_start_button.visible = true
	if animate_intro:
		_animate_result_data_in()

func _apply_result_text_fit(body_text: String, has_warning: bool) -> void:
	var body_lines := body_text.count("\n") + 1
	var total_lines := body_lines + 1 + (1 if has_warning else 0)
	var body_font_size := 18
	if total_lines >= 12:
		body_font_size = 15
	elif total_lines >= 9:
		body_font_size = 16
	elif total_lines >= 6:
		body_font_size = 18
	else:
		body_font_size = 20

	var title_font_size := mini(body_font_size + 2, 20)
	var separation := 5 if total_lines >= 9 else 8
	result_content.add_theme_constant_override("separation", separation)
	result_title_label.add_theme_font_size_override("font_size", title_font_size)
	result_body_label.add_theme_font_size_override("font_size", body_font_size)
	result_warning_label.add_theme_font_size_override("font_size", body_font_size)

func _play_forecast_transition() -> void:
	result_transition_active = true
	if financial_button:
		financial_button.disabled = true
	if result_start_button:
		result_start_button.visible = false

	var fade_out := create_tween()
	fade_out.set_parallel(true)
	fade_out.tween_property(result_motion_root, "position", Vector2(0, -28), 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fade_out.tween_property(result_motion_root, "modulate:a", 0.0, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fade_out.finished

	if financial_button:
		financial_button.visible = false

	for frame_index in range(RESULT_FLIP_FRAME_COUNT):
		result_texture_rect.texture = _get_result_flip_frame(frame_index)
		await get_tree().create_timer(1.0 / RESULT_FLIP_FPS).timeout

	result_texture_rect.texture = RESULT_CONTAINER_TEXTURE
	_show_pre_day_forecast_screen(false)
	await _animate_result_data_in()
	result_transition_active = false

func _animate_result_data_in() -> void:
	result_motion_root.position = Vector2(0, 28)
	result_motion_root.modulate.a = 0.0
	var fade_in := create_tween()
	fade_in.set_parallel(true)
	fade_in.tween_property(result_motion_root, "position", Vector2.ZERO, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade_in.tween_property(result_motion_root, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await fade_in.finished

func _format_peso(amount: int) -> String:
	return "₱%d" % amount

func _report_int(report: Dictionary, key: String) -> int:
	return int(report.get(key, 0))

func _prepare_restock_plan(day: int) -> Dictionary:
	if _has_prepared_restock_plan(day):
		return prepared_restock_plan

	var event := MARKET_PROGRESSION.get_market_event(day)
	var price_roll := MARKET_PROGRESSION.get_daily_price_roll()
	var food_configs: Array = []
	var expected_restock_cost := 0
	var preferred_category := str(event.get("food_category", ""))

	for _index in range(_get_target_food_count_for_day(day)):
		var config = FOOD_SCRIPT.get_random_config_for_category(preferred_category)
		food_configs.append(config)
		expected_restock_cost += _get_stock_cost_for_config(config, day, event, price_roll)

	return {
		"day": day,
		"market_event": event,
		"daily_price_roll": price_roll,
		"food_configs": food_configs,
		"expected_restock_cost": expected_restock_cost,
	}

func _has_prepared_restock_plan(day: int) -> bool:
	return int(prepared_restock_plan.get("day", -1)) == day

func _get_stock_cost_for_config(config, day: int, event: Dictionary, price_roll: float) -> int:
	if config == null:
		return 0

	var category: String = config.category
	var market_multiplier := MARKET_PROGRESSION.get_market_price_multiplier(day, price_roll, event, category)
	return int(ceilf(float(config.base_market_price) * market_multiplier))

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
	var config = _get_next_restock_config(preferred_category)
	var food := FOOD_SCRIPT.new() as Node2D
	food.call("configure", config)
	_apply_food_economy(food)
	var stock_cost: int = food.call("get_stock_cost")

	for _attempt in range(FOOD_PLACEMENT_ATTEMPTS):
		var candidate := _get_random_point_in_polygon(polygon, config.radius)
		if _is_food_position_clear(candidate, config.radius, polygon, active_placed_food_records):
			if not restock_costs_prepaid:
				current_money -= stock_cost
				_update_bankruptcy_state()
				if _check_debt_limit("Maximum debt reached."):
					food.free()
					return false
			day_stock_spent += stock_cost
			_update_bankruptcy_state()
			spawn_floating_money_text(stock_cost, candidate, false)
			food.position = candidate
			food.connect("depleted", _on_food_depleted)
			food_container.add_child(food)
			active_placed_food_records.append({
				"node_ref": food,
				"position": candidate,
				"radius": config.radius,
			})
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

func _is_boss_day(day: int) -> bool:
	return day > 0 and day % 10 == 0

func _spawn_boss_fight() -> void:
	_clear_flies()
	_clear_customers()
	var bounds := _get_fly_bounds()
	var boss := BOSS_FLY_SCRIPT.new() as Node2D
	boss.name = "BossFly"
	boss.position = Vector2(bounds.position.x + bounds.size.x * 0.5, bounds.position.y + bounds.size.y * 0.5)
	boss.connect("died", Callable(self, "_on_boss_died"))
	boss.connect("spawn_requested", Callable(self, "_on_boss_spawn_requested"))
	boss.connect("health_changed", Callable(self, "_on_boss_health_changed"))
	boss.connect("shockwave_released", Callable(self, "_on_boss_shockwave_released"))
	fly_container.add_child(boss)
	boss.call("configure", bounds, 5)
	boss.call("begin_boss_fight")
	flies_left = 1
	_update_hud()

func _on_boss_died(boss_node: Node) -> void:
	if not day_active:
		return
	score += 1
	total_flies_killed += 1
	day_flies_killed += 1
	flies_left = 0
	if swatter_entity != null:
		swatter_entity.call("register_fly_kill")
	_complete_boss_round()

func _complete_boss_round() -> void:
	day_active = false
	boss_round_active = false
	boss_round_pending = false
	_set_swatter_active(false)
	_clear_flies()
	_clear_food()
	_clear_customers()
	_set_boss_health_visible(false)
	_start_day()

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

func _on_boss_spawn_requested(_spawn_position: Vector2, _behavior_name: String = "") -> void:
	pass

func _on_boss_health_changed(lives_remaining: int, max_lives: int, health: int, max_health: int) -> void:
	_set_boss_health_visible(true)
	if boss_health_label:
		boss_health_label.text = "Boss Lives: %d/%d" % [lives_remaining, max_lives]
	if boss_health_bar:
		boss_health_bar.max_value = max_health
		boss_health_bar.value = health

func _on_boss_shockwave_released(_origin: Vector2) -> void:
	_start_screen_shake(0.45, 10.0)

func _on_fly_spawn_requested(spawn_position: Vector2, behavior_name: String = "") -> void:
	if not day_active:
		return
	if boss_round_active and behavior_name == "":
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
		market_label.text = "Boss Fight" if boss_round_active else str(active_market_event.get("name", "Market"))
	if flies_label:
		flies_label.text = "Boss" if boss_round_active else "Flies: %d" % flies_left
	if swatted_label:
		swatted_label.text = "Swatted: %d" % day_flies_killed
	if money_label:
		money_label.text = "Money: ₱%d" % current_money
	if reputation_label:
		reputation_label.text = "Rep: %d" % reputation
	if satisfaction_label:
		satisfaction_label.text = "Sat: %d" % customer_satisfaction
	if rush_label:
		rush_label.text = "Rush" if rush_active else ""
	_set_boss_health_visible(boss_round_active)

	if match_timer_label:
		if boss_round_active:
			match_timer_label.text = "Time: ∞"
		else:
			var minutes := int(maxf(game_timer, 0.0)) / 60.0
			var seconds := int(maxf(game_timer, 0.0)) % 60
			match_timer_label.text = "Time: %d:%02d" % [minutes, seconds]

	_update_upgrade_buttons()

func _set_boss_health_visible(visible: bool) -> void:
	if boss_health_bar == null:
		return
	var boss_row := boss_health_bar.get_parent() as Control
	if boss_row != null:
		boss_row.visible = visible

func _update_upgrade_buttons() -> void:
	if swatter_entity == null:
		return

	if upgrade_label:
		upgrade_label.text = "Upgrades"

	for upgrade_name in upgrade_buttons.keys():
		var button := upgrade_buttons[upgrade_name] as Button
		var cost := int(swatter_entity.call("get_upgrade_cost", upgrade_name))
		var icon_texture := load(icon_paths[upgrade_name]) as Texture2D
		button.icon = icon_texture
		button.text = "₱%d" % cost
		button.disabled = not _can_afford_upgrade(cost) or not day_active

func _update_customer_spawns(delta: float) -> void:
	if not day_active or boss_round_active or customer_container == null:
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
		_update_bankruptcy_state()
		spawn_floating_money_text(payout, hand_node.global_position, true)
		day_gross_sales += payout
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
	_update_bankruptcy_state()
	if _check_debt_limit("Maximum debt reached."):
		return
	swatter_entity.call("upgrade", upgrade_name)
	_check_loss_conditions()
	_update_hud()

func _can_afford_upgrade(cost: int) -> bool:
	return current_money >= cost

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
	if _check_debt_limit("Maximum debt reached."):
		return
	if customer_satisfaction <= 0:
		_game_over("Customer satisfaction reached 0.")
	elif reputation <= 0:
		_game_over("Market reputation reached 0.")

func _check_debt_limit(reason: String) -> bool:
	if day_active and current_money <= MAX_DEBT_LIMIT:
		_game_over(reason)
		return true
	return false

func spawn_floating_money_text(amount: int, position: Vector2, is_income: bool) -> void:
	if hud_layer == null:
		return

	var label := Label.new()
	label.text = "%s₱%d" % ["+" if is_income else "-", abs(amount)]
	label.add_theme_color_override("font_color", Color(0.16, 0.82, 0.28) if is_income else Color(1.0, 0.16, 0.12))
	label.add_theme_font_size_override("font_size", 26)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = position
	hud_layer.add_child(label)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(label, "position", position + Vector2(0, -56), 1.35)
	tween.tween_property(label, "modulate:a", 0.0, 1.35)
	tween.chain().tween_callback(Callable(label, "queue_free"))

func _get_active_customer_count() -> int:
	if customer_container == null:
		return 0
	var count := 0
	for customer in customer_container.get_children():
		if not customer.is_queued_for_deletion():
			count += 1
	return count

func _get_target_food_count() -> int:
	return _get_target_food_count_for_day(market_day)

func _get_target_food_count_for_day(day: int) -> int:
	return mini(BASE_FOOD_COUNT + int(floor(float(day - 1) / 6.0)), 8)

func _get_next_restock_config(preferred_category: String):
	if _has_prepared_restock_plan(market_day):
		var planned_configs := prepared_restock_plan.get("food_configs", []) as Array
		var config_index := active_placed_food_records.size()
		if config_index < planned_configs.size():
			return planned_configs[config_index]

	return FOOD_SCRIPT.get_random_config_for_category(preferred_category)

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

func _start_screen_shake(duration: float, strength: float) -> void:
	screen_shake_duration = duration
	screen_shake_timer = duration
	screen_shake_strength = strength

func _update_screen_shake(delta: float) -> void:
	if screen_shake_timer <= 0.0:
		position = base_scene_position
		return

	screen_shake_timer = maxf(screen_shake_timer - delta, 0.0)
	var fade := screen_shake_timer / maxf(screen_shake_duration, 0.001)
	position = base_scene_position + Vector2(
		randf_range(-screen_shake_strength, screen_shake_strength) * fade,
		randf_range(-screen_shake_strength, screen_shake_strength) * fade
	)
	if screen_shake_timer <= 0.0:
		position = base_scene_position

func _get_active_food_count(excluded_food: Node = null) -> int:
	if food_container == null:
		return 0
	var count := 0
	for food in food_container.get_children():
		if food == excluded_food or food.is_queued_for_deletion():
			continue
		count += 1
	return count
