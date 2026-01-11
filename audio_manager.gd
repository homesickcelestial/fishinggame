extends Node
## AudioManager - Global audio management singleton
## Add this as an autoload in Project Settings > Autoload with name "AudioManager"

# Audio bus names
const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"

# Music player
var _music_player: AudioStreamPlayer
var _current_music: AudioStream

# SFX pool for playing multiple sounds at once
var _sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 8

# Settings
var music_enabled := true
var sfx_enabled := true

# Fade settings
var _fade_tween: Tween


func _ready() -> void:
	# Create music player
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = BUS_MUSIC
	add_child(_music_player)
	
	# Create SFX player pool
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		_sfx_players.append(player)
	
	# Load saved settings
	_load_settings()


#region Music Functions

## Play music, optionally with crossfade
func play_music(stream: AudioStream, fade_duration: float = 0.5) -> void:
	if not music_enabled or stream == _current_music:
		return
	
	_current_music = stream
	
	if fade_duration > 0 and _music_player.playing:
		# Crossfade
		if _fade_tween:
			_fade_tween.kill()
		_fade_tween = create_tween()
		_fade_tween.tween_property(_music_player, "volume_db", -40.0, fade_duration)
		_fade_tween.tween_callback(_start_new_music.bind(stream, fade_duration))
	else:
		_music_player.stream = stream
		_music_player.volume_db = 0.0
		_music_player.play()


func _start_new_music(stream: AudioStream, fade_duration: float) -> void:
	_music_player.stream = stream
	_music_player.volume_db = -40.0
	_music_player.play()
	
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_music_player, "volume_db", 0.0, fade_duration)


## Stop music with optional fade out
func stop_music(fade_duration: float = 0.5) -> void:
	if fade_duration > 0 and _music_player.playing:
		if _fade_tween:
			_fade_tween.kill()
		_fade_tween = create_tween()
		_fade_tween.tween_property(_music_player, "volume_db", -40.0, fade_duration)
		_fade_tween.tween_callback(_music_player.stop)
	else:
		_music_player.stop()
	_current_music = null


## Pause/resume music
func pause_music() -> void:
	_music_player.stream_paused = true


func resume_music() -> void:
	_music_player.stream_paused = false


func is_music_playing() -> bool:
	return _music_player.playing and not _music_player.stream_paused

#endregion


#region SFX Functions

## Play a sound effect, returns the player used (or null if none available)
func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> AudioStreamPlayer:
	if not sfx_enabled or stream == null:
		return null
	
	var player := _get_available_sfx_player()
	if player:
		player.stream = stream
		player.volume_db = volume_db
		player.pitch_scale = pitch_scale
		player.play()
	return player


## Play SFX with random pitch variation (good for footsteps, hits, etc.)
func play_sfx_varied(stream: AudioStream, volume_db: float = 0.0, pitch_min: float = 0.9, pitch_max: float = 1.1) -> AudioStreamPlayer:
	var pitch := randf_range(pitch_min, pitch_max)
	return play_sfx(stream, volume_db, pitch)


func _get_available_sfx_player() -> AudioStreamPlayer:
	# Find a player that's not currently playing
	for player in _sfx_players:
		if not player.playing:
			return player
	# All busy - return the first one (will cut off oldest sound)
	return _sfx_players[0]


## Stop all sound effects
func stop_all_sfx() -> void:
	for player in _sfx_players:
		player.stop()

#endregion


#region Volume Control

## Set volume for a bus (0.0 to 1.0 linear scale)
func set_bus_volume(bus_name: String, linear_volume: float) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(clampf(linear_volume, 0.0, 1.0)))
		_save_settings()


## Get volume for a bus (returns 0.0 to 1.0 linear scale)
func get_bus_volume(bus_name: String) -> float:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return 1.0
	return db_to_linear(AudioServer.get_bus_volume_db(bus_idx))


## Convenience functions
func set_master_volume(linear_volume: float) -> void:
	set_bus_volume(BUS_MASTER, linear_volume)


func set_music_volume(linear_volume: float) -> void:
	set_bus_volume(BUS_MUSIC, linear_volume)


func set_sfx_volume(linear_volume: float) -> void:
	set_bus_volume(BUS_SFX, linear_volume)


func get_master_volume() -> float:
	return get_bus_volume(BUS_MASTER)


func get_music_volume() -> float:
	return get_bus_volume(BUS_MUSIC)


func get_sfx_volume() -> float:
	return get_bus_volume(BUS_SFX)


## Mute/unmute a bus
func set_bus_mute(bus_name: String, muted: bool) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, muted)

#endregion


#region Settings Persistence

const SETTINGS_PATH := "user://audio_settings.cfg"

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", get_master_volume())
	config.set_value("audio", "music_volume", get_music_volume())
	config.set_value("audio", "sfx_volume", get_sfx_volume())
	config.set_value("audio", "music_enabled", music_enabled)
	config.set_value("audio", "sfx_enabled", sfx_enabled)
	config.save(SETTINGS_PATH)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		set_master_volume(config.get_value("audio", "master_volume", 1.0))
		set_music_volume(config.get_value("audio", "music_volume", 1.0))
		set_sfx_volume(config.get_value("audio", "sfx_volume", 1.0))
		music_enabled = config.get_value("audio", "music_enabled", true)
		sfx_enabled = config.get_value("audio", "sfx_enabled", true)

#endregion
