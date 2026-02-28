extends Node

## Manages game state, level progression, and scoring.

signal level_started(level: int)
signal level_completed(level: int)
signal game_over

var current_level: int = 1
var grid_size: Vector2i = Vector2i(8, 10)
var cell_size: float = 2.0

# Level definitions: target_type, target_hp
var level_data: Array[Dictionary] = [
	{"target_type": "wall", "target_hp": 100, "time_limit": 60.0},
	{"target_type": "wall", "target_hp": 250, "time_limit": 60.0},
	{"target_type": "monster", "target_hp": 500, "time_limit": 60.0},
]

func get_level_config() -> Dictionary:
	var idx = clampi(current_level - 1, 0, level_data.size() - 1)
	return level_data[idx]

func start_level(level: int) -> void:
	current_level = level
	level_started.emit(level)

func complete_level() -> void:
	level_completed.emit(current_level)
	current_level += 1
