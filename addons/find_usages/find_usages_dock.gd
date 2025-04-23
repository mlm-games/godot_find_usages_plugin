@tool
extends Control

signal find_usages_requested(identifier)

@onready var search_input: LineEdit = %InputLineEdit
@onready var search_button: Button = %ConfirmButton
@onready var status_label: RichTextLabel = %StatusLabel
@onready var results_tree: Tree = %ResultsTree

func _ready():
	
	search_button.connect("pressed", Callable(self, "_on_search_button_pressed"))
	search_input.connect("text_submitted", Callable(self, "_on_text_submitted"))
	results_tree.connect("item_activated", Callable(self, "_on_result_activated"))
	
	# Set up the tree
	results_tree.set_column_titles_visible(true)
	results_tree.set_column_title(0, "File")
	results_tree.set_column_title(1, "Line")
	results_tree.set_column_title(2, "Text")
	
	# Initial state
	status_label.text = "Enter an identifier to find usages"

func _on_search_button_pressed():
	emit_signal("find_usages_requested", search_input.text)

func _on_text_submitted(text):
	emit_signal("find_usages_requested", text)

func display_results(results: Array, status_message):
	status_label.text = status_message
	results_tree.clear()
	
	var root = results_tree.create_item()
	
	for result in results:
		var item : TreeItem = results_tree.create_item(root)
		item.set_text(0, result.file.get_file())
		item.set_tooltip_text(0, result.file)
		item.set_metadata(0, result)
		
		item.set_text(1, str(result.line))
		item.set_text(2, result.text)

func _on_result_activated():
	var selected = results_tree.get_selected()
	if selected:
		var metadata = selected.get_metadata(0)
		if metadata:
			var script_editor = EditorInterface.get_script_editor()
			var script = load(metadata.file)
			
			if script:
				script_editor.open_script_create_dialog(script.resource_name ,script.resource_path)
				script_editor.goto_line(metadata.line - 1)  # Line numbers are 0-based in the editor
