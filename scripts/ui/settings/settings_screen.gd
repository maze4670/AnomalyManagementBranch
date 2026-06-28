extends Control

const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu/MainMenu.tscn"
const SAVE_MANAGER_SCRIPT := preload("res://scripts/save/save_manager.gd")
const SCREEN_MODE_WINDOWED := "창 모드"
const SCREEN_MODE_FULLSCREEN := "전체 화면"
const TEXT_SIZE_OPTIONS := ["보통", "크게", "작게"]
const TEXT_SIZE_KEYS := ["normal", "large", "small"]
const TEXT_PREVIEW_FONT_SIZES := {
	"small": 14,
	"normal": 18,
	"large": 24
}

@onready var volume_slider: HSlider = $CenterContainer/SettingsPanel/ContentContainer/VolumePanel/VolumeContainer/VolumeSlider
@onready var volume_value_label: Label = $CenterContainer/SettingsPanel/ContentContainer/VolumePanel/VolumeContainer/VolumeValueLabel
@onready var screen_mode_button: Button = $CenterContainer/SettingsPanel/ContentContainer/ScreenModePanel/ScreenModeContainer/ScreenModeButton
@onready var text_size_button: Button = $CenterContainer/SettingsPanel/ContentContainer/TextSizePanel/TextSizeContainer/TextSizeButton
@onready var text_preview_label: Label = $CenterContainer/SettingsPanel/ContentContainer/TextPreviewLabel
@onready var guide_label: Label = $CenterContainer/SettingsPanel/ContentContainer/GuideLabel

var text_size_index: int = 0
var is_loading_settings: bool = false


func _ready() -> void:
	guide_label.text = "설정값은 자동으로 저장됩니다."
	_load_settings_to_ui()


func _on_volume_slider_value_changed(value: float) -> void:
	volume_value_label.text = "%d%%" % int(value)
	_apply_volume(int(value))
	if not is_loading_settings:
		_save_current_settings()


func _on_screen_mode_button_pressed() -> void:
	if screen_mode_button.text == SCREEN_MODE_WINDOWED:
		screen_mode_button.text = SCREEN_MODE_FULLSCREEN
	else:
		screen_mode_button.text = SCREEN_MODE_WINDOWED
	_apply_screen_mode(_get_screen_mode_key())
	_save_current_settings()


func _on_text_size_button_pressed() -> void:
	text_size_index = (text_size_index + 1) % TEXT_SIZE_OPTIONS.size()
	text_size_button.text = TEXT_SIZE_OPTIONS[text_size_index]
	_apply_text_preview_size(TEXT_SIZE_KEYS[text_size_index])
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
	_apply_volume(volume)
	var screen_mode: String = str(settings_data.get("screen_mode", "windowed"))
	screen_mode_button.text = _screen_mode_to_label(screen_mode)
	_apply_screen_mode(screen_mode)
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


func _apply_screen_mode(screen_mode: String) -> void:
	var window: Window = get_window()

	if screen_mode == "fullscreen":
		window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	else:
		window.mode = Window.MODE_WINDOWED


func _apply_volume(volume_percent: int) -> void:
	var master_bus_index: int = AudioServer.get_bus_index("Master")
	if master_bus_index < 0:
		return

	var clamped_volume: int = clampi(volume_percent, 0, 100)
	if clamped_volume <= 0:
		AudioServer.set_bus_volume_db(master_bus_index, -80.0)
		return

	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(float(clamped_volume) / 100.0))


func _apply_text_preview_size(text_size_key: String) -> void:
	var font_size: int = int(TEXT_PREVIEW_FONT_SIZES.get(text_size_key, TEXT_PREVIEW_FONT_SIZES["normal"]))
	text_preview_label.add_theme_font_size_override("font_size", font_size)


func _set_text_size_from_key(text_size_key: String) -> void:
	var found_index: int = TEXT_SIZE_KEYS.find(text_size_key)
	if found_index < 0:
		found_index = 0

	text_size_index = found_index
	text_size_button.text = TEXT_SIZE_OPTIONS[text_size_index]
	_apply_text_preview_size(TEXT_SIZE_KEYS[text_size_index])
