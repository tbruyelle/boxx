extends Node3D

## Visual representation of a single grid cell.

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var bonus_label: Label3D = $BonusLabel

var bonus_type: int = 0  # CellBonus enum value
var is_destroyed: bool = false

func setup(bonus: int) -> void:
	bonus_type = bonus
	_update_visual()

func _update_visual() -> void:
	if not mesh_instance:
		return

	var mat = StandardMaterial3D.new()
	match bonus_type:
		0:  # NONE
			mat.albedo_color = Color(0.85, 0.85, 0.85)
		1:  # FIRE_RATE_X2
			mat.albedo_color = Color(0.2, 0.8, 0.2)
		2:  # FIRE_RATE_HALF
			mat.albedo_color = Color(0.8, 0.2, 0.2)
		3:  # BULLETS_PLUS_10
			mat.albedo_color = Color(0.2, 0.4, 0.9)
	mesh_instance.material_override = mat

	if bonus_label:
		match bonus_type:
			0: bonus_label.text = ""
			1: bonus_label.text = "x2"
			2: bonus_label.text = "/2"
			3: bonus_label.text = "+10"

func clear_bonus() -> void:
	bonus_type = 0
	_update_visual()

func destroy() -> void:
	is_destroyed = true
	var tween = create_tween()
	tween.tween_property(self, "position:y", -2.0, 0.3).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		if mesh_instance:
			mesh_instance.visible = false
		if bonus_label:
			bonus_label.visible = false
	)
