@tool
extends EditorPlugin


var script_editor : ScriptEditor
var vim_mode : bool = true
var visual_mode : bool = false
var input_buffer : Array = []
var clip_buffer : String = ""
var editor_interface : EditorInterface
var current_editor
var code_editor : CodeEdit
var bindings = {
	["H"]: move_left,
	["J"]: move_down,
	["K"]: move_up,
	["L"]: move_right,
	["I"]: disable_vim,
	["A"]: insert_after,
	["O"]: newline_insert,
	["P"]: paste,
	["D","D"]: delete_line,
	["U"]: undo,
	["Ctrl+R"]: redo,
	["Shift+Semicolon","W"]: TODO,
}


func _enter_tree() -> void:
	editor_interface = get_editor_interface()
	script_editor = editor_interface.get_script_editor()
	self.set_process_input(true)


func _input(event):
	current_editor = script_editor.get_current_editor()
	code_editor = current_editor.get_base_editor() as CodeEdit
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
				input_buffer.clear()
	
	#Have bufferable input
	if !input_buffer.is_empty():
		process_buffer()


func process_buffer() ->void :
	print(input_buffer)
	var valid = check_command(input_buffer)
	if valid == 1: #Full match
		input_buffer.clear()
	elif valid == 0: #Partial match??? 
		pass
	elif valid == -1: #No match
		input_buffer.clear()

func check_command(command:Array) -> int:
	if command in bindings.keys():
		bindings[command].call()
		return 1
	else:
		for key in bindings.keys():
			if command[0] in key: # TODO: Fix bugs
				print("Partial match: ", command)
				return 0
	return -1

func enable_vim():
	set_vim_mode(true)
func disable_vim():
	set_vim_mode(false)
func set_vim_mode(mode : bool):
	vim_mode = mode
	if vim_mode:
		code_editor.caret_type = TextEdit.CARET_TYPE_BLOCK
	else:
		code_editor.caret_type = TextEdit.CARET_TYPE_LINE

func move_right():
	move_column_relative(1)
func move_left():
	move_column_relative(-1)
func move_down():
	move_line_relative(1)
func move_up():
	move_line_relative(-1)

func insert_after():
	move_right()
	disable_vim()
	
func newline_insert():
	code_editor.set_caret_column(99999)
	disable_vim()
	var enter = InputEventKey.new()
	enter.pressed = true
	enter.keycode = KEY_ENTER
	Input.parse_input_event(enter)

func move_column_relative(amount:int):
	code_editor.set_caret_column(curr_column() + amount)

func move_line_relative(amount:int):
	code_editor.set_caret_line(curr_line() + amount)
	
func paste():
	code_editor.paste()
	
func delete_line():
	select_line()
	code_editor.cut()
	
func select_line():
	code_editor.select(curr_line(), 0, curr_line(), 999999)
	
func curr_column():
	return code_editor.get_caret_column()
func curr_line():
	return code_editor.get_caret_line()
func undo():
	code_editor.undo()
func redo():
	code_editor.redo()	
	
func TODO():
	pass
