extends Control

const WORK_SCENE_PATH := "res://scenes/work/WorkScreen.tscn"
const DATA_MANAGER_SCRIPT := preload("res://scripts/data/data_manager.gd")

@onready var body_label: Label = $CenterContainer/BriefingContainer/BodyLabel


func _ready() -> void:
	body_label.text = _build_briefing_text()


func _on_start_work_button_pressed() -> void:
	get_tree().change_scene_to_file(WORK_SCENE_PATH)


func _build_briefing_text() -> String:
	if GameState.active_reports.is_empty():
		return "금일 신규 보고는 없습니다."

	var data_manager: Variant = DATA_MANAGER_SCRIPT.new()
	var target_lines := PackedStringArray()

	for active_report in GameState.active_reports:
		if typeof(active_report) != TYPE_DICTIONARY:
			continue

		var active_report_data: Dictionary = active_report as Dictionary
		var case_id: String = str(active_report_data.get("case_id", ""))
		if case_id.is_empty():
			continue

		var case_document: Dictionary = data_manager.load_case_document(case_id)
		var display_id: String = str(case_document.get("display_id", ""))
		var alias: String = str(case_document.get("alias", ""))
		if display_id.is_empty() or alias.is_empty():
			continue

		target_lines.append("대상: %s / %s" % [display_id, alias])

	data_manager.free()

	if target_lines.is_empty():
		return "금일 신규 보고는 없습니다."

	return "금일 신규 보고가 접수되었습니다.\n%s" % "\n".join(target_lines)
