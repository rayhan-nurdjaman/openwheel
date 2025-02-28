extends CanvasLayer

@onready var command_line: LineEdit = $Console/VBoxContainer/HBoxContainer/Command
@export var car: Car

func _process(delta):
	$Console/VBoxContainer/CommandHistory.text = "\n".join(Debug.log)
	if Input.is_action_just_pressed("console"):
		$Console.popup()
	$Label.text = "Engine RPM: %s" % snappedi(car.engine_angular_velocity / 0.1047, 100)
	$Label.text = "Engine RPM: %s" % (car.engine_angular_velocity / 0.1047)
	$TextureProgressBar.value = car.engine_angular_velocity
	$TextureProgressBar.min_value = 0.0
	$TextureProgressBar.max_value = car.engine.upper_redline

	$Drawer.force_front_left = car.running_gear.wheel_states[RunningGear.Wheel.FRONT_LEFT][RunningGear.WheelState.FORCE] * car.transform.basis
	$Drawer.force_front_right = car.running_gear.wheel_states[RunningGear.Wheel.FRONT_RIGHT][RunningGear.WheelState.FORCE] * car.transform.basis
	$Drawer.force_rear_left = car.running_gear.wheel_states[RunningGear.Wheel.REAR_LEFT][RunningGear.WheelState.FORCE] * car.transform.basis
	$Drawer.force_rear_right = car.running_gear.wheel_states[RunningGear.Wheel.REAR_RIGHT][RunningGear.WheelState.FORCE] * car.transform.basis

	$Drawer.load_front_left = car.running_gear.wheel_states[RunningGear.Wheel.FRONT_LEFT][RunningGear.WheelState.LOAD].dot(car.transform.basis.y)
	$Drawer.load_front_right = car.running_gear.wheel_states[RunningGear.Wheel.FRONT_RIGHT][RunningGear.WheelState.LOAD].dot(car.transform.basis.y)
	$Drawer.load_rear_left = car.running_gear.wheel_states[RunningGear.Wheel.REAR_LEFT][RunningGear.WheelState.LOAD].dot(car.transform.basis.y)
	$Drawer.load_rear_right = car.running_gear.wheel_states[RunningGear.Wheel.REAR_RIGHT][RunningGear.WheelState.LOAD].dot(car.transform.basis.y)

	$Drawer.car_relative_velocity = car.linear_velocity * car.transform.basis

func _on_command_text_submitted(new_text):
	Debug.parse_command(new_text)
	command_line.text = ""

func _on_submit_pressed():
	Debug.parse_command(command_line.text)
	command_line.text = ""
