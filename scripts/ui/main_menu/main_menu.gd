extends Control

const BRIEFING_SCENE_PATH := "res://scenes/briefing/BriefingScreen.tscn"
const ARCHIVE_SCENE_PATH := "res://scenes/archive/ArchiveScreen.tscn"
const SETTINGS_SCENE_PATH := "res://scenes/settings/SettingsScreen.tscn"
const SAVE_MANAGER_SCRIPT := preload("res://scripts/save/save_manager.gd")
const SCREEN_TRANSITION := preload("res://scripts/ui/common/screen_transition.gd")
const BUTTON_FEEDBACK := preload("res://scripts/ui/common/button_feedback.gd")
const AUDIO_FEEDBACK := preload("res://scripts/ui/common/audio_feedback.gd")


func _ready() -> void:
	AUDIO_FEEDBACK.play_bgm("main_menu")
	SCREEN_TRANSITION.fade_in(self)
	BUTTON_FEEDBACK.install(self)


func _on_start_work_button_pressed() -> void:
	var save_manager: Variant = SAVE_MANAGER_SCRIPT.new()
	var loaded_save: bool = false
	if save_manager.current_run_save_exists():
		loaded_save = save_manager.apply_current_run_to_game_state()
	save_manager.free()

	if not loaded_save:
		GameState.reset_for_new_run()

	SCREEN_TRANSITION.transition_to_scene(self, BRIEFING_SCENE_PATH)


func _on_archive_button_pressed() -> void:
	SCREEN_TRANSITION.transition_to_scene(self, ARCHIVE_SCENE_PATH)


func _on_settings_button_pressed() -> void:
	SCREEN_TRANSITION.transition_to_scene(self, SETTINGS_SCENE_PATH)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
