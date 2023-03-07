@tool
extends EditorPlugin

var editor_interface : EditorInterface
var script_editor : ScriptEditor
var scrpit_editor_base : ScriptEditorBase
var code_editor : CodeEdit

var vim_mode : bool = true
var visual_mode : bool = false
var visual_line_mode : bool = false

var input_buffer : Array = []
var clip_buffer : String = ""
var select_from_line = 0
var select_from_column = 0

var bindings = {
	["H"]: move_left,
	["J"]: move_down,
	["K"]: move_up,
	["L"]: move_right,
	["E"]: TODO, # End of word
	["B"]: TODO, # Beginning of word
	["Shift+G"]: move_to_end_of_file,
	["G", "G"]: move_to_beginning_of_file,
	["Shift+4"]: move_to_end_of_line,
	["Shift+6"]: move_to_start_of_line,
	["I"]: enable_insert,
	["Shift+I"]: insert_at_beginning_of_line,
	["A"]: insert_after,
	["Shift+A"]: insert_at_end_of_line,
	["O"]: newline_insert,
	["P"]: paste,
	["Shift+P"]: paste_on_previous_line,
	["R", "ANY"]: replace_one_character, # TODO
	["S"]: replace_selection,
	["X"]: delete_at_cursor,
	["D"]: visual_mode_delete,
	["D","D"]: delete_line,
	["D", "W"]: delete_word,
	["U"]: undo,
	["Ctrl+R"]: redo,
	["Shift+Semicolon","W", "Enter"]: save, #TODO - Not working
	["Y"]: visual_mode_yank,
	["Y", "Y"]: yank_line,
	["V"]: enter_visual_selection,
	["Shift+V"]: enter_visual_line_selection,
	["Slash"]: search_function, # TODO - Not Working
	["Shift+Comma", "Shift+Comma"]: dedent,
	["Shift+Period", "Shift+Period"]: indent, 
}

func _enter_tree() -> void:
	editor_interface = get_editor_interface()
	script_editor = editor_interface.get_script_editor()

func _input(event):
	scrpit_editor_base = script_editor.get_current_editor()
	if !scrpit_editor_base:
		return
	code_editor = scrpit_editor_base.get_base_editor() as CodeEdit
	if !code_editor:
		return
	if !code_editor.has_focus(): #Don't process when no focus
		return
	var key_event = event as InputEventKey
	if key_event == null or !key_event.is_pressed(): #Don't process when not a key action
		return
	
	var new_keys = key_event.as_text_keycode() # Check to not block some reserved keys
	if new_keys in ["Ctrl+Z","Ctrl+S", "Ctrl+F", "Shift+Tab", "Ctrl+K", "Up", "Down", "Left", "Right"]:
#		print("Reserved")
#		print(key_event.get_keycode_with_modifiers())
		return

	if vim_mode and event.is_pressed(): #We are in VIM mode
		if new_keys not in ["Shift","Ctrl","Alt","Escape"]: #Don't add these to input buffer.
			input_buffer.push_back(new_keys)
		
		#We are in insert mode
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
	get_viewport().set_input_as_handled()
	get_viewport().set_process_shortcut_input(true)
	
	if abs(valid) == 1: #Full match
		input_buffer.clear()
	elif valid == 0: #Partial match??? 
#		print("Spare buffer: ", input_buffer)
		pass

# Command buffer parser
func check_command(commands:Array) -> int:
#	print(commands)
	if commands in bindings.keys(): # Potential full-match
		var err = bindings[commands].call()
		if err == -1: # partial match
			return 0
		return 1 # full match
	else: # No immediate matches
		for key in bindings.keys(): # Comparing against each binding one by one
			var i = commands.size()
			if i > key.size(): # If command buffer iteration is bigger than length of binding then skip it.
				continue
			if commands[i-1] == key[i-1]: #Partial match, not done with buffer
				return 0
	return -1 # No matches at all?

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
func move_to_end_of_line():
	code_editor.set_caret_column(99999)
func move_to_start_of_line():
	var start = code_editor.get_first_non_whitespace_column(curr_line())
	code_editor.set_caret_column(start)
func move_to_end_of_file():
	code_editor.set_caret_line(code_editor.get_line_count())
	move_to_end_of_line()
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
func insert_at_end_of_line():
	code_editor.set_caret_column(99999)
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
func paste_on_previous_line():
	move_up()
	move_to_end_of_line()
	var enter = InputEventKey.new()
	enter.pressed = true
	enter.keycode = KEY_ENTER
	Input.parse_input_event(enter)
	paste()
func replace_one_character(): # TODO
	TODO()
func replace_selection():
	if !code_editor.has_selection():
		code_editor.select(curr_line(), curr_column(), curr_line(), curr_column() +1)
	code_editor.delete_selection()
	enable_insert()
	
# Deletion
func delete_line():
	select_line()
	code_editor.cut()
func delete_at_cursor():
	var line_len = len(code_editor.get_line(curr_line()))
	if line_len == curr_column():
		code_editor.select(curr_line(), curr_column(), curr_line(), curr_column() -1)
	else:
		code_editor.select(curr_line(), curr_column(), curr_line(), curr_column() +1)
	code_editor.delete_selection()
func delete_word():
	code_editor.select_word_under_caret()
	code_editor.delete_selection()
func visual_mode_delete():
	if !visual_mode and !visual_line_mode:
		return -1
	if  code_editor.has_selection():
		copy()
		code_editor.delete_selection()
		reset_visual()


# Selection
func select_line():
	code_editor.select(curr_line() -1, 99999, curr_line(), 999999)
func curr_column():
	return code_editor.get_caret_column()
func curr_line():
	return code_editor.get_caret_line()
func enter_visual_selection():
	visual_mode = !visual_mode
	if !visual_mode:
		code_editor.deselect()
		return
	select_from_column = curr_column()
	select_from_line = curr_line()
	code_editor.select(curr_line(), curr_column(), curr_line(), curr_column() +1)
func enter_visual_line_selection():
	visual_line_mode = true
	select_from_line = curr_line()
	code_editor.select(curr_line(), 0, curr_line(), 99999)
func update_selection():
	var offset = 1
	var select_offset = 0
	var v_offset = 0
	if (curr_line() < select_from_line):
		offset = 0
		select_offset = 1
		v_offset = 1
	if (curr_line() == select_from_line and curr_column() < select_from_column):
		select_offset = 1
		offset = 0
		v_offset = 0
	if visual_line_mode:
		code_editor.select(select_from_line, 0 if (v_offset == 0) else 99999, curr_line(), 99999 if (v_offset == 0) else 0)
	if visual_mode:
		code_editor.select(select_from_line, select_from_column + select_offset, curr_line(), curr_column() + offset)

# Other
func undo():
	code_editor.undo()
func redo():
	code_editor.redo()
func save():
#	print("Saving?")
	var press_save = InputEventKey.new()
	press_save.keycode = KEY_MASK_CTRL + KEY_S
	press_save.pressed = true
	Input.parse_input_event(press_save)#	file = null # File is closed.
## Resets visual modes to false
func reset_visual():
	visual_line_mode = false
	visual_mode = false
func indent():
	code_editor.indent_lines()
func dedent():
	code_editor.unindent_lines()
func search_function():
#	print("Searching?")
	print(script_editor.find_child("FindReplaceBar"))
	var press_search = InputEventKey.new()
	press_search.keycode = KEY_MASK_CTRL + KEY_F
	press_search.pressed = true
	Input.parse_input_event(press_search)
func copy():
	code_editor.copy()
func visual_mode_yank():
	if !visual_mode and !visual_line_mode:
		return -1 # Way to notify we aren't done with this input
	copy()
	code_editor.deselect()
	reset_visual()
func yank_line():
	select_line()
	copy()
	code_editor.deselect()
	reset_visual()
func TODO():
#	print("Have to implement this function")
	pass
