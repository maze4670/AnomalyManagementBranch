extends Control

const CASE_ID := "case_001"
const DATA_MANAGER_SCRIPT := preload("res://scripts/data/data_manager.gd")

@onready var report_button: Button = $RootContainer/ContentContainer/ReportListContainer/ReportButton
@onready var detail_text: RichTextLabel = $RootContainer/ContentContainer/DetailContainer/DetailText
@onready var completed_stamp_label: Label = $RootContainer/ContentContainer/DetailContainer/CompletedStampLabel
@onready var status_label: Label = $RootContainer/ContentContainer/DetailContainer/StatusLabel
@onready var choice_container: VBoxContainer = $RootContainer/ContentContainer/DetailContainer/ChoiceContainer
@onready var choice_button_a: Button = $RootContainer/ContentContainer/DetailContainer/ChoiceContainer/ChoiceButtonA
@onready var choice_button_b: Button = $RootContainer/ContentContainer/DetailContainer/ChoiceContainer/ChoiceButtonB
@onready var confirm_button: Button = $RootContainer/ContentContainer/DetailContainer/ConfirmButton

var case_document: Dictionary = {}
var case_reports: Dictionary = {}
var ui_messages: Dictionary = {}
var current_choices: Array = []
var selected_choice_index: int = -1
var report_completed: bool = false


func _ready() -> void:
	var data_manager: Variant = DATA_MANAGER_SCRIPT.new()
	case_document = data_manager.load_case_document(CASE_ID)
	case_reports = data_manager.load_case_reports(CASE_ID)
	ui_messages = data_manager.load_ui_messages()
	data_manager.free()
	_update_report_list()
	_set_report_controls_visible(false)


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
	var nodes: Array = case_reports.get("nodes", []) as Array
	if nodes.is_empty() or typeof(nodes[0]) != TYPE_DICTIONARY:
		detail_text.text = "보고서 상세를 표시할 수 없습니다."
		return

	var report_node: Dictionary = nodes[0] as Dictionary
	var detail_lines := PackedStringArray([
		str(case_document.get("display_id", "")),
		str(case_document.get("alias", "")),
		"",
		str(case_document.get("basic_description", "")),
		"",
		str(report_node.get("report_text", ""))
	])
	detail_text.text = "\n".join(detail_lines)
	current_choices = report_node.get("choices", []) as Array
	selected_choice_index = -1
	_set_report_controls_visible(true)
	if report_completed:
		status_label.text = str(ui_messages.get(
			"choice_confirmed",
			"관리자 명령이 접수되었습니다.\n후속 보고는 별도 절차에 따라 전달됩니다."
		))
		completed_stamp_label.text = str(ui_messages.get("completed_stamp", "[처리 완료]"))
	else:
		status_label.text = ""
		completed_stamp_label.text = ""
	_update_choice_buttons()


func _on_choice_button_a_pressed() -> void:
	_select_choice(0)


func _on_choice_button_b_pressed() -> void:
	_select_choice(1)


func _select_choice(choice_index: int) -> void:
	if report_completed:
		return

	selected_choice_index = choice_index
	status_label.text = ""
	_update_choice_buttons()


func _update_choice_buttons() -> void:
	_update_choice_button(choice_button_a, 0)
	_update_choice_button(choice_button_b, 1)
	confirm_button.disabled = current_choices.is_empty() or report_completed


func _update_choice_button(button: Button, choice_index: int) -> void:
	if choice_index >= current_choices.size() or typeof(current_choices[choice_index]) != TYPE_DICTIONARY:
		button.text = ""
		button.disabled = true
		return

	var choice: Dictionary = current_choices[choice_index] as Dictionary
	var choice_text := str(choice.get("choice_text", ""))
	button.text = choice_text
	button.button_pressed = choice_index == selected_choice_index
	button.disabled = report_completed


func _on_confirm_button_pressed() -> void:
	if report_completed:
		return

	if selected_choice_index < 0:
		status_label.text = "대응을 선택해 주십시오."
		return

	if not GameState.consume_action():
		status_label.text = "잔여 대응 절차가 없습니다."
		return

	report_completed = true
	status_label.text = str(ui_messages.get(
		"choice_confirmed",
		"관리자 명령이 접수되었습니다.\n후속 보고는 별도 절차에 따라 전달됩니다."
	))
	completed_stamp_label.text = str(ui_messages.get("completed_stamp", "[처리 완료]"))
	_update_choice_buttons()
	_update_work_screen_action_label()


func _update_work_screen_action_label() -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return

	var action_label: Label = current_scene.get_node_or_null("RootContainer/HeaderContainer/StatusContainer/ActionLabel") as Label
	if action_label == null:
		return

	action_label.text = GameState.get_action_label()


func _set_report_controls_visible(is_visible: bool) -> void:
	choice_container.visible = is_visible
	confirm_button.visible = is_visible
	status_label.visible = is_visible
	completed_stamp_label.visible = is_visible
