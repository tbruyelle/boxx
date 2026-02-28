extends Node3D

## The player character. Moves on the grid, auto-fires bullets at the target.

signal moved(old_pos: Vector2i, new_pos: Vector2i)
signal fired(bullet_count: int)

@export var base_fire_interval: float = 3.0
@export var bullet_damage: float = 10.0

var grid_pos: Vector2i = Vector2i.ZERO
var fire_interval: float = 3.0
var bonus_bullets: int = 0
var is_moving: bool = false

@onready var fire_timer: Timer = $FireTimer
@onready var model: Node3D = $Model

func _ready() -> void:
	fire_timer.wait_time = fire_interval
	fire_timer.timeout.connect(_on_fire_timer_timeout)

func _unhandled_input(event: InputEvent) -> void:
	if is_moving:
		return

	var direction := Vector2i.ZERO
	if event.is_action_pressed("move_up"):
		direction = Vector2i(0, -1)
	elif event.is_action_pressed("move_down"):
		direction = Vector2i(0, 1)
	elif event.is_action_pressed("move_left"):
		direction = Vector2i(-1, 0)
	elif event.is_action_pressed("move_right"):
		direction = Vector2i(1, 0)

	if direction != Vector2i.ZERO:
		attempt_move(direction)

func attempt_move(direction: Vector2i) -> void:
	var new_pos = grid_pos + direction
	var grid = get_parent() as Node3D
	var grid_script = grid.get_node("Grid") if grid.has_node("Grid") else null
	if grid_script and grid_script.is_valid_move(new_pos):
		var old_pos = grid_pos
		grid_pos = new_pos
		moved.emit(old_pos, new_pos)
		_animate_move(grid_script.grid_to_world(new_pos))

func _animate_move(target_world_pos: Vector3) -> void:
	is_moving = true
	var tween = create_tween()
	tween.tween_property(self, "position", target_world_pos, 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): is_moving = false)

func apply_bonus(bonus: int) -> void:
	match bonus:
		1:  # FIRE_RATE_X2
			fire_interval = maxf(fire_interval / 2.0, 0.25)
			fire_timer.wait_time = fire_interval
		2:  # FIRE_RATE_HALF
			fire_interval = fire_interval * 2.0
			fire_timer.wait_time = fire_interval
		3:  # BULLETS_PLUS_10
			bonus_bullets += 10

func get_fire_rate() -> float:
	return 1.0 / fire_interval

func get_time_to_next_shot() -> float:
	return fire_timer.time_left

func _on_fire_timer_timeout() -> void:
	var count = 1 + bonus_bullets
	if bonus_bullets > 0:
		bonus_bullets = maxi(bonus_bullets - 1, 0)
		if bonus_bullets == 0:
			count = 1  # Back to normal next shot
	fired.emit(count)

func reset(start_pos: Vector2i, world_pos: Vector3) -> void:
	grid_pos = start_pos
	position = world_pos
	fire_interval = base_fire_interval
	bonus_bullets = 0
	fire_timer.wait_time = fire_interval
