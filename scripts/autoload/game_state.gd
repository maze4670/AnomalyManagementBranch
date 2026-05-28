extends Node

# Stores the minimal shared run state.

var current_day: int = 1
var max_actions_per_day: int = 3
var remaining_actions: int = 3


func reset_for_new_run() -> void:
	current_day = 1
	max_actions_per_day = 3
	remaining_actions = max_actions_per_day


func reset_actions_for_new_day() -> void:
	remaining_actions = max_actions_per_day


func consume_action() -> bool:
	if remaining_actions <= 0:
		return false

	remaining_actions -= 1
	return true


func advance_day() -> void:
	current_day += 1


func get_action_label() -> String:
	return "[잔여 대응 절차 %d/%d]" % [remaining_actions, max_actions_per_day]
