extends Control

const DAY_MANAGER_SCRIPT := preload("res://scripts/game/day_loop/day_manager.gd")


func _on_end_day_button_pressed() -> void:
	var day_manager: Variant = DAY_MANAGER_SCRIPT.new()
	day_manager.end_day_minimal(get_tree())
	day_manager.free()
