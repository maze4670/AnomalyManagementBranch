extends Control

const ENDING_SCENE_PATH := "res://scenes/ending/EndingScreen.tscn"
const DATA_MANAGER_SCRIPT := preload("res://scripts/data/data_manager.gd")
const SAVE_MANAGER_SCRIPT := preload("res://scripts/save/save_manager.gd")

@onready var screen_title_label: Label = $CenterContainer/FailurePanel/ContentContainer/HeaderPanel/ScreenTitleLabel
@onready var notice_label: Label = $CenterContainer/FailurePanel/ContentContainer/NoticeLabel
@onready var display_id_label: Label = $CenterContainer/FailurePanel/ContentContainer/CaseMetaContainer/DisplayIdLabel
@onready var alias_label: Label = $CenterContainer/FailurePanel/ContentContainer/CaseMetaContainer/AliasLabel
@onready var report_title_label: Label = $CenterContainer/FailurePanel/ContentContainer/ReportTitleLabel
@onready var report_body_label: RichTextLabel = $CenterContainer/FailurePanel/ContentContainer/ReportBodyLabel
@onready var confirm_button: Button = $CenterContainer/FailurePanel/ContentContainer/ConfirmButton

var current_case_id: String = ""
var current_node_id: String = ""
var current_report_node: Dictionary = {}


func _ready() -> void:
	_load_failure_report()
	_update_report_display()


func _load_failure_report() -> void:
	var failure_report: Dictionary = GameState.get_active_containment_failure_report()
	current_case_id = str(failure_report.get("case_id", ""))
	current_node_id = str(failure_report.get("node_id", ""))
	if typeof(failure_report.get("report_node", {})) == TYPE_DICTIONARY:
		current_report_node = failure_report.get("report_node", {}) as Dictionary


func _update_report_display() -> void:
	screen_title_label.text = "긴급 격리 실패 보고"
	notice_label.text = "관리 대상 이상현상이 통제 가능 범위를 벗어났습니다.\n아래 보고를 확인하십시오."

	var data_manager: Variant = DATA_MANAGER_SCRIPT.new()
	var case_document: Dictionary = data_manager.load_case_document(current_case_id)

	display_id_label.text = str(case_document.get("display_id", ""))
	alias_label.text = str(case_document.get("alias", ""))
	report_title_label.text = data_manager.get_report_label(current_report_node)
	report_body_label.text = data_manager.get_report_body(current_report_node)
	data_manager.free()

	confirm_button.disabled = current_case_id.is_empty() or current_node_id.is_empty() or current_report_node.is_empty()


func _on_confirm_button_pressed() -> void:
	if current_case_id.is_empty() or current_node_id.is_empty():
		return

	GameState.mark_report_completed(current_case_id, current_node_id, "")
	GameState.clear_delay_for_report(current_case_id, current_node_id)
	GameState.remove_active_report(current_case_id, current_node_id)
	GameState.clear_case_stabilized(current_case_id)
	_move_to_bad_ending()


func _move_to_bad_ending() -> void:
	var save_manager: Variant = SAVE_MANAGER_SCRIPT.new()
	save_manager.apply_ending_to_archive("bad", _get_current_run_archive_data())
	save_manager.delete_current_run_save()
	save_manager.free()
	get_tree().set_meta("ending_type", "bad")
	get_tree().set_meta("ending_reason", "containment_failure")
	get_tree().change_scene_to_file(ENDING_SCENE_PATH)


func _get_current_run_archive_data() -> Dictionary:
	return {
		"completed_reports": GameState.completed_reports,
		"active_reports": GameState.active_reports,
		"current_day": GameState.current_day,
		"ending_reason": "containment_failure"
	}
