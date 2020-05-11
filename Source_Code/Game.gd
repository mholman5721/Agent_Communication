extends Node

var alien_resource = preload("res://alien/Alien.tscn")
var crystal_resource = preload("res://crystal/Crystal.tscn")
var dropoff_resource = preload("res://dropoff/DropOffPoint.tscn")

signal game_started
signal game_ended

onready var tile_map : TileMap = $aStarMap
onready var camera : Position2D = $CameraController
onready var timer : Timer = $Timer

var aliens = []
var alien_positions := PoolVector2Array()
var lines = []

var crystals = []
var crystal_positions := PoolVector2Array()

var dropoffs = []
var dropoff_positions := PoolVector2Array()

var surrounding_dropoff_positions := PoolVector2Array()

var argc : int = 0
var argv := PoolStringArray()

var num_crystals_remaining : int = 0
var time_elapsed : float = 0.0
var non_productive_time_elapsed : float = 0.0

var quitting : bool = false

func _ready():
	argv = OS.get_cmdline_args()
	argc = len(argv)
	if argc != 12 and argc != 0: # Exit if the number of arguments is anything other than zero or six.
		print("## ERROR: Expected 12 command line arguments - ex: 'godot --path . 15 15 2 20 60 true false false false false false true', or 0 command line arguments")
		get_tree().quit()
	elif argc == 12: # If the number of arguments is six, set values to those arguments. Otherwise use the defaults.
		GlobalValues.map_bounds.x = int(argv[0])
		GlobalValues.map_bounds.y = int(argv[1])
		GlobalValues.num_aliens = int(argv[2])
		GlobalValues.num_crystals = int(argv[3])
		GlobalValues.timer_time = float(argv[4])
		if str(argv[5]) == "true":
			GlobalValues.communicating = true
		else:
			GlobalValues.communicating = false

		if str(argv[6]) == "true":
			GlobalValues.brute_force = true
		else:
			GlobalValues.brute_force = false

		if str(argv[7]) == "true":
			GlobalValues.detecting_crystals = true
		else:
			GlobalValues.detecting_crystals = false

		if str(argv[8]) == "true":
			GlobalValues.using_map_obstacles = true
		else:
			GlobalValues.using_map_obstacles = false

		if str(argv[9]) == "true":
			GlobalValues.random_dropoff = true
		else:
			GlobalValues.random_dropoff = false

		if str(argv[10]) == "true":
			GlobalValues.clustering_crystals = true
		else:
			GlobalValues.clustering_crystals = false

		if str(argv[11]) == "true":
			GlobalValues.spacing_crystals = true
		else:
			GlobalValues.spacing_crystals = false

	tile_map.init()
	yield(get_tree().create_timer(.5), "timeout")
	# Place the dropoffs
	for i in range(0, GlobalValues.num_dropoffs):
		dropoffs.append(dropoff_resource.instance())
		self.add_child(dropoffs[i])
		dropoffs[i].init(camera, tile_map)
		if GlobalValues.random_dropoff:
			dropoff_positions = dropoffs[i].set_random_starting_position(dropoff_positions, [])
		else:
			dropoff_positions = dropoffs[i].set_specific_starting_position(Vector2(floor(GlobalValues.map_bounds.x / 2)+i, floor(GlobalValues.map_bounds.y / 2)+i), dropoff_positions)
		# Ensure that there are clear approaches to the dropoff point from all sides
		var current_drop_pos : Vector2 = dropoff_positions[i]
		for j in range(1, int(current_drop_pos.x)):
			tile_map.set_cell(j, int(current_drop_pos.y), int(rand_range(GlobalValues.walk_tile_first+1, GlobalValues.walk_tile_last+1)))
		for j in range(int(current_drop_pos.x), int(GlobalValues.map_bounds.x) - 1):
			tile_map.set_cell(j, int(current_drop_pos.y), int(rand_range(GlobalValues.walk_tile_first+1, GlobalValues.walk_tile_last+1)))
		for j in range(1, int(current_drop_pos.y)):
			tile_map.set_cell(int(current_drop_pos.x), j, int(rand_range(GlobalValues.walk_tile_first+1, GlobalValues.walk_tile_last+1)))
		for j in range(int(current_drop_pos.y), int(GlobalValues.map_bounds.y) - 1):
			tile_map.set_cell(int(current_drop_pos.x), j, int(rand_range(GlobalValues.walk_tile_first+1, GlobalValues.walk_tile_last+1)))
		tile_map.set_a_star_cells()
		# Ensure crystals are not placed near dropoffs
		for j in range(-1, 2):
			for k in range(-1, 2):
				var new_point : Vector2 = Vector2(current_drop_pos.x + k, current_drop_pos.y + j)
				if not tile_map.is_outside_map_bounds(new_point) and not (j == 0 and k == 0):
					surrounding_dropoff_positions.append(new_point)
#
#	# Place the crystals
	crystal_positions += dropoff_positions
	crystal_positions += surrounding_dropoff_positions
	var j : int = 0
	var counter : int = 0
	var crystal_cluster_size : float = floor(GlobalValues.num_crystals / 4.0)
	var rand_cluster_start = Vector2(int(rand_range(1, GlobalValues.map_bounds.x - crystal_cluster_size)), int(rand_range(1, GlobalValues.map_bounds.y - crystal_cluster_size)))
	for i in range(0, GlobalValues.num_crystals):
		crystals.append(crystal_resource.instance())
		self.add_child(crystals[i])
		crystals[i].init(camera, tile_map)

		if GlobalValues.clustering_crystals:
			crystal_positions = crystals[i].set_specific_starting_position(Vector2(rand_cluster_start.x + (i % 4), rand_cluster_start.y + j), crystal_positions)
			counter += 1
			if counter > int(floor(GlobalValues.num_crystals / 4.0)):
				counter = 0
				j += 1
		elif GlobalValues.spacing_crystals:
			crystal_positions = crystals[i].set_specific_starting_position(Vector2(((i*2) % int(GlobalValues.map_bounds.x-1)) + 1, 1 + (j*2)), crystal_positions)
			counter += 1
			if counter > int(floor((GlobalValues.map_bounds.x - 3) / 2.0)):
				counter = 0
				j += 1
		else:
			crystal_positions = crystals[i].set_random_starting_position(crystal_positions, dropoff_positions)

	# Place the aliens
	alien_positions += crystal_positions
	for i in range(0, GlobalValues.num_aliens):
		aliens.append(alien_resource.instance())
		lines.append(Line2D.new())
		self.add_child(aliens[i])
		self.add_child(lines[i])
		lines[i].default_color = Color(randf(), randf(), randf(), 1.0)
		aliens[i].init_alien(i, camera, tile_map, lines[i], dropoff_positions)
		if GlobalValues.random_dropoff:
			alien_positions = aliens[i].set_random_starting_position(alien_positions, crystal_positions)
		else:
			alien_positions = aliens[i].set_specific_starting_position(dropoff_positions[0], [])
			#alien_positions = aliens[i].set_specific_starting_position(Vector2(floor(GlobalValues.map_bounds.x / 2), floor(GlobalValues.map_bounds.y / 2)), [])
		aliens[i].connect("crystal_collected", self, "_on_crystal_collected")
		aliens[i].connect("crystal_dropped_off", self, "_on_crystal_dropped_off")

	num_crystals_remaining = GlobalValues.num_crystals
	timer.set_wait_time(GlobalValues.timer_time)
	timer.set_one_shot(true)
	timer.start()
	emit_signal("game_started")

# Move the character where the player clicks
func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton and not event is InputEventKey:
		return

	if event is InputEventKey:
		if event.is_action_pressed("UP"):
			camera.velocity += GlobalValues.moves["UP"] * GlobalValues.camera_speed
		if event.is_action_pressed("DOWN"):
			camera.velocity += GlobalValues.moves["DOWN"] * GlobalValues.camera_speed
		if event.is_action_pressed("LEFT"):
			camera.velocity += GlobalValues.moves["LEFT"] * GlobalValues.camera_speed
		if event.is_action_pressed("RIGHT"):
			camera.velocity += GlobalValues.moves["RIGHT"] * GlobalValues.camera_speed
		if event.is_action_released("UP"):
			camera.velocity.y = 0
		if event.is_action_released("DOWN"):
			camera.velocity.y = 0
		if event.is_action_released("LEFT"):
			camera.velocity.x = 0
		if event.is_action_released("RIGHT"):
			camera.velocity.x = 0

	if event is InputEventMouseButton and event.is_action_pressed("MOUSE_LEFT"):
		for i in range(0, GlobalValues.num_aliens):
			var new_pos : Vector2 = tile_map.get_map_loc_from_pos(camera.get_global_mouse_position().x, camera.get_global_mouse_position().y)
			aliens[i].can_move = false
			aliens[i].current_state = 1
			aliens[i].set_destination(new_pos.x, new_pos.y)
			aliens[i].current_destination = new_pos

func _process(delta: float) -> void:
	camera.position += camera.velocity
	if num_crystals_remaining > 0:
		time_elapsed += delta
	if GlobalValues.num_aliens_carrying_crystals == 0 and timer.time_left > 0.0:
		non_productive_time_elapsed += delta

func _on_crystal_collected() -> void:
	GlobalValues.num_aliens_carrying_crystals += 1

func _on_crystal_dropped_off() -> void:
	num_crystals_remaining -= 1
	print("CRYSTAL COLLECTED")
	Logger.info("CRYSTAL COLLECTED")

	GlobalValues.num_aliens_carrying_crystals -= 1
	if GlobalValues.num_aliens_carrying_crystals < 0:
		GlobalValues.num_aliens_carrying_crystals = 0

	if num_crystals_remaining <= 0:
		_end_experiment()

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		_end_experiment()

func _on_Timer_timeout() -> void:
	_end_experiment()

func _end_experiment() -> void:
	timer.set_paused(true)
	print("Experiment ended at: ", (GlobalValues.timer_time - timer.time_left), " seconds")
	Logger.info("Experiment ended at: " + str(GlobalValues.timer_time - timer.time_left) + " seconds")
	print("Total time spent NOT carrying crystals was: ", non_productive_time_elapsed, " seconds")
	Logger.info("Total time spent NOT carrying crystals was: " + str(non_productive_time_elapsed) + " seconds")
	print("There were: ", str(GlobalValues.num_crystals - num_crystals_remaining), " / ", str(GlobalValues.num_crystals), " crystals collected")
	Logger.info("There were: " + str(GlobalValues.num_crystals - num_crystals_remaining) + " / " + str(GlobalValues.num_crystals) + " crystals collected")
	print(OS.get_user_data_dir())
	emit_signal("game_ended")
	yield(get_tree().create_timer(0.5),"timeout")
	get_tree().quit()
