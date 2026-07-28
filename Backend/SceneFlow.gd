extends Node

const MAIN_MENU_SCENE := "res://Objects/main_menu.tscn"
const CUTSCENE_SCENE := "res://Objects/cutscene.tscn"
const TUTORIAL_SCENE := "res://Objects/tutorial.tscn"
const MAIN_GAME_SCENE := "res://Objects/Game.tscn"

var tutorial_enabled := false

func go_to_main_menu() -> void:
	_change_scene(MAIN_MENU_SCENE)

func start_new_game_flow() -> void:
	_change_scene(CUTSCENE_SCENE)

func continue_after_cutscene() -> void:
	if tutorial_enabled and ResourceLoader.exists(TUTORIAL_SCENE):
		_change_scene(TUTORIAL_SCENE)
		return
	_change_scene(MAIN_GAME_SCENE)

func continue_after_tutorial() -> void:
	_change_scene(MAIN_GAME_SCENE)

func _change_scene(scene_path: String) -> void:
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Could not change scene to %s. Error code: %d" % [scene_path, error])
