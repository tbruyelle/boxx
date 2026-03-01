extends Node3D

## The target at the top of the grid (wall or monster). Has HP and can be destroyed.

signal hp_changed(current_hp: float, max_hp: float)
signal destroyed

@export var max_hp: float = 100.0
var current_hp: float = 100.0
var target_type: String = "wall"
var is_dead: bool = false
var base_color: Color = Color.WHITE
var _flash_tween: Tween = null

func _ready() -> void:
	current_hp = max_hp

func _load_texture(path: String) -> ImageTexture:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	if img == null:
		return null
	return ImageTexture.create_from_image(img)

func setup(type: String, hp: float) -> void:
	target_type = type
	max_hp = hp
	current_hp = hp
	is_dead = false
	hp_changed.emit(current_hp, max_hp)
	_update_visual()

func take_damage(amount: float) -> void:
	if is_dead:
		return
	current_hp = maxf(current_hp - amount, 0.0)
	hp_changed.emit(current_hp, max_hp)
	_flash_hit()
	if current_hp <= 0:
		is_dead = true
		destroyed.emit()

func _update_visual() -> void:
	var mesh_instance = $MeshInstance3D
	if not mesh_instance:
		return
	if target_type == "wall":
		var box = BoxMesh.new()
		box.size = Vector3(8.0, 3.0, 1.0)
		mesh_instance.mesh = box
		var mat = StandardMaterial3D.new()
		var tex = _load_texture("res://assets/wall.png")
		if tex:
			mat.albedo_texture = tex
			mat.uv1_scale = Vector3(4.0, 2.0, 1.0)
		else:
			mat.albedo_color = Color(0.6, 0.35, 0.2)
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		base_color = Color.WHITE
		mat.albedo_color = base_color
		mesh_instance.material_override = mat
	elif target_type == "monster":
		var quad = QuadMesh.new()
		quad.size = Vector2(4.0, 4.0)
		mesh_instance.mesh = quad
		var mat = StandardMaterial3D.new()
		var tex = _load_texture("res://assets/monster.png")
		if tex:
			mat.albedo_texture = tex
		else:
			mat.albedo_color = Color(0.7, 0.1, 0.1)
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		base_color = Color.WHITE
		mat.albedo_color = base_color
		mesh_instance.material_override = mat

func explode() -> void:
	var mesh_instance = $MeshInstance3D
	if not mesh_instance:
		return
	if mesh_instance.material_override:
		mesh_instance.material_override.albedo_color = Color(3, 3, 3)
		mesh_instance.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3(3, 3, 3), 0.5).set_ease(Tween.EASE_OUT)
	if mesh_instance.material_override:
		tween.tween_property(mesh_instance.material_override, "albedo_color:a", 0.0, 0.5)
	tween.chain().tween_callback(func(): visible = false; scale = Vector3.ONE)

func _flash_hit() -> void:
	var mesh_instance = $MeshInstance3D
	if mesh_instance and mesh_instance.material_override:
		if _flash_tween and _flash_tween.is_valid():
			_flash_tween.kill()
		mesh_instance.material_override.albedo_color = Color(3, 3, 3)
		_flash_tween = create_tween()
		_flash_tween.tween_property(mesh_instance.material_override, "albedo_color", base_color, 0.15)
