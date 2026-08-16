@tool
extends EditorPlugin

## Web Export Guard — editor plugin entry.
## Uses add_control_to_dock (Godot 4.0+). Does not call 4.7-only add_dock / EditorDock.

const DockScript := preload("dock.gd")

var _dock: Control


func _enter_tree() -> void:
	_dock = DockScript.new()
	_dock.name = "Web Export Guard"
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)


func _exit_tree() -> void:
	if _dock == null:
		return
	remove_control_from_docks(_dock)
	_dock.free()
	_dock = null
