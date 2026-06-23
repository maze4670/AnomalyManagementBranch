extends Control

const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu/MainMenu.tscn"
const SAVE_MANAGER_SCRIPT := preload("res://scripts/save/save_manager.gd")
const DATA_MANAGER_SCRIPT := preload("res://scripts/data/data_manager.gd")

@onready var empty_label: Label = $CenterContainer/ContentContainer/EmptyLabel
@onready var archive_list_title_label: Label = $CenterContainer/ContentContainer/ArchiveListTitleLabel
@onready var archive_list_container: VBoxContainer = $CenterContainer/ContentContainer/ArchiveListContainer
@onready var anomaly_image_slot: Control = $CenterContainer/ContentContainer/AnomalyImageSlot
@onready var anomaly_image_rect: TextureRect = $CenterContainer/ContentContainer/AnomalyImageSlot/ArchiveAnomalyImageRect
@onready var detail_label: Label = $CenterContainer/ContentContainer/DetailLabel


func _ready() -> void:
	_clear_anomaly_image()
	_load_archive_list()


func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _load_archive_list() -> void:
	_clear_archive_list()
	_clear_anomaly_image()
	detail_label.text = "기록을 선택해 주세요."
	detail_label.visible = true

	var save_manager: Variant = SAVE_MANAGER_SCRIPT.new()
	var archive_data: Dictionary = save_manager.load_archive_save()
	save_manager.free()

	var unlocked_cases: Variant = archive_data.get("unlocked_cases", {})
	if typeof(unlocked_cases) != TYPE_DICTIONARY or (unlocked_cases as Dictionary).is_empty():
		_show_empty_archive()
		return

	empty_label.visible = false
	archive_list_title_label.visible = true
	archive_list_container.visible = true

	for case_id in (unlocked_cases as Dictionary).keys():
		var case_archive_data: Variant = (unlocked_cases as Dictionary).get(case_id, {})
		if typeof(case_archive_data) != TYPE_DICTIONARY:
			continue

		var case_archive_dictionary: Dictionary = case_archive_data as Dictionary
		var case_document: Dictionary = _get_case_document(str(case_id))
		if case_document.is_empty():
			continue

		var item_button: Button = Button.new()
		item_button.text = _get_archive_case_label(case_document)
		item_button.pressed.connect(_on_archive_case_pressed.bind(str(case_id), case_archive_dictionary))
		archive_list_container.add_child(item_button)

	if archive_list_container.get_child_count() == 0:
		_show_empty_archive()


func _clear_archive_list() -> void:
	for child in archive_list_container.get_children():
		child.queue_free()


func _show_empty_archive() -> void:
	empty_label.text = "보관된 기록이 없습니다."
	empty_label.visible = true
	archive_list_title_label.visible = false
	archive_list_container.visible = false
	detail_label.text = ""
	detail_label.visible = false
	_clear_anomaly_image()


func _get_archive_case_label(case_document: Dictionary) -> String:
	var display_id: String = str(case_document.get("display_id", ""))
	var alias: String = str(case_document.get("alias", ""))
	if alias.is_empty():
		return display_id

	return "%s / %s" % [display_id, alias]


func _get_case_document(case_id: String) -> Dictionary:
	var data_manager: Variant = DATA_MANAGER_SCRIPT.new()
	var case_document: Dictionary = data_manager.load_case_document(case_id)
	data_manager.free()
	return case_document


func _on_archive_case_pressed(case_id: String, case_archive_data: Dictionary) -> void:
	detail_label.visible = true
	_update_anomaly_image(_get_case_document(case_id))
	detail_label.text = _build_archive_detail_text(case_id, case_archive_data)


func _build_archive_detail_text(case_id: String, case_archive_data: Dictionary) -> String:
	var data_manager: Variant = DATA_MANAGER_SCRIPT.new()
	var case_document: Dictionary = data_manager.load_case_document(case_id)
	var case_reports: Dictionary = data_manager.load_case_reports(case_id)
	data_manager.free()
	if case_document.is_empty():
		return ""

	var lines: Array[String] = []
	lines.append("식별명: %s" % str(case_document.get("display_id", "")))
	lines.append("별칭: %s" % str(case_document.get("alias", "")))
	lines.append("분류: %s" % str(case_document.get("category", "")))
	lines.append("기본 설명: %s" % str(case_document.get("basic_description", "")))
	lines.append("추가 설명:")

	var additional_descriptions: Variant = case_document.get("additional_descriptions", [])
	if typeof(additional_descriptions) == TYPE_ARRAY:
		for description in (additional_descriptions as Array):
			lines.append("- %s" % str(description))

	var report_texts: Array[String] = _get_visible_report_texts(case_id, case_archive_data, case_reports)
	if not report_texts.is_empty():
		lines.append("")
		lines.append("[보고 기록]")
		lines.append_array(report_texts)

	return "\n".join(PackedStringArray(lines))


func _get_visible_report_texts(case_id: String, case_archive_data: Dictionary, case_reports: Dictionary) -> Array[String]:
	var archive_level: String = str(case_archive_data.get("unlock_level", "partial"))
	var visible_node_ids: Array[String] = _get_visible_node_ids(case_id, case_archive_data)
	var report_texts: Array[String] = []
	var nodes: Variant = case_reports.get("nodes", [])
	if typeof(nodes) != TYPE_ARRAY:
		return report_texts

	for node in (nodes as Array):
		if typeof(node) != TYPE_DICTIONARY:
			continue

		var node_data: Dictionary = node as Dictionary
		var node_id: String = str(node_data.get("node_id", ""))
		if archive_level != "full" or not visible_node_ids.is_empty():
			if not visible_node_ids.has(node_id):
				continue

		report_texts.append("%s\n%s" % [
			str(node_data.get("report_day_label", "")),
			str(node_data.get("report_text", ""))
		])

	return report_texts


func _get_visible_node_ids(case_id: String, case_archive_data: Dictionary) -> Array[String]:
	var report_keys: Variant = case_archive_data.get("unlocked_report_keys", [])
	var node_ids: Array[String] = []
	if typeof(report_keys) != TYPE_ARRAY:
		return node_ids

	for report_key in (report_keys as Array):
		var key_parts: PackedStringArray = str(report_key).split(":")
		if key_parts.size() != 2:
			continue
		if key_parts[0] != case_id:
			continue

		node_ids.append(key_parts[1])

	return node_ids


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
