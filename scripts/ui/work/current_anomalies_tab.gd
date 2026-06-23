extends Control

const DATA_MANAGER_SCRIPT := preload("res://scripts/data/data_manager.gd")

@onready var anomaly_list_container: VBoxContainer = $RootContainer/ContentContainer/AnomalyListContainer
@onready var anomaly_list_label: Label = $RootContainer/ContentContainer/AnomalyListContainer/AnomalyListLabel
@onready var anomaly_button_template: Button = $RootContainer/ContentContainer/AnomalyListContainer/AnomalyButtonTemplate
@onready var detail_text: RichTextLabel = $RootContainer/ContentContainer/DetailContainer/DetailScrollContainer/DetailBodyContainer/DetailText
@onready var anomaly_image_slot: Control = $RootContainer/ContentContainer/DetailContainer/DetailScrollContainer/DetailBodyContainer/AnomalyImageSlot
@onready var anomaly_image_rect: TextureRect = $RootContainer/ContentContainer/DetailContainer/DetailScrollContainer/DetailBodyContainer/AnomalyImageSlot/AnomalyImageRect

var case_documents: Dictionary = {}
var current_case_id: String = ""


func _ready() -> void:
	anomaly_button_template.visible = false
	_update_anomaly_list()


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
		anomaly_button.text = _get_case_list_label(case_document, case_id)
		anomaly_button.pressed.connect(_on_anomaly_button_pressed.bind(case_id))
		anomaly_list_container.add_child(anomaly_button)
		visible_case_count += 1

	if visible_case_count == 0:
		detail_text.text = "현재 회차에서 확인된 이상현상이 없습니다."
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
		_clear_anomaly_image()
		return

	var lines: Array[String] = []
	lines.append("식별명: %s" % str(case_document.get("display_id", case_id)))
	lines.append("별칭: %s" % str(case_document.get("alias", "")))
	lines.append("분류: %s" % str(case_document.get("category", "")))
	lines.append("")
	lines.append("기본 설명")
	lines.append(str(case_document.get("basic_description", "")))

	var unlocked_descriptions: Array[String] = _get_unlocked_additional_descriptions(case_id, case_document)
	if not unlocked_descriptions.is_empty():
		lines.append("")
		lines.append("해금된 추가 설명")
		for description in unlocked_descriptions:
			lines.append("- %s" % description)

	detail_text.text = "\n".join(PackedStringArray(lines))
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


func _get_case_list_label(case_document: Dictionary, fallback_case_id: String) -> String:
	var display_id: String = str(case_document.get("display_id", fallback_case_id))
	var alias: String = str(case_document.get("alias", ""))
	if alias.is_empty():
		return display_id

	return "%s / %s" % [display_id, alias]


func _get_unlocked_additional_descriptions(case_id: String, case_document: Dictionary) -> Array[String]:
	var additional_descriptions: Variant = case_document.get("additional_descriptions", [])
	var unlocked_descriptions: Array[String] = []
	if typeof(additional_descriptions) != TYPE_ARRAY:
		return unlocked_descriptions

	var completed_report_count: int = _get_completed_report_count(case_id)
	for description in (additional_descriptions as Array):
		if typeof(description) == TYPE_STRING:
			if unlocked_descriptions.size() >= completed_report_count:
				continue

			unlocked_descriptions.append(str(description))
			continue

		if typeof(description) != TYPE_DICTIONARY:
			continue

		var description_data: Dictionary = description as Dictionary
		if not _is_additional_description_unlocked(case_id, description_data):
			continue

		var description_text: String = _get_additional_description_text(description_data)
		if not description_text.is_empty():
			unlocked_descriptions.append(description_text)

	return unlocked_descriptions


func _get_completed_report_count(case_id: String) -> int:
	var completed_report_count: int = 0
	for report_key in GameState.completed_reports.keys():
		var key_parts: PackedStringArray = str(report_key).split(":")
		if key_parts.size() == 2 and key_parts[0] == case_id:
			completed_report_count += 1

	return completed_report_count


func _is_additional_description_unlocked(case_id: String, description_data: Dictionary) -> bool:
	var unlock_report_key: String = str(description_data.get("unlock_report_key", ""))
	if unlock_report_key.is_empty():
		unlock_report_key = str(description_data.get("report_key", ""))
	if not unlock_report_key.is_empty():
		return GameState.completed_reports.has(unlock_report_key)

	var node_id: String = str(description_data.get("node_id", ""))
	if node_id.is_empty():
		node_id = str(description_data.get("required_node_id", ""))
	if node_id.is_empty():
		return true

	return GameState.completed_reports.has(GameState.make_report_key(case_id, node_id))


func _get_additional_description_text(description_data: Dictionary) -> String:
	for text_key in ["text", "description", "body"]:
		var text: String = str(description_data.get(text_key, ""))
		if not text.is_empty():
			return text

	return ""


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
