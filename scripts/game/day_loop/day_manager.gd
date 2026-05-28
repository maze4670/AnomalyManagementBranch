extends Node

const BRIEFING_SCENE_PATH := "res://scenes/briefing/BriefingScreen.tscn"
const SAVE_MANAGER_SCRIPT := preload("res://scripts/save/save_manager.gd")


func end_day_minimal(scene_tree: SceneTree) -> void:
	GameState.advance_day()
	GameState.reset_actions_for_new_day()
	var save_manager: Variant = SAVE_MANAGER_SCRIPT.new()
	save_manager.save_current_run()
	save_manager.free()
	scene_tree.change_scene_to_file(BRIEFING_SCENE_PATH)
