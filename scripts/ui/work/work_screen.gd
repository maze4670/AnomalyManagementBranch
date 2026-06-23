extends Control

const CONTAINMENT_FAILURE_SCENE_PATH := "res://scenes/ending/ContainmentFailureScreen.tscn"

@onready var current_day_label: Label = $RootContainer/HeaderContainer/StatusContainer/CurrentDayLabel
@onready var action_label: Label = $RootContainer/HeaderContainer/StatusContainer/ActionLabel
@onready var report_tab: Control = $RootContainer/TabContent/ReportTab
@onready var current_anomalies_tab: Control = $RootContainer/TabContent/CurrentAnomaliesTab
@onready var end_day_tab: Control = $RootContainer/TabContent/EndDayTab


func _ready() -> void:
	if GameState.has_active_containment_failure_report():
		call_deferred("_open_containment_failure_screen")
		return

	current_day_label.text = "%d일차" % GameState.current_day
	action_label.text = GameState.get_action_label()
	_show_tab(report_tab)


func _open_containment_failure_screen() -> void:
	get_tree().change_scene_to_file(CONTAINMENT_FAILURE_SCENE_PATH)


func _show_tab(tab_to_show: Control) -> void:
	report_tab.visible = tab_to_show == report_tab
	current_anomalies_tab.visible = tab_to_show == current_anomalies_tab
	end_day_tab.visible = tab_to_show == end_day_tab


func _on_report_tab_button_pressed() -> void:
	_show_tab(report_tab)


func _on_current_anomalies_tab_button_pressed() -> void:
	_show_tab(current_anomalies_tab)


func _on_end_day_tab_button_pressed() -> void:
	_show_tab(end_day_tab)
