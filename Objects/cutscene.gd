extends VideoStreamPlayer

var transition_started := false

func _ready():
	finished.connect(_on_video_finished)
	
func  _on_video_finished():
	if transition_started:
		return
	transition_started = true
	set_process_input(false)
	SceneFlow.continue_after_cutscene()
	
func _input(event):
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		_on_video_finished()
