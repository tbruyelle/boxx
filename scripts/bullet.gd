extends Node3D

## A bullet that travels toward the target and deals damage on arrival.

@export var speed: float = 15.0
@export var damage: float = 10.0

var target_position: Vector3 = Vector3.ZERO
var direction: Vector3 = Vector3.ZERO
var active: bool = true

func _ready() -> void:
	direction = (target_position - global_position).normalized()

func _process(delta: float) -> void:
	if not active:
		return
	position += direction * speed * delta
	# Check if bullet reached or passed target
	if position.z <= target_position.z:
		_hit_target()

func setup(target_pos: Vector3, dmg: float) -> void:
	target_position = target_pos
	damage = dmg

func _hit_target() -> void:
	active = false
	# Signal to game level that bullet hit
	var level = get_tree().get_first_node_in_group("game_level")
	if level and level.has_method("on_bullet_hit"):
		level.on_bullet_hit(damage)
	queue_free()
