extends Node


func _ready() -> void:
	SceneLoader.main_node = self
	
	SceneLoader.request_transition.connect(_on_request_transition)
	SceneLoader.level_loaded.connect(_on_level_loaded)

	$LoadingScreen.finished_fade_in.connect(SceneLoader._on_finished_fade_in)
	#$LoadingScreen.finished_fade_out.connect(_on_loading_screen_finished_fade_out)

	SceneLoader.load_scene("main_menu", true)


func _on_request_transition(no_fade_in):
	if no_fade_in:
		$LoadingScreen.reset()
	else:
		$LoadingScreen.fade_in()


func _on_level_loaded(_level_name: String):
	$LoadingScreen.fade_out()


#func _on_loading_screen_finished_fade_out():
	#$LoadingScreen.hide()
