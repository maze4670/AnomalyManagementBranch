extends Node

const BRIEFING_SCENE_PATH := "res://scenes/briefing/BriefingScreen.tscn"


func end_day_minimal(scene_tree: SceneTree) -> void:
	GameState.advance_day()
	GameState.reset_actions_for_new_day()
	scene_tree.change_scene_to_file(BRIEFING_SCENE_PATH)
