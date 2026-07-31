extends Node2D

signal financial_reports_generated(day_end_report: Dictionary, pre_day_forecast: Dictionary)

const GameConfig = preload("res://Backend/Game/GameConfig.gd")
const GameUI = preload("res://Backend/Game/GameUI.gd")
const GameFlow = preload("res://Backend/Game/GameFlow.gd")
const GameSystems = preload("res://Backend/Game/GameSystems.gd")

const BOOK_POP_SFX_PATH := "res://assets/Sound Effects/sound_fx/book_pop.mp3"
const BOOK_FLIP_SFX_PATH := "res://assets/Sound Effects/sound_fx/book_flip.mp3"
const DOOR_SHUT_SFX_PATH := "res://assets/Sound Effects/sound_fx/door_shut.mp3"
const BOSS_WARNING_SFX_PATH := "res://assets/Sound Effects/sound_fx/boss_warning.mp3"


@export var start_run_on_ready := true

var game_timer := 0.0
var market_day := 1
var difficulty_level := 1
var current_money := 0
var boss_round_active := false
var boss_round_pending := false
var boss_warning_shown := false
var active_knight_guards: Array[Node2D] = []
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
var day_uses_prepared_restock_plan := false
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
var upgrade_cost_labels := {}
var skill_label: Label
var skill_buttons := {}
var skill_cost_labels := {}
var skill_effect_overlays := {}
var skill_effect_textures := {}
var skill_timers := {}
var skill_duration_list: HBoxContainer
var pause_button: TextureButton
var pause_overlay: Control
var pause_menu_box: VBoxContainer
var pause_quit_button: TextureButton
var pause_resume_button: TextureButton
var gameplay_paused := false
var big_fan_popup: Control
var big_fan_choice := "left"
var big_fan_sprite: Sprite2D
var big_fan_direction := 0.0
var fan_camera_offset := Vector2.ZERO
var default_menu_panel: PanelContainer
var result_art_root: Control
var result_board: Control
var result_texture_rect: TextureRect
var result_motion_root: Control
var result_content: VBoxContainer
var result_title_label: Label
var result_body_label: Label
var result_warning_label: Label
var financial_button: TextureButton
var result_start_button: TextureButton
var boss_warning_root: Control
var boss_warning_top: TextureRect
var boss_warning_bottom: TextureRect
var boss_warning_board: Control
var boss_warning_content: VBoxContainer
var boss_warning_title_label: Label
var boss_warning_body_label: Label
var boss_warning_hint_label: Label
var boss_warning_enter_button: TextureButton
var game_over_root: Control
var game_over_background: TextureRect
var game_over_fly: TextureRect
var game_over_data_label: Label
var game_over_try_again_button: TextureButton
var game_over_home_button: TextureButton
var result_transition_active := false
var game_over_action := ""
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

var ui: GameUI
var flow: GameFlow
var systems: GameSystems

func _ready() -> void:
	randomize()
	get_tree().paused = false
	base_scene_position = position
	_build_game_nodes()
	_build_sfx_players()
	big_fan_sprite = get_node_or_null("BigFanIcon") as Sprite2D
	_build_swatter()
	ui = GameUI.new(self)
	systems = GameSystems.new(self)
	flow = GameFlow.new(self)
	ui.build_hud()
	ui.build_menu()
	if start_run_on_ready:
		flow.start_new_run()
	else:
		ui.show_start_menu()

func _process(delta: float) -> void:
	systems.update_big_fan_effect(delta)
	systems.update_screen_shake(delta)
	if not day_active:
		return

	systems.update_swatter(delta)
	systems.update_rush_hour(delta)
	systems.update_customer_spawns(delta)
	_process_day_clock(delta)
	_maintain_food_loop()
	systems.update_skills(delta)
	if boss_round_active:
		_update_background_animation(delta)
		return
	_maintain_fly_loop()
	_update_background_animation(delta)

func _input(event: InputEvent) -> void:
	if not day_active:
		return
	if big_fan_popup != null and big_fan_popup.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		systems.start_swatter_attack()

func _process_day_clock(delta: float) -> void:
	if boss_round_active:
		ui.update_hud()
		return

	game_timer -= delta
	if game_timer <= 0.0:
		flow.complete_day()
		return

	ui.update_hud()

func _maintain_food_loop() -> void:
	if _get_active_food_count() < _get_target_food_count():
		systems.spawn_single_food_loop()

func _maintain_fly_loop() -> void:
	if boss_round_active:
		return

	var max_active_flies := _get_max_active_flies()
	var desired_floor: int = mini(max_active_flies, maxi(5, int(ceil(float(GameConfig.MARKET_PROGRESSION.get_fly_count(market_day, active_market_event)) * GameConfig.FLY_REFILL_RATIO))))
	if flies_left >= desired_floor:
		return

	var bounds := _get_fly_bounds()
	var spawn_count: int = mini(4, mini(desired_floor - flies_left, max_active_flies - flies_left))
	for _index in range(spawn_count):
		_spawn_fly(
			Vector2(randf_range(bounds.position.x, bounds.end.x), randf_range(bounds.position.y, bounds.end.y)),
			bounds,
			true
		)
		flies_left += 1
	ui.update_hud()

func _get_max_active_flies() -> int:
	return int(floor(GameConfig.MAX_ACTIVE_FLIES_BASE + float(market_day) * GameConfig.MAX_ACTIVE_FLIES_PER_DAY))

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

func _build_sfx_players() -> void:
	var sfx_food_spawn := AudioStreamPlayer2D.new()
	sfx_food_spawn.name = "sfx_food_spawn"
	sfx_food_spawn.stream = load("res://assets/Sound Effects/sound_fx/food_spawn.mp3")
	add_child(sfx_food_spawn)

	var sfx_spoil := AudioStreamPlayer2D.new()
	sfx_spoil.name = "sfx_spoil"
	sfx_spoil.stream = load("res://assets/Sound Effects/sound_fx/spoil.mp3")
	add_child(sfx_spoil)

	var sfx_fly_kill := AudioStreamPlayer2D.new()
	sfx_fly_kill.name = "sfx_fly_kill"
	sfx_fly_kill.stream = load("res://assets/Sound Effects/sound_fx/fly_kill.mp3")
	add_child(sfx_fly_kill)

func _connect_button_sfx(button: BaseButton) -> void:
	if button == null:
		return
	var ui_button_callable := Callable(AudioManager, "play_ui_button")
	if not button.pressed.is_connected(ui_button_callable):
		button.pressed.connect(ui_button_callable)

func _build_swatter() -> void:
	swatter_entity = GameConfig.SWATTER_SCRIPT.new()
	swatter_entity.name = "SwatterEnergy"
	swatter_entity.connect("energy_changed", _on_swatter_energy_changed)
	add_child(swatter_entity)

	swatter_layer = CanvasLayer.new()
	swatter_layer.name = "Swatter"
	swatter_layer.layer = 200
	add_child(swatter_layer)

	swatter_sprite = Sprite2D.new()
	swatter_sprite.texture = GameConfig.SWATTER_DEFAULT_TEXTURE
	swatter_sprite.centered = false
	swatter_sprite.offset = -GameConfig.SWATTER_OFFSET
	swatter_sprite.z_index = 1000
	swatter_sprite.visible = false
	swatter_layer.add_child(swatter_sprite)

func _get_fly_bounds() -> Rect2:
	var viewport_size := get_viewport_rect().size
	return Rect2(
		Vector2(GameConfig.EDGE_PADDING, GameConfig.TOP_SAFE_AREA + GameConfig.EDGE_PADDING),
		Vector2(max(viewport_size.x - GameConfig.EDGE_PADDING * 2.0, 1.0), max(viewport_size.y - GameConfig.TOP_SAFE_AREA - GameConfig.EDGE_PADDING * 2.0, 1.0))
	)

func _spawn_fly(spawn_position: Vector2, bounds: Rect2, include_mother: bool, force_mother: bool = false, forced_behavior_name: String = "") -> void:
	var fly = GameConfig.FLY_SCENE.instantiate()
	fly.position = Vector2(clampf(spawn_position.x, bounds.position.x, bounds.end.x), clampf(spawn_position.y, bounds.position.y, bounds.end.y))
	var new_behavior = fly.get_forced_mother_behavior(market_day, active_market_event) if force_mother else fly.get_random_behavior(include_mother, market_day, active_market_event)
	if not forced_behavior_name.is_empty():
		new_behavior = fly.get_behavior_by_name(forced_behavior_name, market_day, active_market_event)
	fly.configure(new_behavior, bounds)
	fly.died.connect(_on_fly_died)
	fly.spawn_requested.connect(_on_fly_spawn_requested)
	fly_container.add_child(fly)

func _spawn_single_food_loop() -> bool:
	return systems.spawn_single_food_loop()

func _apply_food_economy(food: Node2D) -> void:
	var config = food.get("config")
	if config == null:
		return

	var category: String = config.category
	var market_multiplier := GameConfig.MARKET_PROGRESSION.get_market_price_multiplier(market_day, daily_price_roll, active_market_event, category)
	var sell_multiplier := GameConfig.MARKET_PROGRESSION.get_sell_price_multiplier(market_day, active_market_event, category)
	var spoil_multiplier := GameConfig.MARKET_PROGRESSION.get_food_spoil_multiplier(active_market_event)
	food.call("apply_market_modifiers", market_multiplier, sell_multiplier, spoil_multiplier)

func _get_next_restock_config(preferred_category: String):
	if _has_prepared_restock_plan(market_day):
		var planned_configs := prepared_restock_plan.get("food_configs", []) as Array
		var config_index := active_placed_food_records.size()
		if config_index < planned_configs.size():
			return planned_configs[config_index]

	return GameConfig.FOOD_SCRIPT.get_random_config_for_category(preferred_category)

func _has_prepared_restock_plan(day: int) -> bool:
	return int(prepared_restock_plan.get("day", -1)) == day

func _get_stock_cost_for_config(config, day: int, event: Dictionary, price_roll: float) -> int:
	if config == null:
		return 0

	var category: String = config.category
	var market_multiplier := GameConfig.MARKET_PROGRESSION.get_market_price_multiplier(day, price_roll, event, category)
	return int(ceilf(float(config.base_market_price) * market_multiplier))

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

func _show_starting_day_report_screen() -> void:
	menu_state = "starting_day_report"
	day_active = false
	_set_swatter_active(false)
	_set_boss_health_visible(false)
	menu_layer.visible = true
	hud_layer.visible = false
	if pause_button:
		pause_button.visible = false
	food_container.visible = false
	fly_container.visible = false
	customer_container.visible = false
	ui.show_result_art_panel()
	if forecast_warning_label:
		forecast_warning_label.visible = false

	result_title_label.text = "Day %d Briefing" % market_day
	result_body_label.text = "--- TODAY'S MARKET ---\nMarket: %s\nStarting Wallet: %s\nTime Limit: %s\nFood Stock: %d items\nFly Activity: %d flies\n\n--- GOAL ---\nProtect the food, serve customers, and finish the day with profit." % [
		str(active_market_event.get("name", "Market")),
		_format_peso(current_money),
		_format_duration(game_timer),
		_get_target_food_count(),
		day_initial_flies,
	]
	result_warning_label.visible = false
	_apply_result_text_fit(result_body_label.text, false)
	financial_button.visible = false
	financial_button.disabled = true
	result_start_button.visible = true
	result_start_button.disabled = false
	_play_result_container_entrance()

func _show_day_end_summary_screen(completed_market_day: int) -> void:
	menu_state = "day_end_summary"
	menu_layer.visible = true
	hud_layer.visible = false
	ui.show_result_art_panel()
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
	_play_result_container_entrance()
	play_button.text = "Next: Financial Forecast"

func _show_pre_day_forecast_screen(animate_intro := false) -> void:
	menu_state = "pre_day_forecast"
	menu_layer.visible = true
	hud_layer.visible = false
	ui.show_result_art_panel()

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
			forecast_warning_label.text = "⚠️ WARNING: BANKRUPTCY IMMINENT! (Strike %d of %d)" % [strike_count, GameConfig.MAX_BANKRUPTCY_STRIKES]
			forecast_warning_label.add_theme_color_override("font_color", Color(1.0, 0.12, 0.08))
		else:
			forecast_warning_label.text = "Finances Stable"
			forecast_warning_label.add_theme_color_override("font_color", Color(0.18, 0.72, 0.30))

	play_button.text = "Start Day %d" % market_day
	if bool(next_day_forecast.get("is_bankruptcy_state", false)):
		var strike_count := int(next_day_forecast.get("bankruptcy_strikes", bankruptcy_strikes))
		result_warning_label.text = "WARNING: BANKRUPTCY IMMINENT! (Strike %d of %d)" % [strike_count, GameConfig.MAX_BANKRUPTCY_STRIKES]
	else:
		result_warning_label.text = "Finances Stable"
	result_warning_label.add_theme_color_override("font_color", GameConfig.RESULT_TEXT_COLOR)
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
		await _play_bouncy_pop(financial_button)
	if result_start_button:
		result_start_button.visible = false

	var fade_out := create_tween()
	fade_out.set_parallel(true)
	fade_out.tween_property(result_motion_root, "position", Vector2(0, -28), 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fade_out.tween_property(result_motion_root, "modulate:a", 0.0, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fade_out.finished

	if financial_button:
		financial_button.visible = false

	AudioManager.play_book_flip()
	for frame_index in range(GameConfig.RESULT_FLIP_FRAME_COUNT):
		result_texture_rect.texture = _get_result_flip_frame(frame_index)
		await get_tree().create_timer(1.0 / GameConfig.RESULT_FLIP_FPS).timeout

	result_texture_rect.texture = GameConfig.RESULT_CONTAINER_TEXTURE
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

func _play_result_container_entrance() -> void:
	if not result_board:
		return
	AudioManager.play_sfx_path(BOOK_POP_SFX_PATH)
	result_board.scale = Vector2(1.65, 1.65)
	var entrance_tween := create_tween()
	entrance_tween.tween_property(result_board, "scale", Vector2(0.94, 0.94), 0.34).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	entrance_tween.tween_property(result_board, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _play_game_over_entrance() -> void:
	if not game_over_root:
		return

	game_over_background.position = Vector2(0, GameConfig.GAME_OVER_FRAME_SIZE.y)
	game_over_fly.position = Vector2(0, GameConfig.GAME_OVER_FRAME_SIZE.y)
	game_over_data_label.position = GameConfig.GAME_OVER_DATA_POSITION + Vector2(0, 26)
	game_over_data_label.modulate.a = 0.0
	game_over_try_again_button.modulate.a = 0.0
	game_over_home_button.modulate.a = 0.0
	game_over_try_again_button.disabled = true
	game_over_home_button.disabled = true

	var background_tween := create_tween()
	background_tween.tween_property(game_over_background, "position", Vector2.ZERO, 0.46).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	var fly_tween := create_tween()
	fly_tween.tween_interval(0.5)
	fly_tween.tween_property(game_over_fly, "position", Vector2.ZERO, 0.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await fly_tween.finished

	var content_tween := create_tween()
	content_tween.set_parallel(true)
	content_tween.tween_property(game_over_data_label, "position", GameConfig.GAME_OVER_DATA_POSITION, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	content_tween.tween_property(game_over_data_label, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	content_tween.tween_property(game_over_try_again_button, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	content_tween.tween_property(game_over_home_button, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await content_tween.finished
	game_over_try_again_button.disabled = false
	game_over_home_button.disabled = false

func _on_game_over_button_pressed(action: String) -> void:
	if result_transition_active:
		return
	game_over_action = action
	_play_game_over_button_action()

func _play_game_over_button_action() -> void:
	result_transition_active = true
	var target := game_over_try_again_button if game_over_action == "try_again" else game_over_home_button
	if target:
		target.disabled = true
		await _play_bouncy_pop(target)
	if game_over_try_again_button:
		game_over_try_again_button.disabled = false
	if game_over_home_button:
		game_over_home_button.disabled = false
	result_transition_active = false
	if game_over_action == "home":
		SceneFlow.go_to_main_menu()
	else:
		_start_new_run()

func _play_start_day_button_animation() -> void:
	result_transition_active = true
	var starting_report := menu_state == "starting_day_report"
	if result_start_button:
		result_start_button.disabled = true
	if result_board:
		await _play_bouncy_pop(result_board)
	if result_start_button:
		result_start_button.disabled = false
	result_transition_active = false
	if starting_report:
		_begin_prepared_day()
	else:
		_start_day()

func _play_enter_boss_button_animation() -> void:
	result_transition_active = true
	if boss_warning_enter_button:
		boss_warning_enter_button.disabled = true
	await _play_boss_warning_exit()
	if boss_warning_enter_button:
		boss_warning_enter_button.disabled = false
	boss_warning_shown = true
	await _play_boss_start_countdown()
	result_transition_active = false
	_start_day()

func _play_boss_warning_exit() -> void:
	if boss_warning_root == null or boss_warning_top == null or boss_warning_bottom == null or boss_warning_board == null:
		return

	var content_tween := create_tween()
	content_tween.set_parallel(true)
	if boss_warning_content:
		content_tween.tween_property(boss_warning_content, "position", GameConfig.BOSS_WARNING_TEXT_POSITION + Vector2(0, 34), 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		content_tween.tween_property(boss_warning_content, "modulate:a", 0.0, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if boss_warning_enter_button:
		content_tween.tween_property(boss_warning_enter_button, "scale", Vector2(1.08, 1.08), 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		content_tween.tween_property(boss_warning_enter_button, "scale", Vector2.ZERO, 0.18).set_delay(0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		content_tween.tween_property(boss_warning_enter_button, "modulate:a", 0.0, 0.18).set_delay(0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await content_tween.finished

	var board_tween := create_tween()
	board_tween.set_parallel(true)
	board_tween.tween_property(boss_warning_board, "scale", Vector2(1.08, 1.08), 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	board_tween.tween_property(boss_warning_board, "scale", Vector2.ZERO, 0.26).set_delay(0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	board_tween.tween_property(boss_warning_board, "modulate:a", 0.0, 0.22).set_delay(0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await board_tween.finished

	var shutter_tween := create_tween()
	shutter_tween.set_parallel(true)
	shutter_tween.tween_property(boss_warning_top, "position", Vector2(0, -GameConfig.BOSS_SHUTTER_HALF_SIZE.y), 0.64).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	shutter_tween.tween_property(boss_warning_bottom, "position", Vector2(0, GameConfig.GAME_OVER_FRAME_SIZE.y), 0.64).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await shutter_tween.finished
	boss_warning_root.visible = false

func _play_boss_start_countdown() -> void:
	if menu_layer == null:
		return

	var countdown_root := Control.new()
	countdown_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	countdown_root.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_layer.add_child(countdown_root)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.0, 0.0, 0.0, 0.38)
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	countdown_root.add_child(dimmer)

	var word_label := Label.new()
	word_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	word_label.size = GameConfig.GAME_CANVAS_SIZE
	word_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	word_label.add_theme_font_override("font", GameConfig.JERSEY_FONT)
	word_label.add_theme_font_size_override("font_size", GameConfig.BOSS_COUNTDOWN_FONT_SIZE)
	word_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
	word_label.add_theme_constant_override("shadow_offset_x", 4)
	word_label.add_theme_constant_override("shadow_offset_y", 4)
	word_label.pivot_offset = GameConfig.GAME_CANVAS_SIZE * 0.5
	countdown_root.add_child(word_label)

	await _play_countdown_word(word_label, "READY", Color("#b0ed17"), false)
	await _play_countdown_word(word_label, "SET", Color("#b0ed17"), false)
	await _play_countdown_word(word_label, "SWAT", Color("#bd4a13"), true)

	var fade_tween := create_tween()
	fade_tween.tween_property(countdown_root, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fade_tween.finished
	countdown_root.queue_free()

func _play_countdown_word(label: Label, word: String, color: Color, shake: bool) -> void:
	label.text = word
	label.add_theme_color_override("font_color", color)
	label.position = Vector2.ZERO
	label.scale = Vector2(0.2, 0.2)
	label.modulate.a = 0.0

	var pop_tween := create_tween()
	pop_tween.set_parallel(true)
	pop_tween.tween_property(label, "modulate:a", 1.0, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(label, "scale", Vector2(1.16, 1.16), 0.16).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	pop_tween.chain().tween_property(label, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await pop_tween.finished

	if shake:
		var shake_tween := create_tween()
		shake_tween.tween_property(label, "position", Vector2(14, 0), 0.035)
		shake_tween.tween_property(label, "position", Vector2(-12, 5), 0.035)
		shake_tween.tween_property(label, "position", Vector2(8, -4), 0.035)
		shake_tween.tween_property(label, "position", Vector2.ZERO, 0.05)
		await shake_tween.finished

	var out_tween := create_tween()
	out_tween.tween_interval(0.18)
	out_tween.tween_property(label, "modulate:a", 0.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await out_tween.finished

func _play_boss_warning_intro() -> void:
	if boss_warning_root == null or boss_warning_top == null or boss_warning_bottom == null or boss_warning_board == null:
		return

	result_transition_active = true
	boss_warning_root.position = Vector2.ZERO
	boss_warning_top.position = Vector2(0, -GameConfig.BOSS_SHUTTER_HALF_SIZE.y)
	boss_warning_bottom.position = Vector2(0, GameConfig.GAME_OVER_FRAME_SIZE.y)
	boss_warning_board.visible = false
	boss_warning_board.scale = Vector2(1.7, 1.7)
	boss_warning_board.modulate.a = 0.0
	if boss_warning_content:
		boss_warning_content.position = GameConfig.BOSS_WARNING_TEXT_POSITION + Vector2(0, 30)
		boss_warning_content.modulate.a = 0.0
	if boss_warning_enter_button:
		boss_warning_enter_button.position = GameConfig.BOSS_WARNING_BUTTON_POSITION + Vector2(0, 30)
		boss_warning_enter_button.scale = Vector2.ONE
		boss_warning_enter_button.modulate.a = 0.0
		boss_warning_enter_button.disabled = true

	var shutter_tween := create_tween()
	shutter_tween.set_parallel(true)
	shutter_tween.tween_property(boss_warning_top, "position", Vector2.ZERO, 0.86).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	shutter_tween.tween_property(boss_warning_bottom, "position", Vector2(0, GameConfig.BOSS_SHUTTER_HALF_SIZE.y), 0.86).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await shutter_tween.finished
	AudioManager.play_sfx_path(DOOR_SHUT_SFX_PATH)

	var shake_tween := create_tween()
	shake_tween.tween_property(boss_warning_root, "position", Vector2(8, 0), 0.035)
	shake_tween.tween_property(boss_warning_root, "position", Vector2(-7, 3), 0.035)
	shake_tween.tween_property(boss_warning_root, "position", Vector2(5, -2), 0.035)
	shake_tween.tween_property(boss_warning_root, "position", Vector2.ZERO, 0.055)
	await shake_tween.finished

	boss_warning_board.visible = true
	AudioManager.play_sfx_path(BOSS_WARNING_SFX_PATH)
	var board_tween := create_tween()
	board_tween.set_parallel(true)
	board_tween.tween_property(boss_warning_board, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	board_tween.tween_property(boss_warning_board, "scale", Vector2(0.94, 0.94), 0.34).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	board_tween.chain().tween_property(boss_warning_board, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await board_tween.finished

	var content_tween := create_tween()
	content_tween.set_parallel(true)
	if boss_warning_content:
		content_tween.tween_property(boss_warning_content, "position", GameConfig.BOSS_WARNING_TEXT_POSITION, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		content_tween.tween_property(boss_warning_content, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if boss_warning_enter_button:
		content_tween.tween_property(boss_warning_enter_button, "position", GameConfig.BOSS_WARNING_BUTTON_POSITION, 0.34).set_delay(0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		content_tween.tween_property(boss_warning_enter_button, "modulate:a", 1.0, 0.34).set_delay(0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await content_tween.finished
	if boss_warning_enter_button:
		boss_warning_enter_button.disabled = false
	result_transition_active = false

func _play_bouncy_pop(target: Control, process_during_pause: bool = false) -> void:
	target.scale = Vector2.ONE
	var pop_tween := create_tween()
	if process_during_pause:
		pop_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	pop_tween.tween_property(target, "scale", Vector2(1.08, 1.08), 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(target, "scale", Vector2(0.86, 0.86), 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	pop_tween.tween_property(target, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await pop_tween.finished

func _play_control_bounce(target: Control) -> void:
	if target == null:
		return
	target.scale = Vector2.ONE
	var tween := create_tween()
	tween.tween_property(target, "scale", Vector2(1.08, 1.08), 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "scale", Vector2(0.92, 0.92), 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(target, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _play_skill_effect(skill_id: String) -> void:
	var overlay := skill_effect_overlays.get(skill_id) as TextureRect
	var atlas := skill_effect_textures.get(skill_id) as Texture2D
	if overlay == null or atlas == null:
		return
	overlay.visible = true
	overlay.modulate.a = 1.0
	var frame_time := 1.0 / GameConfig.SKILL_EFFECT_FPS
	var tween := create_tween()
	for frame_index in range(GameConfig.SKILL_EFFECT_FRAME_COUNT):
		tween.tween_callback(Callable(self, "_set_skill_effect_frame").bind(skill_id, frame_index))
		tween.tween_interval(frame_time)
	tween.tween_callback(Callable(self, "_hide_skill_effect").bind(skill_id))

func _set_skill_effect_frame(skill_id: String, frame_index: int) -> void:
	var overlay := skill_effect_overlays.get(skill_id) as TextureRect
	var atlas := skill_effect_textures.get(skill_id) as Texture2D
	if overlay == null or atlas == null:
		return
	overlay.texture = _get_atlas_frame(atlas, GameConfig.SKILL_EFFECT_FRAME_SIZE, frame_index)

func _hide_skill_effect(skill_id: String) -> void:
	var overlay := skill_effect_overlays.get(skill_id) as TextureRect
	if overlay == null:
		return
	overlay.visible = false
	overlay.texture = null

func _format_peso(amount: int) -> String:
	return "₱%d" % amount

func _format_duration(seconds: float) -> String:
	var total_seconds := int(round(seconds))
	var minutes := int(total_seconds / 60)
	var remaining_seconds := total_seconds % 60
	return "%d:%02d" % [minutes, remaining_seconds]

func _report_int(report: Dictionary, key: String) -> int:
	return int(report.get(key, 0))

func _prepare_restock_plan(day: int) -> Dictionary:
	if _has_prepared_restock_plan(day):
		return prepared_restock_plan

	var event := GameConfig.MARKET_PROGRESSION.get_market_event(day)
	var price_roll := GameConfig.MARKET_PROGRESSION.get_daily_price_roll()
	var food_configs: Array = []
	var expected_restock_cost := 0
	var preferred_category := str(event.get("food_category", ""))

	for _index in range(_get_target_food_count_for_day(day)):
		var config = GameConfig.FOOD_SCRIPT.get_random_config_for_category(preferred_category)
		food_configs.append(config)
		expected_restock_cost += _get_stock_cost_for_config(config, day, event, price_roll)

	return {
		"day": day,
		"market_event": event,
		"daily_price_roll": price_roll,
		"food_configs": food_configs,
		"expected_restock_cost": expected_restock_cost,
	}

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
		var minimum_distance := candidate_radius + float(placed["radius"]) + GameConfig.FOOD_GAP
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

func _is_boss_day(day: int) -> bool:
	return day > 0 and day % 10 == 0

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
	ui.update_hud()

func _on_boss_died(boss_node: Node) -> void:
	systems.on_boss_died(boss_node)

func _on_boss_spawn_requested(_spawn_position: Vector2, _behavior_name: String = "") -> void:
	systems.on_boss_spawn_requested(_spawn_position, _behavior_name)

func _on_boss_health_changed(lives_remaining: int, max_lives: int, health: int, max_health: int) -> void:
	systems.on_boss_health_changed(lives_remaining, max_lives, health, max_health)

func _on_boss_shockwave_released(_origin: Vector2) -> void:
	systems.on_boss_shockwave_released(_origin)

func _on_boss_guard_blink_requested() -> void:
	if active_knight_guards.is_empty():
		return
	var alive_guards: Array[Node2D] = []
	for guard in active_knight_guards:
		if is_instance_valid(guard) and guard.has_method("play_blink"):
			alive_guards.append(guard)
	if alive_guards.is_empty():
		return
	alive_guards.pick_random().call("play_blink")

func _on_boss_guard_protect_requested(active: bool) -> void:
	for guard in active_knight_guards:
		if is_instance_valid(guard) and guard.has_method("set_invulnerable"):
			guard.call("set_invulnerable", active)

func _on_knight_guard_died(_guard: Area2D) -> void:
	systems.on_knight_guard_died(_guard)

func _on_fly_spawn_requested(spawn_position: Vector2, behavior_name: String = "") -> void:
	systems.on_fly_spawn_requested(spawn_position, behavior_name)

func _on_customer_swatted(_hand: Area2D) -> void:
	systems.on_customer_swatted(_hand)

func _on_buyer_transaction_finished(hand_node: Area2D, status: String, payout: int) -> void:
	systems.on_buyer_transaction_finished(hand_node, status, payout)

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
	ui.play_control_bounce(upgrade_buttons.get(upgrade_name) as Control)
	_check_loss_conditions()
	ui.update_hud()

func _on_skill_pressed(skill_id: String) -> void:
	if swatter_entity == null or not day_active:
		return

	var definitions := GameConfig.BUY_SKILLS.get_skill_definitions()
	if not definitions.has(skill_id):
		return

	var def: Dictionary = definitions[skill_id]
	var cost := int(def.get("cost", 0))
	if float(skill_timers.get(skill_id, 0.0)) > 0.0:
		return
	if not _can_afford_skill(cost):
		return

	current_money -= cost
	_update_bankruptcy_state()
	if _check_debt_limit("Maximum debt reached."):
		return

	ui.play_control_bounce(skill_buttons.get(skill_id) as Control)
	ui.play_skill_effect(skill_id)
	systems.activate_skill(skill_id, def)
	ui.update_hud()

func _on_big_fan_choice(side: String) -> void:
	systems.on_big_fan_choice(side)

func _on_pause_pressed() -> void:
	if not day_active or gameplay_paused:
		return
	_set_pause_button_pressed_frame(true)
	_set_gameplay_paused(true)

func _on_pause_resume_pressed() -> void:
	if not gameplay_paused:
		return
	pause_resume_button.disabled = true
	await ui.play_bouncy_pop(pause_resume_button, true)
	pause_resume_button.disabled = false
	_set_gameplay_paused(false)

func _on_pause_quit_pressed() -> void:
	if not gameplay_paused:
		return
	pause_quit_button.disabled = true
	await ui.play_bouncy_pop(pause_quit_button, true)
	pause_quit_button.disabled = false
	_set_gameplay_paused(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	SceneFlow.go_to_main_menu()

func _on_menu_button_pressed() -> void:
	flow.on_menu_button_pressed()

func _start_new_run() -> void:
	flow.start_new_run()

func _start_day(show_starting_report := false) -> void:
	flow.start_day(show_starting_report)

func _complete_day() -> void:
	flow.complete_day()

func _complete_boss_round() -> void:
	flow.complete_boss_round()

func _begin_prepared_day() -> void:
	flow.begin_prepared_day()

func _show_boss_warning_screen() -> void:
	ui.show_boss_warning_screen()

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
	GameConfig.HIGH_SCORE_MANAGER.save_score(market_day)
	menu_layer.visible = true
	hud_layer.visible = false
	ui.show_game_over_art_panel()
	if forecast_warning_label:
		forecast_warning_label.visible = false
	result_label.text = "%s\nReached Day %d\nMoney: ₱%d\nReputation: %d\nSatisfaction: %d\nFlies swatted: %d" % [
		reason,
		market_day,
		current_money,
		reputation,
		customer_satisfaction,
		total_flies_killed
	]
	game_over_data_label.text = "%s\nReached Day %d\nMoney: %s\nReputation: %d\nSatisfaction: %d\nFlies swatted: %d" % [
		reason,
		market_day,
		_format_peso(current_money),
		reputation,
		customer_satisfaction,
		total_flies_killed
	]
	ui.play_game_over_entrance()
	play_button.text = "Restart Market"

func _game_over(reason: String) -> void:
	if not day_active:
		return

	_show_game_over(reason)

func _game_over_from_day_end(reason: String) -> void:
	_show_game_over(reason)

func _update_bankruptcy_state() -> void:
	pass

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

func _set_gameplay_paused(paused: bool) -> void:
	gameplay_paused = paused
	get_tree().paused = paused
	if pause_overlay:
		pause_overlay.visible = paused
	if pause_button:
		pause_button.visible = day_active
	if paused:
		_set_swatter_active(false)
		ui.play_pause_overlay_entrance()
	elif day_active:
		_set_pause_button_pressed_frame(false)
		_set_swatter_active(true)

func _set_pause_button_pressed_frame(pressed_frame: bool) -> void:
	if pause_button == null:
		return
	var frame_index := 1 if pressed_frame else 0
	var frame := ui.get_atlas_frame(GameConfig.PAUSE_BUTTON_TEXTURE, GameConfig.PAUSE_BUTTON_FRAME_SIZE, frame_index)
	pause_button.texture_normal = frame
	pause_button.texture_hover = frame
	pause_button.texture_pressed = frame

func _set_swatter_active(active: bool) -> void:
	if swatter_sprite != null:
		swatter_sprite.visible = active
		if active:
			swatter_sprite.global_position = get_viewport().get_mouse_position()
			_show_default_swatter()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN if active else Input.MOUSE_MODE_VISIBLE)

func _show_default_swatter() -> void:
	swatter_sprite.texture = GameConfig.SWATTER_DEFAULT_TEXTURE
	swatter_sprite.hframes = 1
	swatter_sprite.vframes = 1
	swatter_sprite.frame = 0
	swatter_attack_timer = 0.0
	swatter_frame_timer = 0.0

func _start_screen_shake(duration: float, strength: float) -> void:
	screen_shake_duration = duration
	screen_shake_timer = duration
	screen_shake_strength = strength

func _mega_swatter_hit_area() -> void:
	if fly_container == null or swatter_entity == null:
		return
	var cursor := get_viewport().get_mouse_position()
	var size_mult := float(swatter_entity.call("get_size_multiplier"))
	var hit_radius := 90.0 * size_mult
	var damage_amount := int(swatter_entity.call("get_damage")) if swatter_entity.has_method("get_damage") else 1
	for fly in fly_container.get_children():
		if not is_instance_valid(fly) or fly.is_queued_for_deletion() or not fly.has_method("take_damage"):
			continue
		if fly.global_position.distance_to(cursor) <= hit_radius:
			fly.call("take_damage", damage_amount)

func _set_boss_health_visible(visible: bool) -> void:
	ui._set_boss_health_visible(visible)

func _spawn_boss_fight() -> void:
	systems.spawn_boss_fight()

func _spawn_flies() -> void:
	systems.spawn_flies()

func _spawn_food() -> void:
	systems.spawn_food()

func _update_hud() -> void:
	ui.update_hud()

func _update_swatter(delta: float) -> void:
	systems.update_swatter(delta)

func _start_swatter_attack() -> void:
	systems.start_swatter_attack()

func _update_customer_spawns(delta: float) -> void:
	systems.update_customer_spawns(delta)

func _update_rush_hour(delta: float) -> void:
	systems.update_rush_hour(delta)

func _update_skills(delta: float) -> void:
	systems.update_skills(delta)

func _update_big_fan_effect(delta: float) -> void:
	systems.update_big_fan_effect(delta)

func _update_screen_shake(delta: float) -> void:
	systems.update_screen_shake(delta)

func _reset_skill_state() -> void:
	systems.reset_skill_state()

func _activate_skill(skill_id: String, def: Dictionary) -> void:
	systems.activate_skill(skill_id, def)

func _set_food_protection(value: bool) -> void:
	if food_container == null:
		return
	for food in food_container.get_children():
		if is_instance_valid(food) and food.has_method("set_protected"):
			food.call("set_protected", value)

func try_intercept_boss_hit(boss: Node2D, damage: int) -> bool:
	if boss == null or active_knight_guards.is_empty() or randf() > GameConfig.BOSS_GUARD_INTERCEPT_CHANCE:
		return false
	var alive_guards: Array[Node2D] = []
	for guard in active_knight_guards:
		if is_instance_valid(guard) and not guard.is_queued_for_deletion() and guard.has_method("intercept_attack"):
			alive_guards.append(guard)
	if alive_guards.is_empty():
		return false
	alive_guards.pick_random().call("intercept_attack", boss.global_position, damage)
	return true

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
	if day_active and current_money <= GameConfig.MAX_DEBT_LIMIT:
		_game_over(reason)
		return true
	return false

func _can_afford_upgrade(cost: int) -> bool:
	return current_money >= cost

func _can_afford_skill(cost: int) -> bool:
	return current_money >= cost

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

func _get_next_customer_spawn_time() -> float:
	var bounds := GameConfig.MARKET_PROGRESSION.get_customer_spawn_bounds(market_day, active_market_event, rush_active)
	return randf_range(bounds.x, bounds.y)

func _get_active_food_count(excluded_food: Node = null) -> int:
	if food_container == null:
		return 0
	var count := 0
	for food in food_container.get_children():
		if food == excluded_food or food.is_queued_for_deletion():
			continue
		count += 1
	return count

func _get_target_food_count() -> int:
	return _get_target_food_count_for_day(market_day)

func _get_target_food_count_for_day(day: int) -> int:
	return mini(GameConfig.BASE_FOOD_COUNT + int(floor(float(day - 1) / 6.0)), 8)

func _get_result_flip_frame(frame_index: int) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = GameConfig.RESULT_FLIP_TEXTURE
	texture.region = Rect2(GameConfig.RESULT_FRAME_SIZE.x * frame_index, 0, GameConfig.RESULT_FRAME_SIZE.x, GameConfig.RESULT_FRAME_SIZE.y)
	return texture

func _get_atlas_frame(atlas: Texture2D, frame_size: Vector2, frame_index: int) -> AtlasTexture:
	return ui.get_atlas_frame(atlas, frame_size, frame_index)
