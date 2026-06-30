extends Node

const SAVE_MANAGER_SCRIPT := preload("res://scripts/save/save_manager.gd")
const TEXT_FONT_SIZES := {
	"small": 14,
	"normal": 18,
	"large": 24
}

var current_settings: Dictionary = {}


func _ready() -> void:
	current_settings = load_settings()
	apply_all_settings(current_settings)


func load_settings() -> Dictionary:
	var save_manager: Variant = SAVE_MANAGER_SCRIPT.new()
	var settings_data: Dictionary = save_manager.load_settings()
	save_manager.free()
	current_settings = _normalize_settings(settings_data)
	return current_settings.duplicate(true)


func save_settings(settings_data: Dictionary) -> bool:
	current_settings = _normalize_settings(settings_data)
	var save_manager: Variant = SAVE_MANAGER_SCRIPT.new()
	var saved: bool = save_manager.save_settings(current_settings)
	save_manager.free()
	return saved


func apply_all_settings(settings_data: Dictionary = {}) -> void:
	var settings_to_apply: Dictionary = current_settings if settings_data.is_empty() else _normalize_settings(settings_data)
	current_settings = settings_to_apply.duplicate(true)
	apply_audio_settings(settings_to_apply)
	apply_display_settings(settings_to_apply)
	apply_text_size_settings(settings_to_apply)


func apply_audio_settings(settings_data: Dictionary) -> void:
	var master_bus_index: int = AudioServer.get_bus_index("Master")
	if master_bus_index < 0:
		return

	var volume_percent: int = clampi(int(settings_data.get("volume", 100)), 0, 100)
	if volume_percent <= 0:
		AudioServer.set_bus_volume_db(master_bus_index, -80.0)
		return
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(float(volume_percent) / 100.0))


func apply_display_settings(settings_data: Dictionary) -> void:
	var window: Window = get_window()
	if window == null:
		return

	if str(settings_data.get("screen_mode", "windowed")) == "fullscreen":
		window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	else:
		window.mode = Window.MODE_WINDOWED


func apply_text_size_settings(settings_data: Dictionary) -> void:
	var text_size_key: String = _normalize_text_size(str(settings_data.get("text_size", "normal")))
	ThemeDB.fallback_font_size = get_text_size_font_size(text_size_key)


func get_text_size_font_size(text_size_key: String) -> int:
	return int(TEXT_FONT_SIZES.get(_normalize_text_size(text_size_key), TEXT_FONT_SIZES["normal"]))


func _normalize_settings(settings_data: Dictionary) -> Dictionary:
	return {
		"save_version": 1,
		"volume": clampi(int(settings_data.get("volume", 100)), 0, 100),
		"screen_mode": "fullscreen" if str(settings_data.get("screen_mode", "windowed")) == "fullscreen" else "windowed",
		"text_size": _normalize_text_size(str(settings_data.get("text_size", "normal")))
	}


func _normalize_text_size(text_size_key: String) -> String:
	if text_size_key == "small" or text_size_key == "large":
		return text_size_key
	return "normal"
