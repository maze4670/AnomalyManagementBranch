extends Control

const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu/MainMenu.tscn"

@onready var title_label: Label = $CenterContainer/ContentContainer/TitleLabel
@onready var body_label: Label = $CenterContainer/ContentContainer/BodyLabel


func _ready() -> void:
	var ending_type: String = str(get_tree().get_meta("ending_type", "bad"))
	if ending_type == "good":
		title_label.text = "근무 완료"
		body_label.text = "60일간의 임시 지부장 근무가 종료되었습니다.\n당신은 해고되지 않고 임기를 마쳤습니다."
	else:
		title_label.text = "근무 종료"
		body_label.text = "기관 신뢰도 붕괴로 인해 지부장 직위가 해제되었습니다."


func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
