extends Node3D

## The target at the top of the grid (monster). Has HP and can be destroyed.

signal hp_changed(current_hp: float, max_hp: float)
signal died
signal destroyed

@export var max_hp: float = 100.0
var current_hp: float = 100.0
var target_type: String = "monster"
var is_dead: bool = false
var _hit_tween: Tween = null
var _move_time: float = 0.0
var _move_origin: Vector3 = Vector3.ZERO
var _moving: bool = false
var _move_amplitude: float = 0.9
var _move_speed: float = 0.4
var _animated_sprite: AnimatedSprite3D = null
var _base_scale: Vector3 = Vector3.ONE

func _ready() -> void:
	current_hp = max_hp

var _sprite_path: String = "res://assets/martoc/martoc_sprites.tres"

func setup(type: String, hp: float, sprite_path: String = "") -> void:
	target_type = type
	max_hp = hp
	current_hp = hp
	is_dead = false
	_moving = false
	_move_time = 0.0
	if sprite_path != "":
		_sprite_path = sprite_path
	hp_changed.emit(current_hp, max_hp)
	_update_visual()

func start_movement() -> void:
	_move_origin = position
	_move_time = 0.0
	_moving = true
	if _animated_sprite:
		_animated_sprite.play("idle")

func _process(delta: float) -> void:
	if not _moving or is_dead:
		return
	_move_time += delta * _move_speed
	position.x = _move_origin.x + _move_amplitude * sin(_move_time)
	position.z = _move_origin.z + _move_amplitude * sin(_move_time * 2.0) * 0.5

func take_damage(amount: float) -> void:
	if is_dead:
		return
	current_hp = maxf(current_hp - amount, 0.0)
	hp_changed.emit(current_hp, max_hp)
	_on_hit()
	if current_hp <= 0:
		is_dead = true
		died.emit()
		if _animated_sprite:
			_animated_sprite.play("death")
			_animated_sprite.animation_finished.connect(_on_death_finished, CONNECT_ONE_SHOT)
		else:
			destroyed.emit()

func _on_death_finished() -> void:
	# Fade out after death animation completes
	if not _animated_sprite:
		destroyed.emit()
		return
	var tween := create_tween()
	tween.tween_property(_animated_sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		visible = false
		destroyed.emit()
	)

func _update_visual() -> void:
	# Hide the MeshInstance3D (kept for scene compatibility)
	var mesh_instance := $MeshInstance3D as MeshInstance3D
	if mesh_instance:
		mesh_instance.visible = false
	# Remove old animated sprite if any
	if _animated_sprite:
		_animated_sprite.queue_free()
		_animated_sprite = null
	var sprite_frames := load(_sprite_path) as SpriteFrames
	_animated_sprite = AnimatedSprite3D.new()
	_animated_sprite.sprite_frames = sprite_frames
	_animated_sprite.pixel_size = 0.045
	_animated_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_animated_sprite.no_depth_test = false
	_animated_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_animated_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	_animated_sprite.modulate = Color.WHITE
	add_child(_animated_sprite)
	_animated_sprite.play("idle")
	_base_scale = _animated_sprite.scale

func explode() -> void:
	# Death animation + fade handled by _on_death_finished
	pass

func _on_hit() -> void:
	if not _animated_sprite:
		return
	if _hit_tween and _hit_tween.is_valid():
		_hit_tween.kill()
	# Red flash + squeeze (scale X shrink, Y stretch) + shake
	_animated_sprite.modulate = Color(2.0, 0.3, 0.3)
	_animated_sprite.scale = _base_scale * Vector3(0.8, 1.2, 1.0)
	_animated_sprite.position.x = randf_range(-0.1, 0.1)
	_hit_tween = create_tween()
	_hit_tween.set_parallel(true)
	_hit_tween.tween_property(_animated_sprite, "modulate", Color.WHITE, 0.2).set_ease(Tween.EASE_OUT)
	_hit_tween.tween_property(_animated_sprite, "scale", _base_scale, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_hit_tween.tween_property(_animated_sprite, "position:x", 0.0, 0.15).set_ease(Tween.EASE_OUT)
