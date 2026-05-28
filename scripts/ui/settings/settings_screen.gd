extends Control

const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu/MainMenu.tscn"
const SAVE_MANAGER_SCRIPT := preload("res://scripts/save/save_manager.gd")
const SCREEN_MODE_WINDOWED := "창 모드"
const SCREEN_MODE_FULLSCREEN := "전체 화면"
const TEXT_SIZE_OPTIONS := ["보통", "크게", "작게"]
const TEXT_SIZE_KEYS := ["normal", "large", "small"]

@onready var volume_slider: HSlider = $CenterContainer/ContentContainer/VolumeContainer/VolumeSlider
@onready var volume_value_label: Label = $CenterContainer/ContentContainer/VolumeContainer/VolumeValueLabel
@onready var screen_mode_button: Button = $CenterContainer/ContentContainer/ScreenModeContainer/ScreenModeButton
@onready var text_size_button: Button = $CenterContainer/ContentContainer/TextSizeContainer/TextSizeButton
@onready var guide_label: Label = $CenterContainer/ContentContainer/GuideLabel

var text_size_index: int = 0
var is_loading_settings: bool = false


func _ready() -> void:
	guide_label.text = "설정값은 자동으로 저장됩니다."
	_load_settings_to_ui()


func _on_volume_slider_value_changed(value: float) -> void:
	volume_value_label.text = "%d%%" % int(value)
	if not is_loading_settings:
		_save_current_settings()


func _on_screen_mode_button_pressed() -> void:
	if screen_mode_button.text == SCREEN_MODE_WINDOWED:
		screen_mode_button.text = SCREEN_MODE_FULLSCREEN
	else:
		screen_mode_button.text = SCREEN_MODE_WINDOWED
	_save_current_settings()


func _on_text_size_button_pressed() -> void:
	text_size_index = (text_size_index + 1) % TEXT_SIZE_OPTIONS.size()
	text_size_button.text = TEXT_SIZE_OPTIONS[text_size_index]
	_save_current_settings()


func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _load_settings_to_ui() -> void:
	is_loading_settings = true
	var save_manager: Variant = SAVE_MANAGER_SCRIPT.new()
	var settings_data: Dictionary = save_manager.load_settings()
	save_manager.free()

	var volume: int = clampi(int(settings_data.get("volume", 100)), 0, 100)
	volume_slider.value = volume
	volume_value_label.text = "%d%%" % volume
	screen_mode_button.text = _screen_mode_to_label(str(settings_data.get("screen_mode", "windowed")))
	_set_text_size_from_key(str(settings_data.get("text_size", "normal")))
	is_loading_settings = false


func _save_current_settings() -> void:
	var save_manager: Variant = SAVE_MANAGER_SCRIPT.new()
	save_manager.save_settings({
		"save_version": 1,
		"volume": int(volume_slider.value),
		"screen_mode": _get_screen_mode_key(),
		"text_size": TEXT_SIZE_KEYS[text_size_index]
	})
	save_manager.free()


func _get_screen_mode_key() -> String:
	if screen_mode_button.text == SCREEN_MODE_FULLSCREEN:
		return "fullscreen"

	return "windowed"


func _screen_mode_to_label(screen_mode: String) -> String:
	if screen_mode == "fullscreen":
		return SCREEN_MODE_FULLSCREEN

	return SCREEN_MODE_WINDOWED


func _set_text_size_from_key(text_size_key: String) -> void:
	var found_index: int = TEXT_SIZE_KEYS.find(text_size_key)
	if found_index < 0:
		found_index = 0

	text_size_index = found_index
	text_size_button.text = TEXT_SIZE_OPTIONS[text_size_index]
