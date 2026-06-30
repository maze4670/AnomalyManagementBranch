extends Control

const DATA_MANAGER_SCRIPT := preload("res://scripts/data/data_manager.gd")
const IMAGE_LIGHTBOX := preload("res://scripts/ui/common/image_lightbox.gd")
const DOCUMENT_RECORDS := preload("res://scripts/ui/common/document_records.gd")

@onready var anomaly_list_container: VBoxContainer = $RootContainer/ContentContainer/AnomalyListPanel/AnomalyListContainer
@onready var anomaly_list_label: Label = $RootContainer/ContentContainer/AnomalyListPanel/AnomalyListContainer/AnomalyListLabel
@onready var anomaly_button_template: Button = $RootContainer/ContentContainer/AnomalyListPanel/AnomalyListContainer/AnomalyButtonTemplate
@onready var pdf_meta_text: RichTextLabel = $RootContainer/ContentContainer/DocumentStage/PDFDocumentPanel/PDFContentMargin/PDFContentContainer/PDFTopRow/PDFMetaText
@onready var detail_text: RichTextLabel = $RootContainer/ContentContainer/DocumentStage/PDFDocumentPanel/PDFContentMargin/PDFContentContainer/DetailScrollContainer/DetailText
@onready var anomaly_image_slot: Control = $RootContainer/ContentContainer/DocumentStage/PDFDocumentPanel/PDFContentMargin/PDFContentContainer/PDFTopRow/AnomalyImageSlot
@onready var anomaly_image_rect: TextureRect = $RootContainer/ContentContainer/DocumentStage/PDFDocumentPanel/PDFContentMargin/PDFContentContainer/PDFTopRow/AnomalyImageSlot/AnomalyImageRect

var case_documents: Dictionary = {}
var current_case_id: String = ""
var document_records_container: VBoxContainer


func _ready() -> void:
	document_records_container = DOCUMENT_RECORDS.ensure_records_container(detail_text)
	anomaly_image_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	anomaly_image_rect.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	anomaly_image_rect.gui_input.connect(_on_anomaly_image_gui_input)
	anomaly_button_template.visible = false
	_update_anomaly_list()


func _on_anomaly_image_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			anomaly_image_rect.accept_event()
			IMAGE_LIGHTBOX.show_image(self, anomaly_image_rect.texture)


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_node_ready() and visible:
		_update_anomaly_list()


func _update_anomaly_list() -> void:
	_clear_anomaly_list_buttons()
	var known_case_ids: Array[String] = _get_current_run_case_ids()
	var first_visible_case_id: String = ""
	var visible_case_count: int = 0

	for case_id in known_case_ids:
		var case_document: Dictionary = _get_case_document(case_id)
		if case_document.is_empty():
			continue
		if first_visible_case_id.is_empty():
			first_visible_case_id = case_id

		var anomaly_button: Button = Button.new()
		anomaly_button.custom_minimum_size = anomaly_button_template.custom_minimum_size
		anomaly_button.add_theme_stylebox_override("normal", anomaly_button_template.get_theme_stylebox("normal"))
		anomaly_button.add_theme_stylebox_override("hover", anomaly_button_template.get_theme_stylebox("hover"))
		anomaly_button.add_theme_stylebox_override("pressed", anomaly_button_template.get_theme_stylebox("pressed"))
		anomaly_button.add_theme_stylebox_override("focus", anomaly_button_template.get_theme_stylebox("focus"))
		anomaly_button.add_theme_color_override("font_color", anomaly_button_template.get_theme_color("font_color"))
		anomaly_button.add_theme_color_override("font_hover_color", anomaly_button_template.get_theme_color("font_hover_color"))
		anomaly_button.add_theme_color_override("font_pressed_color", anomaly_button_template.get_theme_color("font_pressed_color"))
		anomaly_button.add_theme_font_size_override("font_size", anomaly_button_template.get_theme_font_size("font_size"))
		SettingsManager.copy_text_size_baseline(anomaly_button_template, anomaly_button)
		anomaly_button.text = _get_case_list_label(case_document, case_id)
		anomaly_button.pressed.connect(_on_anomaly_button_pressed.bind(case_id))
		anomaly_list_container.add_child(anomaly_button)
		visible_case_count += 1

	if visible_case_count == 0:
		detail_text.text = "현재 회차에서 확인된 이상현상이 없습니다."
		DOCUMENT_RECORDS.populate_records(document_records_container, [])
		pdf_meta_text.text = ""
		_clear_anomaly_image()
		return

	if current_case_id.is_empty() or not known_case_ids.has(current_case_id):
		current_case_id = first_visible_case_id

	_show_case_detail(current_case_id)


func _clear_anomaly_list_buttons() -> void:
	for child in anomaly_list_container.get_children():
		if child == anomaly_list_label or child == anomaly_button_template:
			continue

		child.queue_free()


func _on_anomaly_button_pressed(case_id: String) -> void:
	current_case_id = case_id
	_show_case_detail(case_id)


func _show_case_detail(case_id: String) -> void:
	var case_document: Dictionary = _get_case_document(case_id)
	if case_document.is_empty():
		detail_text.text = "이상현상 문서를 표시할 수 없습니다."
		DOCUMENT_RECORDS.populate_records(document_records_container, [])
		pdf_meta_text.text = ""
		_clear_anomaly_image()
		return

	var meta_lines: Array[String] = []
	meta_lines.append("식별명: %s" % str(case_document.get("display_id", "")))
	meta_lines.append("별칭: %s" % str(case_document.get("alias", "")))
	meta_lines.append("분류: %s" % str(case_document.get("category", "")))
	pdf_meta_text.text = "\n".join(PackedStringArray(meta_lines))

	detail_text.text = "기본 설명\n%s" % str(case_document.get("basic_description", ""))
	DOCUMENT_RECORDS.populate_records(document_records_container, DOCUMENT_RECORDS.build_current_run_records(case_id))
	_update_anomaly_image(case_document)


func _get_current_run_case_ids() -> Array[String]:
	var case_ids: Array[String] = []

	for case_id in GameState.known_cases:
		_add_case_id(case_ids, str(case_id))

	for active_report in GameState.active_reports:
		if typeof(active_report) == TYPE_DICTIONARY:
			_add_case_id(case_ids, str((active_report as Dictionary).get("case_id", "")))

	for scheduled_report in GameState.scheduled_reports:
		if typeof(scheduled_report) == TYPE_DICTIONARY:
			_add_case_id(case_ids, str((scheduled_report as Dictionary).get("case_id", "")))

	for report_key in GameState.completed_reports.keys():
		var key_parts: PackedStringArray = str(report_key).split(":")
		if key_parts.size() == 2:
			_add_case_id(case_ids, key_parts[0])

	for case_id in GameState.get_stabilized_case_ids():
		_add_case_id(case_ids, str(case_id))

	case_ids.sort()
	return case_ids


func _add_case_id(case_ids: Array[String], case_id: String) -> void:
	if case_id.is_empty():
		return
	if case_ids.has(case_id):
		return

	case_ids.append(case_id)


func _get_case_list_label(case_document: Dictionary, _fallback_case_id: String) -> String:
	var display_id: String = str(case_document.get("display_id", ""))
	var alias: String = str(case_document.get("alias", ""))
	if display_id.is_empty():
		return alias
	if alias.is_empty():
		return display_id

	return "%s / %s" % [display_id, alias]


func _get_case_document(case_id: String) -> Dictionary:
	if not case_documents.has(case_id):
		var data_manager: Variant = DATA_MANAGER_SCRIPT.new()
		case_documents[case_id] = data_manager.load_case_document(case_id)
		data_manager.free()

	return case_documents.get(case_id, {})


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
