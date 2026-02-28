extends Node

## Loads and plays sound effects from WAV files at runtime.

var streams: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
const MAX_PLAYERS = 8

func _ready() -> void:
	# Pre-create a pool of AudioStreamPlayers
	for i in range(MAX_PLAYERS):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		players.append(p)

	# Load all SFX
	_load_sfx("move", "res://assets/sfx_move.wav")
	_load_sfx("fire", "res://assets/sfx_fire.wav")
	_load_sfx("hit_wall", "res://assets/sfx_hit_wall.wav")
	_load_sfx("hit_monster", "res://assets/sfx_hit_monster.wav")
	_load_sfx("cell_fall", "res://assets/sfx_cell_fall.wav")
	_load_sfx("confirm", "res://assets/sfx_confirm.wav")
	_load_sfx("explosion", "res://assets/sfx_explosion.wav")
	_load_sfx("victory", "res://assets/sfx_victory.wav")

func _load_sfx(name: String, path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("SFX not found: " + path)
		return
	var bytes = file.get_buffer(file.get_length())
	file.close()
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = bytes.decode_u32(24)
	stream.stereo = false
	stream.data = bytes.slice(44)
	streams[name] = stream

func play(name: String, volume_db: float = 0.0) -> void:
	if not streams.has(name):
		return
	# Find a free player
	for p in players:
		if not p.playing:
			p.stream = streams[name]
			p.volume_db = volume_db
			p.play()
			return
