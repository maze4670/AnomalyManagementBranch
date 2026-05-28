extends Node

func is_good_ending(current_day: int) -> bool:
	return current_day >= 60


func is_bad_ending(trust_value: int) -> bool:
	return trust_value <= 0
