extends Node3D

## The target at the top of the grid (wall or monster). Has HP and can be destroyed.

signal hp_changed(current_hp: float, max_hp: float)
signal destroyed

@export var max_hp: float = 100.0
var current_hp: float = 100.0
var target_type: String = "wall"

func _ready() -> void:
	current_hp = max_hp

func setup(type: String, hp: float) -> void:
	target_type = type
	max_hp = hp
	current_hp = hp
	hp_changed.emit(current_hp, max_hp)
	_update_visual()

func take_damage(amount: float) -> void:
	current_hp = maxf(current_hp - amount, 0.0)
	hp_changed.emit(current_hp, max_hp)
	_flash_hit()
	if current_hp <= 0:
		destroyed.emit()

func _update_visual() -> void:
	# Update mesh/material based on target_type
	var mesh_instance = $MeshInstance3D
	if mesh_instance:
		if target_type == "wall":
			var box = BoxMesh.new()
			box.size = Vector3(8.0, 3.0, 1.0)
			mesh_instance.mesh = box
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.6, 0.35, 0.2)
			mesh_instance.material_override = mat
		elif target_type == "monster":
			var box = BoxMesh.new()
			box.size = Vector3(3.0, 4.0, 3.0)
			mesh_instance.mesh = box
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.7, 0.1, 0.1)
			mesh_instance.material_override = mat

func _flash_hit() -> void:
	var mesh_instance = $MeshInstance3D
	if mesh_instance and mesh_instance.material_override:
		var orig_color = mesh_instance.material_override.albedo_color
		mesh_instance.material_override.albedo_color = Color.WHITE
		var tween = create_tween()
		tween.tween_property(mesh_instance.material_override, "albedo_color", orig_color, 0.15)
