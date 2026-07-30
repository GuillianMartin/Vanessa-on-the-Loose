extends RefCounted
const GameConfig = preload("res://Backend/Game/GameConfig.gd")
var game: Node2D

func _init(p_game: Node2D) -> void:
	game = p_game

func spawn_flies() -> void:
	game._clear_flies()
	var bounds: Rect2 = game._get_fly_bounds()
	for _index in range(game.flies_left):
		game._spawn_fly(
			Vector2(randf_range(bounds.position.x, bounds.end.x), randf_range(bounds.position.y, bounds.end.y)),
			bounds,
			true
		)

func spawn_boss_fight() -> void:
	game._clear_flies()
	game._clear_customers()
	game.active_knight_guards.clear()
	var bounds: Rect2 = game._get_fly_bounds()
	var boss := GameConfig.BOSS_FLY_SCRIPT.new() as Node2D
	boss.name = "BossFly"
	boss.position = Vector2(bounds.position.x + bounds.size.x * 0.5, bounds.position.y + bounds.size.y * 0.5)
	boss.connect("died", Callable(game, "_on_boss_died"))
	boss.connect("spawn_requested", Callable(game, "_on_boss_spawn_requested"))
	boss.connect("health_changed", Callable(game, "_on_boss_health_changed"))
	boss.connect("shockwave_released", Callable(game, "_on_boss_shockwave_released"))
	boss.connect("guard_blink_requested", Callable(game, "_on_boss_guard_blink_requested"))
	boss.connect("guard_protect_requested", Callable(game, "_on_boss_guard_protect_requested"))
	game.fly_container.add_child(boss)
	boss.call("configure", bounds, 5)
	boss.call("begin_boss_fight")
	game.flies_left = 1

	var guard_count := GameConfig.MARKET_PROGRESSION.get_boss_guard_count(game.market_day)
	spawn_knight_guards(boss, guard_count)
	game._update_hud()

func spawn_knight_guards(boss: Node2D, count: int) -> void:
	if count <= 0 or boss == null:
		return
	var bounds: Rect2 = game._get_fly_bounds()
	var guard_health := int(boss.call("get_guard_health"))
	var boss_position := boss.global_position
	for _index in range(count):
		var guard = GameConfig.BOSS_KNIGHT_GUARD_SCRIPT.new() as Area2D
		guard.name = "KnightGuard"
		var angle := randf_range(0.0, TAU)
		var offset := Vector2.RIGHT.rotated(angle) * randf_range(120.0, 200.0)
		guard.position = bounds.position + Vector2(
			clampf(boss_position.x + offset.x - bounds.position.x, 60.0, bounds.size.x - 60.0),
			clampf(boss_position.y + offset.y - bounds.position.y, 80.0, bounds.size.y - 80.0)
		)
		guard.call("configure", bounds, boss_position, guard_health, Vector2.ZERO, boss)
		guard.connect("died", Callable(game, "_on_knight_guard_died"))
		game.fly_container.add_child(guard)
		game.active_knight_guards.append(guard)

func spawn_customer_hand() -> void:
	if game._get_active_customer_count() >= GameConfig.MAX_ACTIVE_CUSTOMERS:
		return

	var foods = game.food_container.get_children()
	if foods.is_empty():
		return

	var random_food = foods.pick_random() as Node2D
	var viewport_size := game.get_viewport_rect().size
	var start_position := Vector2(randf_range(viewport_size.x * 0.4, viewport_size.x * 0.8), -80.0)
	var patience_multiplier := (1.65 if game.rush_active else 1.0) + float(game.market_day - 1) * 0.015
	var payout_multiplier := 1.5 if game.rush_active else 1.0
	var customer_patience := GameConfig.MARKET_PROGRESSION.get_customer_patience(game.day_initial_flies)

	var hand = GameConfig.CUSTOMER_HAND_SCRIPT.new() as Area2D
	hand.call("configure", start_position, random_food, patience_multiplier, payout_multiplier, customer_patience)
	hand.connect("swatted", game._on_customer_swatted)
	hand.connect("finished", game._on_buyer_transaction_finished)
	game.customer_container.add_child(hand)
	game._update_hud()

func spawn_food() -> void:
	game._clear_food()
	var polygon: PackedVector2Array = game._get_container_polygon_global()
	if polygon.size() < 3:
		return

	for _index in range(game._get_target_food_count()):
		if not game._spawn_single_food_loop():
			return

func spawn_single_food_loop() -> bool:
	var polygon: PackedVector2Array = game._get_container_polygon_global()
	var preferred_category := str(game.active_market_event.get("food_category", ""))
	var config = game._get_next_restock_config(preferred_category)
	var food := GameConfig.FOOD_SCRIPT.new() as Node2D
	food.call("configure", config)
	game._apply_food_economy(food)
	var stock_cost: int = food.call("get_stock_cost")

	for _attempt in range(GameConfig.FOOD_PLACEMENT_ATTEMPTS):
		var candidate: Vector2 = game._get_random_point_in_polygon(polygon, config.radius)
		if game._is_food_position_clear(candidate, config.radius, polygon, game.active_placed_food_records):
			if not game.restock_costs_prepaid:
				game.current_money -= stock_cost
				game._update_bankruptcy_state()
				if game._check_debt_limit("Maximum debt reached."):
					food.free()
					return false
			game.day_stock_spent += stock_cost
			game._update_bankruptcy_state()
			game.spawn_floating_money_text(stock_cost, candidate, false)
			food.position = candidate
			food.connect("depleted", game._on_food_depleted)
			game.food_container.add_child(food)
			if float(game.skill_timers.get("fresh_goods", 0.0)) > 0.0 and food.has_method("set_protected"):
				food.call("set_protected", true)
			game.active_placed_food_records.append({
				"node_ref": food,
				"position": candidate,
				"radius": config.radius,
			})
			game._update_hud()
			return true

	food.free()
	return false

func on_boss_died(_boss_node: Node) -> void:
	if not game.day_active:
		return
	game.score += 1
	game.total_flies_killed += 1
	game.day_flies_killed += 1
	game.flies_left = 0
	if game.swatter_entity != null:
		game.swatter_entity.call("register_fly_kill")
	game._complete_boss_round()

func on_boss_spawn_requested(_spawn_position: Vector2, _behavior_name: String = "") -> void:
	pass

func on_boss_health_changed(lives_remaining: int, max_lives: int, health: int, max_health: int) -> void:
	game._set_boss_health_visible(true)
	if game.boss_health_label:
		game.boss_health_label.text = "Boss Lives: %d/%d" % [lives_remaining, max_lives]
	if game.boss_health_bar:
		game.boss_health_bar.max_value = max_health
		game.boss_health_bar.value = health

func on_boss_shockwave_released(_origin: Vector2) -> void:
	game._start_screen_shake(0.45, 10.0)

func on_fly_spawn_requested(spawn_position: Vector2, behavior_name: String = "") -> void:
	if not game.day_active:
		return
	if game.boss_round_active:
		if behavior_name == "KnightGuard":
			spawn_hatched_knight_guard(spawn_position)
		elif behavior_name in ["Normal", "Swarm", "Tank"]:
			spawn_boss_hatched_fly(spawn_position, behavior_name)
		return
	if game.flies_left >= game._get_max_active_flies():
		return
	var bounds: Rect2 = game._get_fly_bounds()
	var offset := Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(70.0, 120.0)
	game._spawn_fly(spawn_position + offset, bounds, false, false, behavior_name)
	game.flies_left += 1
	game._update_hud()

func spawn_boss_hatched_fly(spawn_position: Vector2, behavior_name: String) -> void:
	var bounds: Rect2 = game._get_fly_bounds()
	game._spawn_fly(spawn_position, bounds, false, false, behavior_name)

func spawn_hatched_knight_guard(spawn_position: Vector2) -> void:
	var boss: Node2D = game.fly_container.get_node_or_null("BossFly")
	if boss == null:
		return
	var bounds: Rect2 = game._get_fly_bounds()
	var guard_health := int(boss.call("get_guard_health"))
	var guard = GameConfig.BOSS_KNIGHT_GUARD_SCRIPT.new() as Area2D
	guard.name = "KnightGuard"
	guard.position = bounds.position + Vector2(
		clampf(spawn_position.x - bounds.position.x, 60.0, bounds.size.x - 60.0),
		clampf(spawn_position.y - bounds.position.y, 80.0, bounds.size.y - 80.0)
	)
	guard.call("configure", bounds, boss.global_position, guard_health, Vector2.ZERO, boss)
	guard.connect("died", Callable(game, "_on_knight_guard_died"))
	game.fly_container.add_child(guard)
	game.active_knight_guards.append(guard)

func on_buyer_transaction_finished(hand_node: Area2D, status: String, payout: int) -> void:
	if status == "success":
		game.current_money += payout
		game._update_bankruptcy_state()
		game.spawn_floating_money_text(payout, hand_node.global_position, true)
		game.day_gross_sales += payout
		game.day_money_earned += payout
		game.day_customers_served += 1
		game.total_customers_served += 1
		game._adjust_reputation(2)
		game._adjust_satisfaction(2)
		game.active_placed_food_records = game.active_placed_food_records.filter(
			func(item): return is_instance_valid(item["node_ref"]) and item["node_ref"] != hand_node.target_food
		)
	elif status == "disgusted":
		game._adjust_reputation(-5)
		game._adjust_satisfaction(-12)
	elif status == "depleted":
		game._adjust_satisfaction(-5)

	game._check_loss_conditions()
	game._update_hud()

func on_customer_swatted(_hand: Area2D) -> void:
	if game.swatter_entity != null:
		game.swatter_entity.call("hit_customer")
	game._adjust_satisfaction(-3)
	game._check_loss_conditions()

func on_knight_guard_died(_guard: Area2D) -> void:
	game.active_knight_guards = game.active_knight_guards.filter(func(g): return is_instance_valid(g) and g != _guard)

func update_customer_spawns(delta: float) -> void:
	if not game.day_active or game.customer_container == null:
		return
	game.customer_spawn_timer -= delta
	if game.customer_spawn_timer <= 0.0:
		spawn_customer_hand()
		game.customer_spawn_timer = game._get_next_customer_spawn_time()

func update_rush_hour(delta: float) -> void:
	if game.rush_active:
		game.rush_timer -= delta
		if game.rush_timer <= 0.0:
			game.rush_active = false
		return

	game.rush_check_timer -= delta
	if game.rush_check_timer > 0.0:
		return

	if GameConfig.MARKET_PROGRESSION.should_start_rush(game.market_day):
		game.rush_active = true
		game.rush_timer = GameConfig.MARKET_PROGRESSION.get_rush_duration(game.market_day)
	game.rush_check_timer = randf_range(35.0, 70.0)

func update_big_fan_effect(delta: float) -> void:
	var remaining := float(game.skill_timers.get("big_fan", 0.0))
	if remaining <= 0.0:
		game.fan_camera_offset = Vector2.ZERO
		if game.big_fan_sprite != null:
			game.big_fan_sprite.visible = false
		return
	if game.big_fan_sprite != null:
		game.big_fan_sprite.visible = true
		game.big_fan_sprite.rotation += delta * TAU * 2.0
	var pulse := sin(Time.get_ticks_msec() * 0.012) * 3.0
	game.fan_camera_offset = Vector2(-game.big_fan_direction * 10.0, pulse)
	if game.fly_container == null:
		return
	var bounds: Rect2 = game._get_fly_bounds()
	var target_x: float = bounds.position.x + 30.0 if game.big_fan_direction < 0.0 else bounds.end.x - 30.0
	for fly in game.fly_container.get_children():
		if not is_instance_valid(fly) or fly.is_queued_for_deletion() or fly.is_in_group("boss_flies"):
			continue
		if fly.has_method("apply_big_fan"):
			fly.call("apply_big_fan", game.big_fan_direction, target_x, 900.0, remaining)

func update_skills(delta: float) -> void:
	if game.swatter_entity == null:
		return

	var expired := []
	for skill_id in game.skill_timers.keys():
		var remaining := float(game.skill_timers.get(skill_id, 0.0))
		if remaining <= 0.0:
			continue
		remaining -= delta
		if remaining <= 0.0:
			remaining = 0.0
			expired.append(skill_id)
		game.skill_timers[skill_id] = remaining

	for skill_id in expired:
		deactivate_skill(skill_id)

	game.ui.update_skill_buttons()

func deactivate_skill(skill_id: String) -> void:
	var definitions := GameConfig.BUY_SKILLS.get_skill_definitions()
	var def: Dictionary = definitions.get(skill_id, {})
	match int(def.get("type", -1)):
		GameConfig.BUY_SKILLS.SkillType.MEGA_SWATTER:
			game.swatter_entity.call("set_mega_swatter", false)
			game.swatter_sprite.scale = Vector2.ONE
		GameConfig.BUY_SKILLS.SkillType.INSTANT_ENERGY:
			game.swatter_entity.call("set_instant_energy", false)
		GameConfig.BUY_SKILLS.SkillType.FRESH_GOODS:
			game._set_food_protection(false)

func activate_skill(skill_id: String, def: Dictionary) -> void:
	match int(def.get("type", -1)):
		GameConfig.BUY_SKILLS.SkillType.MEGA_SWATTER:
			game.swatter_entity.call("set_mega_swatter", true)
			game.swatter_sprite.scale = Vector2.ONE * float(game.swatter_entity.call("get_size_multiplier"))
		GameConfig.BUY_SKILLS.SkillType.INSTANT_ENERGY:
			game.swatter_entity.call("set_instant_energy", true)
		GameConfig.BUY_SKILLS.SkillType.FRESH_GOODS:
			game._set_food_protection(true)
		GameConfig.BUY_SKILLS.SkillType.BIG_FAN:
			game.big_fan_popup.visible = true
			if game.swatter_sprite != null:
				game.swatter_sprite.visible = false
			game.Input.set_mouse_mode(game.Input.MOUSE_MODE_VISIBLE)
			return

	var duration := float(def.get("duration", 0.0))
	game.skill_timers[skill_id] = duration
	game._update_hud()

func on_big_fan_choice(side: String) -> void:
	game.big_fan_popup.visible = false
	game.big_fan_choice = side
	if game.swatter_sprite != null:
		game.swatter_sprite.visible = true
		game.Input.set_mouse_mode(game.Input.MOUSE_MODE_HIDDEN)

	var def: Dictionary = GameConfig.BUY_SKILLS.get_skill_definitions()["big_fan"]
	activate_big_fan(side)
	game.skill_timers["big_fan"] = float(def.get("duration", 0.0))
	game._update_hud()

func activate_big_fan(side: String) -> void:
	game.big_fan_direction = -1.0 if side == "left" else 1.0
	if game.big_fan_sprite != null:
		var viewport_size := game.get_viewport_rect().size
		game.big_fan_sprite.position = Vector2(viewport_size.x if side == "left" else 0.0, viewport_size.y * 0.5)
		game.big_fan_sprite.visible = true

func reset_skill_state() -> void:
	for skill_id in game.skill_timers.keys():
		game.skill_timers[skill_id] = 0.0
	if game.swatter_entity != null:
		game.swatter_entity.call("set_mega_swatter", false)
		game.swatter_entity.call("set_instant_energy", false)
	game.swatter_sprite.scale = Vector2.ONE
	game._set_food_protection(false)
	if game.big_fan_popup != null:
		game.big_fan_popup.visible = false
	game.big_fan_direction = 0.0
	game.fan_camera_offset = Vector2.ZERO
	if game.big_fan_sprite != null:
		game.big_fan_sprite.visible = false
	game.ui.update_skill_buttons()

func update_swatter(delta: float) -> void:
	if game.swatter_sprite == null or not game.swatter_sprite.visible:
		return
	game.swatter_sprite.global_position = game.get_viewport().get_mouse_position()
	if game.swatter_attack_timer <= 0.0:
		return
	game.swatter_attack_timer -= delta
	game.swatter_frame_timer -= delta
	if game.swatter_frame_timer <= 0.0:
		game.swatter_frame_timer = GameConfig.SWATTER_ATTACK_FRAME_TIME
		game.swatter_sprite.frame = mini(game.swatter_sprite.frame + 1, GameConfig.SWATTER_ATTACK_FRAMES - 1)
	if game.swatter_attack_timer <= 0.0:
		game._show_default_swatter()

func start_swatter_attack() -> void:
	if game.swatter_sprite == null or game.swatter_entity == null:
		return
	var swat_is_active: bool = game.swatter_entity.has_method("is_swat_active") and bool(game.swatter_entity.call("is_swat_active"))
	if not swat_is_active and not game.swatter_entity.call("swat"):
		return

	game.swatter_sprite.texture = GameConfig.SWATTER_ATTACK_TEXTURE
	game.swatter_sprite.hframes = GameConfig.SWATTER_ATTACK_FRAMES
	game.swatter_sprite.vframes = 1
	game.swatter_sprite.frame = 0
	game.swatter_attack_timer = GameConfig.SWATTER_ATTACK_FRAMES * GameConfig.SWATTER_ATTACK_FRAME_TIME
	game.swatter_frame_timer = GameConfig.SWATTER_ATTACK_FRAME_TIME

	if game.swatter_entity != null and game.swatter_entity.has_method("get_size_multiplier") and float(game.swatter_entity.call("get_size_multiplier")) > 1.0:
		game._mega_swatter_hit_area()

func update_screen_shake(delta: float) -> void:
	if game.screen_shake_timer <= 0.0:
		game.position = game.base_scene_position + game.fan_camera_offset
		return

	game.screen_shake_timer = maxf(game.screen_shake_timer - delta, 0.0)
	var fade: float = game.screen_shake_timer / maxf(game.screen_shake_duration, 0.001)
	game.position = game.base_scene_position + game.fan_camera_offset + Vector2(
		randf_range(-game.screen_shake_strength, game.screen_shake_strength) * fade,
		randf_range(-game.screen_shake_strength, game.screen_shake_strength) * fade
	)
	if game.screen_shake_timer <= 0.0:
		game.position = game.base_scene_position + game.fan_camera_offset
