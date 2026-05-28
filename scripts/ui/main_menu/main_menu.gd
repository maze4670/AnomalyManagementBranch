extends Control

const BRIEFING_SCENE_PATH := "res://scenes/briefing/BriefingScreen.tscn"
const ARCHIVE_SCENE_PATH := "res://scenes/archive/ArchiveScreen.tscn"
const SETTINGS_SCENE_PATH := "res://scenes/settings/SettingsScreen.tscn"
const SAVE_MANAGER_SCRIPT := preload("res://scripts/save/save_manager.gd")


func _on_start_work_button_pressed() -> void:
	var save_manager: Variant = SAVE_MANAGER_SCRIPT.new()
	var loaded_save: bool = false
	if save_manager.current_run_save_exists():
		loaded_save = save_manager.apply_current_run_to_game_state()
	save_manager.free()

	if not loaded_save:
		GameState.reset_for_new_run()

	get_tree().change_scene_to_file(BRIEFING_SCENE_PATH)


func _on_archive_button_pressed() -> void:
	get_tree().change_scene_to_file(ARCHIVE_SCENE_PATH)


func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file(SETTINGS_SCENE_PATH)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
