extends Node

const SAVE_MANAGER_SCRIPT := preload("res://scripts/save/save_manager.gd")
const TEXT_SIZE_SCALES := {
	"small": 0.9,
	"normal": 1.0,
	"large": 1.15
}
const BASE_FONT_META_PREFIX := "settings_base_font_size_"

var current_settings: Dictionary = {}
var base_fallback_font_size: int = 16


func _ready() -> void:
	base_fallback_font_size = ThemeDB.fallback_font_size
	get_tree().node_added.connect(_on_node_added)
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
	current_settings["text_size"] = text_size_key
	var scale: float = _get_text_size_scale(text_size_key)
	ThemeDB.fallback_font_size = maxi(1, roundi(float(base_fallback_font_size) * scale))
	if is_inside_tree():
		apply_text_size_to_tree(get_tree().root)


func get_text_size_font_size(text_size_key: String) -> int:
	return maxi(1, roundi(float(base_fallback_font_size) * _get_text_size_scale(text_size_key)))


func apply_text_size_to_tree(root_node: Node) -> void:
	if root_node == null:
		return
	if root_node is Control:
		apply_text_size_to_control(root_node as Control)
	for child in root_node.get_children():
		apply_text_size_to_tree(child)


func apply_text_size_to_control(control: Control) -> void:
	if control == null or not is_instance_valid(control):
		return

	var scale: float = _get_text_size_scale(str(current_settings.get("text_size", "normal")))
	for font_size_name in _get_font_size_names(control):
		var metadata_key: String = BASE_FONT_META_PREFIX + str(font_size_name)
		if not control.has_meta(metadata_key):
			var initial_font_size: int = base_fallback_font_size
			if control.has_theme_font_size_override(font_size_name):
				initial_font_size = control.get_theme_font_size(font_size_name)
			control.set_meta(metadata_key, initial_font_size)
		var base_font_size: int = int(control.get_meta(metadata_key, base_fallback_font_size))
		control.add_theme_font_size_override(font_size_name, maxi(1, roundi(float(base_font_size) * scale)))


func copy_text_size_baseline(source: Control, target: Control) -> void:
	if source == null or target == null:
		return
	for font_size_name in _get_font_size_names(source):
		var metadata_key: String = BASE_FONT_META_PREFIX + str(font_size_name)
		var base_font_size: int = int(source.get_meta(metadata_key, source.get_theme_font_size(font_size_name)))
		target.set_meta(metadata_key, base_font_size)


func _on_node_added(node: Node) -> void:
	if node is Control:
		call_deferred("_apply_added_control", node)


func _apply_added_control(control: Control) -> void:
	if control == null or not is_instance_valid(control) or not control.is_inside_tree():
		return
	apply_text_size_to_control(control)


func _get_font_size_names(control: Control) -> Array[StringName]:
	if control is RichTextLabel:
		return [&"normal_font_size", &"bold_font_size", &"italics_font_size", &"bold_italics_font_size", &"mono_font_size"]
	if control is Label or control is Button or control is LineEdit or control is TextEdit or control is TabBar or control is ItemList or control is Tree:
		return [&"font_size"]
	return []


func _get_text_size_scale(text_size_key: String) -> float:
	return float(TEXT_SIZE_SCALES.get(_normalize_text_size(text_size_key), TEXT_SIZE_SCALES["normal"]))


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
