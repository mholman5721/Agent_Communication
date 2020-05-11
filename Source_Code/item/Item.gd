extends Area2D

var camera : Position2D
var tile_map : TileMap

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func init(camera : Position2D, tile_map : TileMap) -> void:
	self.camera = camera
	self.tile_map = tile_map
	$Sprite.frame = int(rand_range(0, $Sprite.hframes))

func set_specific_starting_position(pos : Vector2, used_positions : PoolVector2Array) -> PoolVector2Array:
	var start_pos : Vector2 = pos
	if not pos in used_positions and start_pos in self.tile_map.walkable_cells_list:
		start_pos = pos
	else:
		start_pos = get_random_cell_position_accounting_used(used_positions, [])
	used_positions.append(start_pos)
	self.global_position.x = (start_pos.x * tile_map.cell_size.x) + (tile_map.cell_size.x / 2)
	self.global_position.y = (start_pos.y * tile_map.cell_size.y) + (tile_map.cell_size.y / 2)

	return used_positions
	
func set_random_starting_position(used_positions : PoolVector2Array, ensure_path_positions : PoolVector2Array) -> PoolVector2Array:
	var start_pos : Vector2 = get_random_cell_position_accounting_used(used_positions, ensure_path_positions)
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
