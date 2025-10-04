extends CanvasLayer

signal finished_fade_in
signal finished_fade_out


func _ready() -> void:
	$AnimationPlayer.animation_finished.connect(_on_animation_player_animation_finished)


func set_progress(value: float) -> void:
	$Control/ProgressBar.value = value


func reset():
	$AnimationPlayer.play("RESET")


func fade_in():
	show()
	$AnimationPlayer.play("RESET")
	$AnimationPlayer.play("fade_in")


func fade_out():
	$AnimationPlayer.play("RESET")
	$AnimationPlayer.play("fade_out")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"fade_in":
			finished_fade_in.emit()
		"fade_out":
			finished_fade_out.emit()
			hide()


func _process(_delta: float) -> void:
	set_progress(SceneLoader.progress[0] * 100.0)
