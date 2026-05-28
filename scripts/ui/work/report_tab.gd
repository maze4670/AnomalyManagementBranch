extends Control

const CASE_ID := "case_001"
const DATA_MANAGER_SCRIPT := preload("res://scripts/data/data_manager.gd")

@onready var report_button: Button = $RootContainer/ContentContainer/ReportListContainer/ReportButton
@onready var detail_text: RichTextLabel = $RootContainer/ContentContainer/DetailContainer/DetailText

var case_document: Dictionary = {}
var case_reports: Dictionary = {}


func _ready() -> void:
	var data_manager := DATA_MANAGER_SCRIPT.new()
	case_document = data_manager.load_case_document(CASE_ID)
	case_reports = data_manager.load_case_reports(CASE_ID)
	data_manager.free()
	_update_report_list()


func _update_report_list() -> void:
	var display_id := str(case_document.get("display_id", ""))
	var alias := str(case_document.get("alias", ""))

	if display_id.is_empty() or alias.is_empty():
		report_button.text = "표시할 보고서가 없습니다."
		report_button.disabled = true
		return

	report_button.text = "[%s: %s]" % [display_id, alias]
	report_button.disabled = false


func _on_report_button_pressed() -> void:
	var nodes: Array = case_reports.get("nodes", [])
	if nodes.is_empty() or typeof(nodes[0]) != TYPE_DICTIONARY:
		detail_text.text = "보고서 상세를 표시할 수 없습니다."
		return

	var report_node: Dictionary = nodes[0]
	var choices: Array = report_node.get("choices", [])
	var choice_lines := PackedStringArray()

	for choice in choices:
		if typeof(choice) == TYPE_DICTIONARY:
			var choice_text := str(choice.get("choice_text", ""))
			if not choice_text.is_empty():
				choice_lines.append("- %s" % choice_text)

	var detail_lines := PackedStringArray([
		str(case_document.get("display_id", "")),
		str(case_document.get("alias", "")),
		"",
		str(case_document.get("basic_description", "")),
		"",
		str(report_node.get("report_text", "")),
		"",
		"대응 선택지",
		"\n".join(choice_lines)
	])
	detail_text.text = "\n".join(detail_lines)
