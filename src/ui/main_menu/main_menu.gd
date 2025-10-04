extends CanvasLayer


func _ready() -> void:
	$MarginContainer/VBoxContainer/Start.pressed.connect(_on_start_pressed)
	$MarginContainer/VBoxContainer/Exit.pressed.connect(_on_start_pressed)


func _on_start_pressed():
	print("Start")
	SceneLoader.load_scene("test")


func _on_exit_pressed():
	pass
