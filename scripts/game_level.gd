extends Node3D

## Main game level scene controller. Orchestrates grid, player, target, and bullets.

const BULLET_SCENE = preload("res://scenes/bullet.tscn")

enum State { SPLASH, INTRO, PLAYING, GAME_OVER }

@onready var grid: Node3D = $Grid
@onready var player: Node3D = $Player
@onready var target: Node3D = $Target
@onready var hp_bar: ProgressBar = $UI/HPBar
@onready var level_label: Label = $UI/LevelLabel
@onready var fire_rate_label: Label = $UI/FireRateLabel
@onready var timer_label: Label = $UI/TimerLabel
@onready var game_manager: Node = $GameManager
@onready var game_over_panel: Control = $UI/GameOverPanel
@onready var title_label: Node3D = $TitleLabel
@onready var press_key_label: Label = $UI/PressKeyLabel

var state: int = State.SPLASH
var time_remaining: float = 60.0
var title_base_y: float = 5.0
var title_time: float = 0.0

func _ready() -> void:
	add_to_group("game_level")
	_enter_splash()

func _enter_splash() -> void:
	state = State.SPLASH
	game_manager.current_level = 1

	# Show grid without bonuses
	grid.grid_size = game_manager.grid_size
	grid.cell_size = game_manager.cell_size
	grid.generate_grid()

	# Hide player and target
	player.visible = false
	player.set_process_unhandled_input(false)
	player.fire_timer.stop()
	target.visible = false

	# UI: hide game HUD, show title
	hp_bar.visible = false
	level_label.visible = false
	fire_rate_label.visible = false
	timer_label.visible = false
	game_over_panel.visible = false
	title_label.visible = true
	press_key_label.visible = true
	press_key_label.text = "Appuyez sur une touche"

func _enter_intro() -> void:
	state = State.INTRO
	press_key_label.visible = false
	title_label.visible = false

	var config = game_manager.get_level_config()

	# Setup grid fresh
	grid.generate_grid()

	# Show game UI
	hp_bar.visible = true
	level_label.visible = true
	fire_rate_label.visible = true
	timer_label.visible = true
	level_label.text = "Level %d" % game_manager.current_level

	# Player drops from sky
	var start_pos = grid.get_start_position()
	var land_pos = grid.grid_to_world(start_pos)
	player.reset(start_pos, land_pos)
	player.position = land_pos + Vector3(0, 15, 0)
	player.visible = true
	player.set_process_unhandled_input(false)
	player.fire_timer.stop()

	var tween = create_tween()
	tween.tween_property(player, "position", land_pos, 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_callback(_intro_target_slide.bind(config))

func _intro_target_slide(config: Dictionary) -> void:
	# Target slides in from above
	var target_final = grid.grid_to_world(Vector2i(game_manager.grid_size.x / 2, 0))
	target_final.y = 1.5
	target_final.z -= game_manager.cell_size
	target.position = target_final + Vector3(0, 0, -20)
	target.setup(config["target_type"], config["target_hp"])
	target.visible = true

	hp_bar.max_value = config["target_hp"]
	hp_bar.value = config["target_hp"]

	var tween = create_tween()
	tween.tween_property(target, "position", target_final, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(_start_playing)

func _start_playing() -> void:
	state = State.PLAYING
	var config = game_manager.get_level_config()
	time_remaining = config["time_limit"]

	# Connect signals
	if not player.moved.is_connected(_on_player_moved):
		player.moved.connect(_on_player_moved)
	if not player.fired.is_connected(_on_player_fired):
		player.fired.connect(_on_player_fired)
	if not target.hp_changed.is_connected(_on_target_hp_changed):
		target.hp_changed.connect(_on_target_hp_changed)
	if not target.destroyed.is_connected(_on_target_destroyed):
		target.destroyed.connect(_on_target_destroyed)

	player.set_process_unhandled_input(true)
	player.fire_timer.start()

func _trigger_game_over() -> void:
	state = State.GAME_OVER
	player.fire_timer.stop()
	player.set_process_unhandled_input(false)
	game_over_panel.visible = true
	press_key_label.visible = true
	press_key_label.text = "Appuyez sur une touche"

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not event.pressed or event.echo:
		return

	match state:
		State.SPLASH:
			_enter_intro()
		State.GAME_OVER:
			_enter_splash()

func _process(delta: float) -> void:
	if state == State.SPLASH and title_label.visible:
		title_time += delta
		title_label.position.y = title_base_y + sin(title_time * 1.5) * 0.5
	if state == State.PLAYING:
		fire_rate_label.text = "%.2f tir/sec" % player.get_fire_rate()
		time_remaining = maxf(time_remaining - delta, 0.0)
		var minutes = int(time_remaining) / 60
		var seconds = int(time_remaining) % 60
		timer_label.text = "%d:%02d" % [minutes, seconds]
		if time_remaining <= 0.0:
			_trigger_game_over()

func _on_player_moved(old_pos: Vector2i, new_pos: Vector2i) -> void:
	grid.destroy_cell(old_pos)
	var bonus = grid.get_cell_bonus(new_pos)
	player.apply_bonus(bonus)

func _on_player_fired(bullet_count: int) -> void:
	for i in range(bullet_count):
		_spawn_bullet(i)

func _spawn_bullet(index: int) -> void:
	var bullet = BULLET_SCENE.instantiate()
	var offset = Vector3(randf_range(-0.3, 0.3) * index, 0.0, 0.0)
	bullet.position = player.position + Vector3(0, 1.0, 0) + offset
	bullet.setup(target.position + Vector3(0, 1.5, 0), player.bullet_damage)
	add_child(bullet)

func on_bullet_hit(damage: float) -> void:
	target.take_damage(damage)

func _on_target_hp_changed(current: float, max_val: float) -> void:
	hp_bar.value = current

func _on_target_destroyed() -> void:
	game_manager.complete_level()
	await get_tree().create_timer(1.5).timeout
	_enter_intro()
