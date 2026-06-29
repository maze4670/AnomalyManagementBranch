extends Control

const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu/MainMenu.tscn"
const SCREEN_TRANSITION := preload("res://scripts/ui/common/screen_transition.gd")
const BUTTON_FEEDBACK := preload("res://scripts/ui/common/button_feedback.gd")
const TEXT_REVEAL := preload("res://scripts/ui/common/text_reveal_label.gd")
const AUDIO_FEEDBACK := preload("res://scripts/ui/common/audio_feedback.gd")

@onready var title_label: Label = $CenterContainer/ResultPanel/ContentContainer/HeaderPanel/TitleLabel
@onready var body_label: Label = $CenterContainer/ResultPanel/ContentContainer/BodyLabel
@onready var result_panel: PanelContainer = $CenterContainer/ResultPanel
@onready var header_panel: PanelContainer = $CenterContainer/ResultPanel/ContentContainer/HeaderPanel
@onready var body_divider: HSeparator = $CenterContainer/ResultPanel/ContentContainer/BodyDivider
@onready var footer_divider: HSeparator = $CenterContainer/ResultPanel/ContentContainer/FooterDivider
@onready var main_menu_button: Button = $CenterContainer/ResultPanel/ContentContainer/MainMenuButton
@onready var bad_ending_overlay: ColorRect = $BadEndingOverlay
@onready var bad_warning_line: ColorRect = $CenterContainer/ResultPanel/ContentContainer/BadWarningLine
@onready var bad_panel_style_template: PanelContainer = $BadPanelStyleTemplate
@onready var bad_header_style_template: PanelContainer = $BadHeaderStyleTemplate
@onready var bad_button_style_template: Button = $BadButtonStyleTemplate


func _ready() -> void:
	AUDIO_FEEDBACK.play_bgm("work")
	SCREEN_TRANSITION.fade_in(self)
	BUTTON_FEEDBACK.install(self)
	var ending_type: String = str(get_tree().get_meta("ending_type", "bad"))
	if ending_type == "good":
		title_label.add_theme_color_override("font_color", Color(0.55, 0.82, 0.72, 1.0))
		title_label.text = "근무 완료"
		body_label.text = "60일간의 임시 지부장 근무가 종료되었습니다.\n당신은 해고되지 않고 임기를 마쳤습니다."
	else:
		_apply_bad_ending_style()
		title_label.text = "직위 해제 통지"
		body_label.text = "기관 신뢰도 붕괴로 인해 지부장 직위가 해제되었습니다."
	TEXT_REVEAL.reveal(self, body_label, body_label.text, 55.0)


func _apply_bad_ending_style() -> void:
	title_label.add_theme_color_override("font_color", Color(0.88, 0.58, 0.43, 1.0))
	result_panel.add_theme_stylebox_override("panel", bad_panel_style_template.get_theme_stylebox("panel"))
	header_panel.add_theme_stylebox_override("panel", bad_header_style_template.get_theme_stylebox("panel"))
	for style_name in ["normal", "hover", "pressed", "focus"]:
		main_menu_button.add_theme_stylebox_override(style_name, bad_button_style_template.get_theme_stylebox(style_name))
	main_menu_button.add_theme_color_override("font_color", Color(0.94, 0.88, 0.82, 1.0))
	main_menu_button.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.88, 1.0))
	main_menu_button.add_theme_color_override("font_pressed_color", Color(0.88, 0.78, 0.72, 1.0))
	body_divider.self_modulate = Color(0.68, 0.35, 0.27, 0.82)
	footer_divider.self_modulate = Color(0.68, 0.35, 0.27, 0.82)
	bad_ending_overlay.visible = true
	bad_warning_line.visible = true


func _on_main_menu_button_pressed() -> void:
	SCREEN_TRANSITION.transition_to_scene(self, MAIN_MENU_SCENE_PATH)
