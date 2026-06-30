extends Control

const CONTAINMENT_FAILURE_SCENE_PATH := "res://scenes/ending/ContainmentFailureScreen.tscn"
const SCREEN_TRANSITION := preload("res://scripts/ui/common/screen_transition.gd")
const BUTTON_FEEDBACK := preload("res://scripts/ui/common/button_feedback.gd")
const AUDIO_FEEDBACK := preload("res://scripts/ui/common/audio_feedback.gd")
const SCREEN_MODE_WINDOWED := "창 모드"
const SCREEN_MODE_FULLSCREEN := "전체 화면"
const TEXT_SIZE_OPTIONS := ["보통", "크게", "작게"]
const TEXT_SIZE_KEYS := ["normal", "large", "small"]

@onready var current_day_label: Label = $RootContainer/HeaderContainer/StatusContainer/CurrentDayLabel
@onready var action_label: Label = $RootContainer/HeaderContainer/StatusContainer/ActionLabel
@onready var report_tab_button: Button = $RootContainer/TabButtonContainer/ReportTabButton
@onready var current_anomalies_tab_button: Button = $RootContainer/TabButtonContainer/CurrentAnomaliesTabButton
@onready var end_day_tab_button: Button = $RootContainer/TabButtonContainer/EndDayTabButton
@onready var report_tab: Control = $RootContainer/TabContent/ReportTab
@onready var current_anomalies_tab: Control = $RootContainer/TabContent/CurrentAnomaliesTab
@onready var end_day_tab: Control = $RootContainer/TabContent/EndDayTab
@onready var settings_button: Button = $SettingsButton
@onready var settings_overlay: ColorRect = $SettingsOverlay
@onready var volume_slider: HSlider = $SettingsOverlay/CenterContainer/SettingsPanel/Content/VolumePanel/Row/VolumeSlider
@onready var volume_value_label: Label = $SettingsOverlay/CenterContainer/SettingsPanel/Content/VolumePanel/Row/ValueLabel
@onready var screen_mode_button: Button = $SettingsOverlay/CenterContainer/SettingsPanel/Content/ScreenModePanel/Row/ScreenModeButton
@onready var text_size_button: Button = $SettingsOverlay/CenterContainer/SettingsPanel/Content/TextSizePanel/Row/TextSizeButton
@onready var text_preview_label: Label = $SettingsOverlay/CenterContainer/SettingsPanel/Content/TextPreviewLabel
@onready var close_settings_button: Button = $SettingsOverlay/CenterContainer/SettingsPanel/Content/ButtonRow/CloseButton
@onready var quit_confirm_overlay: ColorRect = $QuitConfirmOverlay
@onready var cancel_quit_button: Button = $QuitConfirmOverlay/CenterContainer/Panel/Content/ButtonRow/CancelQuitButton

var text_size_index: int = 0
var is_loading_settings: bool = false


func _ready() -> void:
	if GameState.has_active_containment_failure_report():
		call_deferred("_open_containment_failure_screen")
		return

	AUDIO_FEEDBACK.play_bgm("work")
	SCREEN_TRANSITION.fade_in(self)
	BUTTON_FEEDBACK.install(self)
	current_day_label.text = "%d일차" % GameState.current_day
	action_label.text = GameState.get_action_label()
	_show_tab(report_tab)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if quit_confirm_overlay.visible:
		_close_quit_confirmation()
		get_viewport().set_input_as_handled()
	elif settings_overlay.visible:
		_close_settings_overlay()
		get_viewport().set_input_as_handled()


func _open_containment_failure_screen() -> void:
	if bool(get_tree().get_meta("ui_transition_busy", false)):
		get_tree().change_scene_to_file(CONTAINMENT_FAILURE_SCENE_PATH)
		return
	SCREEN_TRANSITION.transition_to_scene(self, CONTAINMENT_FAILURE_SCENE_PATH)


func _show_tab(tab_to_show: Control) -> void:
	report_tab.visible = tab_to_show == report_tab
	current_anomalies_tab.visible = tab_to_show == current_anomalies_tab
	end_day_tab.visible = tab_to_show == end_day_tab
	report_tab_button.button_pressed = tab_to_show == report_tab
	current_anomalies_tab_button.button_pressed = tab_to_show == current_anomalies_tab
	end_day_tab_button.button_pressed = tab_to_show == end_day_tab


func _on_report_tab_button_pressed() -> void:
	_show_tab(report_tab)


func _on_current_anomalies_tab_button_pressed() -> void:
	_show_tab(current_anomalies_tab)


func _on_end_day_tab_button_pressed() -> void:
	_show_tab(end_day_tab)


func _on_settings_button_pressed() -> void:
	_load_settings_to_ingame_ui()
	settings_overlay.visible = true
	close_settings_button.grab_focus()


func _on_settings_close_button_pressed() -> void:
	_close_settings_overlay()


func _close_settings_overlay() -> void:
	quit_confirm_overlay.visible = false
	settings_overlay.visible = false
	settings_button.grab_focus()


func _on_ingame_volume_slider_value_changed(value: float) -> void:
	volume_value_label.text = "%d%%" % int(value)
	_apply_volume(int(value))
	if not is_loading_settings:
		_save_ingame_settings()


func _on_ingame_screen_mode_button_pressed() -> void:
	if screen_mode_button.text == SCREEN_MODE_WINDOWED:
		screen_mode_button.text = SCREEN_MODE_FULLSCREEN
	else:
		screen_mode_button.text = SCREEN_MODE_WINDOWED
	_apply_screen_mode(_get_screen_mode_key())
	_save_ingame_settings()


func _on_ingame_text_size_button_pressed() -> void:
	text_size_index = (text_size_index + 1) % TEXT_SIZE_OPTIONS.size()
	text_size_button.text = TEXT_SIZE_OPTIONS[text_size_index]
	_apply_text_preview_size(TEXT_SIZE_KEYS[text_size_index])
	_save_ingame_settings()


func _on_quit_request_button_pressed() -> void:
	quit_confirm_overlay.visible = true
	cancel_quit_button.grab_focus()


func _on_quit_cancel_button_pressed() -> void:
	_close_quit_confirmation()


func _close_quit_confirmation() -> void:
	quit_confirm_overlay.visible = false
	close_settings_button.grab_focus()


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _load_settings_to_ingame_ui() -> void:
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


func _save_ingame_settings() -> void:
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
