extends Node

signal state_changed(old_state, new_state)

enum State {MAIN_MENU, LOADING, IN_GAME, PAUSED }

var state: State = State.LOADING

var gui: Node = null
var player: Node = null:
	set(value):
		player = value
		gui.player = player

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func change_state_to(new_state: State):
	var old_state: State = state
	_on_state_exit(state)
	state = new_state
	_on_state_enter(state)
	state_changed.emit(old_state, new_state)
	print_debug(State.keys()[state])


# TODO: This is a bit redundant with GUI.gd
func _on_state_exit(_state: State):
	match _state:
		State.MAIN_MENU:
			pass
		State.LOADING:
			pass
		State.IN_GAME:
			pass
		State.PAUSED:
			get_tree().paused = false
			Engine.time_scale = 1.0


func _on_state_enter(_state: State):
	match _state:
		State.MAIN_MENU:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		State.LOADING:
			pass
		State.IN_GAME:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		State.PAUSED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Engine.time_scale = 0.0
			get_tree().paused = true
