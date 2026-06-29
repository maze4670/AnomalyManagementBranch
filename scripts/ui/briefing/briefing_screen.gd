extends Control

const WORK_SCENE_PATH := "res://scenes/work/WorkScreen.tscn"
const DATA_MANAGER_SCRIPT := preload("res://scripts/data/data_manager.gd")
const SCREEN_TRANSITION := preload("res://scripts/ui/common/screen_transition.gd")
const BUTTON_FEEDBACK := preload("res://scripts/ui/common/button_feedback.gd")
const TEXT_REVEAL := preload("res://scripts/ui/common/text_reveal_label.gd")
const AUDIO_FEEDBACK := preload("res://scripts/ui/common/audio_feedback.gd")

@onready var body_label: Label = $CenterContainer/BriefingPanel/BriefingContainer/BodyScrollContainer/BodyLabel


func _ready() -> void:
	AUDIO_FEEDBACK.play_bgm("work")
	SCREEN_TRANSITION.fade_in(self)
	BUTTON_FEEDBACK.install(self)
	var briefing_text: String = _build_briefing_text()
	TEXT_REVEAL.reveal(self, body_label, briefing_text, 55.0)


func _on_start_work_button_pressed() -> void:
	SCREEN_TRANSITION.transition_to_scene(self, WORK_SCENE_PATH)


func _build_briefing_text() -> String:
	if GameState.active_reports.is_empty():
		return "금일 신규 보고는 없습니다."

	var data_manager: Variant = DATA_MANAGER_SCRIPT.new()
	var delayed_report_count: int = 0
	var new_report_lines := PackedStringArray()

	for active_report in GameState.active_reports:
		if typeof(active_report) != TYPE_DICTIONARY:
			continue

		var active_report_data: Dictionary = active_report as Dictionary
		var case_id: String = str(active_report_data.get("case_id", ""))
		var node_id: String = str(active_report_data.get("node_id", ""))
		if case_id.is_empty() or node_id.is_empty():
			continue

		if GameState.get_report_delay_days(case_id, node_id) > 0:
			delayed_report_count += 1
			continue

		var case_document: Dictionary = data_manager.load_case_document(case_id)
		var display_id: String = str(case_document.get("display_id", ""))
		var alias: String = str(case_document.get("alias", ""))
		if display_id.is_empty() or alias.is_empty():
			continue

		new_report_lines.append("대상: %s / %s" % [display_id, alias])

	data_manager.free()

	var briefing_lines := PackedStringArray()
	if delayed_report_count > 0:
		briefing_lines.append("현재 처리 지연 보고: %d개" % delayed_report_count)

	if not new_report_lines.is_empty():
		if not briefing_lines.is_empty():
			briefing_lines.append("")
		briefing_lines.append("금일 신규 보고가 접수되었습니다.")
		briefing_lines.append_array(new_report_lines)

	if briefing_lines.is_empty():
		return "금일 신규 보고는 없습니다."

	return "\n".join(briefing_lines)
