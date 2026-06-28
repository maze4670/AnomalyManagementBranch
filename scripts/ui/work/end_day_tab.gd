extends Control

const CONTAINMENT_FAILURE_SCENE_PATH := "res://scenes/ending/ContainmentFailureScreen.tscn"
const DAY_MANAGER_SCRIPT := preload("res://scripts/game/day_loop/day_manager.gd")
const SCREEN_TRANSITION := preload("res://scripts/ui/common/screen_transition.gd")


func _on_end_day_button_pressed() -> void:
	if GameState.has_active_containment_failure_report():
		SCREEN_TRANSITION.transition_to_scene(self, CONTAINMENT_FAILURE_SCENE_PATH)
		return

	SCREEN_TRANSITION.fade_then(self, _complete_end_day)


func _complete_end_day() -> void:
	var day_manager: Variant = DAY_MANAGER_SCRIPT.new()
	day_manager.end_day_minimal(get_tree())
	day_manager.free()
