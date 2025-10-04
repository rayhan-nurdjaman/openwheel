extends Marker3D


# Properties
var spring_stiffness: float
var shock_damping: float
var ride_height: float
var effective_radius: float
var max_steer_angle: float
var steer_bias: float
var inertia: float
var driven: bool


# States
var angular_velocity: float = 0.0
var load: Vector3 = Vector3.ZERO
var force: Vector3 = Vector3.ZERO
var is_in_contact: bool = false
var contact_point: Vector3 = Vector3.ZERO
var torque: float = 0.0
var is_slipping: bool = false
