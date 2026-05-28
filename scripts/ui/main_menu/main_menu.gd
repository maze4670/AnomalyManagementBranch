extends Control

const BRIEFING_SCENE_PATH := "res://scenes/briefing/BriefingScreen.tscn"
const ARCHIVE_SCENE_PATH := "res://scenes/archive/ArchiveScreen.tscn"
const SETTINGS_SCENE_PATH := "res://scenes/settings/SettingsScreen.tscn"


func _on_start_work_button_pressed() -> void:
	get_tree().change_scene_to_file(BRIEFING_SCENE_PATH)


func _on_archive_button_pressed() -> void:
	get_tree().change_scene_to_file(ARCHIVE_SCENE_PATH)


func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file(SETTINGS_SCENE_PATH)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
