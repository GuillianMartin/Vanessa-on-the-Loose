extends RefCounted
const GameConfig = preload("res://Backend/Game/GameConfig.gd")
var game: Node2D

func _init(p_game: Node2D) -> void:
	game = p_game

func start_new_run() -> void:
	game.market_day = 1
	game.difficulty_level = 1
	game.boss_round_active = false
	game.boss_round_pending = false
	game.boss_warning_shown = false
	game.current_money = GameConfig.MARKET_PROGRESSION.STARTING_MONEY
	game.bankruptcy_strikes = 0
	game.is_bankrupt = false
	game.current_day_report = {}
	game.next_day_forecast = {}
	game.prepared_restock_plan = {}
	game.bankruptcy_strike_forecast_day = -1
	game.restock_costs_prepaid = false
	game.reputation = GameConfig.MARKET_PROGRESSION.STARTING_REPUTATION
	game.customer_satisfaction = GameConfig.MARKET_PROGRESSION.STARTING_SATISFACTION
	game.score = 0
	game.total_flies_killed = 0
	game.total_customers_served = 0
	if game.swatter_entity != null and game.swatter_entity.has_method("reset_upgrades"):
		game.swatter_entity.call("reset_upgrades")
	start_day(true)

func start_day(show_starting_report := false) -> void:
	if game.boss_round_pending and not game.boss_warning_shown:
		game._show_boss_warning_screen()
		return

	prepare_day()
	if show_starting_report:
		game._show_starting_day_report_screen()
		return

	begin_prepared_day()

func prepare_day() -> void:
	var starting_boss_round: bool = game.boss_round_pending
	game.day_uses_prepared_restock_plan = not starting_boss_round and game._has_prepared_restock_plan(game.market_day)
	game.boss_round_active = starting_boss_round
	game.active_market_event = GameConfig.MARKET_PROGRESSION.get_market_event(game.market_day)
	game.difficulty_level = GameConfig.MARKET_PROGRESSION.get_difficulty_level(game.market_day)
	if game.day_uses_prepared_restock_plan:
		game.active_market_event = game.prepared_restock_plan["market_event"] as Dictionary
		game.daily_price_roll = float(game.prepared_restock_plan["daily_price_roll"])
		game.current_money = int(game.next_day_forecast.get("final_starting_capital", game.current_money))
	else:
		game.daily_price_roll = GameConfig.MARKET_PROGRESSION.get_daily_price_roll()
	game.is_bankrupt = game.current_money < 0
	game.restock_costs_prepaid = game.day_uses_prepared_restock_plan or game.boss_round_active
	game.day_money_start = game.current_money
	game.day_gross_sales = 0
	game.day_money_earned = 0
	game.day_stock_spent = 0
	game.day_leftover_earned = 0
	game.day_fly_reward = 0
	game.day_flies_killed = 0
	game.day_customers_served = 0
	game.day_reputation_start = game.reputation
	game.game_timer = 999999.0 if game.boss_round_active else GameConfig.MARKET_PROGRESSION.DAY_DURATION_SECONDS
	game.flies_left = 0 if game.boss_round_active else mini(GameConfig.MARKET_PROGRESSION.get_fly_count(game.market_day, game.active_market_event), game._get_max_active_flies())
	game.day_initial_flies = game.flies_left
	game.rush_active = false
	game.rush_timer = 0.0
	game.rush_check_timer = randf_range(18.0, 45.0)
	game.active_placed_food_records.clear()
	game.customer_spawn_timer = game._get_next_customer_spawn_time()

func begin_prepared_day() -> void:
	game.swatter_entity.call("reset")
	game.swatter_entity.call("set_day", game.market_day)
	game._reset_skill_state()
	game.day_active = true
	game._set_swatter_active(true)
	game.menu_layer.visible = false
	if game.forecast_warning_label:
		game.forecast_warning_label.visible = false
	game.hud_layer.visible = true
	if game.pause_button:
		game.pause_button.visible = true
	game.food_container.visible = true
	game.fly_container.visible = true
	game.customer_container.visible = true
	if game._check_debt_limit("Maximum debt reached."):
		game.restock_costs_prepaid = false
		return
	game._apply_market_visuals()
	game._update_hud()
	game._spawn_food()
	if game.day_uses_prepared_restock_plan:
		game.prepared_restock_plan = {}
	game.day_uses_prepared_restock_plan = false
	game.restock_costs_prepaid = false
	game._update_bankruptcy_state()
	if game.day_active:
		if game.boss_round_active:
			game._spawn_boss_fight()
		else:
			game._spawn_flies()

func complete_day() -> void:
	if game.boss_round_active:
		complete_boss_round()
		return

	game.day_active = false
	if game.pause_button:
		game.pause_button.visible = false
	game._set_swatter_active(false)
	game.day_leftover_earned = game._sell_leftover_food()
	game.day_fly_reward = GameConfig.REWARD_MANAGER.calculate_fly_reward(game.day_flies_killed)
	game.current_money += game.day_fly_reward
	game.day_money_earned += game.day_fly_reward
	game._clear_flies()
	game._clear_food()
	game._clear_customers()

	var completed_market_day: int = game.market_day
	game.current_day_report = game.generate_day_end_report()

	if game.is_bankrupt and game.current_money < 0:
		game._game_over_from_day_end("Bankruptcy was not recovered before market close.")
		return

	game.boss_round_pending = game._is_boss_day(game.market_day + 1)
	if game.boss_round_pending:
		game.boss_warning_shown = false
	game.market_day += 1
	game.next_day_forecast = game.generate_pre_day_forecast()
	game.financial_reports_generated.emit(game.current_day_report, game.next_day_forecast)
	if bool(game.next_day_forecast.get("is_bankruptcy_state", false)) and game.bankruptcy_strikes >= GameConfig.MAX_BANKRUPTCY_STRIKES:
		game.market_day = completed_market_day
		game._game_over_from_day_end("Bankruptcy strike limit reached.")
		return

	game._show_day_end_summary_screen(completed_market_day)

func complete_boss_round() -> void:
	game.day_active = false
	game.boss_round_active = false
	game.boss_round_pending = false
	game._set_swatter_active(false)
	game._clear_flies()
	game._clear_food()
	game._clear_customers()
	game._set_boss_health_visible(false)

	game.day_leftover_earned = game._sell_leftover_food()
	game.day_fly_reward = GameConfig.REWARD_MANAGER.calculate_fly_reward(game.day_flies_killed)
	game.current_money += game.day_fly_reward
	game.day_money_earned += game.day_fly_reward

	var completed_market_day: int = game.market_day
	game.current_day_report = game.generate_day_end_report()
	game.boss_round_pending = false
	game.market_day += 1
	game.next_day_forecast = game.generate_pre_day_forecast()
	game.financial_reports_generated.emit(game.current_day_report, game.next_day_forecast)
	if bool(game.next_day_forecast.get("is_bankruptcy_state", false)) and game.bankruptcy_strikes >= GameConfig.MAX_BANKRUPTCY_STRIKES:
		game.market_day = completed_market_day
		game._game_over_from_day_end("Bankruptcy strike limit reached.")
		return

	game._show_day_end_summary_screen(completed_market_day)

func play_forecast_transition() -> void:
	game.result_transition_active = true
	if game.financial_button:
		game.financial_button.disabled = true
		await game._play_bouncy_pop(game.financial_button)
	if game.result_start_button:
		game.result_start_button.visible = false

	var fade_out := game.create_tween()
	fade_out.set_parallel(true)
	fade_out.tween_property(game.result_motion_root, "position", Vector2(0, -28), 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fade_out.tween_property(game.result_motion_root, "modulate:a", 0.0, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fade_out.finished

	if game.financial_button:
		game.financial_button.visible = false

	AudioManager.play_book_flip()
	for frame_index in range(GameConfig.RESULT_FLIP_FRAME_COUNT):
		game.result_texture_rect.texture = game._get_result_flip_frame(frame_index)
		await game.get_tree().create_timer(1.0 / GameConfig.RESULT_FLIP_FPS).timeout

	game.result_texture_rect.texture = GameConfig.RESULT_CONTAINER_TEXTURE
	game.ui.show_pre_day_forecast_screen(false)
	await game._animate_result_data_in()
	game.result_transition_active = false

func animate_result_data_in() -> void:
	game.result_motion_root.position = Vector2(0, 28)
	game.result_motion_root.modulate.a = 0.0
	var fade_in := game.create_tween()
	fade_in.set_parallel(true)
	fade_in.tween_property(game.result_motion_root, "position", Vector2.ZERO, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade_in.tween_property(game.result_motion_root, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await fade_in.finished

func play_result_container_entrance() -> void:
	if not game.result_board:
		return
	game.result_board.scale = Vector2(1.65, 1.65)
	var entrance_tween := game.create_tween()
	entrance_tween.tween_property(game.result_board, "scale", Vector2(0.94, 0.94), 0.34).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	entrance_tween.tween_property(game.result_board, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func play_game_over_entrance() -> void:
	if not game.game_over_root:
		return

	game.game_over_background.position = Vector2(0, GameConfig.GAME_OVER_FRAME_SIZE.y)
	game.game_over_fly.position = Vector2(0, GameConfig.GAME_OVER_FRAME_SIZE.y)
	game.game_over_data_label.position = GameConfig.GAME_OVER_DATA_POSITION + Vector2(0, 26)
	game.game_over_data_label.modulate.a = 0.0
	game.game_over_try_again_button.modulate.a = 0.0
	game.game_over_home_button.modulate.a = 0.0
	game.game_over_try_again_button.disabled = true
	game.game_over_home_button.disabled = true

	var background_tween := game.create_tween()
	background_tween.tween_property(game.game_over_background, "position", Vector2.ZERO, 0.46).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	var fly_tween := game.create_tween()
	fly_tween.tween_interval(0.5)
	fly_tween.tween_property(game.game_over_fly, "position", Vector2.ZERO, 0.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fly_tween.finished

	var content_tween := game.create_tween()
	content_tween.set_parallel(true)
	content_tween.tween_property(game.game_over_data_label, "position", GameConfig.GAME_OVER_DATA_POSITION, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	content_tween.tween_property(game.game_over_data_label, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	content_tween.tween_property(game.game_over_try_again_button, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	content_tween.tween_property(game.game_over_home_button, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await content_tween.finished
	game.game_over_try_again_button.disabled = false
	game.game_over_home_button.disabled = false

func play_bouncy_pop(target: Control, process_during_pause: bool = false) -> void:
	target.scale = Vector2.ONE
	var pop_tween := game.create_tween()
	if process_during_pause:
		pop_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	pop_tween.tween_property(target, "scale", Vector2(1.08, 1.08), 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(target, "scale", Vector2(0.86, 0.86), 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	pop_tween.tween_property(target, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await pop_tween.finished

func play_control_bounce(target: Control) -> void:
	if target == null:
		return
	target.scale = Vector2.ONE
	var tween := game.create_tween()
	tween.tween_property(target, "scale", Vector2(1.08, 1.08), 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "scale", Vector2(0.92, 0.92), 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(target, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func play_boss_warning_intro() -> void:
	if game.boss_warning_root == null or game.boss_warning_top == null or game.boss_warning_bottom == null or game.boss_warning_board == null:
		return

	game.result_transition_active = true
	game.boss_warning_root.position = Vector2.ZERO
	game.boss_warning_top.position = Vector2(0, -GameConfig.BOSS_SHUTTER_HALF_SIZE.y)
	game.boss_warning_bottom.position = Vector2(0, GameConfig.GAME_OVER_FRAME_SIZE.y)
	game.boss_warning_board.visible = false
	game.boss_warning_board.scale = Vector2(1.7, 1.7)
	game.boss_warning_board.modulate.a = 0.0
	if game.boss_warning_content:
		game.boss_warning_content.position = GameConfig.BOSS_WARNING_TEXT_POSITION + Vector2(0, 30)
		game.boss_warning_content.modulate.a = 0.0
	if game.boss_warning_enter_button:
		game.boss_warning_enter_button.position = GameConfig.BOSS_WARNING_BUTTON_POSITION + Vector2(0, 30)
		game.boss_warning_enter_button.scale = Vector2.ONE
		game.boss_warning_enter_button.modulate.a = 0.0
		game.boss_warning_enter_button.disabled = true

	var shutter_tween := game.create_tween()
	shutter_tween.set_parallel(true)
	shutter_tween.tween_property(game.boss_warning_top, "position", Vector2.ZERO, 0.86).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	shutter_tween.tween_property(game.boss_warning_bottom, "position", Vector2(0, GameConfig.BOSS_SHUTTER_HALF_SIZE.y), 0.86).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await shutter_tween.finished

	var shake_tween := game.create_tween()
	shake_tween.tween_property(game.boss_warning_root, "position", Vector2(8, 0), 0.035)
	shake_tween.tween_property(game.boss_warning_root, "position", Vector2(-7, 3), 0.035)
	shake_tween.tween_property(game.boss_warning_root, "position", Vector2(5, -2), 0.035)
	shake_tween.tween_property(game.boss_warning_root, "position", Vector2.ZERO, 0.055)
	await shake_tween.finished

	game.boss_warning_board.visible = true
	var board_tween := game.create_tween()
	board_tween.set_parallel(true)
	board_tween.tween_property(game.boss_warning_board, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	board_tween.tween_property(game.boss_warning_board, "scale", Vector2(0.94, 0.94), 0.34).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	board_tween.chain().tween_property(game.boss_warning_board, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await board_tween.finished

	var content_tween := game.create_tween()
	content_tween.set_parallel(true)
	if game.boss_warning_content:
		content_tween.tween_property(game.boss_warning_content, "position", GameConfig.BOSS_WARNING_TEXT_POSITION, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		content_tween.tween_property(game.boss_warning_content, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if game.boss_warning_enter_button:
		content_tween.tween_property(game.boss_warning_enter_button, "position", GameConfig.BOSS_WARNING_BUTTON_POSITION, 0.34).set_delay(0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		content_tween.tween_property(game.boss_warning_enter_button, "modulate:a", 1.0, 0.34).set_delay(0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await content_tween.finished
	if game.boss_warning_enter_button:
		game.boss_warning_enter_button.disabled = false
	game.result_transition_active = false

func play_boss_warning_exit() -> void:
	if game.boss_warning_root == null or game.boss_warning_top == null or game.boss_warning_bottom == null or game.boss_warning_board == null:
		return

	var content_tween := game.create_tween()
	content_tween.set_parallel(true)
	if game.boss_warning_content:
		content_tween.tween_property(game.boss_warning_content, "position", GameConfig.BOSS_WARNING_TEXT_POSITION + Vector2(0, 34), 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		content_tween.tween_property(game.boss_warning_content, "modulate:a", 0.0, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if game.boss_warning_enter_button:
		content_tween.tween_property(game.boss_warning_enter_button, "scale", Vector2(1.08, 1.08), 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		content_tween.tween_property(game.boss_warning_enter_button, "scale", Vector2.ZERO, 0.18).set_delay(0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		content_tween.tween_property(game.boss_warning_enter_button, "modulate:a", 0.0, 0.18).set_delay(0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await content_tween.finished

	var board_tween := game.create_tween()
	board_tween.set_parallel(true)
	board_tween.tween_property(game.boss_warning_board, "scale", Vector2(1.08, 1.08), 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	board_tween.tween_property(game.boss_warning_board, "scale", Vector2.ZERO, 0.26).set_delay(0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	board_tween.tween_property(game.boss_warning_board, "modulate:a", 0.0, 0.22).set_delay(0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await board_tween.finished

	var shutter_tween := game.create_tween()
	shutter_tween.set_parallel(true)
	shutter_tween.tween_property(game.boss_warning_top, "position", Vector2(0, -GameConfig.BOSS_SHUTTER_HALF_SIZE.y), 0.64).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	shutter_tween.tween_property(game.boss_warning_bottom, "position", Vector2(0, GameConfig.GAME_OVER_FRAME_SIZE.y), 0.64).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await shutter_tween.finished
	game.boss_warning_root.visible = false

func play_boss_start_countdown() -> void:
	if game.menu_layer == null:
		return

	var countdown_root := Control.new()
	countdown_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	countdown_root.mouse_filter = Control.MOUSE_FILTER_STOP
	game.menu_layer.add_child(countdown_root)

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

	var fade_tween := game.create_tween()
	fade_tween.tween_property(countdown_root, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fade_tween.finished
	countdown_root.queue_free()

func _play_countdown_word(label: Label, word: String, color: Color, shake: bool) -> void:
	label.text = word
	label.add_theme_color_override("font_color", color)
	label.position = Vector2.ZERO
	label.scale = Vector2(0.2, 0.2)
	label.modulate.a = 0.0

	var pop_tween := game.create_tween()
	pop_tween.set_parallel(true)
	pop_tween.tween_property(label, "modulate:a", 1.0, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(label, "scale", Vector2(1.16, 1.16), 0.16).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	pop_tween.chain().tween_property(label, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await pop_tween.finished

	if shake:
		var shake_tween := game.create_tween()
		shake_tween.tween_property(label, "position", Vector2(14, 0), 0.035)
		shake_tween.tween_property(label, "position", Vector2(-12, 5), 0.035)
		shake_tween.tween_property(label, "position", Vector2(8, -4), 0.035)
		shake_tween.tween_property(label, "position", Vector2.ZERO, 0.05)
		await shake_tween.finished

	var out_tween := game.create_tween()
	out_tween.tween_interval(0.18)
	out_tween.tween_property(label, "modulate:a", 0.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await out_tween.finished

func on_menu_button_pressed() -> void:
	if game.result_transition_active:
		return

	match game.menu_state:
		"starting_day_report":
			game._play_start_day_button_animation()
		"day_end_summary":
			play_forecast_transition()
		"pre_day_forecast":
			game._play_start_day_button_animation()
		"boss_warning":
			game._play_enter_boss_button_animation()
		"start", "game_over":
			game._start_new_run()
		_:
			game._start_new_run()

func on_game_over_button_pressed(action: String) -> void:
	if game.result_transition_active:
		return
	game.game_over_action = action
	game._play_game_over_button_action()

func play_start_day_button_animation() -> void:
	game.result_transition_active = true
	var starting_report: bool = game.menu_state == "starting_day_report"
	if game.result_start_button:
		game.result_start_button.disabled = true
	if game.result_board:
		await game._play_bouncy_pop(game.result_board)
	if game.result_start_button:
		game.result_start_button.disabled = false
	game.result_transition_active = false
	if starting_report:
		game._begin_prepared_day()
	else:
		game._start_day()

func play_enter_boss_button_animation() -> void:
	game.result_transition_active = true
	if game.boss_warning_enter_button:
		game.boss_warning_enter_button.disabled = true
	await play_boss_warning_exit()
	if game.boss_warning_enter_button:
		game.boss_warning_enter_button.disabled = false
	game.boss_warning_shown = true
	await game._play_boss_start_countdown()
	game.result_transition_active = false
	game._start_day()
