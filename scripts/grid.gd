extends Node3D

## Manages the grid of cells. Handles cell states (active, destroyed, bonus/malus).

const CELL_SCENE = preload("res://scenes/cell.tscn")

@export var grid_size: Vector2i = Vector2i(10, 10)
@export var cell_size: float = 2.0

# Grid data: each cell stores its state
var cells: Dictionary = {}  # Vector2i -> CellData

enum CellState { ACTIVE, DESTROYED }
enum CellBonus { NONE, FIRE_RATE_X2, FIRE_RATE_HALF, BULLETS_PLUS_10 }

class CellData:
	var state: int = CellState.ACTIVE
	var bonus: int = CellBonus.NONE
	var node: Node3D = null

func _ready() -> void:
	generate_grid()

func generate_grid() -> void:
	# Clear existing cells
	for key in cells:
		if cells[key].node:
			cells[key].node.queue_free()
	cells.clear()

	for x in range(grid_size.x):
		for z in range(grid_size.y):
			var pos = Vector2i(x, z)
			var cell_data = CellData.new()
			cell_data.bonus = _random_bonus(pos)
			cell_data.state = CellState.ACTIVE

			var cell_node = CELL_SCENE.instantiate()
			cell_node.position = grid_to_world(pos)
			cell_node.name = "Cell_%d_%d" % [x, z]
			add_child(cell_node)

			cell_data.node = cell_node
			cell_node.setup(cell_data.bonus)
			cells[pos] = cell_data

func _random_bonus(pos: Vector2i) -> int:
	# Starting cell has no bonus
	var start = get_start_position()
	if pos == start:
		return CellBonus.NONE

	var roll = randf()
	if roll < 0.15:
		return CellBonus.FIRE_RATE_X2
	elif roll < 0.25:
		return CellBonus.FIRE_RATE_HALF
	elif roll < 0.35:
		return CellBonus.BULLETS_PLUS_10
	return CellBonus.NONE

func get_start_position() -> Vector2i:
	return Vector2i(grid_size.x / 2, grid_size.y - 1)

func grid_to_world(pos: Vector2i) -> Vector3:
	var offset_x = -(grid_size.x - 1) * cell_size / 2.0
	var offset_z = -(grid_size.y - 1) * cell_size / 2.0
	return Vector3(pos.x * cell_size + offset_x, 0.0, pos.y * cell_size + offset_z)

func is_valid_move(pos: Vector2i) -> bool:
	if not cells.has(pos):
		return false
	return cells[pos].state == CellState.ACTIVE

func destroy_cell(pos: Vector2i) -> void:
	if cells.has(pos):
		cells[pos].state = CellState.DESTROYED
		if cells[pos].node:
			cells[pos].node.destroy()

func get_cell_bonus(pos: Vector2i) -> int:
	if cells.has(pos):
		return cells[pos].bonus
	return CellBonus.NONE
