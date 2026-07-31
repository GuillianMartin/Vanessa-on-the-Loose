extends RefCounted
const GameConfig = preload("res://Backend/Game/GameConfig.gd")
var game: Node2D

func _init(p_game: Node2D) -> void:
	game = p_game

func build_hud() -> void:
	var hud_layer = GameConfig.HUD_SCENE.instantiate()
	hud_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	game.hud_layer = hud_layer
	game.add_child(hud_layer)
	game.day_label = hud_layer.get_node("TopBar/Day")
	game.market_label = hud_layer.get_node("TopBar/Market")
	game.money_label = hud_layer.get_node("TopBar/Money")
	game.reputation_label = hud_layer.get_node("TopBar/Reputation")
	game.satisfaction_label = hud_layer.get_node("TopBar/Satisfaction")
	game.flies_label = hud_layer.get_node("TopBar/Flies")
	game.swatted_label = hud_layer.get_node("TopBar/Swatted")
	game.match_timer_label = hud_layer.get_node("TopBar/MatchTimer")
	game.rush_label = hud_layer.get_node("TopBar/Rush")
	game.swatter_energy_label = hud_layer.get_node("TopBar/EnergyLabel")
	game.swatter_energy_bar = hud_layer.get_node("TopBar/EnergyBar")
	var energy_bg := StyleBoxFlat.new()
	energy_bg.bg_color = Color(0.15, 0.15, 0.15, 0.6)
	energy_bg.corner_radius_top_left = 6
	energy_bg.corner_radius_top_right = 6
	energy_bg.corner_radius_bottom_left = 6
	energy_bg.corner_radius_bottom_right = 6
	game.swatter_energy_bar.add_theme_stylebox_override("bg", energy_bg)
	var energy_fill := StyleBoxFlat.new()
	energy_fill.bg_color = Color(0.2, 0.85, 0.35)
	energy_fill.corner_radius_top_left = 6
	energy_fill.corner_radius_top_right = 6
	energy_fill.corner_radius_bottom_left = 6
	energy_fill.corner_radius_bottom_right = 6
	game.swatter_energy_bar.add_theme_stylebox_override("fill", energy_fill)
	game.boss_health_label = hud_layer.get_node("BossHealth/Label")
	game.boss_health_bar = hud_layer.get_node("BossHealth/Bar")
	game.skill_duration_list = hud_layer.get_node("DurationList")
	build_upgrade_panel()
	build_skill_panel()
	build_pause_ui()

func _make_hud_label(text: String, width: float) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(width, 0)
	return label

func build_upgrade_panel() -> void:
	game.upgrade_label = game.hud_layer.get_node("UpgradePanel/Title")
	game.upgrade_buttons = {}
	game.upgrade_cost_labels = {}
	for upgrade_name in ["damage", "speed", "energy"]:
		var node_name: String = str(upgrade_name).capitalize()
		var scene_button: Button = game.hud_layer.get_node("UpgradePanel/" + node_name)
		var cost_label: Label = game.hud_layer.get_node("UpgradePanel/" + node_name + "Cost")
		_prepare_icon_button(scene_button)
		_prepare_cost_label(cost_label)
		scene_button.tooltip_text = GameConfig.upgrade_descriptions.get(upgrade_name, "")
		game._connect_button_sfx(scene_button)
		scene_button.pressed.connect(game._on_upgrade_pressed.bind(upgrade_name))
		game.upgrade_buttons[upgrade_name] = scene_button
		game.upgrade_cost_labels[upgrade_name] = cost_label

func build_skill_panel() -> void:
	game.skill_label = game.hud_layer.get_node("SkillPanel/Title")
	var definitions := GameConfig.BUY_SKILLS.get_skill_definitions()
	game.skill_timers = {}
	game.skill_buttons = {}
	game.skill_cost_labels = {}
	game.skill_effect_overlays = {}
	game.skill_effect_textures = {
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
		var scene_button: Button = game.hud_layer.get_node("SkillPanel/" + node_name)
		var cost_label: Label = game.hud_layer.get_node("SkillPanel/" + node_name + "Cost")
		_prepare_icon_button(scene_button)
		_prepare_cost_label(cost_label)
		_create_skill_effect_overlay(skill_id, scene_button)
		game._connect_button_sfx(scene_button)
		scene_button.pressed.connect(game._on_skill_pressed.bind(skill_id))
		scene_button.tooltip_text = str(def.get("description", ""))
		game.skill_buttons[skill_id] = scene_button
		game.skill_cost_labels[skill_id] = cost_label
		game.skill_timers[skill_id] = 0.0
	build_big_fan_popup()

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
	label.add_theme_font_override("font", GameConfig.JERSEY_FONT)
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color(0.12, 0.07, 0.03, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)

func _create_skill_effect_overlay(skill_id: String, button: Button) -> void:
	var overlay := TextureRect.new()
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.custom_minimum_size = GameConfig.SKILL_EFFECT_FRAME_SIZE
	overlay.size = GameConfig.SKILL_EFFECT_FRAME_SIZE
	overlay.position = (button.size - GameConfig.SKILL_EFFECT_FRAME_SIZE) * 0.5 + GameConfig.SKILL_EFFECT_OFFSET
	overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	overlay.z_index = 20
	button.add_child(overlay)
	game.skill_effect_overlays[skill_id] = overlay

func build_big_fan_popup() -> void:
	game.big_fan_popup = Control.new()
	game.big_fan_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	game.big_fan_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	game.big_fan_popup.visible = false
	game.hud_layer.add_child(game.big_fan_popup)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	game.big_fan_popup.add_child(center)

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
	game._connect_button_sfx(left_btn)
	left_btn.pressed.connect(game._on_big_fan_choice.bind("left"))
	btn_row.add_child(left_btn)

	var right_btn := Button.new()
	right_btn.text = "Right"
	right_btn.custom_minimum_size = Vector2(120, 44)
	game._connect_button_sfx(right_btn)
	right_btn.pressed.connect(game._on_big_fan_choice.bind("right"))
	btn_row.add_child(right_btn)

func build_pause_ui() -> void:
	game.pause_button = TextureButton.new()
	game.pause_button.name = "PauseButton"
	game.pause_button.process_mode = Node.PROCESS_MODE_ALWAYS
	game.pause_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	game.pause_button.offset_left = -104.0
	game.pause_button.offset_top = 4.0
	game.pause_button.offset_right = -10.0
	game.pause_button.offset_bottom = 96.0
	game.pause_button.texture_normal = get_atlas_frame(GameConfig.PAUSE_BUTTON_TEXTURE, GameConfig.PAUSE_BUTTON_FRAME_SIZE, 0)
	game.pause_button.texture_hover = get_atlas_frame(GameConfig.PAUSE_BUTTON_TEXTURE, GameConfig.PAUSE_BUTTON_FRAME_SIZE, 1)
	game.pause_button.texture_pressed = get_atlas_frame(GameConfig.PAUSE_BUTTON_TEXTURE, GameConfig.PAUSE_BUTTON_FRAME_SIZE, 1)
	game.pause_button.ignore_texture_size = true
	game.pause_button.custom_minimum_size = GameConfig.PAUSE_BUTTON_SIZE
	game.pause_button.size = GameConfig.PAUSE_BUTTON_SIZE
	game.pause_button.pivot_offset = GameConfig.PAUSE_BUTTON_SIZE * 0.5
	game.pause_button.z_index = 50
	game._connect_button_sfx(game.pause_button)
	game.pause_button.pressed.connect(game._on_pause_pressed)
	game.hud_layer.add_child(game.pause_button)

	game.pause_overlay = Control.new()
	game.pause_overlay.name = "PauseOverlay"
	game.pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	game.pause_overlay.visible = false
	game.pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	game.pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	game.pause_overlay.z_index = 40
	game.hud_layer.add_child(game.pause_overlay)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.0, 0.0, 0.0, 0.58)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	game.pause_overlay.add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	game.pause_overlay.add_child(center)

	game.pause_menu_box = VBoxContainer.new()
	game.pause_menu_box.alignment = BoxContainer.ALIGNMENT_CENTER
	game.pause_menu_box.add_theme_constant_override("separation", 18)
	game.pause_menu_box.pivot_offset = Vector2(GameConfig.PAUSE_MENU_BUTTON_SIZE.x * 0.5, GameConfig.PAUSE_MENU_BUTTON_SIZE.y + 9.0)
	center.add_child(game.pause_menu_box)

	game.pause_quit_button = _make_pause_menu_button(GameConfig.QUIT_BUTTON_TEXTURE)
	game._connect_button_sfx(game.pause_quit_button)
	game.pause_quit_button.pressed.connect(game._on_pause_quit_pressed)
	game.pause_menu_box.add_child(game.pause_quit_button)

	game.pause_resume_button = _make_pause_menu_button(GameConfig.RESUME_BUTTON_TEXTURE)
	game._connect_button_sfx(game.pause_resume_button)
	game.pause_resume_button.pressed.connect(game._on_pause_resume_pressed)
	game.pause_menu_box.add_child(game.pause_resume_button)

func _make_pause_menu_button(texture: Texture2D) -> TextureButton:
	var button := TextureButton.new()
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.texture_normal = get_atlas_frame(texture, GameConfig.PAUSE_MENU_BUTTON_SIZE, 0)
	button.texture_hover = get_atlas_frame(texture, GameConfig.PAUSE_MENU_BUTTON_SIZE, 1)
	button.texture_pressed = get_atlas_frame(texture, GameConfig.PAUSE_MENU_BUTTON_SIZE, 1)
	button.ignore_texture_size = true
	button.custom_minimum_size = GameConfig.PAUSE_MENU_BUTTON_SIZE
	button.size = GameConfig.PAUSE_MENU_BUTTON_SIZE
	button.pivot_offset = GameConfig.PAUSE_MENU_BUTTON_SIZE * 0.5
	return button

func build_menu() -> void:
	game.menu_layer = CanvasLayer.new()
	game.menu_layer.name = "Menu"
	game.add_child(game.menu_layer)

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.45)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	game.menu_layer.add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	game.menu_layer.add_child(center)

	var panel := PanelContainer.new()
	game.default_menu_panel = panel
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

	game.menu_title = Label.new()
	game.menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game.menu_title.text = "Bangaw"
	content.add_child(game.menu_title)

	game.result_label = Label.new()
	game.result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	game.result_label.text = ""
	game.result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game.result_label.custom_minimum_size = Vector2(480, 0)
	content.add_child(game.result_label)

	game.forecast_warning_label = Label.new()
	game.forecast_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game.forecast_warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game.forecast_warning_label.custom_minimum_size = Vector2(480, 0)
	game.forecast_warning_label.visible = false
	content.add_child(game.forecast_warning_label)

	game.play_button = Button.new()
	game.play_button.text = "Play"
	game.play_button.custom_minimum_size = Vector2(190, 44)
	game._connect_button_sfx(game.play_button)
	game.play_button.pressed.connect(game._on_menu_button_pressed)
	content.add_child(game.play_button)

	build_result_art_menu()
	build_boss_warning_menu()
	build_game_over_menu()

func build_result_art_menu() -> void:
	game.result_art_root = GameConfig.AFTER_DAY_REPORT_SCENE.instantiate()
	game.menu_layer.add_child(game.result_art_root)
	game.result_board = game.result_art_root.get_node("Center/Board")
	game.result_texture_rect = game.result_art_root.get_node("Center/Board/Background")
	game.result_motion_root = game.result_art_root.get_node("Center/Board/MotionRoot")
	game.result_content = game.result_art_root.get_node("Center/Board/MotionRoot/TextMargin/Content")
	game.result_title_label = game.result_art_root.get_node("Center/Board/MotionRoot/TextMargin/Content/Title")
	game.result_body_label = game.result_art_root.get_node("Center/Board/MotionRoot/TextMargin/Content/Body")
	game.result_warning_label = game.result_art_root.get_node("Center/Board/MotionRoot/TextMargin/Content/Warning")
	game.financial_button = game.result_art_root.get_node("Center/Board/FinancialButton")
	game.result_start_button = game.result_art_root.get_node("Center/Board/StartButton")
	game._connect_button_sfx(game.financial_button)
	game._connect_button_sfx(game.result_start_button)
	game.financial_button.pressed.connect(game._on_menu_button_pressed)
	game.result_start_button.pressed.connect(game._on_menu_button_pressed)

func _get_button_frame(atlas: Texture2D, frame_index: int) -> AtlasTexture:
	return get_atlas_frame(atlas, GameConfig.RESULT_BUTTON_FRAME_SIZE, frame_index)

func get_atlas_frame(atlas: Texture2D, frame_size: Vector2, frame_index: int) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = Rect2(frame_size.x * frame_index, 0, frame_size.x, frame_size.y)
	return texture

func build_game_over_menu() -> void:
	game.game_over_root = Control.new()
	game.game_over_root.visible = false
	game.game_over_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	game.menu_layer.add_child(game.game_over_root)

	game.game_over_background = TextureRect.new()
	game.game_over_background.texture = GameConfig.GAME_OVER_TEXTURE
	game.game_over_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	game.game_over_background.stretch_mode = TextureRect.STRETCH_SCALE
	game.game_over_root.add_child(game.game_over_background)

	game.game_over_fly = TextureRect.new()
	game.game_over_fly.texture = GameConfig.GAME_OVER_FLY_TEXTURE
	game.game_over_fly.set_anchors_preset(Control.PRESET_FULL_RECT)
	game.game_over_fly.stretch_mode = TextureRect.STRETCH_SCALE
	game.game_over_root.add_child(game.game_over_fly)

	game.game_over_data_label = Label.new()
	game.game_over_data_label.position = GameConfig.GAME_OVER_DATA_POSITION
	game.game_over_data_label.size = GameConfig.GAME_OVER_DATA_SIZE
	game.game_over_data_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	game.game_over_data_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game.game_over_data_label.add_theme_font_override("font", GameConfig.PIXELIFY_FONT)
	game.game_over_data_label.add_theme_color_override("font_color", Color.WHITE)
	game.game_over_data_label.add_theme_font_size_override("font_size", 20)
	game.game_over_root.add_child(game.game_over_data_label)

	game.game_over_try_again_button = TextureButton.new()
	game.game_over_try_again_button.position = GameConfig.GAME_OVER_TRY_AGAIN_BUTTON_POSITION
	game.game_over_try_again_button.texture_normal = _get_game_over_button_frame(GameConfig.TRY_AGAIN_BUTTON_TEXTURE, 0)
	game.game_over_try_again_button.texture_hover = _get_game_over_button_frame(GameConfig.TRY_AGAIN_BUTTON_TEXTURE, 1)
	game.game_over_try_again_button.texture_pressed = _get_game_over_button_frame(GameConfig.TRY_AGAIN_BUTTON_TEXTURE, 1)
	game.game_over_try_again_button.ignore_texture_size = true
	game.game_over_try_again_button.custom_minimum_size = GameConfig.GAME_OVER_BUTTON_FRAME_SIZE
	game.game_over_try_again_button.size = GameConfig.GAME_OVER_BUTTON_FRAME_SIZE
	game.game_over_try_again_button.pivot_offset = GameConfig.GAME_OVER_BUTTON_FRAME_SIZE * 0.5
	game._connect_button_sfx(game.game_over_try_again_button)
	game.game_over_try_again_button.pressed.connect(game._on_game_over_button_pressed.bind("try_again"))
	game.game_over_root.add_child(game.game_over_try_again_button)

	game.game_over_home_button = TextureButton.new()
	game.game_over_home_button.position = GameConfig.GAME_OVER_HOME_BUTTON_POSITION
	game.game_over_home_button.texture_normal = _get_game_over_button_frame(GameConfig.HOME_BUTTON_TEXTURE, 0)
	game.game_over_home_button.texture_hover = _get_game_over_button_frame(GameConfig.HOME_BUTTON_TEXTURE, 1)
	game.game_over_home_button.texture_pressed = _get_game_over_button_frame(GameConfig.HOME_BUTTON_TEXTURE, 1)
	game.game_over_home_button.ignore_texture_size = true
	game.game_over_home_button.custom_minimum_size = GameConfig.GAME_OVER_BUTTON_FRAME_SIZE
	game.game_over_home_button.size = GameConfig.GAME_OVER_BUTTON_FRAME_SIZE
	game.game_over_home_button.pivot_offset = GameConfig.GAME_OVER_BUTTON_FRAME_SIZE * 0.5
	game._connect_button_sfx(game.game_over_home_button)
	game.game_over_home_button.pressed.connect(game._on_game_over_button_pressed.bind("home"))
	game.game_over_root.add_child(game.game_over_home_button)

func _get_game_over_button_frame(atlas: Texture2D, frame_index: int) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = Rect2(GameConfig.GAME_OVER_BUTTON_FRAME_SIZE.x * frame_index, 0, GameConfig.GAME_OVER_BUTTON_FRAME_SIZE.x, GameConfig.GAME_OVER_BUTTON_FRAME_SIZE.y)
	return texture

func build_boss_warning_menu() -> void:
	game.boss_warning_root = Control.new()
	game.boss_warning_root.visible = false
	game.boss_warning_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	game.menu_layer.add_child(game.boss_warning_root)

	game.boss_warning_top = TextureRect.new()
	game.boss_warning_top.texture = GameConfig.BOSS_BG_TOP_TEXTURE
	game.boss_warning_top.position = Vector2(0, -GameConfig.BOSS_SHUTTER_HALF_SIZE.y)
	game.boss_warning_top.size = GameConfig.BOSS_SHUTTER_HALF_SIZE
	game.boss_warning_top.stretch_mode = TextureRect.STRETCH_SCALE
	game.boss_warning_root.add_child(game.boss_warning_top)

	game.boss_warning_bottom = TextureRect.new()
	game.boss_warning_bottom.texture = GameConfig.BOSS_BG_BOTTOM_TEXTURE
	game.boss_warning_bottom.position = Vector2(0, GameConfig.GAME_OVER_FRAME_SIZE.y)
	game.boss_warning_bottom.size = GameConfig.BOSS_SHUTTER_HALF_SIZE
	game.boss_warning_bottom.stretch_mode = TextureRect.STRETCH_SCALE
	game.boss_warning_root.add_child(game.boss_warning_bottom)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	game.boss_warning_root.add_child(center)

	game.boss_warning_board = Control.new()
	game.boss_warning_board.custom_minimum_size = GameConfig.BOSS_WARNING_FRAME_SIZE
	game.boss_warning_board.size = GameConfig.BOSS_WARNING_FRAME_SIZE
	game.boss_warning_board.pivot_offset = GameConfig.BOSS_WARNING_FRAME_SIZE * 0.5
	game.boss_warning_board.visible = false
	center.add_child(game.boss_warning_board)

	var board_texture := TextureRect.new()
	board_texture.texture = GameConfig.BOSS_WARNING_CONTAINER_TEXTURE
	board_texture.size = GameConfig.BOSS_WARNING_FRAME_SIZE
	board_texture.stretch_mode = TextureRect.STRETCH_SCALE
	game.boss_warning_board.add_child(board_texture)

	var text_area := VBoxContainer.new()
	game.boss_warning_content = text_area
	text_area.position = GameConfig.BOSS_WARNING_TEXT_POSITION
	text_area.size = GameConfig.BOSS_WARNING_TEXT_SIZE
	text_area.clip_contents = true
	text_area.alignment = BoxContainer.ALIGNMENT_CENTER
	text_area.add_theme_constant_override("separation", 12)
	game.boss_warning_board.add_child(text_area)

	game.boss_warning_title_label = Label.new()
	game.boss_warning_title_label.text = "BOSS WARNING"
	game.boss_warning_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game.boss_warning_title_label.add_theme_font_override("font", GameConfig.JERSEY_FONT)
	game.boss_warning_title_label.add_theme_font_size_override("font_size", 36)
	game.boss_warning_title_label.add_theme_color_override("font_color", Color("#5D371E"))
	text_area.add_child(game.boss_warning_title_label)

	game.boss_warning_body_label = Label.new()
	game.boss_warning_body_label.text = "A powerful Boss Fly awaits! Protect your market and survive the Boss Fight to continue.\n\nIt will be guarded by elite Knight Flies. Customers will still visit during the fight, so keep your reputation and satisfaction up."
	game.boss_warning_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game.boss_warning_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game.boss_warning_body_label.add_theme_font_override("font", GameConfig.PIXELIFY_FONT)
	game.boss_warning_body_label.add_theme_font_size_override("font_size", 18)
	game.boss_warning_body_label.add_theme_color_override("font_color", Color("#5D371E"))
	game.boss_warning_body_label.custom_minimum_size = Vector2(GameConfig.BOSS_WARNING_TEXT_SIZE.x, 0)
	text_area.add_child(game.boss_warning_body_label)

	game.boss_warning_hint_label = Label.new()
	game.boss_warning_hint_label.text = "Boss Fight incoming - prepare your swatter!"
	game.boss_warning_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game.boss_warning_hint_label.add_theme_font_override("font", GameConfig.PIXELIFY_FONT)
	game.boss_warning_hint_label.add_theme_font_size_override("font_size", 17)
	game.boss_warning_hint_label.add_theme_color_override("font_color", Color("#B62A19"))
	text_area.add_child(game.boss_warning_hint_label)

	game.boss_warning_enter_button = TextureButton.new()
	game.boss_warning_enter_button.texture_normal = GameConfig.ENTER_BOSS_BUTTON_TEXTURE
	game.boss_warning_enter_button.texture_hover = GameConfig.ENTER_BOSS_BUTTON_TEXTURE
	game.boss_warning_enter_button.texture_pressed = GameConfig.ENTER_BOSS_BUTTON_TEXTURE
	game.boss_warning_enter_button.ignore_texture_size = true
	game.boss_warning_enter_button.position = GameConfig.BOSS_WARNING_BUTTON_POSITION
	game.boss_warning_enter_button.custom_minimum_size = GameConfig.BOSS_WARNING_BUTTON_SIZE
	game.boss_warning_enter_button.size = GameConfig.BOSS_WARNING_BUTTON_SIZE
	game.boss_warning_enter_button.pivot_offset = GameConfig.BOSS_WARNING_BUTTON_SIZE * 0.5
	game._connect_button_sfx(game.boss_warning_enter_button)
	game.boss_warning_enter_button.pressed.connect(game._on_menu_button_pressed)
	game.boss_warning_board.add_child(game.boss_warning_enter_button)

func show_default_menu_panel() -> void:
	if game.default_menu_panel:
		game.default_menu_panel.visible = true
	if game.result_art_root:
		game.result_art_root.visible = false
	if game.boss_warning_root:
		game.boss_warning_root.visible = false
	if game.game_over_root:
		game.game_over_root.visible = false
	game.result_transition_active = false

func show_result_art_panel() -> void:
	if game.default_menu_panel:
		game.default_menu_panel.visible = false
	if game.result_art_root:
		game.result_art_root.visible = true
	if game.boss_warning_root:
		game.boss_warning_root.visible = false
	if game.game_over_root:
		game.game_over_root.visible = false
	if game.result_board:
		game.result_board.scale = Vector2.ONE
	if game.result_texture_rect:
		game.result_texture_rect.texture = GameConfig.RESULT_CONTAINER_TEXTURE
	if game.result_motion_root:
		game.result_motion_root.position = Vector2.ZERO
		game.result_motion_root.modulate.a = 1.0

func show_game_over_art_panel() -> void:
	if game.default_menu_panel:
		game.default_menu_panel.visible = false
	if game.result_art_root:
		game.result_art_root.visible = false
	if game.boss_warning_root:
		game.boss_warning_root.visible = false
	if game.game_over_root:
		game.game_over_root.visible = true

func show_boss_warning_art_panel() -> void:
	if game.default_menu_panel:
		game.default_menu_panel.visible = false
	if game.result_art_root:
		game.result_art_root.visible = false
	if game.game_over_root:
		game.game_over_root.visible = false
	if game.boss_warning_root:
		game.boss_warning_root.visible = true

func update_hud() -> void:
	if game.day_label:
		game.day_label.text = "Day %d" % game.market_day
	if game.market_label:
		game.market_label.text = "Boss Fight" if game.boss_round_active else str(game.active_market_event.get("name", "Market"))
	if game.flies_label:
		game.flies_label.text = "Boss" if game.boss_round_active else "Flies: %d" % game.flies_left
	if game.swatted_label:
		game.swatted_label.text = "Swatted: %d" % game.day_flies_killed
	if game.money_label:
		game.money_label.text = "Money: ₱%d" % game.current_money
	if game.reputation_label:
		game.reputation_label.text = "Rep: %d" % game.reputation
	if game.satisfaction_label:
		game.satisfaction_label.text = "Sat: %d" % game.customer_satisfaction
	if game.rush_label:
		game.rush_label.text = "Rush" if game.rush_active else ""
	_set_boss_health_visible(game.boss_round_active)

	if game.match_timer_label:
		if game.boss_round_active:
			game.match_timer_label.text = "Time: ∞"
		else:
			var minutes := int(maxf(game.game_timer, 0.0)) / 60.0
			var seconds := int(maxf(game.game_timer, 0.0)) % 60
			game.match_timer_label.text = "Time: %d:%02d" % [minutes, seconds]

	_fit_top_bar_labels()
	update_upgrade_buttons()
	update_skill_buttons()
	update_skill_duration_list(GameConfig.BUY_SKILLS.get_skill_definitions())

func _fit_top_bar_labels() -> void:
	for label in [game.day_label, game.market_label, game.match_timer_label, game.satisfaction_label, game.reputation_label, game.money_label, game.rush_label]:
		_fit_label_to_width(label as Label)

func _fit_label_to_width(label: Label) -> void:
	if label == null:
		return
	label.clip_text = true
	var available_width: float = maxf(label.size.x - 4.0, 1.0)
	var font_size := GameConfig.HUD_STAT_FONT_MAX
	while font_size > GameConfig.HUD_STAT_FONT_MIN and _estimated_label_width(label.text, font_size) > available_width:
		font_size -= 1
	label.add_theme_font_size_override("font_size", font_size)

func _estimated_label_width(text: String, font_size: int) -> float:
	return float(text.length()) * float(font_size) * 0.58

func _set_boss_health_visible(visible: bool) -> void:
	if game.boss_health_bar == null:
		return
	var boss_row := game.boss_health_bar.get_parent() as Control
	if boss_row != null:
		boss_row.visible = visible

func update_upgrade_buttons() -> void:
	if game.swatter_entity == null:
		return

	if game.upgrade_label:
		game.upgrade_label.text = "Upgrades"

	for upgrade_name in game.upgrade_buttons.keys():
		var button := game.upgrade_buttons[upgrade_name] as Button
		var cost := int(game.swatter_entity.call("get_upgrade_cost", upgrade_name))
		var icon_texture := load(GameConfig.icon_paths[upgrade_name]) as Texture2D
		button.icon = icon_texture
		button.text = ""
		var cost_label := game.upgrade_cost_labels.get(upgrade_name) as Label
		if cost_label:
			cost_label.text = "₱%d" % cost
		button.disabled = not game._can_afford_upgrade(cost) or not game.day_active

func update_skill_buttons() -> void:
	if game.swatter_entity == null:
		return

	var definitions := GameConfig.BUY_SKILLS.get_skill_definitions()
	for skill_id in game.skill_buttons.keys():
		var button := game.skill_buttons[skill_id] as Button
		var def: Dictionary = definitions[skill_id]
		var cost := int(def.get("cost", 0))
		var icon_texture := load(str(def.get("icon", ""))) as Texture2D
		button.icon = icon_texture
		var cost_label := game.skill_cost_labels.get(skill_id) as Label
		if cost_label:
			cost_label.text = "₱%d" % cost
		var remaining := float(game.skill_timers.get(skill_id, 0.0))
		if remaining > 0.0:
			button.text = ""
			button.disabled = true
		else:
			button.text = ""
			button.disabled = not game._can_afford_skill(cost) or not game.day_active

func update_skill_duration_list(definitions: Dictionary) -> void:
	if game.skill_duration_list == null:
		return
	for child in game.skill_duration_list.get_children():
		child.queue_free()
	for skill_id in definitions.keys():
		var remaining := float(game.skill_timers.get(skill_id, 0.0))
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
		game.skill_duration_list.add_child(item)

func play_skill_effect(skill_id: String) -> void:
	var overlay := game.skill_effect_overlays.get(skill_id) as TextureRect
	var atlas := game.skill_effect_textures.get(skill_id) as Texture2D
	if overlay == null or atlas == null:
		return
	overlay.visible = true
	overlay.modulate.a = 1.0
	var frame_time := 1.0 / GameConfig.SKILL_EFFECT_FPS
	var tween := game.create_tween()
	for frame_index in range(GameConfig.SKILL_EFFECT_FRAME_COUNT):
		tween.tween_callback(Callable(game, "_set_skill_effect_frame").bind(skill_id, frame_index))
		tween.tween_interval(frame_time)
	tween.tween_callback(Callable(game, "_hide_skill_effect").bind(skill_id))

func show_start_menu() -> void:
	game._set_gameplay_paused(false)
	game.menu_state = "start"
	game.day_active = false
	game.boss_round_active = false
	game.boss_round_pending = false
	game.boss_warning_shown = false
	game._set_swatter_active(false)
	game._set_boss_health_visible(false)
	game.menu_layer.visible = true
	game.hud_layer.visible = false
	if game.pause_button:
		game.pause_button.visible = false
	game.fly_container.visible = false
	game.food_container.visible = false
	game.customer_container.visible = false
	game._clear_flies()
	game._clear_food()
	game._clear_customers()
	show_default_menu_panel()
	game.menu_title.text = "Bangaw Fly Market"
	game.result_label.text = "Run a stall, protect the food, earn profit, and survive as many market days as possible."
	if game.forecast_warning_label:
		game.forecast_warning_label.visible = false
	game.play_button.text = "Start Market"

func show_boss_warning_screen() -> void:
	game.menu_state = "boss_warning"
	game.day_active = false
	game.boss_round_active = false
	game._set_swatter_active(false)
	game._set_boss_health_visible(false)
	game.menu_layer.visible = true
	game.hud_layer.visible = false
	game.fly_container.visible = false
	game.food_container.visible = false
	game.customer_container.visible = false
	game._clear_flies()
	game._clear_food()
	game._clear_customers()
	show_boss_warning_art_panel()
	game.menu_title.text = "⚠ BOSS WARNING ⚠"
	game.result_label.text = "A powerful Boss Fly awaits! Protect your market and survive the Boss Fight to continue.\n\nIt will be guarded by elite Knight Flies. Customers will still visit during the fight, so keep your reputation and satisfaction up."
	if game.forecast_warning_label:
		game.forecast_warning_label.visible = true
		game.forecast_warning_label.text = "Boss Fight incoming — prepare your swatter!"
		game.forecast_warning_label.add_theme_color_override("font_color", Color(1.0, 0.12, 0.08))
	game.play_button.text = "Enter Boss Fight"
	game._play_boss_warning_intro()

func show_starting_day_report_screen() -> void:
	game.menu_state = "starting_day_report"
	game.day_active = false
	game._set_swatter_active(false)
	game._set_boss_health_visible(false)
	game.menu_layer.visible = true
	game.hud_layer.visible = false
	if game.pause_button:
		game.pause_button.visible = false
	game.food_container.visible = false
	game.fly_container.visible = false
	game.customer_container.visible = false
	show_result_art_panel()
	if game.forecast_warning_label:
		game.forecast_warning_label.visible = false

	game.result_title_label.text = "Day %d Briefing" % game.market_day
	game.result_body_label.text = "--- TODAY'S MARKET ---\nMarket: %s\nStarting Wallet: %s\nTime Limit: %s\nFood Stock: %d items\nFly Activity: %d flies\n\n--- GOAL ---\nProtect the food, serve customers, and finish the day with profit." % [
		str(game.active_market_event.get("name", "Market")),
		game._format_peso(game.current_money),
		game._format_duration(game.game_timer),
		game._get_target_food_count(),
		game.day_initial_flies,
	]
	game.result_warning_label.visible = false
	game._apply_result_text_fit(game.result_body_label.text, false)
	game.financial_button.visible = false
	game.financial_button.disabled = true
	game.result_start_button.visible = true
	game.result_start_button.disabled = false
	game._play_result_container_entrance()

func show_day_end_summary_screen(completed_market_day: int) -> void:
	game.menu_state = "day_end_summary"
	game.menu_layer.visible = true
	game.hud_layer.visible = false
	show_result_art_panel()
	if game.forecast_warning_label:
		game.forecast_warning_label.visible = false

	game.result_title_label.text = "Day %d Complete" % completed_market_day
	game.result_body_label.text = "--- TODAY'S PERFORMANCE ---\nCustomers Served: %d\nMarket Reputation: %d (%+d)\nFlies Swatted: %d\n\n--- FINANCIALS ---\nGross Sales: +%s\nLeftover Stock Sold: +%s\nFly Bounty: +%s\n(Minus) Stock Costs: -%s\nTotal End of Day Wallet: %s" % [
		game._report_int(game.current_day_report, "customers_served"),
		game._report_int(game.current_day_report, "market_reputation"),
		game._report_int(game.current_day_report, "market_reputation_change"),
		game._report_int(game.current_day_report, "flies_killed"),
		game._format_peso(game._report_int(game.current_day_report, "gross_sales")),
		game._format_peso(game._report_int(game.current_day_report, "leftover_stock_value")),
		game._format_peso(game._report_int(game.current_day_report, "fly_bounty_bonus")),
		game._format_peso(game._report_int(game.current_day_report, "stock_costs")),
		game._format_peso(game._report_int(game.current_day_report, "total_wallet_end_of_day")),
	]
	game.result_warning_label.visible = false
	game._apply_result_text_fit(game.result_body_label.text, false)
	game.financial_button.visible = true
	game.financial_button.disabled = false
	game.result_start_button.visible = false
	game._play_result_container_entrance()
	game.play_button.text = "Next: Financial Forecast"

func show_pre_day_forecast_screen(animate_intro := false) -> void:
	game.menu_state = "pre_day_forecast"
	game.menu_layer.visible = true
	game.hud_layer.visible = false
	show_result_art_panel()

	game.result_title_label.text = "Day %d Forecast" % game.market_day
	game.result_body_label.text = "--- TOMORROW'S FORECAST ---\nCarried Over Wallet: %s\nExpected Restock Cost: -%s\nStarting Capital for Tomorrow: %s" % [
		game._format_peso(game._report_int(game.next_day_forecast, "carried_over_wallet")),
		game._format_peso(game._report_int(game.next_day_forecast, "expected_restock_cost")),
		game._format_peso(game._report_int(game.next_day_forecast, "final_starting_capital")),
	]

	if game.forecast_warning_label:
		game.forecast_warning_label.visible = false
		if bool(game.next_day_forecast.get("is_bankruptcy_state", false)):
			var strike_count := int(game.next_day_forecast.get("bankruptcy_strikes", game.bankruptcy_strikes))
			game.forecast_warning_label.text = "⚠️ WARNING: BANKRUPTCY IMMINENT! (Strike %d of %d)" % [strike_count, GameConfig.MAX_BANKRUPTCY_STRIKES]
			game.forecast_warning_label.add_theme_color_override("font_color", Color(1.0, 0.12, 0.08))
		else:
			game.forecast_warning_label.text = "Finances Stable"
			game.forecast_warning_label.add_theme_color_override("font_color", Color(0.18, 0.72, 0.30))

	game.play_button.text = "Start Day %d" % game.market_day
	if bool(game.next_day_forecast.get("is_bankruptcy_state", false)):
		var strike_count := int(game.next_day_forecast.get("bankruptcy_strikes", game.bankruptcy_strikes))
		game.result_warning_label.text = "WARNING: BANKRUPTCY IMMINENT! (Strike %d of %d)" % [strike_count, GameConfig.MAX_BANKRUPTCY_STRIKES]
	else:
		game.result_warning_label.text = "Finances Stable"
	game.result_warning_label.add_theme_color_override("font_color", GameConfig.RESULT_TEXT_COLOR)
	game.result_warning_label.visible = true
	game._apply_result_text_fit(game.result_body_label.text, true)
	game.financial_button.visible = false
	game.result_start_button.visible = true
	if animate_intro:
		game._animate_result_data_in()

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

func play_pause_overlay_entrance() -> void:
	if game.pause_menu_box == null:
		return
	game.pause_menu_box.scale = Vector2(1.65, 1.65)
	game.pause_quit_button.disabled = true
	game.pause_resume_button.disabled = true
	var entrance_tween := game.create_tween()
	entrance_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	entrance_tween.tween_property(game.pause_menu_box, "scale", Vector2(0.94, 0.94), 0.34).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	entrance_tween.tween_property(game.pause_menu_box, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await entrance_tween.finished
	if game.gameplay_paused:
		game.pause_quit_button.disabled = false
		game.pause_resume_button.disabled = false
