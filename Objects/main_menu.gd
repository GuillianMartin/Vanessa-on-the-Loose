extends Control

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
