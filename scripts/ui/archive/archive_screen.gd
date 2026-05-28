extends Control

const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu/MainMenu.tscn"
const SAVE_MANAGER_SCRIPT := preload("res://scripts/save/save_manager.gd")
const DATA_MANAGER_SCRIPT := preload("res://scripts/data/data_manager.gd")

@onready var empty_label: Label = $CenterContainer/ContentContainer/EmptyLabel
@onready var archive_list_title_label: Label = $CenterContainer/ContentContainer/ArchiveListTitleLabel
@onready var archive_list_container: VBoxContainer = $CenterContainer/ContentContainer/ArchiveListContainer


func _ready() -> void:
	_load_archive_list()


func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _load_archive_list() -> void:
	_clear_archive_list()

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

		var item_label: Label = Label.new()
		item_label.text = _get_archive_case_label(str(case_id), case_archive_data as Dictionary)
		item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		archive_list_container.add_child(item_label)

	if archive_list_container.get_child_count() == 0:
		_show_empty_archive()


func _clear_archive_list() -> void:
	for child in archive_list_container.get_children():
		child.queue_free()


func _show_empty_archive() -> void:
	empty_label.text = "아직 해금된 기록이 없습니다."
	empty_label.visible = true
	archive_list_title_label.visible = false
	archive_list_container.visible = false


func _get_archive_case_label(case_id: String, case_archive_data: Dictionary) -> String:
	var data_manager: Variant = DATA_MANAGER_SCRIPT.new()
	var case_document: Dictionary = data_manager.load_case_document(case_id)
	data_manager.free()

	var display_id: String = str(case_document.get("display_id", case_id))
	var alias: String = str(case_document.get("alias", ""))
	var unlock_level: String = str(case_archive_data.get("unlock_level", "partial"))
	var unlock_label: String = "일부 기록 해금"
	if unlock_level == "full":
		unlock_label = "전체 기록 해금"

	if alias.is_empty():
		return "%s - %s" % [display_id, unlock_label]

	return "%s / %s - %s" % [display_id, alias, unlock_label]
