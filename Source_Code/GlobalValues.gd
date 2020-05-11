extends Node

# Map variables
export var map_bounds := Vector2(15, 15)
export var obstacle_tile_first : int = 0
export var obstacle_tile_last : int = 3
export var walk_tile_first : int = 4
export var walk_tile_last : int = 8

# Control variables
export var camera_speed : float = 10.0
export var timer_time : float = 60.0
export var timer_time_left : float = 0.0
export var yellow_list_chance : float = 0.25
export var num_aliens_carrying_crystals : int = 0

# Testing variables
export var communicating : bool = true
export var brute_force : bool = false
export var detecting_crystals : bool = true
export var using_map_obstacles : bool = false
export var random_dropoff : bool = true
export var clustering_crystals : bool = false
export var spacing_crystals : bool = true

# Other game variables
export var num_aliens : int = 2
export var num_crystals : int = 20
export var num_dropoffs : int = 1

# Noise generator
var noise := OpenSimplexNoise.new()

export var moves = {'RIGHT' : Vector2(1, 0),
			 'LEFT'  : Vector2(-1, 0),
			 'UP'    : Vector2(0, -1),
			 'DOWN'  : Vector2(0, 1)}

func _ready() -> void:
	randomize()
	noise.seed = randi()
	noise.octaves = 3
	noise.lacunarity = 0.1
	noise.period = 3

# Maps one value in one range to another range
func map(value : float, low1 : float, high1 : float, low2 : float, high2 : float) -> float:
	var denom : float = high1 - low1
	var a : float = (high2 - low2) / denom
	var b : float = (high1 * low2 - high2 * low1) / denom
	return a * value + b

# Remove duplicate entries in a list
func remove_duplicates_from_list(list : Array) -> Array:
	var result = []
	for list_item in list:
		var duplicate : bool = false
		for result_item in result:
			if list_item == result_item:
				duplicate = true
				break
		if duplicate == false:
			result.append(list_item)
	return result

func relative_distance(v1 : Vector2, v2 : Vector2) -> float:
	return ((v2.x - v1.x) * (v2.x - v1.x)) + ((v2.y - v1.y) * (v2.y - v1.y))

func custom_sort_1(a, b):
	if a[1] < b[1]:
		return true
	return false
