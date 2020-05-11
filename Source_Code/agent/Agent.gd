extends KinematicBody2D

export (int) var animSpeed
export (int) var moveSpeed
export (float) var MASS
export (float) var ARRIVE_DISTANCE

var ID : int = 0 #setget ID_set, ID_get

var state_color : Color = Color.green

var can_move = true
var velocity = Vector2.ZERO
var map = []

var camera : Position2D
var tile_map : TileMap
var line_2d : Line2D

var path := PoolVector2Array() setget set_path
var target_point_world = Vector2()
var current_position : Vector2

func _ready():
	self.can_move = false
#	facing = moves.keys()[randi() %4]
#	yield(get_tree().create_timer(0.5), "timeout")

func init_agent(camera : Position2D, tile_map : TileMap, line_2d : Line2D) -> void:
	self.camera = camera
	self.tile_map = tile_map
	self.line_2d = line_2d

# Set a path's final destination in cell coordinates
func set_destination(path_to_x : int, path_to_y : int) -> int:
	self.line_2d.default_color = self.state_color

	self.can_move = false
	get_tile_path(path_to_x, path_to_y)
	if not path or len(path) == 1:
		print("########## BAD PATH - Agent: ", self.ID)
		Logger.info("########## BAD PATH - Agent: " + str(self.ID))
		print("########## PATH: ", self.global_position, self.path)
		Logger.info("########## PATH: " + str(self.global_position) + " " + str(self.path))
		return 1
	target_point_world = path[1]
	path.remove(0)
	return 0

# Get the path for a character to follow
func get_tile_path(path_to_x : int, path_to_y : int) -> void:

	if Vector2(path_to_x, path_to_y) in self.tile_map.walkable_cells_list: # if the tile destination is movable
		self.path = self.tile_map.find_path(self.current_position, Vector2(path_to_x, path_to_y))
		if not self.path or len(path) == 0: #if not self.path or len(path) <= 1:
			return
		self.line_2d.points = self.path
		self.can_move = true

# Move along pre-determined path
func move_along_path() -> void:
	if not self.can_move:
		return

	if $AnimationPlayer.is_playing() == false:
		$AnimationPlayer.playback_speed = self.animSpeed
		$AnimationPlayer.play("Walk")

#	if can_move and target_point_world != path[0]:
#		target_point_world = path[0]

	var desired_velocity = (target_point_world - position).normalized() * self.moveSpeed
	var steering = desired_velocity - self.velocity
	self.velocity += steering / MASS
	self.global_position += self.velocity * get_process_delta_time()

	if position.distance_to(target_point_world) < ARRIVE_DISTANCE:
		path.remove(0)
		if len(path) == 0:
			self.can_move = false
			return
		target_point_world = path[0]

func set_specific_starting_position(pos : Vector2, used_positions : PoolVector2Array) -> PoolVector2Array:
	var start_pos : Vector2 = pos
	if not pos in used_positions and pos in self.tile_map.walkable_cells_list:
		start_pos = pos
	else:
		start_pos = get_random_cell_position_accounting_used(used_positions, [])
	self.current_position = start_pos
	used_positions.append(start_pos)
	self.global_position.x = (start_pos.x * tile_map.cell_size.x) + (tile_map.cell_size.x / 2)
	self.global_position.y = (start_pos.y * tile_map.cell_size.y) + (tile_map.cell_size.y / 2)
	
	return used_positions

func set_random_starting_position(used_positions : PoolVector2Array, ensure_path_positions : PoolVector2Array) -> PoolVector2Array:
	var start_pos : Vector2 = get_random_cell_position_accounting_used(used_positions, ensure_path_positions)
	self.current_position = start_pos
	used_positions.append(start_pos)
	self.global_position.x = (start_pos.x * tile_map.cell_size.x) + (tile_map.cell_size.x / 2)
	self.global_position.y = (start_pos.y * tile_map.cell_size.y) + (tile_map.cell_size.y / 2)
	
	return used_positions

func get_random_cell_position() -> Vector2:
	var rand_pos : Vector2 = Vector2(int(rand_range(0, GlobalValues.map_bounds.x)), int(rand_range(0, GlobalValues.map_bounds.y)))
	while not rand_pos in self.tile_map.walkable_cells_list:
		rand_pos = Vector2(int(rand_range(0, GlobalValues.map_bounds.x)), int(rand_range(0, GlobalValues.map_bounds.y)))
	return rand_pos

func get_random_cell_position_accounting_used(used_positions : PoolVector2Array, ensure_path_positions : PoolVector2Array) -> Vector2:
	var rand_pos : Vector2 = Vector2(int(rand_range(0, GlobalValues.map_bounds.x)), int(rand_range(0, GlobalValues.map_bounds.y)))
	while not rand_pos in self.tile_map.walkable_cells_list or rand_pos in used_positions or rand_pos in ensure_path_positions:
		rand_pos = Vector2(int(rand_range(0, GlobalValues.map_bounds.x)), int(rand_range(0, GlobalValues.map_bounds.y)))
	if len(ensure_path_positions) > 0:
		for i in range(0, len(ensure_path_positions)):
			var new_path = self.tile_map.find_path(rand_pos, ensure_path_positions[i])
			var path_len : int = len(new_path)
			while path_len <= 1:
				rand_pos = Vector2(int(rand_range(0, GlobalValues.map_bounds.x)), int(rand_range(0, GlobalValues.map_bounds.y)))
				if rand_pos != ensure_path_positions[i]:
					new_path = tile_map.find_path(rand_pos, ensure_path_positions[i])
				path_len = len(new_path)
	return rand_pos
	
# Setter - Path points in Vector2 format
func set_path(value : PoolVector2Array) -> void:
	path = value
	if value.size() == 0:
		return
	set_process(true)

func generate_map() -> void:
	for y in range(GlobalValues.map_bounds.y):
		self.map.append([])
		for x in range(GlobalValues.map_bounds.x):
			self.map[y].append(self.tile_map.get_cell(x, y))
