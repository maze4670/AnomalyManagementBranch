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
var current_node_id: String = ""
var current_report_node: Dictionary = {}
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

	current_report_node = _get_first_active_report_node()
	if current_report_node.is_empty():
		report_button.text = "현재 도착한 보고가 없습니다."
		report_button.disabled = true
		detail_text.text = "현재 도착한 보고가 없습니다."
		_set_report_controls_visible(false)
		return

	if display_id.is_empty() or alias.is_empty():
		report_button.text = "표시할 보고서가 없습니다."
		report_button.disabled = true
		return

	var active_node_id: String = str(current_report_node.get("node_id", ""))
	var delayed_label: String = _get_delayed_label(CASE_ID, active_node_id)
	if delayed_label.is_empty():
		report_button.text = "[%s: %s]" % [display_id, alias]
	else:
		report_button.text = "[%s: %s] %s" % [display_id, alias, delayed_label]
	report_button.disabled = false


func _on_report_button_pressed() -> void:
	if current_report_node.is_empty():
		detail_text.text = "보고서 상세를 표시할 수 없습니다."
		return

	var report_node: Dictionary = current_report_node
	current_node_id = str(report_node.get("node_id", ""))
	var delayed_label: String = _get_delayed_label(CASE_ID, current_node_id)
	var detail_lines := PackedStringArray([
		str(case_document.get("display_id", "")),
		str(case_document.get("alias", ""))
	])
	if not delayed_label.is_empty():
		detail_lines.append(delayed_label)
	detail_lines.append_array(PackedStringArray([
		"",
		str(case_document.get("basic_description", "")),
		"",
		str(report_node.get("report_text", ""))
	]))
	detail_text.text = "\n".join(detail_lines)
	current_choices = report_node.get("choices", []) as Array
	report_completed = GameState.is_report_completed(CASE_ID, current_node_id)
	selected_choice_index = _find_choice_index(GameState.get_completed_report_choice(CASE_ID, current_node_id))
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

	var selected_choice: Dictionary = current_choices[selected_choice_index] as Dictionary
	var selected_choice_id := str(selected_choice.get("choice_id", ""))
	var next_node_id := str(selected_choice.get("next_node_id", ""))
	GameState.mark_report_completed(CASE_ID, current_node_id, selected_choice_id)
	GameState.clear_delay_for_report(CASE_ID, current_node_id)
	GameState.record_completed_choice_for_end_day(CASE_ID, current_node_id, selected_choice_id, next_node_id)
	report_completed = true
	status_label.text = str(ui_messages.get(
		"choice_confirmed",
		"관리자 명령이 접수되었습니다.\n후속 보고는 별도 절차에 따라 전달됩니다."
	))
	completed_stamp_label.text = str(ui_messages.get("completed_stamp", "[처리 완료]"))
	_update_choice_buttons()
	_update_report_list()
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


func _find_choice_index(choice_id: String) -> int:
	if choice_id.is_empty():
		return -1

	for index in range(current_choices.size()):
		if typeof(current_choices[index]) == TYPE_DICTIONARY:
			var choice: Dictionary = current_choices[index] as Dictionary
			if str(choice.get("choice_id", "")) == choice_id:
				return index

	return -1


func _get_first_active_report_node() -> Dictionary:
	for active_report in GameState.active_reports:
		if typeof(active_report) != TYPE_DICTIONARY:
			continue

		var active_report_data: Dictionary = active_report as Dictionary
		if str(active_report_data.get("case_id", "")) != CASE_ID:
			continue

		var node_id: String = str(active_report_data.get("node_id", ""))
		var report_node: Dictionary = _find_report_node(node_id)
		if not report_node.is_empty():
			return report_node

	return {}


func _find_report_node(node_id: String) -> Dictionary:
	var nodes: Array = case_reports.get("nodes", []) as Array
	for node in nodes:
		if typeof(node) == TYPE_DICTIONARY:
			var report_node: Dictionary = node as Dictionary
			if str(report_node.get("node_id", "")) == node_id:
				return report_node

	return {}


func _get_delayed_label(case_id: String, node_id: String) -> String:
	if GameState.get_report_delay_days(case_id, node_id) <= 0:
		return ""

	return str(ui_messages.get("delayed_label", "[처리 지연]"))
