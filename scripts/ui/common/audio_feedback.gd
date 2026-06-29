extends Node

const MANAGER_NAME := "UIAudioFeedback"
const BGM_BUS := "BGM"
const SFX_BUS := "SFX"
const GENERAL_SFX_REDUCTION_DB := -6.0206
const CONFIRM_REDUCTION_DB := -13.9794
const REPORT_OPEN_REDUCTION_DB := -6.1960
const BGM_VOLUME_DB := -23.1186
const WORK_BGM_REDUCTION_DB := -4.4370
const BGM_FADE_SECONDS := 0.8
const SFX_POOL_SIZE := 8
const SAVE_MANAGER_SCRIPT := preload("res://scripts/save/save_manager.gd")

const SFX_PATHS := {
	"button_hover": "res://assets/sounds/sfx/ui_hover.ogg",
	"button_click": "res://assets/sounds/sfx/ui_click.ogg",
	"confirm": "res://assets/sounds/sfx/ui_confirm.ogg",
	"danger": "res://assets/sounds/sfx/ui_danger.ogg",
	"report_open": "res://assets/sounds/sfx/report_open.ogg",
	"text_tick": "res://assets/sounds/sfx/text_tick.ogg",
	"scene_transition": "res://assets/sounds/sfx/scene_transition.ogg",
}

# The supplied BGM files use MP3 rather than the requested OGG extension.
const BGM_PATHS := {
	"main_menu": "res://assets/sounds/bgm/bgm_main_menu.mp3",
	"work": "res://assets/sounds/bgm/bgm_work.mp3",
}

var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_streams: Dictionary = {}
var current_track: String = ""
var bgm_tween: Tween
var sfx_cursor: int = 0
var last_hover_time_msec: int = -1000
var last_text_tick_time_msec: int = -1000


static func play_button_hover() -> void:
	_call_manager("play_sfx", ["button_hover", -9.0 + GENERAL_SFX_REDUCTION_DB])


static func play_button_click() -> void:
	_call_manager("play_sfx", ["button_click", -6.0 + GENERAL_SFX_REDUCTION_DB])


static func play_confirm() -> void:
	_call_manager("play_sfx", ["confirm", -5.0 + CONFIRM_REDUCTION_DB])


static func play_danger() -> void:
	_call_manager("play_sfx", ["danger", -5.0 + GENERAL_SFX_REDUCTION_DB])


static func play_report_open() -> void:
	_call_manager("play_sfx", ["report_open", -7.0 + GENERAL_SFX_REDUCTION_DB + REPORT_OPEN_REDUCTION_DB])


static func play_text_tick() -> void:
	_call_manager("play_sfx", ["text_tick", -12.0 + GENERAL_SFX_REDUCTION_DB])


static func play_scene_transition() -> void:
	_call_manager("play_sfx", ["scene_transition", -9.0 + GENERAL_SFX_REDUCTION_DB])


static func play_bgm(track_name: String) -> void:
	_call_manager("play_bgm_track", [track_name])


static func stop_bgm() -> void:
	_call_manager("stop_bgm_track")


static func fade_bgm_to(track_name: String) -> void:
	_call_manager("fade_to_bgm_track", [track_name])


static func _call_manager(method: StringName, arguments: Array = []) -> void:
	var manager: Node = _get_or_create_manager()
	if manager != null:
		manager.callv(method, arguments)


static func _get_or_create_manager() -> Node:
	var main_loop: MainLoop = Engine.get_main_loop()
	if not main_loop is SceneTree:
		return null

	var tree := main_loop as SceneTree
	var existing: Node = tree.root.get_node_or_null(MANAGER_NAME)
	if existing != null:
		return existing

	var manager_script: Script = load("res://scripts/ui/common/audio_feedback.gd") as Script
	var manager: Node = manager_script.new()
	manager.name = MANAGER_NAME
	tree.root.add_child(manager)
	return manager


func _ready() -> void:
	_ensure_bus(BGM_BUS)
	_ensure_bus(SFX_BUS)
	_apply_saved_master_volume()

	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = BGM_BUS
	add_child(bgm_player)

	for index in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % index
		player.bus = SFX_BUS
		add_child(player)
		sfx_players.append(player)


func play_sfx(effect_name: String, volume_db: float = -6.0) -> void:
	var now_msec: int = Time.get_ticks_msec()
	if effect_name == "button_hover":
		if now_msec - last_hover_time_msec < 90:
			return
		last_hover_time_msec = now_msec
	elif effect_name == "text_tick":
		if now_msec - last_text_tick_time_msec < 55:
			return
		last_text_tick_time_msec = now_msec

	var stream: AudioStream = _get_sfx_stream(effect_name)
	if stream == null or sfx_players.is_empty():
		return

	var player: AudioStreamPlayer = sfx_players[sfx_cursor]
	sfx_cursor = (sfx_cursor + 1) % sfx_players.size()
	player.stop()
	player.stream = stream
	player.volume_db = volume_db
	player.play()


func play_bgm_track(track_name: String) -> void:
	var normalized_name: String = _normalize_track_name(track_name)
	if normalized_name.is_empty():
		return
	if current_track == normalized_name and bgm_player != null and bgm_player.playing:
		return
	if current_track.is_empty() or bgm_player == null or not bgm_player.playing:
		_start_bgm(normalized_name, true)
		return
	fade_to_bgm_track(normalized_name)


func fade_to_bgm_track(track_name: String) -> void:
	var normalized_name: String = _normalize_track_name(track_name)
	if normalized_name.is_empty():
		return
	if current_track == normalized_name and bgm_player != null and bgm_player.playing:
		return
	if bgm_player == null or not bgm_player.playing:
		_start_bgm(normalized_name, true)
		return

	_kill_bgm_tween()
	bgm_tween = create_tween()
	bgm_tween.tween_property(bgm_player, "volume_db", -36.0, BGM_FADE_SECONDS * 0.5)
	bgm_tween.tween_callback(_start_bgm.bind(normalized_name, false))
	bgm_tween.tween_property(bgm_player, "volume_db", _get_bgm_volume_db(normalized_name), BGM_FADE_SECONDS * 0.5)


func stop_bgm_track() -> void:
	_kill_bgm_tween()
	if bgm_player != null:
		bgm_player.stop()
	current_track = ""


func _start_bgm(track_name: String, fade_in: bool) -> void:
	var path: String = str(BGM_PATHS.get(track_name, ""))
	var stream: AudioStream = _load_audio_stream(path)
	if stream == null or bgm_player == null:
		return

	_set_stream_loop(stream)
	bgm_player.stop()
	bgm_player.stream = stream
	bgm_player.volume_db = -30.0 if fade_in else -36.0
	bgm_player.play()
	current_track = track_name
	if fade_in:
		_kill_bgm_tween()
		bgm_tween = create_tween()
		bgm_tween.tween_property(bgm_player, "volume_db", _get_bgm_volume_db(track_name), BGM_FADE_SECONDS)


func _get_bgm_volume_db(track_name: String) -> float:
	if track_name == "work":
		return BGM_VOLUME_DB + WORK_BGM_REDUCTION_DB
	return BGM_VOLUME_DB


func _get_sfx_stream(effect_name: String) -> AudioStream:
	if sfx_streams.has(effect_name):
		return sfx_streams[effect_name] as AudioStream

	var path: String = str(SFX_PATHS.get(effect_name, ""))
	var stream: AudioStream = _load_audio_stream(path)
	sfx_streams[effect_name] = stream
	return stream


func _load_audio_stream(path: String) -> AudioStream:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


func _normalize_track_name(track_name: String) -> String:
	var normalized: String = track_name.strip_edges().to_lower()
	if normalized.ends_with(".ogg") or normalized.ends_with(".mp3"):
		normalized = normalized.get_basename()
	if normalized.begins_with("bgm_"):
		normalized = normalized.trim_prefix("bgm_")
	return normalized if BGM_PATHS.has(normalized) else ""


func _set_stream_loop(stream: AudioStream) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true


func _kill_bgm_tween() -> void:
	if bgm_tween != null and bgm_tween.is_valid():
		bgm_tween.kill()
	bgm_tween = null


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var bus_index: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, "Master")


func _apply_saved_master_volume() -> void:
	var save_manager: Variant = SAVE_MANAGER_SCRIPT.new()
	var settings_data: Dictionary = save_manager.load_settings()
	save_manager.free()
	var volume_percent: int = clampi(int(settings_data.get("volume", 100)), 0, 100)
	var master_bus_index: int = AudioServer.get_bus_index("Master")
	if master_bus_index < 0:
		return
	if volume_percent <= 0:
		AudioServer.set_bus_volume_db(master_bus_index, -80.0)
		return
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(float(volume_percent) / 100.0))
