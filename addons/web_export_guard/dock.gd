@tool
extends VBoxContainer

## Editor dock: read Web presets from export_presets.cfg and report
## index.html filename + last-export sibling files (.wasm / .js / .pck).

const PRESETS_PATH := "res://export_presets.cfg"
const SIBLING_EXTS: PackedStringArray = [".wasm", ".js", ".pck"]
const INDEX_NAMES: PackedStringArray = ["index.html", "index.htm"]

const _OK_COLOR := Color(0.42, 0.82, 0.52)
const _WARN_COLOR := Color(0.95, 0.74, 0.28)
const _MUTED_COLOR := Color(0.72, 0.74, 0.78)

var _results: VBoxContainer
var _note: Label
var _refreshing := false


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(220, 0)
	add_theme_constant_override("separation", 8)
	_build_chrome()
	visibility_changed.connect(_on_visibility_changed)
	refresh()


func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		refresh()


func _notification(what: int) -> void:
	# ScrollContainer will otherwise let labels grow sideways instead of wrapping.
	if what == NOTIFICATION_RESIZED:
		_fit_results_width()


func _fit_results_width() -> void:
	if _results == null:
		return
	var w := size.x - 8.0
	if w > 0.0:
		_results.custom_minimum_size.x = w


func refresh() -> void:
	if _refreshing:
		return
	_refreshing = true
	_clear_results()
	_set_note("")
	var loaded := _collect_web_presets()
	if loaded["ok"]:
		_render_presets(loaded["presets"])
	else:
		_results.add_child(_status_label(
			"WARN",
			"Could not parse res://export_presets.cfg. Fix the file or re-save presets under Project → Export."
		))
	_refreshing = false


func _build_chrome() -> void:
	var title := Label.new()
	title.text = "Web Export Guard"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(title)

	var blurb := _muted_label(
		"Reads this project's Web export presets and the last files written next to them. Independent helper — not affiliated with Godot Engine."
	)
	add_child(blurb)

	var refresh_btn := Button.new()
	refresh_btn.text = "Refresh"
	refresh_btn.tooltip_text = "Re-read export_presets.cfg and check files on disk."
	refresh_btn.pressed.connect(refresh)
	add_child(refresh_btn)

	add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	_results = VBoxContainer.new()
	_results.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_results.add_theme_constant_override("separation", 10)
	scroll.add_child(_results)

	_note = _muted_label("")
	add_child(_note)


func _clear_results() -> void:
	if _results == null:
		return
	for child in _results.get_children():
		_results.remove_child(child)
		child.queue_free()


func _render_presets(presets: Array) -> void:
	if presets.is_empty():
		_results.add_child(_status_label(
			"WARN",
			"No Web export preset in this project. Add one under Project → Export, then click Refresh."
		))
		return

	for i in presets.size():
		var preset: Dictionary = presets[i]
		if i > 0:
			_results.add_child(HSeparator.new())
		_results.add_child(_preset_block(preset))


func _preset_block(preset: Dictionary) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4)

	var heading := Label.new()
	heading.text = "Web preset: %s" % preset["name"]
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(heading)

	var raw_path: String = preset["export_path"]
	var shown := raw_path if not raw_path.is_empty() else "(empty)"
	box.add_child(_muted_label("Export path: %s" % shown))

	var abs_path: String = preset["abs_path"]
	if raw_path.is_empty():
		box.add_child(_status_label(
			"WARN",
			"Export path is empty. Set one on this preset in Project → Export. Use index.html as the file name."
		))
		box.add_child(_open_button("", ""))
		return box

	var filename := abs_path.get_file()
	if filename.to_lower() in INDEX_NAMES:
		box.add_child(_status_label("OK", "Export filename is %s." % filename))
	else:
		box.add_child(_status_label(
			"WARN",
			"Export filename is %s. Official Godot 4 web docs suggest exporting as index.html (index.htm is also accepted here)." % filename
		))

	box.add_child(_sibling_status(abs_path))

	var parent_dir := abs_path.get_base_dir()
	box.add_child(_open_button(parent_dir, raw_path))
	return box


func _sibling_status(abs_html: String) -> Label:
	if not FileAccess.file_exists(abs_html):
		var base_name := abs_html.get_file().get_basename()
		return _status_label(
			"WARN",
			"No export on disk yet. After you export, this dock looks for %s.wasm, %s.js, and %s.pck next to the HTML file." % [base_name, base_name, base_name]
		)

	var base := abs_html.get_basename()
	var missing: PackedStringArray = []
	var found: PackedStringArray = []
	for ext in SIBLING_EXTS:
		var sibling := base + ext
		if FileAccess.file_exists(sibling):
			found.append(sibling.get_file())
		else:
			missing.append(sibling.get_file())

	if missing.is_empty():
		return _status_label(
			"OK",
			"Sibling files are present: %s." % ", ".join(found)
		)
	var found_bit := (" Found: %s." % ", ".join(found)) if not found.is_empty() else ""
	return _status_label(
		"WARN",
		"Last export is missing sibling file(s): %s.%s" % [", ".join(missing), found_bit]
	)


func _open_button(abs_dir: String, raw_path: String) -> Button:
	var btn := Button.new()
	btn.text = "Open export folder"
	btn.tooltip_text = "Open the parent folder of this preset's export path in the OS file manager."
	if raw_path.is_empty() or abs_dir.is_empty():
		btn.disabled = true
	else:
		btn.pressed.connect(_on_open_folder.bind(abs_dir))
	return btn


func _on_open_folder(abs_dir: String) -> void:
	if abs_dir.is_empty():
		_set_note("WARN  No folder to open — export path is empty.")
		return
	if not DirAccess.dir_exists_absolute(abs_dir):
		_set_note("WARN  Export folder is not on disk yet: %s" % abs_dir)
		return
	var err := OS.shell_open(abs_dir)
	if err != OK:
		_set_note("WARN  Could not open the folder (OS.shell_open returned %s)." % error_string(err))
		return
	_set_note("Opened export folder in the file manager.")


func _collect_web_presets() -> Dictionary:
	var out: Array = []
	if not FileAccess.file_exists(PRESETS_PATH):
		return {"ok": true, "presets": out}

	var cfg := ConfigFile.new()
	if cfg.load(PRESETS_PATH) != OK:
		_set_note("WARN  Could not parse res://export_presets.cfg.")
		return {"ok": false, "presets": out}

	for section in cfg.get_sections():
		if not _is_preset_section(section):
			continue
		var platform := str(cfg.get_value(section, "platform", "")).strip_edges()
		if platform.to_lower() != "web":
			continue
		var preset_name := str(cfg.get_value(section, "name", section)).strip_edges()
		if preset_name.is_empty():
			preset_name = section
		var export_path := str(cfg.get_value(section, "export_path", "")).strip_edges()
		out.append({
			"section": section,
			"name": preset_name,
			"export_path": export_path,
			"abs_path": _resolve_export_path(export_path),
		})
	return {"ok": true, "presets": out}


func _is_preset_section(section: String) -> bool:
	if not section.begins_with("preset."):
		return false
	# Skip [preset.N.options] — only the top-level preset block has platform / export_path.
	if section.ends_with(".options"):
		return false
	return true


func _resolve_export_path(export_path: String) -> String:
	if export_path.is_empty():
		return ""
	if export_path.begins_with("res://") or export_path.begins_with("user://"):
		return ProjectSettings.globalize_path(export_path)
	if export_path.is_absolute_path():
		return export_path
	var root := ProjectSettings.globalize_path("res://")
	return root.path_join(export_path)


func _status_label(kind: String, text: String) -> Label:
	var label := Label.new()
	label.text = "%s  %s" % [kind, text]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if kind == "OK":
		label.add_theme_color_override("font_color", _OK_COLOR)
	else:
		label.add_theme_color_override("font_color", _WARN_COLOR)
	return label


func _muted_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", _MUTED_COLOR)
	return label


func _set_note(text: String) -> void:
	if _note == null:
		return
	_note.text = text
	if text.begins_with("WARN"):
		_note.add_theme_color_override("font_color", _WARN_COLOR)
	else:
		_note.add_theme_color_override("font_color", _MUTED_COLOR)
