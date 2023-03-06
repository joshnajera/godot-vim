@tool
extends EditorPlugin


var script_editor : ScriptEditor
var vim_mode : bool = true
var visual_mode : bool = false
var input_buffer : Array = []
var clip_buffer : String = ""
var editor_interface : EditorInterface
var current_editor : ScriptEditorBase
var code_editor : CodeEdit
var select_from_line
var select_from_column
var visual_selection_mode : bool = false
var visual_line_mode : bool = false
var comman_mode : bool = false
var bindings = {
	["H"]: move_left,
	["J"]: move_down,
	["K"]: move_up,
	["L"]: move_right,
	["E"]: TODO,
	["B"]: TODO,
	["Shift+G"]: move_to_beginning_of_file,
	["G", "G"]: move_to_end_of_file,
	["I"]: enable_insert,
	["Shift+I"]: insert_at_beginning_of_line,
	["A"]: insert_after,
	["Shift+A"]:TODO,
	["O"]: newline_insert,
	["P"]: paste,
	["Shift+P"]: TODO,
	["R", "ANY"]: replace_one_character,
	["S"]: replace_selection,
	["X"]: delete_at_cursor,
	["D","D"]: delete_line,
	["D", "W"]: delete_word,
	["U"]: undo,
	["Ctrl+R"]: redo,
	["Shift+Semicolon","W", "Enter"]: TODO, 
	["Y"]: yank,
	["Y", "Y"]: TODO, #Yank line
	["V"]: enter_visual_selection,
	["Shift+V"]: enter_visual_line_selection,
	["Slash"]: search_function, #TODO
}


func _enter_tree() -> void:
	editor_interface = get_editor_interface()
	script_editor = editor_interface.get_script_editor()


func _input(event):
	current_editor = script_editor.get_current_editor()
	if !current_editor:
		return
	code_editor = current_editor.get_base_editor() as CodeEdit
	if !code_editor:
		return
	if !code_editor.has_focus(): #Don't process when no focus
		return
	var key_event = event as InputEventKey
	if key_event == null or !key_event.is_pressed(): #Don't process when not a key action
		return

	if event is InputEventKey and vim_mode and event.is_pressed(): #We are in VIM mode
		var new_keys = key_event.as_text_keycode()
		if new_keys not in ["Shift","Ctrl","Alt","Escape"]: #Don't add these to input buffer.
			input_buffer.push_back(new_keys)
		get_viewport().set_input_as_handled()
		
	if event is InputEventKey: #We are in insert mode
		if key_event.is_pressed() and !key_event.is_echo():
			if key_event.get_keycode_with_modifiers() == KEY_ESCAPE:
				enable_vim()
				visual_mode = false
				visual_line_mode = false
				input_buffer.clear()
				if code_editor.has_selection():
					code_editor.deselect()
	
	#Have bufferable input
	if !input_buffer.is_empty():
		process_buffer()


# Checks for available commands to run, and manages clearing buffer.
func process_buffer() ->void :
	var valid = check_command(input_buffer)
	if abs(valid) == 1: #Full match
		input_buffer.clear()
	elif valid == 0: #Partial match??? 
		print("Spare buffer: ", input_buffer)
		pass

# Command buffer parser
func check_command(commands:Array) -> int:
	var partial = false
	var full = false
	var nomatch = false
	if commands in bindings.keys():#Potential full-match
		var err = bindings[commands].call()
		if err != -1: # full match
			full = true
			return 1
		partial = true # Our last command sent back to buffer
		return 0
	else: #No immediate matches
		for key in bindings.keys():
			print(commands)
			var i = commands.size()
			if i > key.size(): # If command buffer iteration is bigger than length of binding then skip it.
				continue
			var cmd = commands[i-1]
			if cmd == key[i-1]:
				print("\n\ncurrently matching?\n\n")
				print("i:", i)
				partial = true
				return 0

	# No matches at all?
	return -1


###########################
####  BOUND FUNCTIONS  ####
###########################

# Enabling/Disabling VIM mode
func enable_vim():
	set_vim_mode(true)
func enable_insert():
	set_vim_mode(false)
func set_vim_mode(mode : bool):
	vim_mode = mode
	if vim_mode:
		code_editor.caret_type = TextEdit.CARET_TYPE_BLOCK
	else:
		code_editor.caret_type = TextEdit.CARET_TYPE_LINE

# Movement
func move_to_end_of_file():
	code_editor.set_caret_line(code_editor.get_line_count())
	code_editor.set_caret_column(99999)
func move_to_beginning_of_file():
	code_editor.set_caret_column(0)
	code_editor.set_caret_line(0)
func move_right():
	move_column_relative(1)
	update_selection()
func move_left():
	move_column_relative(-1)
	update_selection()
func move_down():
	move_line_relative(1)
	update_selection()
func move_up():
	move_line_relative(-1)
	update_selection()
func move_column_relative(amount:int):
	code_editor.set_caret_column(curr_column() + amount)
func move_line_relative(amount:int):
	code_editor.set_caret_line(curr_line() + amount)

# Insertion
func insert_after():
	move_right()
	enable_insert()
func insert_at_beginning_of_line():
	var new_pos = code_editor.get_first_non_whitespace_column(curr_line())
	code_editor.set_caret_column(new_pos)
	enable_insert()
func newline_insert():
	code_editor.set_caret_column(99999)
	enable_insert()
	if code_editor.has_selection():
		code_editor.deselect()
	var enter = InputEventKey.new()
	enter.pressed = true
	enter.keycode = KEY_ENTER
	Input.parse_input_event(enter)
func paste():
	code_editor.paste()
func replace_one_character():
	TODO()
func replace_selection():
	if code_editor.has_selection():
		code_editor.delete_selection()
		enable_insert()
	
# Deletion
func delete_line():
	select_line()
	code_editor.cut()
func delete_at_cursor():
	code_editor.select(curr_line(), curr_column(), curr_line(), curr_column() +1)
	code_editor.delete_selection()
func delete_word():
	code_editor.select_word_under_caret()
	code_editor.delete_selection()
	
# Selection
func select_line():
	code_editor.select(curr_line(), 0, curr_line(), 999999)
func curr_column():
	return code_editor.get_caret_column()
func curr_line():
	return code_editor.get_caret_line()
func enter_visual_selection():
	visual_mode = true
	select_from_column = curr_column()
	select_from_line = curr_line()
	code_editor.select(curr_line(), curr_column(), curr_line(), curr_column() +1)
func enter_visual_line_selection():
	visual_line_mode = true
	select_from_line = curr_line()
	code_editor.select(curr_line(), 0, curr_line(), 99999)
	pass
func update_selection():
	if visual_line_mode:
		code_editor.select(select_from_line, 0, curr_line(), 9999)
	if visual_mode:
		code_editor.select(select_from_line, select_from_column, curr_line(), curr_column() +1)

# Other
func undo():
	code_editor.undo()
func redo():
	code_editor.redo()
func save():
	var saver = current_editor.get_script()
	TODO()
func search_function():
	TODO()
func copy():
	code_editor.copy()
func yank():
	if !visual_mode and !visual_line_mode:
		return -1 # Way to notify we aren't done with this input
	copy()
	code_editor.deselect()
func TODO():
	print("Have to implement this function")
