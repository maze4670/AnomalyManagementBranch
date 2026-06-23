extends Control

const CONTAINMENT_FAILURE_SCENE_PATH := "res://scenes/ending/ContainmentFailureScreen.tscn"
const DAY_MANAGER_SCRIPT := preload("res://scripts/game/day_loop/day_manager.gd")


func _on_end_day_button_pressed() -> void:
	if GameState.has_active_containment_failure_report():
		get_tree().change_scene_to_file(CONTAINMENT_FAILURE_SCENE_PATH)
		return

	var day_manager: Variant = DAY_MANAGER_SCRIPT.new()
	day_manager.end_day_minimal(get_tree())
	day_manager.free()
