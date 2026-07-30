extends Node

const UI_BUTTON_SFX_PATH := "res://assets/Sound Effects/sound_fx/ui_button.mp3"
const BOOK_FLIP_SFX_PATH := "res://assets/Sound Effects/sound_fx/book_flip.mp3"

var ui_button := UI_BUTTON_SFX_PATH
var book_flip := BOOK_FLIP_SFX_PATH
var _stream_cache := {}

func play_ui_button() -> void:
	play_sfx_path(ui_button)

func play_book_flip() -> void:
	play_sfx_path(book_flip)

func play_sfx_path(path: String) -> void:
	play_sfx(_get_mp3_stream(path))

func play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "SFX"
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _get_mp3_stream(path: String) -> AudioStreamMP3:
	if _stream_cache.has(path):
		return _stream_cache[path]
	if not FileAccess.file_exists(path):
		push_warning("SFX file not found: %s" % path)
		return null

	var data := FileAccess.get_file_as_bytes(path)
	if data.is_empty():
		push_warning("SFX file is empty: %s" % path)
		return null

	var stream := AudioStreamMP3.new()
	stream.data = data
	_stream_cache[path] = stream
	return stream
