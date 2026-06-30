extends Control

const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu/MainMenu.tscn"
const SCREEN_TRANSITION := preload("res://scripts/ui/common/screen_transition.gd")
const BUTTON_FEEDBACK := preload("res://scripts/ui/common/button_feedback.gd")
const AUDIO_FEEDBACK := preload("res://scripts/ui/common/audio_feedback.gd")
const SCREEN_MODE_WINDOWED := "창 모드"
const SCREEN_MODE_FULLSCREEN := "전체 화면"
const TEXT_SIZE_OPTIONS := ["보통", "크게", "작게"]
const TEXT_SIZE_KEYS := ["normal", "large", "small"]

@onready var volume_slider: HSlider = $CenterContainer/SettingsPanel/ContentContainer/VolumePanel/VolumeContainer/VolumeSlider
@onready var volume_value_label: Label = $CenterContainer/SettingsPanel/ContentContainer/VolumePanel/VolumeContainer/VolumeValueLabel
@onready var screen_mode_button: Button = $CenterContainer/SettingsPanel/ContentContainer/ScreenModePanel/ScreenModeContainer/ScreenModeButton
@onready var text_size_button: Button = $CenterContainer/SettingsPanel/ContentContainer/TextSizePanel/TextSizeContainer/TextSizeButton
@onready var text_preview_label: Label = $CenterContainer/SettingsPanel/ContentContainer/TextPreviewLabel
@onready var guide_label: Label = $CenterContainer/SettingsPanel/ContentContainer/GuideLabel

var text_size_index: int = 0
var is_loading_settings: bool = false


func _ready() -> void:
	AUDIO_FEEDBACK.play_bgm("main_menu")
	SCREEN_TRANSITION.fade_in(self)
	BUTTON_FEEDBACK.install(self)
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
	SCREEN_TRANSITION.transition_to_scene(self, MAIN_MENU_SCENE_PATH)


func _load_settings_to_ui() -> void:
	is_loading_settings = true
	var settings_data: Dictionary = SettingsManager.load_settings()
	SettingsManager.apply_all_settings(settings_data)

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
	SettingsManager.save_settings({
		"save_version": 1,
		"volume": int(volume_slider.value),
		"screen_mode": _get_screen_mode_key(),
		"text_size": TEXT_SIZE_KEYS[text_size_index]
	})


func _get_screen_mode_key() -> String:
	if screen_mode_button.text == SCREEN_MODE_FULLSCREEN:
		return "fullscreen"

	return "windowed"


func _screen_mode_to_label(screen_mode: String) -> String:
	if screen_mode == "fullscreen":
		return SCREEN_MODE_FULLSCREEN

	return SCREEN_MODE_WINDOWED


func _apply_screen_mode(screen_mode: String) -> void:
	SettingsManager.apply_display_settings({"screen_mode": screen_mode})


func _apply_volume(volume_percent: int) -> void:
	SettingsManager.apply_audio_settings({"volume": volume_percent})


func _apply_text_preview_size(text_size_key: String) -> void:
	SettingsManager.apply_text_size_settings({"text_size": text_size_key})


func _set_text_size_from_key(text_size_key: String) -> void:
	var found_index: int = TEXT_SIZE_KEYS.find(text_size_key)
	if found_index < 0:
		found_index = 0

	text_size_index = found_index
	text_size_button.text = TEXT_SIZE_OPTIONS[text_size_index]
	_apply_text_preview_size(TEXT_SIZE_KEYS[text_size_index])
