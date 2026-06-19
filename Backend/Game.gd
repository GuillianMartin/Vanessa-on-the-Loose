extends Node2D

const FLY_SCENE := preload("res://Objects/Fly.tscn")
const ROUND_FLY_COUNT := 8
const TOP_SAFE_AREA := 72.0
const EDGE_PADDING := 70.0

var score := 0
var flies_left := 0
var round_active := false

var fly_container: Node2D
var hud_layer: CanvasLayer
var menu_layer: CanvasLayer
var score_label: Label
var flies_label: Label
var menu_title: Label
var result_label: Label
var play_button: Button

func _ready() -> void:
	randomize()
	_build_game_nodes()
	_build_hud()
	_build_menu()
	_show_menu()

func _build_game_nodes() -> void:
	fly_container = Node2D.new()
	fly_container.name = "Flies"
	add_child(fly_container)

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
	score_label.custom_minimum_size = Vector2(160, 0)
	row.add_child(score_label)

	flies_label = Label.new()
	flies_label.text = "Flies: 0"
	row.add_child(flies_label)

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

func _show_menu(final_score: int = -1) -> void:
	round_active = false
	menu_layer.visible = true
	hud_layer.visible = false
	fly_container.visible = false
	_clear_flies()

	if final_score >= 0:
		menu_title.text = "Round Complete"
		result_label.text = "Flies killed: %d" % final_score
		play_button.text = "Start Over"
	else:
		menu_title.text = "Bangaw"
		result_label.text = ""
		play_button.text = "Play"

func _start_round() -> void:
	score = 0
	flies_left = ROUND_FLY_COUNT
	round_active = true
	menu_layer.visible = false
	hud_layer.visible = true
	fly_container.visible = true
	_update_hud()
	_spawn_flies()

func _spawn_flies() -> void:
	_clear_flies()

	var viewport_size := get_viewport_rect().size
	var bounds := Rect2(
		Vector2(EDGE_PADDING, TOP_SAFE_AREA + EDGE_PADDING),
		Vector2(
			max(viewport_size.x - EDGE_PADDING * 2.0, 1.0),
			max(viewport_size.y - TOP_SAFE_AREA - EDGE_PADDING * 2.0, 1.0)
		)
	)

	for _index in range(ROUND_FLY_COUNT):
		var fly = FLY_SCENE.instantiate()
		fly.position = Vector2(
			randf_range(bounds.position.x, bounds.end.x),
			randf_range(bounds.position.y, bounds.end.y)
		)
		fly.configure(fly.get_random_behavior(), bounds)
		fly.died.connect(_on_fly_died)
		fly_container.add_child(fly)

func _clear_flies() -> void:
	if fly_container == null:
		return

	for child in fly_container.get_children():
		child.queue_free()

func _on_fly_died(_fly: Area2D) -> void:
	if not round_active:
		return

	score += 1
	flies_left -= 1
	_update_hud()

	if flies_left <= 0:
		_show_menu(score)

func _update_hud() -> void:
	score_label.text = "Score: %d" % score
	flies_label.text = "Flies: %d" % flies_left
