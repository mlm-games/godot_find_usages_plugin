@tool
extends EditorPlugin

var dock
var script_editor
var current_script

func _enter_tree():
	# Initialize the dock
	dock = preload("res://addons/find_usages/find_usages_dock.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, dock)
	
	# Get the script editor
	script_editor = EditorInterface.get_script_editor()
	
	# Connect to signals
	script_editor.connect("editor_script_changed", Callable(self, "_on_script_changed"))
	dock.connect("find_usages_requested", Callable(self, "_on_find_usages_requested"))

func _exit_tree():
	# Clean up
	remove_control_from_docks(dock)
	dock.free()

func _on_script_changed(script):
	current_script = script

func _on_find_usages_requested(identifier):
	if identifier.strip_edges() == "":
		dock.display_results([], "Please select a valid identifier")
		return
	
	var results : Array = find_usages_in_project(identifier)
	dock.display_results(results, "Found " + str(results.size()) + " usages of '" + identifier + "'")

func find_usages_in_project(identifier):
	var results : Array = []
	var dir = DirAccess.open("res://")
	
	if dir:
		_scan_directory(dir, "res://", identifier, results)
	
	return results

func _scan_directory(dir, path, identifier, results):
	# List directory content
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name != "." and file_name != "..":
			var full_path = path + "/" + file_name
			
			if dir.current_is_dir():
				var subdir = DirAccess.open(full_path)
				if subdir:
					_scan_directory(subdir, full_path, identifier, results)
			elif file_name.ends_with(".gd"):
				_scan_script_file(full_path, identifier, results)
			elif file_name.ends_with(".tscn") or file_name.ends_with(".tres"):
				_scan_resource_file(full_path, identifier, results)
		
		file_name = dir.get_next()

func _scan_script_file(file_path, identifier, results):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var line_number = 0
		while not file.eof_reached():
			line_number += 1
			var line = file.get_line()
			
			# Simple search for the identifier
			# For a more robust solution, you'd need a proper parser
			if line.find(identifier) != -1:
				# Ignore comments
				var comment_pos = line.find("#")
				if comment_pos == -1 or line.find(identifier) < comment_pos:
					results.append({
						"file": file_path,
						"line": line_number,
						"text": line.strip_edges(),
						"column": line.find(identifier)
					})
		file.close()

func _scan_resource_file(file_path, identifier, results):
	# For scene and resource files, we do a simpler text search
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		if content.find(identifier) != -1:
			results.append({
				"file": file_path,
				"line": 1,  # We don't parse line numbers for resource files
				"text": "Resource contains reference to '" + identifier + "'",
				"column": 0
			})
		file.close()
