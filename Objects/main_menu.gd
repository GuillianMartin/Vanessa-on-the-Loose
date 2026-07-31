extends Control

const GameConfig = preload("res://Backend/Game/GameConfig.gd")

@onready var button_container = $Buttons
@onready var popup_container = $PopUps

var music_bus = AudioServer.get_bus_index("Music")
var sfx_bus = AudioServer.get_bus_index("SFX")
@onready var music_slider = popup_container.get_node("SettingsPopup/NotebookBG/MarginContainer/VBoxContainer/music_slider")
@onready var sfx_slider = popup_container.get_node("SettingsPopup/NotebookBG/MarginContainer/VBoxContainer/sfx_slider")

func _ready():
	
	# Menu
	for button in button_container.get_children():
		button.mouse_entered.connect(_on_any_button_hovered.bind(button))
		button.mouse_exited.connect(_on_any_button_unhovered.bind(button))
		button.pressed.connect(AudioManager.play_ui_button)
		button.pressed.connect(_on_any_button_pressed.bind(button))		
	
	# Pop Up
	for popup_close in popup_container.get_children():
		var exit_btn = popup_close.get_node_or_null("NotebookBG/ExitButton")
		
		if exit_btn != null:
			exit_btn.mouse_entered.connect(_on_popup_btn_hovered.bind(exit_btn))
			exit_btn.mouse_exited.connect(_on_popup_btn_unhovered.bind(exit_btn))
			exit_btn.pressed.connect(AudioManager.play_ui_button)
			exit_btn.pressed.connect(_on_popup_button_pressed.bind(popup_close))
	
	# Audio Settings
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus))
	
	music_slider.value_changed.connect(_on_music_value_changed)
	sfx_slider.value_changed.connect(_on_sfx_value_changed)
	
	_build_trophy_highscores()

func _build_trophy_highscores() -> void:
	var trophy_popup = popup_container.get_node("TrophyPopup")
	var notebook_bg = trophy_popup.get_node("NotebookBG")

	var scroll := ScrollContainer.new()
	scroll.name = "HighScoreScroll"
	scroll.set_anchors_preset(Control.PRESET_CENTER)
	scroll.offset_left = -360.0
	scroll.offset_top = -120.0
	scroll.offset_right = 360.0
	scroll.offset_bottom = 180.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

	var bg := ColorRect.new()
	bg.color = Color(0.95, 0.9, 0.8, 0.35)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.offset_left = 4.0
	bg.offset_top = 4.0
	bg.offset_right = -4.0
	bg.offset_bottom = -4.0
	scroll.add_child(bg)

	notebook_bg.add_child(scroll)
	notebook_bg.move_child(scroll, 0)

	var list := VBoxContainer.new()
	list.name = "HighScoreList"
	list.alignment = BoxContainer.ALIGNMENT_CENTER
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)

func _refresh_trophy_highscores() -> void:
	var trophy_popup = popup_container.get_node("TrophyPopup")
	var list = trophy_popup.get_node_or_null("NotebookBG/HighScoreScroll/HighScoreList")
	if list == null:
		return

	for child in list.get_children():
		child.queue_free()

	var scores := GameConfig.HIGH_SCORE_MANAGER.get_top_10()

	var title := Label.new()
	title.text = "TOP 10 HIGH SCORES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(420, 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_override("font", GameConfig.JERSEY_FONT)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("#5D371E"))
	list.add_child(title)

	if scores.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No runs yet!"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.custom_minimum_size = Vector2(420, 28)
		empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty_label.add_theme_font_override("font", GameConfig.PIXELIFY_FONT)
		empty_label.add_theme_font_size_override("font_size", 20)
		empty_label.add_theme_color_override("font_color", Color("#5D371E"))
		list.add_child(empty_label)
		return

	for i in range(scores.size()):
		var entry := scores[i]
		var day := int(entry.get("day", 0))
		var date := str(entry.get("date", ""))
		var label := Label.new()
		label.text = "#%d   Day %d   (%s)" % [i + 1, day, date]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(420, 26)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_override("font", GameConfig.PIXELIFY_FONT)
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color("#5D371E"))
		list.add_child(label)

func _on_any_button_hovered(button: Node):
	var sprite = button.get_child(0)
	
	if button.name == "PlayButton":
		sprite.play("play_hover")
	elif button.name == "SettingsButton":
		sprite.play("settings_hover")
	elif button.name == "TrophyButton":
		sprite.play("trophy_hover")
	elif button.name == "AlmanacButton":
		sprite.play("almanac_hover")
	
func _on_any_button_unhovered(button: Node):
	var sprite = button.get_child(0)
	
	if button.name == "PlayButton":
		sprite.play("play_idle")
	elif button.name == "SettingsButton":
		sprite.play("settings_idle")
	elif button.name == "TrophyButton":
		sprite.play("trophy_idle")
	elif button.name == "AlmanacButton":
		sprite.play("almanac_idle")

func _on_any_button_pressed(button: Node):
	var settings_popup = popup_container.get_node("SettingsPopup")
	var almanac_popup = popup_container.get_node("AlmanacPopup")
	var trophy_popup = popup_container.get_node("TrophyPopup")
	
	if button.name == "PlayButton":
		SceneFlow.start_new_game_flow()
	elif button.name == "SettingsButton":
		settings_popup.show()
	elif button.name == "AlmanacButton":
		almanac_popup.show()
	elif button.name == "TrophyButton":
		_refresh_trophy_highscores()
		trophy_popup.show()

# PopUps
func _on_popup_btn_hovered(button: Node):
	var sprite = button.get_child(0)
	if button.name == "ExitButton":
		sprite.play("exit_hover")
		
func _on_popup_btn_unhovered(button: Node):
	var sprite = button.get_child(0)
	if button.name == "ExitButton":
		sprite.play("exit_idle")
		
func _on_popup_button_pressed(popup_close: Node):
	popup_close.hide()
		
# Volume Control
func _on_music_value_changed(value: float):
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(value))
	
func _on_sfx_value_changed(value: float):
	AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(value))
