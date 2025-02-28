extends AudioStreamPlayer3D

@onready var sample_hz = stream.mix_rate
@onready var playback = get_stream_playback()
var pulse_hz = 50.0 # The frequency of the sound wave.
var phase: float = 0.0
@export var wave_shape: Curve

func _process(delta):
	pulse_hz += delta * 10.0
	var step: float = get_parent().engine_angular_velocity / (2.0*PI) / 4.0 * 6.0 / sample_hz
	var frames_available = playback.get_frames_available()

	for i in range(frames_available):
		var displacement: float = 2.0 * wave_shape.sample(phase) - 1.0
		displacement += randf_range(-0.01, 0.01)
		playback.push_frame(Vector2.ONE * displacement)
		phase = fmod(phase + step, 1.0)
