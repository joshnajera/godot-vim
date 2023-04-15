@tool
extends EditorPlugin

var editor_interface : EditorInterface
var script_editor : ScriptEditor
var scrpit_editor_base : ScriptEditorBase
var code_editor : CodeEdit

var vim_mode : bool = true
var visual_mode : bool = false
var visual_line_mode : bool = false
var extra_processing : bool = false

var input_buffer : Array = []
var clip_buffer : String = ""
var search_buffer : String = ""
var jump_buffer : Array[Vector2] = []
var select_from_line = 0
var select_from_column = 0

var bindings = {
	["H"]: move_left,
	["J"]: move_down,
	["K"]: move_up,
	["L"]: move_right,
	["E"]: move_to_end_of_word,
	["Shift+E"]: move_to_next_whitespace,
	["B"]: move_to_start_of_word,
	["Shift+B"]:  move_to_previous_whitespace,
	["Shift+G"]: move_to_end_of_file,
	["G", "G"]: move_to_beginning_of_file,
	["Shift+4"]: move_to_end_of_line,
	["Shift+6"]: move_to_start_of_line, # stops before whitespace
	["0"]: move_to_zero_column,
	["Shift+8"]: find_next_occurance_of_word,
	["N"]: find_again,
	["Shift+N"]: find_again_backwards,
	["I"]: enable_insert,
	["Shift+I"]: insert_at_beginning_of_line,
	["A"]: insert_after,
	["Shift+A"]: insert_at_end_of_line,
	["O"]: newline_insert,
	["Shift+O"]: previous_line_insert,
	["Ctrl+O"]: jump_to_last_buffered_position,
	["P"]: paste_after,
	["Shift+P"]: paste_on_previous_line, # TODO: Correct functionality
	["R", "ANY"]: replace_one_character, # TODO: not working
	["S"]: replace_selection,
	["X"]: delete_at_cursor,
	["D"]: visual_mode_delete,
	["D","D"]: delete_line,
	["D", "W"]: delete_word,
	["U"]: undo,
	["Ctrl+R"]: redo,
	["Shift+Semicolon","W", "Enter"]: save,
	["Y"]: visual_mode_yank,
	["Y", "Y"]: yank_line,
	["V"]: enter_visual_selection,
	["Shift+V"]: enter_visual_line_selection,
	["Slash"]: search_function,
	["Shift+Comma", "Shift+Comma"]: dedent,
	["Shift+Period", "Shift+Period"]: indent, 
	["Z", "M"]: fold_all,
	["Z", "R"]: unfold_all , 
	["Z", "C"]: fold_line ,
	["Z", "O"]: unfold_line
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
	if new_keys in ["Ctrl+Z","Ctrl+S", "Ctrl+F", "Shift+Tab", "Ctrl+K", "Up", "Down", "Left", "Right", "Ctrl+Shift+Q"]:
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


## Checks for available commands to run, and manages clearing buffer.
func process_buffer() ->void :
	var valid = check_command(input_buffer)
	get_viewport().set_input_as_handled()
	if abs(valid) == 1: #Full match
		input_buffer.clear()
	elif valid == 0: #Partial match??? 
#		print("Spare buffer: ", input_buffer)
		pass
	elif valid == 2: # Special case -- ends with "ANY"
#		print("Processing ANY key")
		var copy_input_buffer = [] + input_buffer
		copy_input_buffer[copy_input_buffer.size()-1] = "ANY"
		if bindings.has(copy_input_buffer):
#			print(input_buffer[input_buffer.size()-1])
			bindings[copy_input_buffer].call(input_buffer[input_buffer.size()-1])
		input_buffer.clear()

## Command buffer parser --naive implementation, could be improved
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
				return 0 # Need to rewrite this to make sure the previous commands in the buffer match
#			if key[i-1] == "ANY":
#				print(key)
#				return 2
	return -1 # No matches at all?

###########################
####  BOUND FUNCTIONS  ####
###########################

# Enabling/Disabling VIM mode
func enable_vim():
	set_vim_mode(true)
func enable_insert():
	code_editor.deselect()
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
	update_selection()
func move_to_start_of_line():
	var start = code_editor.get_first_non_whitespace_column(curr_line())
	code_editor.set_caret_column(start)
	update_selection()
func move_to_end_of_file():
	push_jump_buffer()
	code_editor.set_caret_line(code_editor.get_line_count())
	move_to_end_of_line()
	update_selection()
func move_to_beginning_of_file():
	push_jump_buffer()
	code_editor.set_caret_column(0)
	code_editor.set_caret_line(0)
	update_selection()
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
func move_to_end_of_word():
	var current_text = code_editor.get_line(curr_line())
	move_column_relative(1)
	var i = curr_column()
	while i < len(current_text)-1:
		i+= 1 
#		print("I:", i)
#		print("len:", len(current_text))
		if current_text[i] in [' ',':','(',')','	','.',',']:
			break
		else:
			move_column_relative(1)
	if i == len(current_text):
		move_line_relative(1)
		code_editor.set_caret_column(0)
		move_to_end_of_word()
	update_selection()
func move_to_start_of_word():
	var current_text = code_editor.get_line(curr_line())
	move_column_relative(-1)
	var i = curr_column()
	while i > 0:
		i-= 1
		if current_text[i] in [' ',':','(',')','	','.',',']:
			break
		move_column_relative(-1)
	if i <= 0:
		move_line_relative(-1)
		code_editor.set_caret_column(99999)
		move_to_start_of_word()
	update_selection()
func move_to_next_whitespace():
	var current_text = code_editor.get_line(curr_line())
	move_column_relative(1)
	var i = curr_column()
	while i < len(current_text) -1 :
		i+= 1 
		if current_text[i] in [' ','	','\n']:
			break
		move_column_relative(1)
	if i == len(current_text):
		move_line_relative(1)
		code_editor.set_caret_column(0)
		move_to_next_whitespace()
	update_selection()
func move_to_previous_whitespace():
	var current_text = code_editor.get_line(curr_line())
	move_column_relative(-1)
	var i = curr_column()
	while i >0:
		i-= 1
		if current_text[i] in [' ','	','\n']:
			break
		move_column_relative(-1)
	if i <= 0:
		move_line_relative(-1)
		code_editor.set_caret_column(99999)
		move_to_previous_whitespace()
	update_selection()
func jump_to_last_buffered_position():
	var temp = jump_buffer.pop_front()
	code_editor.set_caret_line(temp.x)
	code_editor.set_caret_column(temp.y)
	update_selection()
func move_to_zero_column():
	code_editor.set_caret_column(0)

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
	simulate_press(KEY_ENTER)
func previous_line_insert():
	move_line_relative(-1)
	code_editor.set_caret_column(99999)
	enable_insert()
	simulate_press(KEY_ENTER)
func paste_after():
	move_column_relative(1)
	code_editor.paste()
func paste_on_previous_line():
	move_up()
	move_to_end_of_line()
	simulate_press(KEY_ENTER)
	code_editor.paste()
func replace_one_character(the_char): # TODO
	enable_insert()
	code_editor.select(curr_line(), curr_column(), curr_line(), curr_column() +1)
	code_editor.delete_selection()
	print("Simulate press", OS.find_keycode_from_string(the_char))
	simulate_press(OS.find_keycode_from_string(the_char))

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
	if !visual_mode and !visual_line_mode:
		return
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
		

# Folding
func unfold_all():
	code_editor.unfold_all_lines()
func fold_all():
	code_editor.fold_all_lines()
func unfold_line():
	code_editor.unfold_line(curr_line())
func fold_line():
	code_editor.fold_line(curr_line())
	

# Other
func undo():
	code_editor.undo()
func redo():
	code_editor.redo()
func save():	
	var press = InputEventKey.new()
	var release = InputEventKey.new()
	press.ctrl_pressed = true
	release.ctrl_pressed = true 
	press.keycode = KEY_S 
	release.keycode = KEY_S
	press.pressed = true
	release.pressed = false
	Input.parse_input_event(press)
	Input.parse_input_event(release) 

	pass
#	simulate_press(KEY_MASK_CTRL + KEY_S)
#	simulate_press(KEY_CTRL + KEY_S)
#	simulate_press(KEY_MASK_CMD_OR_CTRL + KEY_S)
	
#	print("Saving?")
## Resets visual modes to false
func reset_visual():
	visual_line_mode = false
	visual_mode = false
func indent():
	code_editor.indent_lines()
func dedent():
	code_editor.unindent_lines()
func search_function():
	var press = InputEventKey.new()
	var release = InputEventKey.new()
	press.ctrl_pressed = true
	release.ctrl_pressed = true 
	press.keycode = KEY_F 
	release.keycode = KEY_F
	press.pressed = true
	release.pressed = false
	Input.parse_input_event(press)
	Input.parse_input_event(release) 

func find_next_occurance_of_word():
	push_jump_buffer()
	code_editor.select_word_under_caret()
	search_buffer = code_editor.get_selected_text()
	code_editor.deselect()
	var result = code_editor.search(search_buffer, 0, curr_line(), curr_column())
	code_editor.set_caret_column(result.x)
	code_editor.set_caret_line(result.y)
func find_again():
	push_jump_buffer()
	if search_buffer != "":
		var result =code_editor.search(search_buffer, 0, curr_line(), curr_column() + 1)
		code_editor.set_caret_column(result.x)
		code_editor.set_caret_line(result.y)
func find_again_backwards():
	push_jump_buffer()
	if search_buffer != "":
		var result = code_editor.search(search_buffer, 4 , curr_line(), curr_column() -1)
		code_editor.set_caret_column(result.x)
		code_editor.set_caret_line(result.y)
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
# Helpers
func simulate_press(keycode):
#	print(keycode , " Received")
	var press = InputEventKey.new()
	var release = InputEventKey.new()
	press.keycode = keycode
	release.keycode = keycode
	press.pressed = true
	release.pressed = false
	Input.parse_input_event(press)
	Input.parse_input_event(release)
func push_jump_buffer():
	jump_buffer.push_front(Vector2(curr_line(),curr_column()))
	if(jump_buffer.size() > 50):
		jump_buffer.pop_back()
func TODO():
#	print("Have to implement this function")
	pass
