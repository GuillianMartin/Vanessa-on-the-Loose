extends Node2D

signal financial_reports_generated(day_end_report: Dictionary, pre_day_forecast: Dictionary)

const FLY_SCENE := preload("res://Objects/Fly.tscn")
const BOSS_FLY_SCRIPT := preload("res://Backend/Object Behavior/BossFly.gd")
const BOSS_KNIGHT_GUARD_SCRIPT := preload("res://Backend/Object Behavior/BossKnightGuard.gd")
const FOOD_SCRIPT := preload("res://Backend/Object Behavior/Food.gd")
const CUSTOMER_HAND_SCRIPT := preload("res://Backend/Object Behavior/CustomerHand.gd")
const SWATTER_SCRIPT := preload("res://Backend/Swatter.gd")
const MARKET_PROGRESSION := preload("res://Backend/MarketProgression.gd")
const REWARD_MANAGER := preload("res://Backend/RewardManager.gd")
const BUY_SKILLS := preload("res://Backend/Buy_skills.gd")
const SWATTER_DEFAULT_TEXTURE := preload("res://assets/weapon/swatter/swatter_default.png")
const SWATTER_ATTACK_TEXTURE := preload("res://assets/weapon/swatter/swatter_attack.png")
const RESULT_CONTAINER_TEXTURE := preload("res://assets/ui_container/result_container.png")
const RESULT_FLIP_TEXTURE := preload("res://assets/ui_container/result_flip.png")
const BOSS_BG_TOP_TEXTURE := preload("res://assets/ui_container/boss_bg1.png")
const BOSS_BG_BOTTOM_TEXTURE := preload("res://assets/ui_container/boss_bg2.png")
const BOSS_WARNING_CONTAINER_TEXTURE := preload("res://assets/ui_container/boss_warning_container.png")
const FINANCIAL_BUTTON_TEXTURE := preload("res://assets/buttons/financial_button.png")
const START_BUTTON_TEXTURE := preload("res://assets/buttons/start_button.png")
const ENTER_BOSS_BUTTON_TEXTURE := preload("res://assets/buttons/enter_boss.png")
const PAUSE_BUTTON_TEXTURE := preload("res://assets/buttons/pause.png")
const QUIT_BUTTON_TEXTURE := preload("res://assets/buttons/quit_button.png")
const RESUME_BUTTON_TEXTURE := preload("res://assets/buttons/resume_button.png")
const HUD_SCENE: PackedScene = preload("res://Objects/HUD.tscn")
const AFTER_DAY_REPORT_SCENE: PackedScene = preload("res://Objects/AfterDayReport.tscn")
const BOSS_GUARD_INTERCEPT_CHANCE := 0.35
const GAME_OVER_TEXTURE := preload("res://assets/background/game_over/game_over.png")
const GAME_OVER_FLY_TEXTURE := preload("res://assets/background/game_over/game_over_fly.png")
const TRY_AGAIN_BUTTON_TEXTURE := preload("res://assets/buttons/try_again.png")
const HOME_BUTTON_TEXTURE := preload("res://assets/buttons/home_button.png")
const PIXELIFY_FONT := preload("res://assets/font/PixelifySans.ttf")
const JERSEY_FONT := preload("res://assets/font/Jersey10.ttf")

const BASE_FOOD_COUNT := 8
const TOP_SAFE_AREA := 72.0
const EDGE_PADDING := 30.0
const FOOD_GAP := 1.0
const FOOD_PLACEMENT_ATTEMPTS := 500
const GAME_CANVAS_SIZE := Vector2(1152, 648)
const SWATTER_ATTACK_FRAMES := 4
const SWATTER_ATTACK_FRAME_TIME := 0.045
const SWATTER_OFFSET := Vector2(34, 34)
const MAX_ACTIVE_CUSTOMERS := 5
const MAX_ACTIVE_FLIES_BASE := 25
const MAX_ACTIVE_FLIES_PER_DAY := 1.2
const FLY_REFILL_RATIO := 0.45
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
const BOSS_WARNING_FRAME_SIZE := Vector2(1063, 570)
const BOSS_WARNING_BUTTON_SIZE := Vector2(322, 37)
const BOSS_SHUTTER_HALF_SIZE := Vector2(1152, 324)
const BOSS_WARNING_TEXT_POSITION := Vector2(258, 154)
const BOSS_WARNING_TEXT_SIZE := Vector2(548, 238)
const BOSS_WARNING_BUTTON_POSITION := Vector2(370, 382)
const BOSS_COUNTDOWN_FONT_SIZE := 118
const GAME_OVER_FRAME_SIZE := Vector2(1152, 648)
const GAME_OVER_BUTTON_FRAME_SIZE := Vector2(169, 143)
const GAME_OVER_DATA_POSITION := Vector2(410, 266)
const GAME_OVER_DATA_SIZE := Vector2(340, 170)
const GAME_OVER_TRY_AGAIN_BUTTON_POSITION := Vector2(363, 458)
const GAME_OVER_HOME_BUTTON_POSITION := Vector2(620, 458)
const PAUSE_BUTTON_FRAME_SIZE := Vector2(94, 92)
const PAUSE_BUTTON_SIZE := Vector2(94, 92)
const PAUSE_MENU_BUTTON_SIZE := Vector2(330, 70)
const SKILL_EFFECT_FRAME_SIZE := Vector2(194, 145)
const SKILL_EFFECT_FRAME_COUNT := 9
const SKILL_EFFECT_FPS := 10.0
const SKILL_EFFECT_OFFSET := Vector2(-20, 0)
const HUD_STAT_FONT_MAX := 16
const HUD_STAT_FONT_MIN := 12

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

func _ready() -> void:
	randomize()
	get_tree().paused = false
	base_scene_position = position
	_build_game_nodes()
	big_fan_sprite = get_node_or_null("BigFanIcon") as Sprite2D
	_build_swatter()
	_build_hud()
	_build_menu()
	_show_start_menu()

func _process(delta: float) -> void:
	_update_big_fan_effect(delta)
	_update_screen_shake(delta)
	if not day_active:
		return

	_update_swatter(delta)
	_update_rush_hour(delta)
	_update_customer_spawns(delta)
	_process_day_clock(delta)
	_maintain_food_loop()
	_update_skills(delta)
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

	var max_active_flies := _get_max_active_flies()
	var desired_floor: int = mini(max_active_flies, maxi(5, int(ceil(float(MARKET_PROGRESSION.get_fly_count(market_day, active_market_event)) * FLY_REFILL_RATIO))))
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
	_update_hud()

func _get_max_active_flies() -> int:
	return int(floor(MAX_ACTIVE_FLIES_BASE + float(market_day) * MAX_ACTIVE_FLIES_PER_DAY))

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
	swatter_layer.layer = 200
	add_child(swatter_layer)

	swatter_sprite = Sprite2D.new()
	swatter_sprite.texture = SWATTER_DEFAULT_TEXTURE
	swatter_sprite.centered = false
	swatter_sprite.offset = -SWATTER_OFFSET
	swatter_sprite.z_index = 1000
	swatter_sprite.visible = false
	swatter_layer.add_child(swatter_sprite)

func _build_hud() -> void:
	hud_layer = HUD_SCENE.instantiate()
	hud_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud_layer)
	day_label = hud_layer.get_node("TopBar/Day")
	market_label = hud_layer.get_node("TopBar/Market")
	money_label = hud_layer.get_node("TopBar/Money")
	reputation_label = hud_layer.get_node("TopBar/Reputation")
	satisfaction_label = hud_layer.get_node("TopBar/Satisfaction")
	flies_label = hud_layer.get_node("TopBar/Flies")
	swatted_label = hud_layer.get_node("TopBar/Swatted")
	match_timer_label = hud_layer.get_node("TopBar/MatchTimer")
	rush_label = hud_layer.get_node("TopBar/Rush")
	swatter_energy_label = hud_layer.get_node("TopBar/EnergyLabel")
	swatter_energy_bar = hud_layer.get_node("TopBar/EnergyBar")
	boss_health_label = hud_layer.get_node("BossHealth/Label")
	boss_health_bar = hud_layer.get_node("BossHealth/Bar")
	skill_duration_list = hud_layer.get_node("DurationList")
	_build_upgrade_panel()
	_build_skill_panel()
	_build_pause_ui()
	return
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
	_build_skill_panel()

func _make_hud_label(text: String, width: float) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(width, 0)
	return label

func _build_upgrade_panel() -> void:
	upgrade_label = hud_layer.get_node("UpgradePanel/Title")
	upgrade_buttons = {}
	upgrade_cost_labels = {}
	for upgrade_name in ["damage", "speed", "energy"]:
		var node_name: String = str(upgrade_name).capitalize()
		var scene_button: Button = hud_layer.get_node("UpgradePanel/" + node_name)
		var cost_label: Label = hud_layer.get_node("UpgradePanel/" + node_name + "Cost")
		_prepare_icon_button(scene_button)
		_prepare_cost_label(cost_label)
		scene_button.pressed.connect(_on_upgrade_pressed.bind(upgrade_name))
		upgrade_buttons[upgrade_name] = scene_button
		upgrade_cost_labels[upgrade_name] = cost_label
	return
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

func _build_skill_panel() -> void:
	skill_label = hud_layer.get_node("SkillPanel/Title")
	var definitions := BUY_SKILLS.get_skill_definitions()
	skill_timers = {}
	skill_buttons = {}
	skill_cost_labels = {}
	skill_effect_overlays = {}
	skill_effect_textures = {
		"big_fan": load("res://assets/effects/skills/fan_animation.png") as Texture2D,
		"fresh_goods": load("res://assets/effects/skills/health_animation.png") as Texture2D,
		"instant_energy": load("res://assets/effects/skills/energy_animation.png") as Texture2D,
		"mega_swatter": load("res://assets/effects/skills/increase_animation.png") as Texture2D,
	}
	var scene_node_names := {
		"mega_swatter": "MegaSwatter",
		"instant_energy": "InstantEnergy",
		"fresh_goods": "FreshGoods",
		"big_fan": "BigFan",
	}
	for skill_id in definitions.keys():
		var def: Dictionary = definitions[skill_id]
		var node_name: String = str(scene_node_names[skill_id])
		var scene_button: Button = hud_layer.get_node("SkillPanel/" + node_name)
		var cost_label: Label = hud_layer.get_node("SkillPanel/" + node_name + "Cost")
		_prepare_icon_button(scene_button)
		_prepare_cost_label(cost_label)
		_create_skill_effect_overlay(skill_id, scene_button)
		scene_button.pressed.connect(_on_skill_pressed.bind(skill_id))
		scene_button.tooltip_text = str(def.get("description", ""))
		skill_buttons[skill_id] = scene_button
		skill_cost_labels[skill_id] = cost_label
		skill_timers[skill_id] = 0.0
	_build_big_fan_popup()
	return

	var panel := PanelContainer.new()
	panel.name = "SkillPanel"
	panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.offset_left = -342
	panel.offset_top = -150
	panel.offset_right = -12
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
	content.alignment = BoxContainer.ALIGNMENT_END
	margin.add_child(content)

	skill_label = Label.new()
	skill_label.text = "Skills"
	skill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(skill_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.alignment = BoxContainer.ALIGNMENT_END
	content.add_child(row)

	for skill_id in definitions.keys():
		var def: Dictionary = definitions[skill_id]
		var button := Button.new()
		button.custom_minimum_size = Vector2(96, 72)
		button.pressed.connect(_on_skill_pressed.bind(skill_id))
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.tooltip_text = str(def.get("description", ""))
		row.add_child(button)
		skill_buttons[skill_id] = button
		skill_timers[skill_id] = 0.0

	_build_big_fan_popup()

func _prepare_icon_button(button: Button) -> void:
	button.text = ""
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.expand_icon = true
	button.z_index = 8
	button.pivot_offset = button.size * 0.5
	var empty_style := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, empty_style)

func _prepare_cost_label(label: Label) -> void:
	if label == null:
		return
	label.z_index = 40
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", JERSEY_FONT)
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color(0.12, 0.07, 0.03, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)

func _create_skill_effect_overlay(skill_id: String, button: Button) -> void:
	var overlay := TextureRect.new()
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.custom_minimum_size = SKILL_EFFECT_FRAME_SIZE
	overlay.size = SKILL_EFFECT_FRAME_SIZE
	overlay.position = (button.size - SKILL_EFFECT_FRAME_SIZE) * 0.5 + SKILL_EFFECT_OFFSET
	overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	overlay.z_index = 20
	button.add_child(overlay)
	skill_effect_overlays[skill_id] = overlay

func _build_big_fan_popup() -> void:
	big_fan_popup = Control.new()
	big_fan_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	big_fan_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	big_fan_popup.visible = false
	hud_layer.add_child(big_fan_popup)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	big_fan_popup.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	center.add_child(box)

	var title := Label.new()
	title.text = "Big Fan: blow flies to which side?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	box.add_child(btn_row)

	var left_btn := Button.new()
	left_btn.text = "Left"
	left_btn.custom_minimum_size = Vector2(120, 44)
	left_btn.pressed.connect(_on_big_fan_choice.bind("left"))
	btn_row.add_child(left_btn)

	var right_btn := Button.new()
	right_btn.text = "Right"
	right_btn.custom_minimum_size = Vector2(120, 44)
	right_btn.pressed.connect(_on_big_fan_choice.bind("right"))
	btn_row.add_child(right_btn)

func _build_pause_ui() -> void:
	pause_button = TextureButton.new()
	pause_button.name = "PauseButton"
	pause_button.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_button.offset_left = -104.0
	pause_button.offset_top = 4.0
	pause_button.offset_right = -10.0
	pause_button.offset_bottom = 96.0
	pause_button.texture_normal = _get_atlas_frame(PAUSE_BUTTON_TEXTURE, PAUSE_BUTTON_FRAME_SIZE, 0)
	pause_button.texture_hover = _get_atlas_frame(PAUSE_BUTTON_TEXTURE, PAUSE_BUTTON_FRAME_SIZE, 1)
	pause_button.texture_pressed = _get_atlas_frame(PAUSE_BUTTON_TEXTURE, PAUSE_BUTTON_FRAME_SIZE, 1)
	pause_button.ignore_texture_size = true
	pause_button.custom_minimum_size = PAUSE_BUTTON_SIZE
	pause_button.size = PAUSE_BUTTON_SIZE
	pause_button.pivot_offset = PAUSE_BUTTON_SIZE * 0.5
	pause_button.z_index = 50
	pause_button.pressed.connect(_on_pause_pressed)
	hud_layer.add_child(pause_button)

	pause_overlay = Control.new()
	pause_overlay.name = "PauseOverlay"
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.visible = false
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.z_index = 40
	hud_layer.add_child(pause_overlay)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.0, 0.0, 0.0, 0.58)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(center)

	pause_menu_box = VBoxContainer.new()
	pause_menu_box.alignment = BoxContainer.ALIGNMENT_CENTER
	pause_menu_box.add_theme_constant_override("separation", 18)
	pause_menu_box.pivot_offset = Vector2(PAUSE_MENU_BUTTON_SIZE.x * 0.5, PAUSE_MENU_BUTTON_SIZE.y + 9.0)
	center.add_child(pause_menu_box)

	pause_quit_button = _make_pause_menu_button(QUIT_BUTTON_TEXTURE)
	pause_quit_button.pressed.connect(_on_pause_quit_pressed)
	pause_menu_box.add_child(pause_quit_button)

	pause_resume_button = _make_pause_menu_button(RESUME_BUTTON_TEXTURE)
	pause_resume_button.pressed.connect(_on_pause_resume_pressed)
	pause_menu_box.add_child(pause_resume_button)

func _make_pause_menu_button(texture: Texture2D) -> TextureButton:
	var button := TextureButton.new()
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.texture_normal = _get_atlas_frame(texture, PAUSE_MENU_BUTTON_SIZE, 0)
	button.texture_hover = _get_atlas_frame(texture, PAUSE_MENU_BUTTON_SIZE, 1)
	button.texture_pressed = _get_atlas_frame(texture, PAUSE_MENU_BUTTON_SIZE, 1)
	button.ignore_texture_size = true
	button.custom_minimum_size = PAUSE_MENU_BUTTON_SIZE
	button.size = PAUSE_MENU_BUTTON_SIZE
	button.pivot_offset = PAUSE_MENU_BUTTON_SIZE * 0.5
	return button

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
	_build_boss_warning_menu()
	_build_game_over_menu()

func _build_result_art_menu() -> void:
	result_art_root = AFTER_DAY_REPORT_SCENE.instantiate()
	menu_layer.add_child(result_art_root)
	result_board = result_art_root.get_node("Center/Board")
	result_texture_rect = result_art_root.get_node("Center/Board/Background")
	result_motion_root = result_art_root.get_node("Center/Board/MotionRoot")
	result_content = result_art_root.get_node("Center/Board/MotionRoot/TextMargin/Content")
	result_title_label = result_art_root.get_node("Center/Board/MotionRoot/TextMargin/Content/Title")
	result_body_label = result_art_root.get_node("Center/Board/MotionRoot/TextMargin/Content/Body")
	result_warning_label = result_art_root.get_node("Center/Board/MotionRoot/TextMargin/Content/Warning")
	financial_button = result_art_root.get_node("Center/Board/FinancialButton")
	result_start_button = result_art_root.get_node("Center/Board/StartButton")
	financial_button.pressed.connect(_on_menu_button_pressed)
	result_start_button.pressed.connect(_on_menu_button_pressed)
	return
	result_art_root = Control.new()
	result_art_root.visible = false
	result_art_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(result_art_root)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_art_root.add_child(center)

	var board := Control.new()
	result_board = board
	board.custom_minimum_size = RESULT_FRAME_SIZE
	board.size = RESULT_FRAME_SIZE
	board.pivot_offset = RESULT_FRAME_SIZE * 0.5
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
	financial_button.pivot_offset = RESULT_BUTTON_FRAME_SIZE * 0.5
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
	result_start_button.pivot_offset = RESULT_BUTTON_FRAME_SIZE * 0.5
	result_start_button.pressed.connect(_on_menu_button_pressed)
	result_start_button.visible = false
	board.add_child(result_start_button)

func _get_button_frame(atlas: Texture2D, frame_index: int) -> AtlasTexture:
	return _get_atlas_frame(atlas, RESULT_BUTTON_FRAME_SIZE, frame_index)

func _get_atlas_frame(atlas: Texture2D, frame_size: Vector2, frame_index: int) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = Rect2(frame_size.x * frame_index, 0, frame_size.x, frame_size.y)
	return texture

func _build_game_over_menu() -> void:
	game_over_root = Control.new()
	game_over_root.visible = false
	game_over_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(game_over_root)

	game_over_background = TextureRect.new()
	game_over_background.texture = GAME_OVER_TEXTURE
	game_over_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over_background.stretch_mode = TextureRect.STRETCH_SCALE
	game_over_root.add_child(game_over_background)

	game_over_fly = TextureRect.new()
	game_over_fly.texture = GAME_OVER_FLY_TEXTURE
	game_over_fly.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over_fly.stretch_mode = TextureRect.STRETCH_SCALE
	game_over_root.add_child(game_over_fly)

	game_over_data_label = Label.new()
	game_over_data_label.position = GAME_OVER_DATA_POSITION
	game_over_data_label.size = GAME_OVER_DATA_SIZE
	game_over_data_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	game_over_data_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game_over_data_label.add_theme_font_override("font", PIXELIFY_FONT)
	game_over_data_label.add_theme_color_override("font_color", Color.WHITE)
	game_over_data_label.add_theme_font_size_override("font_size", 20)
	game_over_root.add_child(game_over_data_label)

	game_over_try_again_button = TextureButton.new()
	game_over_try_again_button.position = GAME_OVER_TRY_AGAIN_BUTTON_POSITION
	game_over_try_again_button.texture_normal = _get_game_over_button_frame(TRY_AGAIN_BUTTON_TEXTURE, 0)
	game_over_try_again_button.texture_hover = _get_game_over_button_frame(TRY_AGAIN_BUTTON_TEXTURE, 1)
	game_over_try_again_button.texture_pressed = _get_game_over_button_frame(TRY_AGAIN_BUTTON_TEXTURE, 1)
	game_over_try_again_button.ignore_texture_size = true
	game_over_try_again_button.custom_minimum_size = GAME_OVER_BUTTON_FRAME_SIZE
	game_over_try_again_button.size = GAME_OVER_BUTTON_FRAME_SIZE
	game_over_try_again_button.pivot_offset = GAME_OVER_BUTTON_FRAME_SIZE * 0.5
	game_over_try_again_button.pressed.connect(_on_game_over_button_pressed.bind("try_again"))
	game_over_root.add_child(game_over_try_again_button)

	game_over_home_button = TextureButton.new()
	game_over_home_button.position = GAME_OVER_HOME_BUTTON_POSITION
	game_over_home_button.texture_normal = _get_game_over_button_frame(HOME_BUTTON_TEXTURE, 0)
	game_over_home_button.texture_hover = _get_game_over_button_frame(HOME_BUTTON_TEXTURE, 1)
	game_over_home_button.texture_pressed = _get_game_over_button_frame(HOME_BUTTON_TEXTURE, 1)
	game_over_home_button.ignore_texture_size = true
	game_over_home_button.custom_minimum_size = GAME_OVER_BUTTON_FRAME_SIZE
	game_over_home_button.size = GAME_OVER_BUTTON_FRAME_SIZE
	game_over_home_button.pivot_offset = GAME_OVER_BUTTON_FRAME_SIZE * 0.5
	game_over_home_button.pressed.connect(_on_game_over_button_pressed.bind("home"))
	game_over_root.add_child(game_over_home_button)

func _get_game_over_button_frame(atlas: Texture2D, frame_index: int) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = Rect2(GAME_OVER_BUTTON_FRAME_SIZE.x * frame_index, 0, GAME_OVER_BUTTON_FRAME_SIZE.x, GAME_OVER_BUTTON_FRAME_SIZE.y)
	return texture

func _get_result_flip_frame(frame_index: int) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = RESULT_FLIP_TEXTURE
	texture.region = Rect2(RESULT_FRAME_SIZE.x * frame_index, 0, RESULT_FRAME_SIZE.x, RESULT_FRAME_SIZE.y)
	return texture

func _build_boss_warning_menu() -> void:
	boss_warning_root = Control.new()
	boss_warning_root.visible = false
	boss_warning_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(boss_warning_root)

	boss_warning_top = TextureRect.new()
	boss_warning_top.texture = BOSS_BG_TOP_TEXTURE
	boss_warning_top.position = Vector2(0, -BOSS_SHUTTER_HALF_SIZE.y)
	boss_warning_top.size = BOSS_SHUTTER_HALF_SIZE
	boss_warning_top.stretch_mode = TextureRect.STRETCH_SCALE
	boss_warning_root.add_child(boss_warning_top)

	boss_warning_bottom = TextureRect.new()
	boss_warning_bottom.texture = BOSS_BG_BOTTOM_TEXTURE
	boss_warning_bottom.position = Vector2(0, GAME_OVER_FRAME_SIZE.y)
	boss_warning_bottom.size = BOSS_SHUTTER_HALF_SIZE
	boss_warning_bottom.stretch_mode = TextureRect.STRETCH_SCALE
	boss_warning_root.add_child(boss_warning_bottom)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	boss_warning_root.add_child(center)

	boss_warning_board = Control.new()
	boss_warning_board.custom_minimum_size = BOSS_WARNING_FRAME_SIZE
	boss_warning_board.size = BOSS_WARNING_FRAME_SIZE
	boss_warning_board.pivot_offset = BOSS_WARNING_FRAME_SIZE * 0.5
	boss_warning_board.visible = false
	center.add_child(boss_warning_board)

	var board_texture := TextureRect.new()
	board_texture.texture = BOSS_WARNING_CONTAINER_TEXTURE
	board_texture.size = BOSS_WARNING_FRAME_SIZE
	board_texture.stretch_mode = TextureRect.STRETCH_SCALE
	boss_warning_board.add_child(board_texture)

	var text_area := VBoxContainer.new()
	boss_warning_content = text_area
	text_area.position = BOSS_WARNING_TEXT_POSITION
	text_area.size = BOSS_WARNING_TEXT_SIZE
	text_area.clip_contents = true
	text_area.alignment = BoxContainer.ALIGNMENT_CENTER
	text_area.add_theme_constant_override("separation", 12)
	boss_warning_board.add_child(text_area)

	boss_warning_title_label = Label.new()
	boss_warning_title_label.text = "BOSS WARNING"
	boss_warning_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_warning_title_label.add_theme_font_override("font", JERSEY_FONT)
	boss_warning_title_label.add_theme_font_size_override("font_size", 36)
	boss_warning_title_label.add_theme_color_override("font_color", Color("#5D371E"))
	text_area.add_child(boss_warning_title_label)

	boss_warning_body_label = Label.new()
	boss_warning_body_label.text = "A powerful Boss Fly awaits! Protect your market and survive the Boss Fight to continue.\n\nIt will be guarded by elite Knight Flies. Customers will still visit during the fight, so keep your reputation and satisfaction up."
	boss_warning_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_warning_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	boss_warning_body_label.add_theme_font_override("font", PIXELIFY_FONT)
	boss_warning_body_label.add_theme_font_size_override("font_size", 18)
	boss_warning_body_label.add_theme_color_override("font_color", Color("#5D371E"))
	boss_warning_body_label.custom_minimum_size = Vector2(BOSS_WARNING_TEXT_SIZE.x, 0)
	text_area.add_child(boss_warning_body_label)

	boss_warning_hint_label = Label.new()
	boss_warning_hint_label.text = "Boss Fight incoming - prepare your swatter!"
	boss_warning_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_warning_hint_label.add_theme_font_override("font", PIXELIFY_FONT)
	boss_warning_hint_label.add_theme_font_size_override("font_size", 17)
	boss_warning_hint_label.add_theme_color_override("font_color", Color("#B62A19"))
	text_area.add_child(boss_warning_hint_label)

	boss_warning_enter_button = TextureButton.new()
	boss_warning_enter_button.texture_normal = ENTER_BOSS_BUTTON_TEXTURE
	boss_warning_enter_button.texture_hover = ENTER_BOSS_BUTTON_TEXTURE
	boss_warning_enter_button.texture_pressed = ENTER_BOSS_BUTTON_TEXTURE
	boss_warning_enter_button.ignore_texture_size = true
	boss_warning_enter_button.position = BOSS_WARNING_BUTTON_POSITION
	boss_warning_enter_button.custom_minimum_size = BOSS_WARNING_BUTTON_SIZE
	boss_warning_enter_button.size = BOSS_WARNING_BUTTON_SIZE
	boss_warning_enter_button.pivot_offset = BOSS_WARNING_BUTTON_SIZE * 0.5
	boss_warning_enter_button.pressed.connect(_on_menu_button_pressed)
	boss_warning_board.add_child(boss_warning_enter_button)

func _show_default_menu_panel() -> void:
	if default_menu_panel:
		default_menu_panel.visible = true
	if result_art_root:
		result_art_root.visible = false
	if boss_warning_root:
		boss_warning_root.visible = false
	if game_over_root:
		game_over_root.visible = false
	result_transition_active = false

func _show_result_art_panel() -> void:
	if default_menu_panel:
		default_menu_panel.visible = false
	if result_art_root:
		result_art_root.visible = true
	if boss_warning_root:
		boss_warning_root.visible = false
	if game_over_root:
		game_over_root.visible = false
	if result_board:
		result_board.scale = Vector2.ONE
	if result_texture_rect:
		result_texture_rect.texture = RESULT_CONTAINER_TEXTURE
	if result_motion_root:
		result_motion_root.position = Vector2.ZERO
		result_motion_root.modulate.a = 1.0

func _show_game_over_art_panel() -> void:
	if default_menu_panel:
		default_menu_panel.visible = false
	if result_art_root:
		result_art_root.visible = false
	if boss_warning_root:
		boss_warning_root.visible = false
	if game_over_root:
		game_over_root.visible = true

func _show_boss_warning_art_panel() -> void:
	if default_menu_panel:
		default_menu_panel.visible = false
	if result_art_root:
		result_art_root.visible = false
	if game_over_root:
		game_over_root.visible = false
	if boss_warning_root:
		boss_warning_root.visible = true

func _show_start_menu() -> void:
	_set_gameplay_paused(false)
	menu_state = "start"
	day_active = false
	boss_round_active = false
	boss_round_pending = false
	boss_warning_shown = false
	_set_swatter_active(false)
	_set_boss_health_visible(false)
	menu_layer.visible = true
	hud_layer.visible = false
	if pause_button:
		pause_button.visible = false
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

func _on_pause_pressed() -> void:
	if not day_active or gameplay_paused:
		return
	_set_pause_button_pressed_frame(true)
	_set_gameplay_paused(true)

func _set_gameplay_paused(paused: bool) -> void:
	gameplay_paused = paused
	get_tree().paused = paused
	if pause_overlay:
		pause_overlay.visible = paused
	if pause_button:
		pause_button.visible = day_active
	if paused:
		_set_swatter_active(false)
		_play_pause_overlay_entrance()
	elif day_active:
		_set_pause_button_pressed_frame(false)
		_set_swatter_active(true)

func _set_pause_button_pressed_frame(pressed_frame: bool) -> void:
	if pause_button == null:
		return
	var frame_index := 1 if pressed_frame else 0
	var frame := _get_atlas_frame(PAUSE_BUTTON_TEXTURE, PAUSE_BUTTON_FRAME_SIZE, frame_index)
	pause_button.texture_normal = frame
	pause_button.texture_hover = frame
	pause_button.texture_pressed = frame

func _play_pause_overlay_entrance() -> void:
	if pause_menu_box == null:
		return
	pause_menu_box.scale = Vector2(1.65, 1.65)
	pause_quit_button.disabled = true
	pause_resume_button.disabled = true
	var entrance_tween := create_tween()
	entrance_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	entrance_tween.tween_property(pause_menu_box, "scale", Vector2(0.94, 0.94), 0.34).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	entrance_tween.tween_property(pause_menu_box, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await entrance_tween.finished
	if gameplay_paused:
		pause_quit_button.disabled = false
		pause_resume_button.disabled = false

func _on_pause_resume_pressed() -> void:
	if not gameplay_paused:
		return
	pause_resume_button.disabled = true
	await _play_bouncy_pop(pause_resume_button, true)
	pause_resume_button.disabled = false
	_set_gameplay_paused(false)

func _on_pause_quit_pressed() -> void:
	if not gameplay_paused:
		return
	pause_quit_button.disabled = true
	await _play_bouncy_pop(pause_quit_button, true)
	pause_quit_button.disabled = false
	_set_gameplay_paused(false)
	_show_start_menu()

func _on_menu_button_pressed() -> void:
	if result_transition_active:
		return

	match menu_state:
		"day_end_summary":
			_play_forecast_transition()
		"pre_day_forecast":
			_play_start_day_button_animation()
		"boss_warning":
			_play_enter_boss_button_animation()
		"start", "game_over":
			_start_new_run()
		_:
			_start_new_run()

func _show_boss_warning_screen() -> void:
	menu_state = "boss_warning"
	day_active = false
	boss_round_active = false
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
	_show_boss_warning_art_panel()
	menu_title.text = "⚠ BOSS WARNING ⚠"
	result_label.text = "A powerful Boss Fly awaits! Protect your market and survive the Boss Fight to continue.\n\nIt will be guarded by elite Knight Flies. Customers will still visit during the fight, so keep your reputation and satisfaction up."
	if forecast_warning_label:
		forecast_warning_label.visible = true
		forecast_warning_label.text = "Boss Fight incoming — prepare your swatter!"
		forecast_warning_label.add_theme_color_override("font_color", Color(1.0, 0.12, 0.08))
	play_button.text = "Enter Boss Fight"
	_play_boss_warning_intro()

func _start_new_run() -> void:
	market_day = 1
	difficulty_level = 1
	boss_round_active = false
	boss_round_pending = false
	boss_warning_shown = false
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
	if boss_round_pending and not boss_warning_shown:
		_show_boss_warning_screen()
		return

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
	flies_left = 0 if boss_round_active else mini(MARKET_PROGRESSION.get_fly_count(market_day, active_market_event), _get_max_active_flies())
	day_initial_flies = flies_left
	rush_active = false
	rush_timer = 0.0
	rush_check_timer = randf_range(18.0, 45.0)
	active_placed_food_records.clear()
	customer_spawn_timer = _get_next_customer_spawn_time()

	swatter_entity.call("reset")
	swatter_entity.call("set_day", market_day)
	_reset_skill_state()
	day_active = true
	_set_swatter_active(true)
	menu_layer.visible = false
	if forecast_warning_label:
		forecast_warning_label.visible = false
	hud_layer.visible = true
	if pause_button:
		pause_button.visible = true
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
	if pause_button:
		pause_button.visible = false
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

	boss_round_pending = _is_boss_day(market_day + 1)
	if boss_round_pending:
		boss_warning_shown = false
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
	_show_game_over_art_panel()
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
	_play_game_over_entrance()
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
	_play_result_container_entrance()
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

func _play_result_container_entrance() -> void:
	if not result_board:
		return
	result_board.scale = Vector2(1.65, 1.65)
	var entrance_tween := create_tween()
	entrance_tween.tween_property(result_board, "scale", Vector2(0.94, 0.94), 0.34).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	entrance_tween.tween_property(result_board, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _play_game_over_entrance() -> void:
	if not game_over_root:
		return

	game_over_background.position = Vector2(0, GAME_OVER_FRAME_SIZE.y)
	game_over_fly.position = Vector2(0, GAME_OVER_FRAME_SIZE.y)
	game_over_data_label.position = GAME_OVER_DATA_POSITION + Vector2(0, 26)
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
	content_tween.tween_property(game_over_data_label, "position", GAME_OVER_DATA_POSITION, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
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
		_show_start_menu()
	else:
		_start_new_run()

func _play_start_day_button_animation() -> void:
	result_transition_active = true
	if result_start_button:
		result_start_button.disabled = true
	if result_board:
		await _play_bouncy_pop(result_board)
	if result_start_button:
		result_start_button.disabled = false
	result_transition_active = false
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
		content_tween.tween_property(boss_warning_content, "position", BOSS_WARNING_TEXT_POSITION + Vector2(0, 34), 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
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
	shutter_tween.tween_property(boss_warning_top, "position", Vector2(0, -BOSS_SHUTTER_HALF_SIZE.y), 0.64).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	shutter_tween.tween_property(boss_warning_bottom, "position", Vector2(0, GAME_OVER_FRAME_SIZE.y), 0.64).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
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
	word_label.size = GAME_CANVAS_SIZE
	word_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	word_label.add_theme_font_override("font", JERSEY_FONT)
	word_label.add_theme_font_size_override("font_size", BOSS_COUNTDOWN_FONT_SIZE)
	word_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
	word_label.add_theme_constant_override("shadow_offset_x", 4)
	word_label.add_theme_constant_override("shadow_offset_y", 4)
	word_label.pivot_offset = GAME_CANVAS_SIZE * 0.5
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
	boss_warning_top.position = Vector2(0, -BOSS_SHUTTER_HALF_SIZE.y)
	boss_warning_bottom.position = Vector2(0, GAME_OVER_FRAME_SIZE.y)
	boss_warning_board.visible = false
	boss_warning_board.scale = Vector2(1.7, 1.7)
	boss_warning_board.modulate.a = 0.0
	if boss_warning_content:
		boss_warning_content.position = BOSS_WARNING_TEXT_POSITION + Vector2(0, 30)
		boss_warning_content.modulate.a = 0.0
	if boss_warning_enter_button:
		boss_warning_enter_button.position = BOSS_WARNING_BUTTON_POSITION + Vector2(0, 30)
		boss_warning_enter_button.scale = Vector2.ONE
		boss_warning_enter_button.modulate.a = 0.0
		boss_warning_enter_button.disabled = true

	var shutter_tween := create_tween()
	shutter_tween.set_parallel(true)
	shutter_tween.tween_property(boss_warning_top, "position", Vector2.ZERO, 0.86).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	shutter_tween.tween_property(boss_warning_bottom, "position", Vector2(0, BOSS_SHUTTER_HALF_SIZE.y), 0.86).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await shutter_tween.finished

	var shake_tween := create_tween()
	shake_tween.tween_property(boss_warning_root, "position", Vector2(8, 0), 0.035)
	shake_tween.tween_property(boss_warning_root, "position", Vector2(-7, 3), 0.035)
	shake_tween.tween_property(boss_warning_root, "position", Vector2(5, -2), 0.035)
	shake_tween.tween_property(boss_warning_root, "position", Vector2.ZERO, 0.055)
	await shake_tween.finished

	boss_warning_board.visible = true
	var board_tween := create_tween()
	board_tween.set_parallel(true)
	board_tween.tween_property(boss_warning_board, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	board_tween.tween_property(boss_warning_board, "scale", Vector2(0.94, 0.94), 0.34).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	board_tween.chain().tween_property(boss_warning_board, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await board_tween.finished

	var content_tween := create_tween()
	content_tween.set_parallel(true)
	if boss_warning_content:
		content_tween.tween_property(boss_warning_content, "position", BOSS_WARNING_TEXT_POSITION, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		content_tween.tween_property(boss_warning_content, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if boss_warning_enter_button:
		content_tween.tween_property(boss_warning_enter_button, "position", BOSS_WARNING_BUTTON_POSITION, 0.34).set_delay(0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
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
	var frame_time := 1.0 / SKILL_EFFECT_FPS
	var tween := create_tween()
	for frame_index in range(SKILL_EFFECT_FRAME_COUNT):
		tween.tween_callback(Callable(self, "_set_skill_effect_frame").bind(skill_id, frame_index))
		tween.tween_interval(frame_time)
	tween.tween_callback(Callable(self, "_hide_skill_effect").bind(skill_id))

func _set_skill_effect_frame(skill_id: String, frame_index: int) -> void:
	var overlay := skill_effect_overlays.get(skill_id) as TextureRect
	var atlas := skill_effect_textures.get(skill_id) as Texture2D
	if overlay == null or atlas == null:
		return
	overlay.texture = _get_atlas_frame(atlas, SKILL_EFFECT_FRAME_SIZE, frame_index)

func _hide_skill_effect(skill_id: String) -> void:
	var overlay := skill_effect_overlays.get(skill_id) as TextureRect
	if overlay == null:
		return
	overlay.visible = false
	overlay.texture = null

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
	active_knight_guards.clear()
	var bounds := _get_fly_bounds()
	var boss := BOSS_FLY_SCRIPT.new() as Node2D
	boss.name = "BossFly"
	boss.position = Vector2(bounds.position.x + bounds.size.x * 0.5, bounds.position.y + bounds.size.y * 0.5)
	boss.connect("died", Callable(self, "_on_boss_died"))
	boss.connect("spawn_requested", Callable(self, "_on_boss_spawn_requested"))
	boss.connect("health_changed", Callable(self, "_on_boss_health_changed"))
	boss.connect("shockwave_released", Callable(self, "_on_boss_shockwave_released"))
	boss.connect("guard_blink_requested", Callable(self, "_on_boss_guard_blink_requested"))
	boss.connect("guard_protect_requested", Callable(self, "_on_boss_guard_protect_requested"))
	fly_container.add_child(boss)
	boss.call("configure", bounds, 5)
	boss.call("begin_boss_fight")
	flies_left = 1

	var guard_count := MARKET_PROGRESSION.get_boss_guard_count(market_day)
	_spawn_knight_guards(boss, guard_count)
	_update_hud()

func _spawn_knight_guards(boss: Node2D, count: int) -> void:
	if count <= 0 or boss == null:
		return
	var bounds := _get_fly_bounds()
	var guard_health := int(boss.call("get_guard_health"))
	var boss_position := boss.global_position
	for _index in range(count):
		var guard = BOSS_KNIGHT_GUARD_SCRIPT.new() as Area2D
		guard.name = "KnightGuard"
		var angle := randf_range(0.0, TAU)
		var offset := Vector2.RIGHT.rotated(angle) * randf_range(120.0, 200.0)
		guard.position = bounds.position + Vector2(
			clampf(boss_position.x + offset.x - bounds.position.x, 60.0, bounds.size.x - 60.0),
			clampf(boss_position.y + offset.y - bounds.position.y, 80.0, bounds.size.y - 80.0)
		)
		guard.call("configure", bounds, boss_position, guard_health, Vector2.ZERO, boss)
		guard.connect("died", Callable(self, "_on_knight_guard_died"))
		fly_container.add_child(guard)
		active_knight_guards.append(guard)

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
	active_knight_guards = active_knight_guards.filter(func(g): return is_instance_valid(g) and g != _guard)

func try_intercept_boss_hit(boss: Node2D, damage: int) -> bool:
	if boss == null or active_knight_guards.is_empty() or randf() > BOSS_GUARD_INTERCEPT_CHANCE:
		return false
	var alive_guards: Array[Node2D] = []
	for guard in active_knight_guards:
		if is_instance_valid(guard) and not guard.is_queued_for_deletion() and guard.has_method("intercept_attack"):
			alive_guards.append(guard)
	if alive_guards.is_empty():
		return false
	alive_guards.pick_random().call("intercept_attack", boss.global_position, damage)
	return true

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

	day_leftover_earned = _sell_leftover_food()
	day_fly_reward = REWARD_MANAGER.calculate_fly_reward(day_flies_killed)
	current_money += day_fly_reward
	day_money_earned += day_fly_reward

	var completed_market_day := market_day
	current_day_report = generate_day_end_report()
	boss_round_pending = false
	market_day += 1
	next_day_forecast = generate_pre_day_forecast()
	financial_reports_generated.emit(current_day_report, next_day_forecast)
	if bool(next_day_forecast.get("is_bankruptcy_state", false)) and bankruptcy_strikes >= MAX_BANKRUPTCY_STRIKES:
		market_day = completed_market_day
		_game_over_from_day_end("Bankruptcy strike limit reached.")
		return

	_show_day_end_summary_screen(completed_market_day)

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
	if boss_round_active:
		if behavior_name == "KnightGuard":
			_spawn_hatched_knight_guard(spawn_position)
		elif behavior_name in ["Normal", "Swarm", "Tank"]:
			_spawn_boss_hatched_fly(spawn_position, behavior_name)
		return
	if flies_left >= _get_max_active_flies():
		return
	var bounds := _get_fly_bounds()
	var offset := Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(70.0, 120.0)
	_spawn_fly(spawn_position + offset, bounds, false, false, behavior_name)
	flies_left += 1
	_update_hud()

func _spawn_boss_hatched_fly(spawn_position: Vector2, behavior_name: String) -> void:
	var bounds := _get_fly_bounds()
	_spawn_fly(spawn_position, bounds, false, false, behavior_name)

func _spawn_hatched_knight_guard(spawn_position: Vector2) -> void:
	var boss := fly_container.get_node_or_null("BossFly")
	if boss == null:
		return
	var bounds := _get_fly_bounds()
	var guard_health := int(boss.call("get_guard_health"))
	var guard = BOSS_KNIGHT_GUARD_SCRIPT.new() as Area2D
	guard.name = "KnightGuard"
	guard.position = bounds.position + Vector2(
		clampf(spawn_position.x - bounds.position.x, 60.0, bounds.size.x - 60.0),
		clampf(spawn_position.y - bounds.position.y, 80.0, bounds.size.y - 80.0)
	)
	guard.call("configure", bounds, boss.global_position, guard_health, Vector2.ZERO, boss)
	guard.connect("died", Callable(self, "_on_knight_guard_died"))
	fly_container.add_child(guard)
	active_knight_guards.append(guard)

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

	_fit_top_bar_labels()
	_update_upgrade_buttons()
	_update_skill_buttons()
	_update_skill_duration_list(BUY_SKILLS.get_skill_definitions())

func _fit_top_bar_labels() -> void:
	for label in [day_label, market_label, match_timer_label, satisfaction_label, reputation_label, money_label, rush_label]:
		_fit_label_to_width(label as Label)

func _fit_label_to_width(label: Label) -> void:
	if label == null:
		return
	label.clip_text = true
	var available_width: float = maxf(label.size.x - 4.0, 1.0)
	var font_size := HUD_STAT_FONT_MAX
	while font_size > HUD_STAT_FONT_MIN and _estimated_label_width(label.text, font_size) > available_width:
		font_size -= 1
	label.add_theme_font_size_override("font_size", font_size)

func _estimated_label_width(text: String, font_size: int) -> float:
	return float(text.length()) * float(font_size) * 0.58

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
		button.text = ""
		var cost_label := upgrade_cost_labels.get(upgrade_name) as Label
		if cost_label:
			cost_label.text = "₱%d" % cost
		button.disabled = not _can_afford_upgrade(cost) or not day_active

func _update_skill_buttons() -> void:
	if swatter_entity == null:
		return

	var definitions := BUY_SKILLS.get_skill_definitions()
	for skill_id in skill_buttons.keys():
		var button := skill_buttons[skill_id] as Button
		var def: Dictionary = definitions[skill_id]
		var cost := int(def.get("cost", 0))
		var icon_texture := load(str(def.get("icon", ""))) as Texture2D
		button.icon = icon_texture
		var cost_label := skill_cost_labels.get(skill_id) as Label
		if cost_label:
			cost_label.text = "₱%d" % cost
		var remaining := float(skill_timers.get(skill_id, 0.0))
		if remaining > 0.0:
			button.text = ""
			button.disabled = true
		else:
			button.text = ""
			button.disabled = not _can_afford_skill(cost) or not day_active

func _update_skill_duration_list(definitions: Dictionary) -> void:
	if skill_duration_list == null:
		return
	for child in skill_duration_list.get_children():
		child.queue_free()
	for skill_id in definitions.keys():
		var remaining := float(skill_timers.get(skill_id, 0.0))
		if remaining <= 0.0:
			continue
		var def: Dictionary = definitions[skill_id]
		var item := VBoxContainer.new()
		item.alignment = BoxContainer.ALIGNMENT_CENTER
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(34, 34)
		icon.texture = load(str(def.get("icon", ""))) as Texture2D
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item.add_child(icon)
		var duration := Label.new()
		duration.text = "%.1fs" % remaining
		duration.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item.add_child(duration)
		skill_duration_list.add_child(item)

func _can_afford_skill(cost: int) -> bool:
	return current_money >= cost

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
	_play_control_bounce(upgrade_buttons.get(upgrade_name) as Control)
	_check_loss_conditions()
	_update_hud()

func _can_afford_upgrade(cost: int) -> bool:
	return current_money >= cost

func _on_skill_pressed(skill_id: String) -> void:
	if swatter_entity == null or not day_active:
		return

	var definitions := BUY_SKILLS.get_skill_definitions()
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

	_play_control_bounce(skill_buttons.get(skill_id) as Control)
	_play_skill_effect(skill_id)
	_activate_skill(skill_id, def)
	_update_hud()

func _activate_skill(skill_id: String, def: Dictionary) -> void:
	match int(def.get("type", -1)):
		BUY_SKILLS.SkillType.MEGA_SWATTER:
			swatter_entity.call("set_mega_swatter", true)
			swatter_sprite.scale = Vector2.ONE * float(swatter_entity.call("get_size_multiplier"))
		BUY_SKILLS.SkillType.INSTANT_ENERGY:
			swatter_entity.call("set_instant_energy", true)
		BUY_SKILLS.SkillType.FRESH_GOODS:
			_set_food_protection(true)
		BUY_SKILLS.SkillType.BIG_FAN:
			big_fan_popup.visible = true
			if swatter_sprite != null:
				swatter_sprite.visible = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			return

	var duration := float(def.get("duration", 0.0))
	skill_timers[skill_id] = duration
	_update_hud()

func _set_food_protection(value: bool) -> void:
	if food_container == null:
		return
	for food in food_container.get_children():
		if is_instance_valid(food) and food.has_method("set_protected"):
			food.call("set_protected", value)

func _on_big_fan_choice(side: String) -> void:
	big_fan_popup.visible = false
	big_fan_choice = side
	if swatter_sprite != null:
		swatter_sprite.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	var def: Dictionary = BUY_SKILLS.get_skill_definitions()["big_fan"]
	_activate_big_fan(side)
	skill_timers["big_fan"] = float(def.get("duration", 0.0))
	_update_hud()

func _activate_big_fan(side: String) -> void:
	big_fan_direction = -1.0 if side == "left" else 1.0
	if big_fan_sprite != null:
		var viewport_size := get_viewport_rect().size
		big_fan_sprite.position = Vector2(viewport_size.x if side == "left" else 0.0, viewport_size.y * 0.5)
		big_fan_sprite.visible = true

func _update_big_fan_effect(delta: float) -> void:
	var remaining := float(skill_timers.get("big_fan", 0.0))
	if remaining <= 0.0:
		fan_camera_offset = Vector2.ZERO
		if big_fan_sprite != null:
			big_fan_sprite.visible = false
		return
	if big_fan_sprite != null:
		big_fan_sprite.visible = true
		big_fan_sprite.rotation += delta * TAU * 2.0
	var pulse := sin(Time.get_ticks_msec() * 0.012) * 3.0
	fan_camera_offset = Vector2(-big_fan_direction * 10.0, pulse)
	if fly_container == null:
		return
	var bounds := _get_fly_bounds()
	var target_x := bounds.position.x + 30.0 if big_fan_direction < 0.0 else bounds.end.x - 30.0
	for fly in fly_container.get_children():
		if not is_instance_valid(fly) or fly.is_queued_for_deletion() or fly.is_in_group("boss_flies"):
			continue
		if fly.has_method("apply_big_fan"):
			fly.call("apply_big_fan", big_fan_direction, target_x, 900.0, remaining)

func _update_skills(delta: float) -> void:
	if swatter_entity == null:
		return

	var expired := []
	for skill_id in skill_timers.keys():
		var remaining := float(skill_timers.get(skill_id, 0.0))
		if remaining <= 0.0:
			continue
		remaining -= delta
		if remaining <= 0.0:
			remaining = 0.0
			expired.append(skill_id)
		skill_timers[skill_id] = remaining

	for skill_id in expired:
		_deactivate_skill(skill_id)

	_update_skill_buttons()

func _deactivate_skill(skill_id: String) -> void:
	var definitions := BUY_SKILLS.get_skill_definitions()
	var def: Dictionary = definitions.get(skill_id, {})
	match int(def.get("type", -1)):
		BUY_SKILLS.SkillType.MEGA_SWATTER:
			swatter_entity.call("set_mega_swatter", false)
			swatter_sprite.scale = Vector2.ONE
		BUY_SKILLS.SkillType.INSTANT_ENERGY:
			swatter_entity.call("set_instant_energy", false)
		BUY_SKILLS.SkillType.FRESH_GOODS:
			_set_food_protection(false)

func _reset_skill_state() -> void:
	for skill_id in skill_timers.keys():
		skill_timers[skill_id] = 0.0
	if swatter_entity != null:
		swatter_entity.call("set_mega_swatter", false)
		swatter_entity.call("set_instant_energy", false)
	swatter_sprite.scale = Vector2.ONE
	_set_food_protection(false)
	if big_fan_popup != null:
		big_fan_popup.visible = false
	big_fan_direction = 0.0
	fan_camera_offset = Vector2.ZERO
	if big_fan_sprite != null:
		big_fan_sprite.visible = false
	_update_skill_buttons()

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

	if swatter_entity != null and swatter_entity.has_method("get_size_multiplier") and float(swatter_entity.call("get_size_multiplier")) > 1.0:
		_mega_swatter_hit_area()

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
		position = base_scene_position + fan_camera_offset
		return

	screen_shake_timer = maxf(screen_shake_timer - delta, 0.0)
	var fade := screen_shake_timer / maxf(screen_shake_duration, 0.001)
	position = base_scene_position + fan_camera_offset + Vector2(
		randf_range(-screen_shake_strength, screen_shake_strength) * fade,
		randf_range(-screen_shake_strength, screen_shake_strength) * fade
	)
	if screen_shake_timer <= 0.0:
		position = base_scene_position + fan_camera_offset

func _get_active_food_count(excluded_food: Node = null) -> int:
	if food_container == null:
		return 0
	var count := 0
	for food in food_container.get_children():
		if food == excluded_food or food.is_queued_for_deletion():
			continue
		count += 1
	return count
