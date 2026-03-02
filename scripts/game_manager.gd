extends Node

## Manages game state, level progression, and scoring.

signal level_started(level: int)
signal level_completed(level: int)
signal game_over

var current_level: int = 1
var grid_size: Vector2i = Vector2i(8, 10)
var cell_size: float = 2.0

var base_hp: float = 500.0
var enemy_sprites: Array[String] = [
	"res://assets/martoc/martoc_sprites.tres",
	"res://assets/martoc2/martoc2_sprites.tres",
]

func get_level_config() -> Dictionary:
	var hp := base_hp * pow(1.5, current_level - 1)
	var sprite := enemy_sprites[(current_level - 1) % enemy_sprites.size()]
	return {"target_type": "monster", "target_hp": hp, "time_limit": 60.0, "sprite": sprite}

func start_level(level: int) -> void:
	current_level = level
	level_started.emit(level)

func complete_level() -> void:
	level_completed.emit(current_level)
	current_level += 1
