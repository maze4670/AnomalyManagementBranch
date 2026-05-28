extends Control

const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu/MainMenu.tscn"
const SCREEN_MODE_WINDOWED := "창 모드"
const SCREEN_MODE_FULLSCREEN := "전체 화면"
const TEXT_SIZE_OPTIONS := ["보통", "크게", "작게"]

@onready var volume_value_label: Label = $CenterContainer/ContentContainer/VolumeContainer/VolumeValueLabel
@onready var screen_mode_button: Button = $CenterContainer/ContentContainer/ScreenModeContainer/ScreenModeButton
@onready var text_size_button: Button = $CenterContainer/ContentContainer/TextSizeContainer/TextSizeButton

var text_size_index: int = 0


func _on_volume_slider_value_changed(value: float) -> void:
	volume_value_label.text = "%d%%" % int(value)


func _on_screen_mode_button_pressed() -> void:
	if screen_mode_button.text == SCREEN_MODE_WINDOWED:
		screen_mode_button.text = SCREEN_MODE_FULLSCREEN
	else:
		screen_mode_button.text = SCREEN_MODE_WINDOWED


func _on_text_size_button_pressed() -> void:
	text_size_index = (text_size_index + 1) % TEXT_SIZE_OPTIONS.size()
	text_size_button.text = TEXT_SIZE_OPTIONS[text_size_index]


func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
