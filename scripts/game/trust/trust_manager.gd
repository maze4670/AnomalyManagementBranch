extends Node

const BASE_TRUST_VALUE := 100


func calculate_trust_from_anomaly_states(anomaly_states: Dictionary) -> int:
	var state_total: int = 0
	for state_value in anomaly_states.values():
		state_total += int(state_value)

	return clampi(BASE_TRUST_VALUE + state_total, 0, 100)
