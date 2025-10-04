extends Node

signal request_transition(no_fade_in)
signal level_loaded(level_name)
signal level_unloaded(level_name)

#const PLAYER_PACKED_SCENE: PackedScene = preload("res://src/player/player.tscn")
const MAIN_MENU_ID = "main_menu"
const LEVEL_PATHS: Dictionary = {
	"test": "res://src/levels/test.tscn",
	MAIN_MENU_ID: "res://src/ui/main_menu/main_menu.tscn",
}

# For later to show intro like CS2
var is_first_main_menu_load: bool = true

# Set by Game (root node)
var main_node: Node = null

var current_scene: Node = null
var progress: Array = [0.0]
var loading_scene_id: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)


func load_scene(level_name: String, no_fade_in: bool = false) -> void:
	# Load and setup new level
	if not loading_scene_id.is_empty():  # LevelManager currently loading level
		return
	if not LEVEL_PATHS.has(level_name):  # ID not found
		push_error("LevelManager: Invalid level name: " + level_name)
		return

	loading_scene_id = level_name

	progress = [0.0]
	# Hey, I need to load the level, set the state to loading
	#GameState.change_state_to(GameState.State.LOADING)
	# If it's the first time I'm loading main menu though, set it to intro
	# And don't let anything happen
	# I'll wait for the screen to fade first before loading
	request_transition.emit(no_fade_in)
	if no_fade_in:
		_on_finished_fade_in()


func _on_finished_fade_in() -> void:
	print("Finished fade in")
	# OK, I'm now allowed to start loading resources
	# Unload current level if it exists
	if current_scene:
		#GameState.player = null
		current_scene.queue_free()
		emit_signal("level_unloaded", current_scene.name)

	# Make loading thread
	var err = ResourceLoader.load_threaded_request(LEVEL_PATHS[loading_scene_id])

	if err != OK:
		push_error("Threaded loading failed with error: " + str(err))
		return

	# Start checking continuously
	set_process(true)


func _process(_delta: float) -> void:
	var status = ResourceLoader.load_threaded_get_status(LEVEL_PATHS[loading_scene_id], progress)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		_setup_scene()
		set_process(false)
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		push_error("Threaded loading FAILED.")
		set_process(false)


func _setup_scene() -> void:
	var level_scene = ResourceLoader.load_threaded_get(LEVEL_PATHS[loading_scene_id])
	current_scene = level_scene.instantiate()
	main_node.add_child(current_scene)

	# Can accomodate gamemodes for future projects
	if loading_scene_id == MAIN_MENU_ID:
		_setup_main_menu()
	else:
		_setup_level()
	loading_scene_id = ""

	emit_signal("level_loaded", current_scene.name)


func _setup_level():
	pass
	# Spawn player at designated spawn point
	#var spawn_point = current_scene.get_node_or_null("SpawnPoint")
	#if not spawn_point:
		#push_error('No "SpawnPoint" marker node found in level.')
		#return

	#var player_node = PLAYER_PACKED_SCENE.instantiate()
	#GameState.player = player_node

	#player_node.transform = spawn_point.transform
	#current_scene.add_child(player_node)
	# Hey GameState, I finished loading, please start transition to IN_GAME
	#GameState.change_state_to(GameState.State.IN_GAME)


func _setup_main_menu():
	var camera_marker: Marker3D = current_scene.get_node_or_null("CameraMarker")
	if not camera_marker:
		push_error('No "CameraMarker" marker node found in level.')
		return

	var camera = Camera3D.new()
	camera.fov = 90.0

	camera.transform = camera_marker.transform
	current_scene.add_child(camera)
	# Hey GameState, I finished loading, please start transition to MAIN_MENU
	#GameState.change_state_to(GameState.State.MAIN_MENU)
