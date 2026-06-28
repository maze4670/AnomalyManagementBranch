extends Control

const ENDING_SCENE_PATH := "res://scenes/ending/EndingScreen.tscn"
const DATA_MANAGER_SCRIPT := preload("res://scripts/data/data_manager.gd")
const SAVE_MANAGER_SCRIPT := preload("res://scripts/save/save_manager.gd")

@onready var report_list_container: VBoxContainer = $RootContainer/ContentContainer/ReportListPanel/ReportListContainer
@onready var report_list_label: Label = $RootContainer/ContentContainer/ReportListPanel/ReportListContainer/ReportListLabel
@onready var report_button: Button = $RootContainer/ContentContainer/ReportListPanel/ReportListContainer/ReportButton
@onready var detail_header_text: RichTextLabel = $RootContainer/ContentContainer/ElectronicReportContainer/DetailHeaderPanel/CentralReportContent/DetailHeaderText
@onready var detail_text: RichTextLabel = $RootContainer/ContentContainer/ElectronicReportContainer/DetailHeaderPanel/CentralReportContent/DetailBodyPanel/DetailScrollContainer/DetailText
@onready var completed_stamp_label: Label = $RootContainer/ContentContainer/ElectronicReportContainer/DetailHeaderPanel/CentralReportContent/CompletedStampLabel
@onready var status_label: Label = $RootContainer/ContentContainer/ElectronicReportContainer/DetailHeaderPanel/CentralReportContent/StatusLabel
@onready var confirmed_choice_label: Label = $RootContainer/ContentContainer/ElectronicReportContainer/DetailHeaderPanel/CentralReportContent/ConfirmedChoiceLabel
@onready var choice_panel: PanelContainer = $RootContainer/ContentContainer/ElectronicReportContainer/DetailHeaderPanel/CentralReportContent/ChoicePanel
@onready var choice_container: VBoxContainer = $RootContainer/ContentContainer/ElectronicReportContainer/DetailHeaderPanel/CentralReportContent/ChoicePanel/ChoiceContainer
@onready var choice_button_a: Button = $RootContainer/ContentContainer/ElectronicReportContainer/DetailHeaderPanel/CentralReportContent/ChoicePanel/ChoiceContainer/ChoiceButtonA
@onready var choice_button_b: Button = $RootContainer/ContentContainer/ElectronicReportContainer/DetailHeaderPanel/CentralReportContent/ChoicePanel/ChoiceContainer/ChoiceButtonB
@onready var confirm_button: Button = $RootContainer/ContentContainer/ElectronicReportContainer/DetailHeaderPanel/CentralReportContent/ConfirmButton
@onready var pdf_meta_text: RichTextLabel = $RootContainer/ContentContainer/PDFDocumentPanel/PDFContentMargin/PDFContentContainer/PDFTopRow/PDFMetaText
@onready var pdf_description_text: RichTextLabel = $RootContainer/ContentContainer/PDFDocumentPanel/PDFContentMargin/PDFContentContainer/PDFScrollContainer/PDFDocumentBody/PDFDescriptionText
@onready var anomaly_image_slot: Control = $RootContainer/ContentContainer/PDFDocumentPanel/PDFContentMargin/PDFContentContainer/PDFTopRow/AnomalyImageSlot
@onready var anomaly_image_rect: TextureRect = $RootContainer/ContentContainer/PDFDocumentPanel/PDFContentMargin/PDFContentContainer/PDFTopRow/AnomalyImageSlot/AnomalyImageRect

var case_documents: Dictionary = {}
var case_reports_by_id: Dictionary = {}
var ui_messages: Dictionary = {}
var current_case_id: String = ""
var current_node_id: String = ""
var current_report_node: Dictionary = {}
var current_choices: Array = []
var choice_buttons: Array[Button] = []
var selected_choice_index: int = -1
var report_completed: bool = false


func _ready() -> void:
	var data_manager: Variant = DATA_MANAGER_SCRIPT.new()
	ui_messages = data_manager.load_ui_messages()
	data_manager.free()

	choice_buttons = [choice_button_a, choice_button_b]
	report_button.visible = false
	_update_report_list()
	_set_report_controls_visible(false)


func _update_report_list() -> void:
	_clear_report_list_buttons()
	var visible_report_count: int = 0

	for active_report in GameState.active_reports:
		if typeof(active_report) != TYPE_DICTIONARY:
			continue

		var active_report_data: Dictionary = active_report as Dictionary
		var case_id: String = str(active_report_data.get("case_id", ""))
		var node_id: String = str(active_report_data.get("node_id", ""))
		if case_id.is_empty() or node_id.is_empty():
			continue

		var report_node: Dictionary = _find_report_node(case_id, node_id)
		if report_node.is_empty():
			continue

		var report_list_button: Button = Button.new()
		report_list_button.custom_minimum_size = report_button.custom_minimum_size
		report_list_button.add_theme_stylebox_override("normal", report_button.get_theme_stylebox("normal"))
		report_list_button.add_theme_stylebox_override("hover", report_button.get_theme_stylebox("hover"))
		report_list_button.add_theme_stylebox_override("pressed", report_button.get_theme_stylebox("pressed"))
		report_list_button.add_theme_stylebox_override("focus", report_button.get_theme_stylebox("focus"))
		report_list_button.add_theme_color_override("font_color", report_button.get_theme_color("font_color"))
		report_list_button.add_theme_color_override("font_hover_color", report_button.get_theme_color("font_hover_color"))
		report_list_button.add_theme_font_size_override("font_size", report_button.get_theme_font_size("font_size"))
		report_list_button.text = _get_report_list_label(case_id, node_id)
		report_list_button.pressed.connect(_on_report_list_button_pressed.bind(case_id, node_id))
		report_list_container.add_child(report_list_button)
		visible_report_count += 1

	if visible_report_count == 0:
		detail_text.text = "현재 도착한 보고가 없습니다."
		_set_report_controls_visible(false)
		return

	if current_case_id.is_empty() or not _is_active_report(current_case_id, current_node_id):
		detail_text.text = "보고서 목록에서 항목을 선택해 주세요."
		_set_report_controls_visible(false)


func _clear_report_list_buttons() -> void:
	for child in report_list_container.get_children():
		if child == report_list_label or child == report_button:
			continue

		child.queue_free()


func _get_report_list_label(case_id: String, node_id: String) -> String:
	var case_document: Dictionary = _get_case_document(case_id)
	var display_id: String = str(case_document.get("display_id", case_id))
	var alias: String = str(case_document.get("alias", ""))
	var label_text: String = display_id
	if not alias.is_empty():
		label_text = "%s / %s" % [display_id, alias]

	var delayed_label: String = _get_delayed_label(case_id, node_id)
	if not delayed_label.is_empty():
		label_text = "%s %s" % [label_text, delayed_label]

	return label_text


func _on_report_button_pressed() -> void:
	for active_report in GameState.active_reports:
		if typeof(active_report) != TYPE_DICTIONARY:
			continue

		var active_report_data: Dictionary = active_report as Dictionary
		_on_report_list_button_pressed(
			str(active_report_data.get("case_id", "")),
			str(active_report_data.get("node_id", ""))
		)
		return


func _on_report_list_button_pressed(case_id: String, node_id: String) -> void:
	var report_node: Dictionary = _find_report_node(case_id, node_id)
	if report_node.is_empty():
		detail_text.text = "보고서 상세를 표시할 수 없습니다."
		_set_report_controls_visible(false)
		return

	current_case_id = case_id
	current_node_id = node_id
	current_report_node = report_node
	current_choices = report_node.get("choices", []) as Array
	report_completed = GameState.is_report_completed(current_case_id, current_node_id)
	selected_choice_index = _find_choice_index(GameState.get_completed_report_choice(current_case_id, current_node_id))

	_show_current_report_detail()
	_set_report_controls_visible(true)
	_update_choice_buttons()


func _show_current_report_detail() -> void:
	var case_document: Dictionary = _get_case_document(current_case_id)
	var header_lines: PackedStringArray = PackedStringArray()
	var report_title: String = _get_report_title(current_report_node)
	if not report_title.is_empty():
		header_lines.append(report_title)

	var delayed_label: String = _get_delayed_label(current_case_id, current_node_id)
	if not delayed_label.is_empty():
		header_lines.append(delayed_label)
	detail_header_text.text = "\n".join(header_lines)

	var document_meta_lines: PackedStringArray = PackedStringArray([
		"식별명: %s" % str(case_document.get("display_id", "")),
		"별칭: %s" % str(case_document.get("alias", "")),
		"분류: %s" % str(case_document.get("category", ""))
	])
	pdf_meta_text.text = "\n".join(document_meta_lines)
	pdf_description_text.text = str(case_document.get("basic_description", ""))
	detail_text.text = _get_report_body(current_report_node)
	_update_anomaly_image(case_document)

	if report_completed:
		status_label.text = str(ui_messages.get(
			"choice_confirmed",
			"관리자 명령이 접수되었습니다.\n후속 보고는 별도 절차에 따라 전달됩니다."
		))
		completed_stamp_label.text = str(ui_messages.get("completed_stamp", "[처리 완료]"))
		completed_stamp_label.visible = true
		_update_confirmed_choice_label()
	else:
		status_label.text = ""
		completed_stamp_label.text = ""
		completed_stamp_label.visible = false
		confirmed_choice_label.text = ""
		confirmed_choice_label.visible = false


func _update_confirmed_choice_label() -> void:
	if selected_choice_index < 0 or selected_choice_index >= current_choices.size():
		confirmed_choice_label.text = ""
		confirmed_choice_label.visible = false
		return
	if typeof(current_choices[selected_choice_index]) != TYPE_DICTIONARY:
		confirmed_choice_label.text = ""
		confirmed_choice_label.visible = false
		return

	var selected_choice: Dictionary = current_choices[selected_choice_index] as Dictionary
	var selected_choice_text: String = str(selected_choice.get("choice_text", ""))
	if selected_choice_text.is_empty():
		confirmed_choice_label.text = ""
		confirmed_choice_label.visible = false
		return

	confirmed_choice_label.text = "확정된 대응 절차: %s" % selected_choice_text
	confirmed_choice_label.visible = true


func _on_choice_button_a_pressed() -> void:
	_select_choice(0)


func _on_choice_button_b_pressed() -> void:
	_select_choice(1)


func _select_choice(choice_index: int) -> void:
	if report_completed:
		return
	if choice_index >= current_choices.size():
		return

	selected_choice_index = choice_index
	status_label.text = ""
	_update_choice_buttons()


func _update_choice_buttons() -> void:
	_ensure_choice_buttons()
	for choice_index in range(choice_buttons.size()):
		_update_choice_button(choice_buttons[choice_index], choice_index)

	confirm_button.disabled = report_completed or (current_choices.is_empty() and not _is_terminal_report_node(current_report_node))


func _ensure_choice_buttons() -> void:
	while choice_buttons.size() < current_choices.size():
		var choice_button: Button = Button.new()
		choice_button.custom_minimum_size = choice_button_a.custom_minimum_size
		choice_button.toggle_mode = choice_button_a.toggle_mode
		choice_button.add_theme_stylebox_override("normal", choice_button_a.get_theme_stylebox("normal"))
		choice_button.add_theme_stylebox_override("hover", choice_button_a.get_theme_stylebox("hover"))
		choice_button.add_theme_stylebox_override("pressed", choice_button_a.get_theme_stylebox("pressed"))
		choice_button.add_theme_stylebox_override("focus", choice_button_a.get_theme_stylebox("focus"))
		choice_button.add_theme_stylebox_override("disabled", choice_button_a.get_theme_stylebox("disabled"))
		choice_button.add_theme_color_override("font_color", choice_button_a.get_theme_color("font_color"))
		choice_button.add_theme_color_override("font_hover_color", choice_button_a.get_theme_color("font_hover_color"))
		choice_button.add_theme_color_override("font_pressed_color", choice_button_a.get_theme_color("font_pressed_color"))
		choice_button.add_theme_color_override("font_disabled_color", choice_button_a.get_theme_color("font_disabled_color"))
		choice_button.add_theme_font_size_override("font_size", choice_button_a.get_theme_font_size("font_size"))
		choice_button.text = ""
		choice_button.button_pressed = false
		choice_button.disabled = true
		choice_button.pressed.connect(_select_choice.bind(choice_buttons.size()))
		choice_container.add_child(choice_button)
		choice_buttons.append(choice_button)


func _update_choice_button(button: Button, choice_index: int) -> void:
	if choice_index >= current_choices.size() or typeof(current_choices[choice_index]) != TYPE_DICTIONARY:
		button.text = ""
		button.button_pressed = false
		button.disabled = true
		button.visible = false
		return

	var choice: Dictionary = current_choices[choice_index] as Dictionary
	button.visible = true
	button.text = str(choice.get("choice_text", ""))
	button.button_pressed = choice_index == selected_choice_index
	button.disabled = report_completed
	if report_completed and choice_index == selected_choice_index:
		button.add_theme_stylebox_override("disabled", choice_button_a.get_theme_stylebox("pressed"))
		button.add_theme_color_override("font_disabled_color", choice_button_a.get_theme_color("font_pressed_color"))
	else:
		button.add_theme_stylebox_override("disabled", choice_button_a.get_theme_stylebox("normal"))
		button.add_theme_color_override("font_disabled_color", Color(0.55, 0.6, 0.59, 1))


func _on_confirm_button_pressed() -> void:
	if report_completed:
		return

	if current_case_id.is_empty() or current_node_id.is_empty():
		status_label.text = "보고서를 선택해 주십시오."
		return

	if _is_terminal_report_node(current_report_node):
		_confirm_terminal_report()
		return

	if selected_choice_index < 0:
		status_label.text = "대응을 선택해 주십시오."
		return

	if selected_choice_index >= current_choices.size() or typeof(current_choices[selected_choice_index]) != TYPE_DICTIONARY:
		status_label.text = "대응을 선택해 주십시오."
		return

	if not GameState.consume_action():
		status_label.text = "잔여 대응 절차가 없습니다."
		return

	var selected_choice: Dictionary = current_choices[selected_choice_index] as Dictionary
	var selected_choice_id: String = str(selected_choice.get("choice_id", ""))
	var next_node_id: String = str(selected_choice.get("next_node_id", ""))
	GameState.mark_report_completed(current_case_id, current_node_id, selected_choice_id)
	GameState.clear_delay_for_report(current_case_id, current_node_id)
	GameState.record_completed_choice_for_end_day(current_case_id, current_node_id, selected_choice_id, next_node_id)

	report_completed = true
	selected_choice_index = _find_choice_index(selected_choice_id)
	_show_current_report_detail()
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
	if not is_visible:
		_clear_anomaly_image()
		detail_header_text.text = ""
		pdf_meta_text.text = ""
		pdf_description_text.text = ""
		completed_stamp_label.visible = false
		confirmed_choice_label.text = ""
		confirmed_choice_label.visible = false

	choice_panel.visible = is_visible
	confirm_button.visible = is_visible
	status_label.visible = is_visible


func _find_choice_index(choice_id: String) -> int:
	if choice_id.is_empty():
		return -1

	for index in range(current_choices.size()):
		if typeof(current_choices[index]) == TYPE_DICTIONARY:
			var choice: Dictionary = current_choices[index] as Dictionary
			if str(choice.get("choice_id", "")) == choice_id:
				return index

	return -1


func _is_active_report(case_id: String, node_id: String) -> bool:
	for active_report in GameState.active_reports:
		if typeof(active_report) != TYPE_DICTIONARY:
			continue

		var active_report_data: Dictionary = active_report as Dictionary
		if str(active_report_data.get("case_id", "")) == case_id and str(active_report_data.get("node_id", "")) == node_id:
			return true

	return false


func _find_report_node(case_id: String, node_id: String) -> Dictionary:
	var case_reports: Dictionary = _get_case_reports(case_id)
	var data_manager: Variant = DATA_MANAGER_SCRIPT.new()
	var nodes: Array = data_manager.get_all_report_route_nodes(case_reports)
	data_manager.free()
	for node in nodes:
		if typeof(node) == TYPE_DICTIONARY:
			var report_node: Dictionary = node as Dictionary
			if str(report_node.get("node_id", "")) == node_id:
				return report_node

	return {}


func _is_terminal_report_node(report_node: Dictionary) -> bool:
	var result: String = str(report_node.get("result", ""))
	return result == "stabilized" or result == "returned_to_stable" or result == "containment_failed"


func _confirm_terminal_report() -> void:
	var result: String = str(current_report_node.get("result", ""))
	GameState.mark_report_completed(current_case_id, current_node_id, "")
	GameState.clear_delay_for_report(current_case_id, current_node_id)
	GameState.remove_active_report(current_case_id, current_node_id)

	if result == "stabilized" or result == "returned_to_stable":
		_apply_terminal_state_delta()
		GameState.mark_case_stabilized(current_case_id)
		report_completed = true
		_update_report_list()
		_show_current_report_detail()
		_set_report_controls_visible(true)
		_update_choice_buttons()
		return

	if result == "containment_failed":
		GameState.clear_case_stabilized(current_case_id)
		_move_to_bad_ending()


func _apply_terminal_state_delta() -> void:
	var state_delta: Variant = current_report_node.get("state_delta", 0)
	if typeof(state_delta) == TYPE_INT:
		GameState.apply_anomaly_state_delta(current_case_id, state_delta)


func _move_to_bad_ending() -> void:
	var save_manager: Variant = SAVE_MANAGER_SCRIPT.new()
	save_manager.apply_ending_to_archive("bad", _get_current_run_archive_data())
	save_manager.delete_current_run_save()
	save_manager.free()
	get_tree().set_meta("ending_type", "bad")
	get_tree().change_scene_to_file(ENDING_SCENE_PATH)


func _get_current_run_archive_data() -> Dictionary:
	return {
		"completed_reports": GameState.completed_reports,
		"active_reports": GameState.active_reports,
		"current_day": GameState.current_day
	}


func _get_report_body(report_node: Dictionary) -> String:
	var data_manager: Variant = DATA_MANAGER_SCRIPT.new()
	var report_body: String = data_manager.get_report_body(report_node)
	data_manager.free()
	return report_body


func _get_report_title(report_node: Dictionary) -> String:
	var data_manager: Variant = DATA_MANAGER_SCRIPT.new()
	var report_title: String = data_manager.get_report_label(report_node)
	data_manager.free()
	return report_title


func _get_case_document(case_id: String) -> Dictionary:
	if not case_documents.has(case_id):
		var data_manager: Variant = DATA_MANAGER_SCRIPT.new()
		case_documents[case_id] = data_manager.load_case_document(case_id)
		data_manager.free()

	return case_documents.get(case_id, {})


func _get_case_reports(case_id: String) -> Dictionary:
	if not case_reports_by_id.has(case_id):
		var data_manager: Variant = DATA_MANAGER_SCRIPT.new()
		case_reports_by_id[case_id] = data_manager.load_case_reports(case_id)
		data_manager.free()

	return case_reports_by_id.get(case_id, {})


func _update_anomaly_image(case_document: Dictionary) -> void:
	var image_path: String = str(case_document.get("image_path", ""))
	if image_path.is_empty() or not ResourceLoader.exists(image_path):
		_clear_anomaly_image()
		return

	var texture_resource: Resource = load(image_path)
	var texture: Texture2D = texture_resource as Texture2D
	if texture == null:
		_clear_anomaly_image()
		return

	anomaly_image_rect.texture = texture
	anomaly_image_slot.visible = true


func _clear_anomaly_image() -> void:
	anomaly_image_rect.texture = null
	anomaly_image_slot.visible = false


func _get_delayed_label(case_id: String, node_id: String) -> String:
	if GameState.get_report_delay_days(case_id, node_id) <= 0:
		return ""

	return str(ui_messages.get("delayed_label", "[처리 지연]"))
