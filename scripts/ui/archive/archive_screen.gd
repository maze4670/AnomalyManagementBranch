extends Control

const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu/MainMenu.tscn"
const SAVE_MANAGER_SCRIPT := preload("res://scripts/save/save_manager.gd")
const DATA_MANAGER_SCRIPT := preload("res://scripts/data/data_manager.gd")
const SCREEN_TRANSITION := preload("res://scripts/ui/common/screen_transition.gd")
const BUTTON_FEEDBACK := preload("res://scripts/ui/common/button_feedback.gd")
const AUDIO_FEEDBACK := preload("res://scripts/ui/common/audio_feedback.gd")
const DOCUMENT_RECORDS := preload("res://scripts/ui/common/document_records.gd")

@onready var empty_label: Label = $RootMargin/RootContainer/ContentContainer/ArchiveListPanel/ArchiveListContent/EmptyLabel
@onready var archive_list_title_label: Label = $RootMargin/RootContainer/ContentContainer/ArchiveListPanel/ArchiveListContent/ArchiveListTitleLabel
@onready var archive_list_container: VBoxContainer = $RootMargin/RootContainer/ContentContainer/ArchiveListPanel/ArchiveListContent/ArchiveListScroll/ArchiveListContainer
@onready var archive_button_template: Button = $RootMargin/RootContainer/ContentContainer/ArchiveListPanel/ArchiveListContent/ArchiveListScroll/ArchiveListContainer/ArchiveButtonTemplate
@onready var pdf_meta_text: RichTextLabel = $RootMargin/RootContainer/ContentContainer/DocumentStage/PDFDocumentPanel/PDFContentMargin/PDFContentContainer/PDFTopRow/PDFMetaText
@onready var anomaly_image_slot: Control = $RootMargin/RootContainer/ContentContainer/DocumentStage/PDFDocumentPanel/PDFContentMargin/PDFContentContainer/PDFTopRow/AnomalyImageSlot
@onready var anomaly_image_rect: TextureRect = $RootMargin/RootContainer/ContentContainer/DocumentStage/PDFDocumentPanel/PDFContentMargin/PDFContentContainer/PDFTopRow/AnomalyImageSlot/ArchiveAnomalyImageRect
@onready var detail_label: RichTextLabel = $RootMargin/RootContainer/ContentContainer/DocumentStage/PDFDocumentPanel/PDFContentMargin/PDFContentContainer/DetailScrollContainer/DetailLabel

var document_records_container: VBoxContainer


func _ready() -> void:
	document_records_container = DOCUMENT_RECORDS.ensure_records_container(detail_label)
	AUDIO_FEEDBACK.play_bgm("work")
	SCREEN_TRANSITION.fade_in(self)
	BUTTON_FEEDBACK.install(self)
	archive_button_template.visible = false
	_clear_anomaly_image()
	_load_archive_list()


func _on_main_menu_button_pressed() -> void:
	SCREEN_TRANSITION.transition_to_scene(self, MAIN_MENU_SCENE_PATH)


func _load_archive_list() -> void:
	_clear_archive_list()
	_clear_anomaly_image()
	pdf_meta_text.text = ""
	detail_label.text = "기록을 선택해 주세요."
	DOCUMENT_RECORDS.populate_records(document_records_container, [])
	detail_label.visible = true

	var save_manager: Variant = SAVE_MANAGER_SCRIPT.new()
	var archive_data: Dictionary = save_manager.load_archive_save()
	save_manager.free()

	var unlocked_cases: Variant = archive_data.get("unlocked_cases", {})
	var collected_records: Array = archive_data.get("collected_records", []) as Array
	if typeof(unlocked_cases) != TYPE_DICTIONARY or (unlocked_cases as Dictionary).is_empty():
		_show_empty_archive()
		return

	empty_label.visible = false
	archive_list_title_label.visible = true
	archive_list_container.visible = true

	var visible_archive_count: int = 0
	for case_id in (unlocked_cases as Dictionary).keys():
		var case_archive_data: Variant = (unlocked_cases as Dictionary).get(case_id, {})
		if typeof(case_archive_data) != TYPE_DICTIONARY:
			continue

		var case_archive_dictionary: Dictionary = (case_archive_data as Dictionary).duplicate(true)
		case_archive_dictionary["collected_records"] = _get_case_collected_records(str(case_id), collected_records)
		var case_document: Dictionary = _get_case_document(str(case_id))
		if case_document.is_empty():
			continue

		var item_button: Button = Button.new()
		item_button.custom_minimum_size = archive_button_template.custom_minimum_size
		item_button.add_theme_stylebox_override("normal", archive_button_template.get_theme_stylebox("normal"))
		item_button.add_theme_stylebox_override("hover", archive_button_template.get_theme_stylebox("hover"))
		item_button.add_theme_stylebox_override("pressed", archive_button_template.get_theme_stylebox("pressed"))
		item_button.add_theme_stylebox_override("focus", archive_button_template.get_theme_stylebox("focus"))
		item_button.add_theme_color_override("font_color", archive_button_template.get_theme_color("font_color"))
		item_button.add_theme_color_override("font_hover_color", archive_button_template.get_theme_color("font_hover_color"))
		item_button.add_theme_color_override("font_pressed_color", archive_button_template.get_theme_color("font_pressed_color"))
		item_button.add_theme_font_size_override("font_size", archive_button_template.get_theme_font_size("font_size"))
		SettingsManager.copy_text_size_baseline(archive_button_template, item_button)
		item_button.text = _get_archive_case_label(case_document)
		item_button.pressed.connect(_on_archive_case_pressed.bind(str(case_id), case_archive_dictionary))
		archive_list_container.add_child(item_button)
		visible_archive_count += 1

	if visible_archive_count == 0:
		_show_empty_archive()


func _clear_archive_list() -> void:
	for child in archive_list_container.get_children():
		if child == archive_button_template:
			continue
		child.queue_free()


func _show_empty_archive() -> void:
	empty_label.text = "보관된 기록이 없습니다."
	empty_label.visible = true
	archive_list_title_label.visible = false
	archive_list_container.visible = false
	pdf_meta_text.text = ""
	detail_label.text = ""
	detail_label.visible = false
	DOCUMENT_RECORDS.populate_records(document_records_container, [])
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
	var case_document: Dictionary = _get_case_document(case_id)
	pdf_meta_text.text = _build_archive_meta_text(case_document)
	_update_anomaly_image(case_document)
	detail_label.text = "기본 설명\n%s" % str(case_document.get("basic_description", ""))
	var records: Array[Dictionary] = DOCUMENT_RECORDS.build_archive_collected_records(case_id, case_archive_data.get("collected_records", []))
	if records.is_empty():
		records = DOCUMENT_RECORDS.build_archive_records(case_id, case_archive_data.get("unlocked_report_keys", []))
	DOCUMENT_RECORDS.populate_records(document_records_container, records)


func _get_case_collected_records(case_id: String, collected_records: Array) -> Array:
	var case_records: Array = []
	for record in collected_records:
		if typeof(record) == TYPE_DICTIONARY and str((record as Dictionary).get("case_id", "")) == case_id:
			case_records.append(record)
	return case_records


func _build_archive_meta_text(case_document: Dictionary) -> String:
	if case_document.is_empty():
		return ""

	var lines: Array[String] = []
	lines.append("식별명: %s" % str(case_document.get("display_id", "")))
	lines.append("별칭: %s" % str(case_document.get("alias", "")))
	lines.append("분류: %s" % str(case_document.get("category", "")))
	return "\n".join(PackedStringArray(lines))


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
