extends Control

const WORK_SCENE_PATH := "res://scenes/work/WorkScreen.tscn"


func _on_start_work_button_pressed() -> void:
	get_tree().change_scene_to_file(WORK_SCENE_PATH)
