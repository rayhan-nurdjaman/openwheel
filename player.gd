extends Controller

var input_state: Dictionary = {
	"accelerate": false,
	"brake": false,
	"clutch": false,
	"steer_left": false,
	"steer_right": false,
}
var discrete_callbacks: Dictionary = {
	"shift_up": null,
	"shift_down": null,
}

var steer_speed: float = 2.0
var accelerate_speed: float = 4.0
var brake_speed: float = 4.0
var clutch_speed: float = 4.0

func _unhandled_input(event):
	poll_input(event, "accelerate")
	poll_input(event, "brake")
	poll_input(event, "steer_left")
	poll_input(event, "steer_right")
	poll_input(event, "clutch")
	poll_discrete_input(event, "shift_up", discrete_callbacks["shift_up"])
	poll_discrete_input(event, "shift_down", discrete_callbacks["shift_down"])

func poll_input(event: InputEvent, action: String):
	if event.is_action_pressed(action):
		input_state[action] = true
	elif event.is_action_released(action):
		input_state[action] = false

func poll_discrete_input(event: InputEvent, action: String, callback: Callable):
	if event.is_action_pressed(action):
		if callback != null:
			callback.call()

func _physics_process(delta):
	var target_steer: float = (
		float(input_state["steer_right"]) -
		float(input_state["steer_left"])
	)
	control_value[ControlValue.STEER] = move_toward(
		control_value[ControlValue.STEER],
		target_steer,
		steer_speed * delta
	)

	var target_accelerate: float = bool(input_state["accelerate"])
	control_value[ControlValue.ACCELERATE] = move_toward(
		control_value[ControlValue.ACCELERATE],
		target_accelerate,
		accelerate_speed * delta
	)

	var target_brake: float = bool(input_state["brake"])
	control_value[ControlValue.BRAKE] = move_toward(
		control_value[ControlValue.BRAKE],
		target_brake,
		brake_speed * delta
	)

	var target_clutch: float = bool(input_state["clutch"])
	control_value[ControlValue.CLUTCH] = move_toward(
		control_value[ControlValue.CLUTCH],
		target_clutch,
		clutch_speed * delta
	)
