# godot-vim
VIM bindings for godot 4

Most typically used by myself, open to suggestions on missing bindings :)

## Bindings

"H"                            : move_left
"J"                            : move_down
"K"                            : move_up
"L"                            : move_right
"E"                            : move_to_end_of_word
"Shift+E"                      : move_to_next_whitespace
"B"                            : move_to_start_of_word
"Shift+B"                      : move_to_previous_whitespace
"Shift+G"                      : move_to_end_of_file
"G", "G"                       : move_to_beginning_of_file
"Shift+4"                      : move_to_end_of_line
"Shift+6"                      : move_to_start_of_line,  # stops before whitespac
"0"                            : move_to_zero_column
"Shift+8"                      : find_next_occurance_of_word
"N"                            : find_again
"Shift+N"                      : find_again_backwards
"I"                            : enable_insert
"Shift+I"                      : insert_at_beginning_of_line
"A"                            : insert_after
"Shift+A"                      : insert_at_end_of_line
"O"                            : newline_insert
"Shift+O"                      : previous_line_insert
"Ctrl+O"                       : jump_to_last_buffered_position
"P"                            : paste_after
"Shift+P"                      : paste_on_previous_line, # TODO: Correct functionalit
"R", "ANY"                     : replace_one_character,  # TODO: not workin
"S"                            : replace_selection
"X"                            : delete_at_cursor
"D"                            : visual_mode_delete
"D","D"                        : delete_line
"D", "W"                       : delete_word
"U"                            : undo
"Ctrl+R"                       : redo
"Shift+Semicolon","W", "Enter" : save
"Y"                            : visual_mode_yank
"Y", "Y"                       : yank_line
"V"                            : enter_visual_selection
"Shift+V"                      : enter_visual_line_selection
"/"                            : search_function
"Shift+Comma", "Shift+Comma"   : dedent
"Shift+Period", "Shift+Period" : indent,
"Z", "M"                       : fold_all
"Z", "R"                       : unfold_all,
"Z", "C"                       : fold_line
"Z", "O"                       : unfold_line