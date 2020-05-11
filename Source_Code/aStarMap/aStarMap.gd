#NOTE: a substantial portion of the A-Star code was adapted from code provided by
#GDQuest, which was published under the MIT licence, and is available here:
#
#https://github.com/GDQuest/godot-demos/tree/master/2018/03-30-astar-pathfinding
#
#**MIT License**
#
#Copyright (c) 2017 Nathan Lovato
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

extends TileMap

signal startGeneratingMap
signal doneGeneratingMap

onready var astar_node = AStar.new()
onready var _half_cell_size = cell_size / 2

# The path start and end variables
var path_start_position = Vector2() setget _set_path_start_position
var path_end_position = Vector2() setget _set_path_end_position

var _point_path = []
var obstacles = []
var walkable_cells_list = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func init() -> void:
	emit_signal("startGeneratingMap")
	generateMap()
	emit_signal("doneGeneratingMap")
	set_a_star_cells()

func set_a_star_cells() -> void:
	obstacles.clear()
	for i in range(GlobalValues.obstacle_tile_first, GlobalValues.obstacle_tile_last + 1):
		obstacles += get_used_cells_by_id(i)
	
	walkable_cells_list = astar_add_walkable_cells(obstacles)
	astar_connect_walkable_cells(walkable_cells_list)

func generateMap() -> void:
	_generateMapEdges()
	if GlobalValues.using_map_obstacles:
		_generateMapCenter()
	else:
		_generateEmptyMap()

func _generateMapEdges() -> void:
	var val : float = 0.0
	# Top and bottom edges - Wall
	for x in range(0, GlobalValues.map_bounds.x):
		val = GlobalValues.map(GlobalValues.noise.get_noise_2d(x, 0), -1, 1, 0, 1)
		if val < 0.4:#x % 2 == 0:
			self.set_cell(x, 0, 0)
		else:
			self.set_cell(x, 0, 1)
	for x in range(0, GlobalValues.map_bounds.x):
		val = GlobalValues.map(GlobalValues.noise.get_noise_2d(x, GlobalValues.map_bounds.y - 1), -1, 1, 0, 1)
		if val < 0.4:#x % 2 == 0:
			self.set_cell(x, int(GlobalValues.map_bounds.y) - 1, 0)
		else:
			self.set_cell(x, int(GlobalValues.map_bounds.y) - 1, 1)

	# Left and right edges - Wall
	for y in range(0, int(GlobalValues.map_bounds.y)-1):
		val = GlobalValues.map(GlobalValues.noise.get_noise_2d(0, y), -1, 1, 0, 1)
		if val < 0.4:#y % 2 == 0:
			self.set_cell(0, y, 3)
		else:
			self.set_cell(0, y, 2)
	for y in range(0, GlobalValues.map_bounds.y-1):
		val = GlobalValues.map(GlobalValues.noise.get_noise_2d(GlobalValues.map_bounds.x - 1, y), -1, 1, 0, 1)
		if val < 0.4:#y % 2 == 0:
			self.set_cell(int(GlobalValues.map_bounds.x) - 1, y, 2)
		else:
			self.set_cell(int(GlobalValues.map_bounds.x) - 1, y, 3)

	# Top and bottom inside edges - Floor
	for y in [1, GlobalValues.map_bounds.y - 2]:
		for x in range(1, GlobalValues.map_bounds.x - 1): 
			self.set_cell(x, y, int(rand_range(GlobalValues.walk_tile_first+1, GlobalValues.walk_tile_last+1)))

	# Left and right inside edges - Floor
	for y in range(1, GlobalValues.map_bounds.y - 1):
		for x in [1, GlobalValues.map_bounds.x - 2]:
			self.set_cell(x, y, int(rand_range(GlobalValues.walk_tile_first+1, GlobalValues.walk_tile_last+1)))

func _generateEmptyMap() -> void:
	# Make floor empty
	for y in range(2, GlobalValues.map_bounds.y - 2):
		for x in range(2, GlobalValues.map_bounds.x - 2):
			self.set_cell(x, y, int(rand_range(GlobalValues.walk_tile_first+1, GlobalValues.walk_tile_last+1)))

func _generateMapCenter() -> void:
	var val : float = 0.0
	# set obstacle tiles
	for y in range(2, GlobalValues.map_bounds.y-2):
		for x in range(2, GlobalValues.map_bounds.x-2):
			val = GlobalValues.map(GlobalValues.noise.get_noise_2d(x, y), -1, 1, 0, 1)
			if val < 0.417:
				self.set_cell(x, y, 0)
			else:
				self.set_cell(x, y, int(rand_range(GlobalValues.walk_tile_first+1, GlobalValues.walk_tile_last+1)))
	# fix up 'edge' tiles
	for y in range(2, GlobalValues.map_bounds.y-2):
		for x in range(2, GlobalValues.map_bounds.x-2):
			if self.get_cell(x, y) <= GlobalValues.obstacle_tile_last and self.get_cell(x, y+1) >= GlobalValues.walk_tile_first:
				val = GlobalValues.map(GlobalValues.noise.get_noise_2d(x, y), -1, 1, 0, 1)
				if val < 0.3:
					self.set_cell(x, y, 0)
				else:
					self.set_cell(x, y, 1)
			elif self.get_cell(x, y) <= GlobalValues.obstacle_tile_last and self.get_cell(x, y+1) <= GlobalValues.obstacle_tile_last:
				val = GlobalValues.map(GlobalValues.noise.get_noise_2d(x, y), -1, 1, 0, 1)
				if val < 0.45:
					self.set_cell(x, y, 2)
				else:
					self.set_cell(x, y, 3)

# Loop through all cells within the map's bounds and add all points to the astar_node, except the obstacles
func astar_add_walkable_cells(obstacles = []):
	var points_array = []
	for y in range(GlobalValues.map_bounds.y):
		for x in range(GlobalValues.map_bounds.x):
			var point = Vector2(x, y)
			if point in obstacles:
				continue

			points_array.append(point)
			var point_index = calculate_point_index(point)
			astar_node.add_point(point_index, Vector3(point.x, point.y, 0.0))
	return points_array

func astar_connect_walkable_cells(points_array):
	for point in points_array:
		var point_index = calculate_point_index(point)
		# If a surrpounding point is in the map and not an obstalce connect the current point with it
		var points_relative = PoolVector2Array([
			Vector2(point.x, point.y - 1),     # up
			Vector2(point.x + 1, point.y - 1), # up-right
			Vector2(point.x + 1, point.y),     # right
			Vector2(point.x + 1, point.y + 1), # down-right
			Vector2(point.x, point.y + 1),     # down
			Vector2(point.x - 1, point.y + 1), # down-left
			Vector2(point.x - 1, point.y),     # left
			Vector2(point.x - 1, point.y - 1)  # left-up
			])
		for i in range(0, len(points_relative)):
			var point_relative_index = calculate_point_index(points_relative[i])
			
			# Ensure the point itself is valid
			if is_outside_map_bounds(points_relative[i]):
				continue
			if not astar_node.has_point(point_relative_index):
				continue
			
			# Handle diagonals
			if i % 2 == 1:
				var point_relative_index1 = calculate_point_index(points_relative[(i-1)%len(points_relative)])
				var point_relative_index2 = calculate_point_index(points_relative[(i+1)%len(points_relative)])
				if is_outside_map_bounds(points_relative[(i-1)%len(points_relative)]) or is_outside_map_bounds(points_relative[(i+1)%len(points_relative)]):
					continue
				if not astar_node.has_point(point_relative_index1) or not astar_node.has_point(point_relative_index2):
					continue
			# Connect the points
			astar_node.connect_points(point_index, point_relative_index, false)

# Primary path finding function
func find_path(start, end):
	self.path_start_position = start
	self.path_end_position = end
	_recalculate_path()
	var path_world = []
	for point in _point_path:
		var point_world = map_to_world(Vector2(point.x, point.y)) + _half_cell_size
		path_world.append(point_world)
	return path_world

func _recalculate_path():
	#clear_previous_path_drawing()
	var start_point_index = calculate_point_index(path_start_position)
	var end_point_index = calculate_point_index(path_end_position)
	# This method gives us an array of points. Note you need the start and end points' indices as input
	_point_path = astar_node.get_point_path(start_point_index, end_point_index)
	# Update drawing
	update()

# Calculate how many tiles go in each dimension of the map
func calculate_map_bounds_in_tiles(tilemap : TileMap) -> Vector2:
	var used_cells = tilemap.get_used_cells()
	var max_x : float = 0.0
	var max_y : float = 0.0
	
	for pos in used_cells:
		if pos.x > max_x:
			max_x = int(pos.x)
		if pos.y > max_y:
			max_y = int(pos.y)
	return Vector2(max_x + 1, max_y + 1)

# Calculate where in the map an object is based on its pixel coordinates
func get_map_loc_from_pos(pos_x : float, pos_y : float) -> Vector2:
	return Vector2(floor(pos_x / self.cell_size.x), floor(pos_y / self.cell_size.y))

func is_outside_map_bounds(point : Vector2) -> bool:
	return point.x < 0 or point.y < 0 or point.x >= GlobalValues.map_bounds.x or point.y >= GlobalValues.map_bounds.y

func calculate_point_index(point : Vector2) -> int:
	return int(point.x + GlobalValues.map_bounds.x * point.y)

# Setters for the start and end path values.
func _set_path_start_position(value):
	if value in obstacles:
		return
	if is_outside_map_bounds(value):
		return
	path_start_position = value
	if path_end_position and path_end_position != path_start_position:
		_recalculate_path()

func _set_path_end_position(value):
	if value in obstacles:
		return
	if is_outside_map_bounds(value):
		return
	path_end_position = value
	if path_start_position != value:
		_recalculate_path()

func clear_previous_path_drawing():
	if not _point_path:
		return
	var point_start = _point_path[0]
	var point_end = _point_path[len(_point_path) - 1]
	set_cell(point_start.x, point_start.y, -1)
	set_cell(point_end.x, point_end.y, -1)
