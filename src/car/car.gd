class_name Car

extends RigidBody3D

@export var controller: Controller
@export var running_gear: RunningGear
@export var engine: CarEngine

@export var gear_ratios: Array[float] = [
	-2.00,  # Reverse gear
	2.07,
	1.56,
	1.20,
	0.95,
	0.77,
	0.63
]
@export var final_drive: float = 4.26
@export var clutch_torque_capacity: float = 621.0
var transmission_inertia: float = 0.5
var differential_inertia: float = 0.5

var current_gear: int = 1

var camera_mode: CameraMode = CameraMode.FOLLOW
var camera_rotation: Vector3 = Vector3.ZERO
var follow_camera_start_align: bool = true
var camera_shake: Vector3 = Vector3.ZERO

enum CameraMode{
	FOLLOW,
	BUMPER
}
@onready var camera: Dictionary = {
	CameraMode.FOLLOW : $FollowCameraPivot/FollowCamera,
	CameraMode.BUMPER : $BumperCamera
}

func _ready() -> void:
	$FollowCamera.set_as_top_level(true)
	Debug.current_car = self
	running_gear.update_wheel_properties()
	controller.discrete_callbacks["shift_up"] = func() -> void:
		if current_gear < gear_ratios.size() - 1:
			current_gear += 1
			running_gear.update_wheel_properties()

	controller.discrete_callbacks["shift_down"] = func() -> void:
		if current_gear > 0:
			current_gear -= 1
			running_gear.update_wheel_properties()

func _input(event) -> void:
	if event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_MASK_RIGHT:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			follow_camera_start_align = false
			$FollowCameraReset.start()
			camera_rotation.y += event.relative.x * -0.005
			camera_rotation.x += event.relative.y * -0.005
			camera_rotation.y = wrapf(camera_rotation.y, -PI, PI)
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta) -> void:
	camera_rotation.x = clamp(camera_rotation.x, -PI/2.0, 0)
	if follow_camera_start_align:
		camera_rotation *= pow(32, -delta)
	$FollowCameraPivot.rotation.y = camera_rotation.y
	$FollowCameraPivot.rotation.x = camera_rotation.x
	$FollowCameraPivot/FollowCamera.transform.origin = Vector3.ZERO
	$FollowCameraPivot/FollowCamera.transform.origin.z = 6.0
	$FollowCameraPivot/FollowCamera.transform.origin.y = 2.0 * (1.0 + sin(camera_rotation.x))
	var just_changed_camera: bool = false
	if Input.is_action_just_pressed("camera"):
		just_changed_camera = true
		camera_mode = CameraMode.values()[(int(camera_mode) + 1) % CameraMode.size()]
	if just_changed_camera:
		match camera_mode:
			CameraMode.FOLLOW:
				$BumperCamera.current = false
				$FollowCamera.current = true
			CameraMode.BUMPER:
				$FollowCamera.current = false
				$BumperCamera.current = true
	$FollowCamera.global_transform = $FollowCamera.global_transform.interpolate_with($FollowCameraPivot/FollowCamera.global_transform, delta * 20.0)


var engine_angular_velocity: float = 0.0
var differential_angular_velocity: float = 0.0

func _integrate_forces(state) -> void:
	var driven_wheels = [RunningGear.Wheel.REAR_LEFT, RunningGear.Wheel.REAR_RIGHT]
	# Brake system configuration
	var brake_capacity: float = 1500.0
	var brake_torque = 0.0

	# Update rear wheel angular velocities and calculate brake torque
	for wheel in driven_wheels:
		# Set wheel velocity from differential (note: can be unstable at low speeds)
		running_gear.wheel_states[wheel][RunningGear.WheelState.ANGULAR_VELOCITY] = differential_angular_velocity

		# Calculate brake torque based on wheel speed and brake input
		brake_torque += brake_capacity * controller.control_value[Controller.ControlValue.BRAKE] * \
						clamp(running_gear.wheel_states[wheel][RunningGear.WheelState.ANGULAR_VELOCITY] * state.step * 5.0, -1.0, 1.0)

	# Update suspension physics
	running_gear.simulate_suspensions(state, controller)

	# Calculate drivetrain forces
	var engine_output_torque = engine.get_engine_torque(engine_angular_velocity, controller, state.step)
	var driven_wheel_resistance_torque = brake_torque
	# var free_wheel_resistance_torque = brake_torque
	# var wheel_resistance_torque = brake_torque

	# Calculate total drivetrain inertia and resistance
	var total_drivetrain_inertia = differential_inertia + transmission_inertia * final_drive
	for wheel in RunningGear.Wheel.values():
		if wheel in driven_wheels:
			driven_wheel_resistance_torque += running_gear.wheel_states[wheel][RunningGear.WheelState.TORQUE]
		else:
			var free_wheel_resistance_torque = brake_capacity * controller.control_value[Controller.ControlValue.BRAKE] * \
				clamp(running_gear.wheel_states[wheel][RunningGear.WheelState.ANGULAR_VELOCITY] * state.step * 5.0, -1.0, 1.0)
			running_gear.wheel_states[wheel][RunningGear.WheelState.ANGULAR_VELOCITY] -= free_wheel_resistance_torque / running_gear.wheel_properties[wheel][RunningGear.WheelProperty.INERTIA] * state.step
		total_drivetrain_inertia += running_gear.wheel_properties[wheel][RunningGear.WheelProperty.INERTIA]

	# Clutch simulation parameters and calculations
	var clutch_engagement_rate = 5.0
	var combined_gear_ratio = gear_ratios[current_gear] * final_drive
	var clutch_speed_difference: float = engine_angular_velocity - differential_angular_velocity * combined_gear_ratio
	var clutch_engagement_factor: float = 1.0 - controller.control_value[Controller.ControlValue.CLUTCH]

	# Calculate clutch torque based on engagement and speed difference
	var max_clutch_torque: float = clutch_torque_capacity * clutch_engagement_factor * \
								clamp(abs(clutch_speed_difference) * state.step * clutch_engagement_rate, 0.0, 1.0)
	var max_transferable_torque: float = max(abs(engine_output_torque), abs(driven_wheel_resistance_torque))
	var actual_clutch_torque: float = sign(clutch_speed_difference) * min(max_transferable_torque, max_clutch_torque)

	# Update engine and differential angular velocities
	var engine_acceleration = (engine_output_torque - actual_clutch_torque) / engine.inertia * state.step
	var differential_acceleration = (actual_clutch_torque * combined_gear_ratio - driven_wheel_resistance_torque) / \
								(total_drivetrain_inertia) * state.step

	engine_angular_velocity += engine_acceleration
	differential_angular_velocity += differential_acceleration

	# Apply physical forces to each wheel in contact with ground
	for wheel in RunningGear.Wheel.values():
		if not running_gear.wheel_states[wheel][RunningGear.WheelState.IN_CONTACT]:
			continue

		var wheel_position_offset = state.transform.basis * running_gear.wheel_properties[wheel][RunningGear.WheelProperty.POSITION]

		# Apply suspension load force
		state.apply_force(
			running_gear.wheel_states[wheel][RunningGear.WheelState.LOAD],
			wheel_position_offset
		)

		# Apply ground contact force
		state.apply_force(
			running_gear.wheel_states[wheel][RunningGear.WheelState.FORCE],
			running_gear.wheel_states[wheel][RunningGear.WheelState.CONTACT_POINT]
		)

func _on_follow_camera_reset_timeout():
	follow_camera_start_align = true
