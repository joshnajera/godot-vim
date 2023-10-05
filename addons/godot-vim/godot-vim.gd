@tool
extends EditorPlugin


const INF_COL : int = 99999
const DEBUGGING : int = 0 # Change to 1 for debugging
const CODE_MACRO_PLAY_END : int = 10000

const BREAKERS : Dictionary = { '!': 1, '"': 1, '#': 1, '$': 1, '%': 1, '&': 1, '(': 1, ')': 1, '*': 1, '+': 1, ',': 1, '-': 1, '.': 1, '/': 1, ':': 1, ';': 1, '<': 1, '=': 1, '>': 1, '?': 1, '@': 1, '[': 1, '\\': 1, ']': 1, '^': 1, '`': 1, '\'': 1, '{': 1, '|': 1, '}': 1, '~': 1 }
const WHITESPACE: Dictionary = { ' ': 1, '	': 1, '\n' : 1 }
const ALPHANUMERIC: Dictionary = { 'a': 1, 'b': 1, 'c': 1, 'd': 1, 'e': 1, 'f': 1, 'g': 1, 'h': 1, 'i': 1, 'j': 1, 'k': 1, 'l': 1, 'm': 1, 'n': 1, 'o': 1, 'p': 1, 'q': 1, 'r': 1, 's': 1, 't': 1, 'u': 1, 'v': 1, 'w': 1, 'x': 1, 'y': 1, 'z': 1, 'A': 1, 'B': 1, 'C': 1, 'D': 1, 'E': 1, 'F': 1, 'G': 1, 'H': 1, 'I': 1, 'J': 1, 'K': 1, 'L': 1, 'M': 1, 'N': 1, 'O': 1, 'P': 1, 'Q': 1, 'R': 1, 'S': 1, 'T': 1, 'U': 1, 'V': 1, 'W': 1, 'X': 1, 'Y': 1, 'Z': 1, '0': 1, '1': 1, '2': 1, '3': 1, '4': 1, '5': 1, '6': 1, '7': 1, '8': 1, '9': 1, '_': 1 }
const LOWER_ALPHA: Dictionary = { 'a': 1, 'b': 1, 'c': 1, 'd': 1, 'e': 1, 'f': 1, 'g': 1, 'h': 1, 'i': 1, 'j': 1, 'k': 1, 'l': 1, 'm': 1, 'n': 1, 'o': 1, 'p': 1, 'q': 1, 'r': 1, 's': 1, 't': 1, 'u': 1, 'v': 1, 'w': 1, 'x': 1, 'y': 1, 'z': 1 }
const SYMBOLS = { "(": ")", ")": "(", "[": "]", "]": "[", "{": "}", "}": "{", "<": ">", ">": "<", '"': '"', "'": "'" }


enum {
    MOTION,
    OPERATOR,
    OPERATOR_MOTION,
    ACTION,
}


enum Context {
    NORMAL,
    VISUAL,
}


var the_key_map : Array[Dictionary] = [
    # Move
    { "keys": ["H"],                            "type": MOTION, "motion": "move_by_characters", "motion_args": { "forward": false } },
    { "keys": ["L"],                            "type": MOTION, "motion": "move_by_characters", "motion_args": { "forward": true } },
    { "keys": ["J"],                            "type": MOTION, "motion": "move_by_lines", "motion_args": { "forward": true, "line_wise": true } },
    { "keys": ["K"],                            "type": MOTION, "motion": "move_by_lines", "motion_args": { "forward": false, "line_wise": true } },
    { "keys": ["Shift+Equal"],                  "type": MOTION, "motion": "move_by_lines", "motion_args": { "forward": true, "to_first_char": true } },
    { "keys": ["Minus"],                        "type": MOTION, "motion": "move_by_lines", "motion_args": { "forward": false, "to_first_char": true } },
    { "keys": ["Shift+4"],                      "type": MOTION, "motion": "move_to_end_of_line", "motion_args": { "inclusive": true } },
    { "keys": ["Shift+6"],                      "type": MOTION, "motion": "move_to_first_non_white_space_character" },
    { "keys": ["0"],                            "type": MOTION, "motion": "move_to_start_of_line" },
    { "keys": ["Shift+H"],                      "type": MOTION, "motion": "move_to_top_line", "motion_args": { "to_jump_list": true } },
    { "keys": ["Shift+L"],                      "type": MOTION, "motion": "move_to_bottom_line", "motion_args": { "to_jump_list": true } },
    { "keys": ["Shift+M"],                      "type": MOTION, "motion": "move_to_middle_line", "motion_args": { "to_jump_list": true } },
    { "keys": ["G", "G"],                       "type": MOTION, "motion": "move_to_line_or_edge_of_document", "motion_args": { "forward": false, "to_jump_list": true } },
    { "keys": ["Shift+G"],                      "type": MOTION, "motion": "move_to_line_or_edge_of_document", "motion_args": { "forward": true, "to_jump_list": true } },
    { "keys": ["Ctrl+F"],                       "type": MOTION, "motion": "move_by_page", "motion_args": { "forward": true } },
    { "keys": ["Ctrl+B"],                       "type": MOTION, "motion": "move_by_page", "motion_args": { "forward": false } },
    { "keys": ["Ctrl+D"],                       "type": MOTION, "motion": "move_by_scroll", "motion_args": { "forward": true } },
    { "keys": ["Ctrl+U"],                       "type": MOTION, "motion": "move_by_scroll", "motion_args": { "forward": false } },
    { "keys": ["Shift+BackSlash"],              "type": MOTION, "motion": "move_to_column" },
    { "keys": ["W"],                            "type": MOTION, "motion": "move_by_words", "motion_args": { "forward": true, "word_end": false, "big_word": false } },
    { "keys": ["Shift+W"],                      "type": MOTION, "motion": "move_by_words", "motion_args": { "forward": true, "word_end": false, "big_word": true } },
    { "keys": ["E"],                            "type": MOTION, "motion": "move_by_words", "motion_args": { "forward": true, "word_end": true, "big_word": false, "inclusive": true } },
    { "keys": ["Shift+E"],                      "type": MOTION, "motion": "move_by_words", "motion_args": { "forward": true, "word_end": true, "big_word": true, "inclusive": true } },
    { "keys": ["B"],                            "type": MOTION, "motion": "move_by_words", "motion_args": { "forward": false, "word_end": false, "big_word": false } },
    { "keys": ["Shift+B"],                      "type": MOTION, "motion": "move_by_words", "motion_args": { "forward": false, "word_end": false, "big_word": true } },
    { "keys": ["G", "E"],                       "type": MOTION, "motion": "move_by_words", "motion_args": { "forward": false, "word_end": true, "big_word": false } },
    { "keys": ["G", "Shift+E"],                 "type": MOTION, "motion": "move_by_words", "motion_args": { "forward": false, "word_end": true, "big_word": true } },
    { "keys": ["Shift+5"],                      "type": MOTION, "motion": "move_to_matched_symbol", "motion_args": { "inclusive": true, "to_jump_list": true } },
    { "keys": ["F", "{char}"],                  "type": MOTION, "motion": "move_to_next_char", "motion_args": { "forward": true, "inclusive": true } },
    { "keys": ["Shift+F", "{char}"],            "type": MOTION, "motion": "move_to_next_char", "motion_args": { "forward": false } },
    { "keys": ["T", "{char}"],                  "type": MOTION, "motion": "move_to_next_char", "motion_args": { "forward": true, "stop_before": true, "inclusive": true } },
    { "keys": ["Shift+T", "{char}"],            "type": MOTION, "motion": "move_to_next_char", "motion_args": { "forward": false, "stop_before": true } },
    { "keys": ["Semicolon"],                    "type": MOTION, "motion": "repeat_last_char_search", "motion_args": {} },
    { "keys": ["Shift+8"],                      "type": MOTION, "motion": "find_word_under_caret", "motion_args": { "forward": true, "to_jump_list": true } },
    { "keys": ["Shift+3"],                      "type": MOTION, "motion": "find_word_under_caret", "motion_args": { "forward": false, "to_jump_list": true } },
    { "keys": ["N"],                            "type": MOTION, "motion": "find_again", "motion_args": { "forward": true, "to_jump_list": true } },
    { "keys": ["Shift+N"],                      "type": MOTION, "motion": "find_again", "motion_args": { "forward": false, "to_jump_list": true } },
    { "keys": ["A", "Shift+9"],                 "type": MOTION, "motion": "text_object", "motion_args": { "inner": false, "object":"(" } },
    { "keys": ["A", "Shift+0"],                 "type": MOTION, "motion": "text_object", "motion_args": { "inner": false, "object":"(" } },
    { "keys": ["A", "B"],                       "type": MOTION, "motion": "text_object", "motion_args": { "inner": false, "object":"(" } },
    { "keys": ["A", "BracketLeft"],             "type": MOTION, "motion": "text_object", "motion_args": { "inner": false, "object":"[" } },
    { "keys": ["A", "BracketRight"],            "type": MOTION, "motion": "text_object", "motion_args": { "inner": false, "object":"[" } },
    { "keys": ["A", "Shift+BracketLeft"],       "type": MOTION, "motion": "text_object", "motion_args": { "inner": false, "object":"{" } },
    { "keys": ["A", "Shift+BracketRight"],      "type": MOTION, "motion": "text_object", "motion_args": { "inner": false, "object":"{" } },
    { "keys": ["A", "Shift+B"],                 "type": MOTION, "motion": "text_object", "motion_args": { "inner": false, "object":"{" } },
    { "keys": ["A", "Apostrophe"],              "type": MOTION, "motion": "text_object", "motion_args": { "inner": false, "object":"'" } },
    { "keys": ["A", 'Shift+Apostrophe'],        "type": MOTION, "motion": "text_object", "motion_args": { "inner": false, "object":'"' } },
    { "keys": ["I", "Shift+9"],                 "type": MOTION, "motion": "text_object", "motion_args": { "inner": true, "object":"(" } },
    { "keys": ["I", "Shift+0"],                 "type": MOTION, "motion": "text_object", "motion_args": { "inner": true, "object":"(" } },
    { "keys": ["I", "B"],                       "type": MOTION, "motion": "text_object", "motion_args": { "inner": true, "object":"(" } },
    { "keys": ["I", "BracketLeft"],             "type": MOTION, "motion": "text_object", "motion_args": { "inner": true, "object":"[" } },
    { "keys": ["I", "BracketRight"],            "type": MOTION, "motion": "text_object", "motion_args": { "inner": true, "object":"[" } },
    { "keys": ["I", "Shift+BracketLeft"],       "type": MOTION, "motion": "text_object", "motion_args": { "inner": true, "object":"{" } },
    { "keys": ["I", "Shift+BracketRight"],      "type": MOTION, "motion": "text_object", "motion_args": { "inner": true, "object":"{" } },
    { "keys": ["I", "Shift+B"],                 "type": MOTION, "motion": "text_object", "motion_args": { "inner": true, "object":"{" } },
    { "keys": ["I", "Apostrophe"],              "type": MOTION, "motion": "text_object", "motion_args": { "inner": true, "object":"'" } },
    { "keys": ["I", 'Shift+Apostrophe'],        "type": MOTION, "motion": "text_object", "motion_args": { "inner": true, "object":'"' } },
    { "keys": ["I", "W"],                       "type": MOTION, "motion": "text_object", "motion_args": { "inner": true, "object":"w" } },
    { "keys": ["D"],                            "type": OPERATOR, "operator": "delete" },
    { "keys": ["Shift+D"],                      "type": OPERATOR_MOTION, "operator": "delete", "motion": "move_to_end_of_line", "motion_args": { "inclusive": true } },
    { "keys": ["Y"],                            "type": OPERATOR, "operator": "yank" },
    { "keys": ["Shift+Y"],                      "type": OPERATOR_MOTION, "operator": "yank", "motion": "move_to_end_of_line", "motion_args": { "inclusive": true } },
    { "keys": ["C"],                            "type": OPERATOR, "operator": "change" },
    { "keys": ["Shift+C"],                      "type": OPERATOR_MOTION, "operator": "change", "motion": "move_to_end_of_line", "motion_args": { "inclusive": true } },
    { "keys": ["X"],                            "type": OPERATOR_MOTION, "operator": "delete", "motion": "move_by_characters", "motion_args": { "forward": true, "one_line": true }, "context": Context.NORMAL },
    { "keys": ["X"],                            "type": OPERATOR, "operator": "delete", "context": Context.VISUAL },
    { "keys": ["Shift+X"],                      "type": OPERATOR_MOTION, "operator": "delete", "motion": "move_by_characters", "motion_args": { "forward": false } },
    { "keys": ["U"],                            "type": OPERATOR, "operator": "change_case", "operator_args": { "lower": true }, "context": Context.VISUAL },
    { "keys": ["Shift+U"],                      "type": OPERATOR, "operator": "change_case", "operator_args": { "lower": false }, "context": Context.VISUAL },
    { "keys": ["Shift+QuoteLeft"],              "type": OPERATOR, "operator": "toggle_case", "operator_args": {}, "context": Context.VISUAL },
    { "keys": ["Shift+QuoteLeft"],              "type": OPERATOR_MOTION, "operator": "toggle_case", "motion": "move_by_characters", "motion_args": { "forward": true }, "context": Context.NORMAL },
    { "keys": ["P"],                            "type": ACTION, "action": "paste", "action_args": { "after": true } },
    { "keys": ["Shift+P"],                      "type": ACTION, "action": "paste", "action_args": { "after": false } },
    { "keys": ["U"],                            "type": ACTION, "action": "undo", "action_args": {}, "context": Context.NORMAL },
    { "keys": ["Ctrl+R"],                       "type": ACTION, "action": "redo", "action_args": {} },
    { "keys": ["R", "{char}"],                  "type": ACTION, "action": "replace", "action_args": {} },
    { "keys": ["Period"],                       "type": ACTION, "action": "repeat_last_edit", "action_args": {} },
    { "keys": ["I"],                            "type": ACTION, "action": "enter_insert_mode", "action_args": { "insert_at": "inplace" }, "context": Context.NORMAL },
    { "keys": ["Shift+I"],                      "type": ACTION, "action": "enter_insert_mode", "action_args": { "insert_at": "bol" } },
    { "keys": ["A"],                            "type": ACTION, "action": "enter_insert_mode", "action_args": { "insert_at": "after" }, "context": Context.NORMAL },
    { "keys": ["Shift+A"],                      "type": ACTION, "action": "enter_insert_mode", "action_args": { "insert_at": "eol" } },
    { "keys": ["O"],                            "type": ACTION, "action": "enter_insert_mode", "action_args": { "insert_at": "new_line_below" } },
    { "keys": ["Shift+O"],                      "type": ACTION, "action": "enter_insert_mode", "action_args": { "insert_at": "new_line_above" } },
    { "keys": ["V"],                            "type": ACTION, "action": "enter_visual_mode", "action_args": { "line_wise": false } },
    { "keys": ["Shift+V"],                      "type": ACTION, "action": "enter_visual_mode", "action_args": { "line_wise": true } },
    { "keys": ["Slash"],                        "type": ACTION, "action": "search", "action_args": {} },
    { "keys": ["Ctrl+O"],                       "type": ACTION, "action": "jump_list_walk", "action_args": { "forward": false } },
    { "keys": ["Ctrl+I"],                       "type": ACTION, "action": "jump_list_walk", "action_args": { "forward": true } },
    { "keys": ["Z", "A"],                       "type": ACTION, "action": "toggle_folding", },
    { "keys": ["Z", "Shift+M"],                 "type": ACTION, "action": "fold_all", },
    { "keys": ["Z", "Shift+R"],                 "type": ACTION, "action": "unfold_all", },
    { "keys": ["Q", "{char}"],                  "type": ACTION, "action": "record_macro", "when_not": "is_recording" },
    { "keys": ["Q"],                            "type": ACTION, "action": "stop_record_macro", "when": "is_recording" },
    { "keys": ["Shift+2", "{char}"],            "type": ACTION, "action": "play_macro", },
    { "keys": ["Shift+Comma"],                  "type": ACTION, "action": "indent", "action_args": { "forward" = false} },
    { "keys": ["Shift+Period"],                 "type": ACTION, "action": "indent", "action_args": {  "forward" = true } },
    { "keys": ["Shift+J"],                      "type": ACTION, "action": "join_lines", "action_args": {} },
    { "keys": ["M", "{char}"],                  "type": ACTION, "action": "set_bookmark", "action_args": {} },
    { "keys": ["Apostrophe", "{char}"],         "type": MOTION, "motion": "go_to_bookmark", "motion_args": {} },
]


# The list of command keys we handle (other command keys will be handled by Godot)
var command_keys_white_list : Dictionary = {
    "Escape": 1,
    "Enter": 1,
    # "Ctrl+F": 1,  # Uncomment if you would like move-forward by page function instead of search on slash
    "Ctrl+B": 1,
    "Ctrl+U": 1,
    "Ctrl+D": 1,
    "Ctrl+O": 1,
    "Ctrl+I": 1,
    "Ctrl+R": 1
}


var editor_interface : EditorInterface
var the_ed := EditorAdaptor.new() # The current editor adaptor
var the_vim := Vim.new()
var the_dispatcher := CommandDispatcher.new(the_key_map) # The command dispatcher


func _enter_tree() -> void:
    editor_interface = get_editor_interface()

    var script_editor = editor_interface.get_script_editor()
    script_editor.editor_script_changed.connect(on_script_changed)
    script_editor.script_close.connect(on_script_closed)
    on_script_changed(script_editor.get_current_script())

    var settings = editor_interface.get_editor_settings()
    settings.settings_changed.connect(on_settings_changed)
    on_settings_changed()

    var find_bar = find_first_node_of_type(script_editor, 'FindReplaceBar')
    var find_bar_line_edit : LineEdit = find_first_node_of_type(find_bar, 'LineEdit')
    find_bar_line_edit.text_changed.connect(on_search_text_changed)


func _input(event) -> void:
    var key = event as InputEventKey

    # Don't process when not a key action
    if key == null or !key.is_pressed() or not the_ed.has_focus():
        return

    if key.get_keycode_with_modifiers() == KEY_NONE and key.unicode == CODE_MACRO_PLAY_END:
        the_vim.macro_manager.on_macro_finished(the_ed)
        get_viewport().set_input_as_handled()
        return

    # Check to not block some reserved keys (we only handle unicode keys and the white list)
    var key_code = key.as_text_keycode()
    if DEBUGGING:
        print("Key: %s Buffer: %s" % [key_code, the_vim.current.input_state.key_codes()])

    # We only process keys in the white list or it is ASCII char or SHIFT+ASCII char
    if key.get_keycode_with_modifiers() & (~KEY_MASK_SHIFT) > 128 and key_code not in command_keys_white_list:
        return

    if the_dispatcher.dispatch(key, the_vim, the_ed):
        get_viewport().set_input_as_handled()


func on_script_changed(s: Script) -> void:
    the_vim.set_current_session(s, the_ed)

    var script_editor = editor_interface.get_script_editor()
    var scrpit_editor_base := script_editor.get_current_editor()
    if scrpit_editor_base:
        var code_editor := scrpit_editor_base.get_base_editor() as CodeEdit
        the_ed.set_code_editor(code_editor)
        the_ed.set_block_caret(true)

        if not code_editor.is_connected("caret_changed", on_caret_changed):
            code_editor.caret_changed.connect(on_caret_changed)
        if not code_editor.is_connected("lines_edited_from", on_lines_edited_from):
            code_editor.lines_edited_from.connect(on_lines_edited_from)


func on_script_closed(s: Script) -> void:
    the_vim.remove_session(s)


func on_settings_changed() -> void:
    var settings := editor_interface.get_editor_settings()
    the_ed.notify_settings_changed(settings)


func on_caret_changed()-> void:
    the_ed.set_block_caret(not the_vim.current.insert_mode)


func on_lines_edited_from(from: int, to: int) -> void:
    the_vim.current.jump_list.on_lines_edited(from, to)
    the_vim.current.text_change_number += 1
    the_vim.current.bookmark_manager.on_lines_edited(from, to)


func on_search_text_changed(new_search_text: String) -> void:
    the_vim.search_buffer = new_search_text


static func find_first_node_of_type(p: Node, type: String) -> Node:
    if p.get_class() == type:
        return p
    for c in p.get_children():
        var t := find_first_node_of_type(c, type)
        if t:
            return t
    return null


class Command:

    ###  MOTIONS

    static func move_by_characters(cur: Position, args: Dictionary, ed: EditorAdaptor, vim: Vim) -> Position:
        var one_line = args.get('one_line', false)
        var col : int = cur.column + args.repeat * (1 if args.forward else -1)
        var line := cur.line
        if col > ed.last_column(line):
            if one_line:
                col = ed.last_column(line) + 1
            else:
                line += 1
                col = 0
        elif col < 0:
            if one_line:
                col = 0
            else:
                line -= 1
                col = ed.last_column(line)
        return Position.new(line, col)

    static func move_by_scroll(cur: Position, args: Dictionary, ed: EditorAdaptor, vim: Vim) -> Position:
        var count = ed.get_visible_line_count(ed.first_visible_line(), ed.last_visible_line())
        return Position.new(ed.next_unfolded_line(cur.line, count / 2, args.forward), cur.column)

    static func move_by_page(cur: Position, args: Dictionary, ed: EditorAdaptor, vim: Vim) -> Position:
        var count = ed.get_visible_line_count(ed.first_visible_line(), ed.last_visible_line())
        return Position.new(ed.next_unfolded_line(cur.line, count, args.forward), cur.column)

    static func move_to_column(cur: Position, args: Dictionary, ed: EditorAdaptor, vim: Vim) -> Position:
        return Position.new(cur.line, args.repeat - 1)

    static func move_by_lines(cur: Position, args: Dictionary, ed: EditorAdaptor, vim: Vim) -> Position:
        # Depending what our last motion was, we may want to do different things.
        # If our last motion was moving vertically, we want to preserve the column from our
        # last horizontal move.  If our last motion was going to the end of a line,
        # moving vertically we should go to the end of the line, etc.
        var col : int = cur.column
        match vim.current.last_motion:
            "move_by_lines", "move_by_scroll", "move_by_page", "move_to_end_of_line", "move_to_column":
                col = vim.current.last_h_pos
            _:
                vim.current.last_h_pos = col

        var line = ed.next_unfolded_line(cur.line, args.repeat, args.forward)
        if args.get("to_first_char", false):
            col = ed.find_first_non_white_space_character(line)

        return Position.new(line, col)

    static func move_to_first_non_white_space_character(cur: Position, args: Dictionary, ed: EditorAdaptor, vim: Vim) -> Position:
        var i := ed.find_first_non_white_space_character(ed.curr_line())
        return Position.new(cur.line, i)

    static func move_to_start_of_line(cur: Position, args: Dictionary, ed: EditorAdaptor, vim: Vim) -> Position:
        return Position.new(cur.line, 0)

    static func move_to_end_of_line(cur: Position, args: Dictionary, ed: EditorAdaptor, vim: Vim) -> Position:
        var line = cur.line
        if args.repeat > 1:
            line = ed.next_unfolded_line(line, args.repeat - 1)
        vim.current.last_h_pos = INF_COL
        return Position.new(line, ed.last_column(line))

    static func move_to_top_line(cur: Position, args: Dictionary, ed: EditorAdaptor, vim: Vim) -> Position:
        return Position.new(ed.first_visible_line(), cur.column)

    static func move_to_bottom_line(cur: Position, args: Dictionary, ed: EditorAdaptor, vim: Vim) -> Position:
        return Position.new(ed.last_visible_line(), cur.column)

    static func move_to_middle_line(cur: Position, args: Dictionary, ed: EditorAdaptor, vim: Vim) -> Position:
        var first := ed.first_visible_line()
        var count = ed.get_visible_line_count(first, ed.last_visible_line())
        return Position.new(ed.next_unfolded_line(first, count / 2), cur.column)

    static func move_to_line_or_edge_of_document(cur: Position, args: Dictionary, ed: EditorAdaptor, vim: Vim) -> Position:
        var line = ed.last_line() if args.forward else ed.first_line()
        if args.repeat_is_explicit:
            line = args.repeat + ed.first_line() - 1
        return Position.new(line, ed.find_first_non_white_space_character(line))

    static func move_by_words(cur: Position, args: Dictionary, ed: EditorAdaptor, vim: Vim) -> Position:
        var start_line := cur.line
        var start_col := cur.column
        var start_pos := cur.duplicate()

        # If we are beyond line end, move it to line end
        if start_col > 0 and start_col == ed.last_column(start_line) + 1:
            cur = Position.new(start_line, start_col-1)

        var forward : bool = args.forward
        var word_end : bool = args.word_end
        var big_word : bool = args.big_word
        var repeat : int = args.repeat
        var empty_line_is_word := not (forward and word_end) # For 'e', empty lines are not considered words
        var one_line := not vim.current.input_state.operator.is_empty() # if there is an operator pending, let it not beyond the line end each time

        if (forward and !word_end) or (not forward and word_end): # w or ge
            repeat += 1

        var words : Array[TextRange] = []
        for i in range(repeat):
            var word = _find_word(cur, ed, forward, big_word, empty_line_is_word, one_line)
            if word != null:
                words.append(word)
                cur = Position.new(word.from.line, word.to.column-1 if forward else word.from.column)
            else: # eof
                words.append(TextRange.new(ed.last_pos(), ed.last_pos()) if forward else TextRange.zero)
                break

        var short_circuit : bool = len(words) != repeat
        var first_word := words[0]
        var last_word : TextRange = words.pop_back()
        if forward and not word_end: # w
            if vim.current.input_state.operator == "change":  # cw need special treatment to not cover whitespaces
                if not short_circuit:
                    last_word = words.pop_back()
                return last_word.to
            if not short_circuit and not start_pos.equals(first_word.from):
                last_word = words.pop_back() # We did not start in the middle of a word. Discard the extra word at the end.
            return last_word.from
        elif forward and word_end: # e
            return last_word.to.left()
        elif not forward and word_end: # ge
            if not short_circuit and not start_pos.equals(first_word.to.left()):
                last_word = words.pop_back() # We did not start in the middle of a word. Discard the extra word at the end.
            return last_word.to.left()
        else: # b
            return last_word.from

    static func move_to_matched_symbol(cur: Position, args: Dictionary, ed: EditorAdaptor, vim: Vim) -> Position:
        # Get the symbol to match
        var symbol := ed.find_forward(cur.line, cur.column, func(c): return c.char in "()[]{}", true)
        if symbol == null: # No symbol found in this line after or under caret
            return null

        var counter_part : String = SYMBOLS[symbol.char]

        # Two attemps to find the symbol pair: from line start or doc start
        for from in [Position.new(symbol.line, 0), Position.new(0, 0)]:
            var parser = GDScriptParser.new(ed, from)
            if not parser.parse_until(symbol):
               continue

            if symbol.char in ")]}":
                parser.stack.reverse()
                for p in parser.stack:
                    if p.char == counter_part:
                        return p
                continue
            else:
                parser.parse_one_char()
                return parser.find_matching()
        return null

    static func move_to_next_char(cur: Position, args: Dictionary, ed: EditorAdaptor, vim: Vim) -> Position:
        vim.last_char_search = args

        var forward : bool = args.forward
        var stop_before : bool = args.get("stop_before", false)
        var to_find = args.selected_character
        var repeat : int = args.repeat

        var old_pos := cur.duplicate()
        for ch in ed.chars(cur.line, cur.column + (1 if forward else -1), forward, true):
            if ch.char == to_find:
                repeat -= 1
                if repeat == 0:
                    return old_pos if stop_before else Position.new(ch.line, ch.column)
            old_pos = Position.new(ch.line, ch.column)
        return null

    static func repeat_last_char_search(cur: Position, args: Dictionary, ed: EditorAdaptor, vim: Vim) -> Position:
        var last_char_search := vim.last_char_search
        if last_char_search.is_empty():
            return null
        args.forward = last_char_search.forward
        args.selected_character = last_char_search.selected_character
        args.stop_before = last_char_search.get("stop_before", false)
        args.inclusive = last_char_search.get("inclusive", false)
        return move_to_next_char(cur, args, ed, vim)

    static func expand_to_line(cur: Position, args: Dictionary, ed: EditorAdaptor, vim: Vim) -> Position:
        return Position.new(cur.line + args.repeat - 1, INF_COL)

    static func find_word_under_caret(cur: Position, args: Dictionary, ed: EditorAdaptor, vim: Vim) -> Position:
        var forward : bool = args.forward
        var range := ed.get_word_at_pos(cur.line, cur.column)
        var text := ed.range_text(range)
        var pos := ed.search(text, cur.line, cur.column + (1 if forward else -1), false, true, forward)
        vim.last_search_command = "*" if forward else "#"
        vim.search_buffer = text
        return pos

    static func find_again(cur: Position, args: Dictionary, ed: EditorAdaptor, vim: Vim) -> Position:
        var forward : bool = args.forward
        forward = forward == (vim.last_search_command != "#")
        var case_sensitive := vim.last_search_command in "*#"
        var whole_word := vim.last_search_command in "*#"
        cur = cur.next(ed) if forward else cur.prev(ed)
        return ed.search(vim.search_buffer, cur.line, cur.column, case_sensitive, whole_word, forward)

    static func text_object(cur: Position, args: Dictionary, ed: EditorAdaptor, vim: Vim) -> Variant:
        var inner : bool = args.inner
        var obj : String = args.object

        if obj == "w" and inner:
            return ed.get_word_at_pos(cur.line, cur.column)

        if obj in "([{\"'":
            var counter_part : String = SYMBOLS[obj]
            for from in [Position.new(cur.line, 0), Position.new(0, 0)]: # Two attemps: from line beginning doc beginning
                var parser = GDScriptParser.new(ed, from)
                if not parser.parse_until(cur):
                    continue

                var range = TextRange.zero
                if parser.stack_top_char == obj:
                    range.from = parser.stack.back()
                    range.to = parser.find_matching()
                elif ed.char_at(cur.line, cur.column) == obj:
                    parser.parse_one_char()
                    range.from = parser.pos
                    range.to = parser.find_matching()
                else:
                    continue

                if range.from == null or range.to == null:
                    continue

                if inner:
                    range.from = range.from.next(ed)
                else:
                    range.to = range.to.next(ed)
                return range

        return null


###  OPERATORS

    static func delete(args: Dictionary, ed: EditorAdaptor, vim: Vim) -> void:
        var text := ed.selected_text()
        vim.register.set_text(text, args.get("line_wise", false))
        ed.delete_selection()
        var line := ed.curr_line()
        var col := ed.curr_column()
        if col > ed.last_column(line): # If after deletion we are beyond the end, move left
            ed.set_curr_column(ed.last_column(line))

    static func yank(args: Dictionary, ed: EditorAdaptor, vim: Vim) -> void:
        var text := ed.selected_text()
        ed.deselect()
        vim.register.set_text(text, args.get("line_wise", false))

    static func change(args: Dictionary, ed: EditorAdaptor, vim: Vim) -> void:
        var text := ed.selected_text()
        vim.register.set_text(text, args.get("line_wise", false))

        vim.current.enter_insert_mode();
        ed.delete_selection()

    static func change_case(args: Dictionary, ed: EditorAdaptor, vim: Vim) -> void:
        var lower_case : bool = args.get("lower", false)
        var text := ed.selected_text()
        ed.replace_selection(text.to_lower() if lower_case else text.to_upper())

    static func toggle_case(args: Dictionary, ed: EditorAdaptor, vim: Vim) -> void:
        var text := ed.selected_text()
        var s := PackedStringArray()
        for c in text:
            s.append(c.to_lower() if c == c.to_upper() else c.to_upper())
        ed.replace_selection(''.join(s))


    ###  ACTIONS

    static func paste(args: Dictionary, ed: EditorAdaptor, vim: Vim) -> void:
        var after : bool = args.after
        var line_wise := vim.register.line_wise
        var clipboard_text := vim.register.text

        var text : String = ""
        for i in range(args.repeat):
            text += clipboard_text

        var line := ed.curr_line()
        var col := ed.curr_column()

        if line_wise:
            if after:
                text = "\n" + text.substr(0, len(text)-1)
                col = len(ed.line_text(line))
            else:
                col = 0
        else:
            col += 1 if after else 0

        ed.set_curr_column(col)
        ed.insert_text(text)

    static func undo(args: Dictionary, ed: EditorAdaptor, vim: Vim) -> void:
        for i in range(args.repeat):
            ed.undo()
        ed.deselect()

    static func redo(args: Dictionary, ed: EditorAdaptor, vim: Vim) -> void:
        for i in range(args.repeat):
            ed.redo()
        ed.deselect()

    static func replace(args: Dictionary, ed: EditorAdaptor, vim: Vim) -> void:
        var to_replace = args.selected_character
        var line := ed.curr_line()
        var col := ed.curr_column()
        ed.select(line, col, line, col+1)
        ed.replace_selection(to_replace)

    static func enter_insert_mode(args: Dictionary, ed: EditorAdaptor, vim: Vim) -> void:
        var insert_at : String = args.insert_at
        var line = ed.curr_line()
        var col = ed.curr_column()

        vim.current.enter_insert_mode()

        match insert_at:
            "inplace":
                pass
            "after":
                ed.set_curr_column(col + 1)
            "bol":
                ed.set_curr_column(ed.find_first_non_white_space_character(line))
            "eol":
                ed.set_curr_column(INF_COL)
            "new_line_below":
                ed.set_curr_column(INF_COL)
                ed.simulate_press(KEY_ENTER)
            "new_line_above":
                ed.set_curr_column(0)
                if line == ed.first_line():
                    ed.insert_text("\n")
                    ed.jump_to(0, 0)
                else:
                    ed.jump_to(line - 1, INF_COL)
                    ed.simulate_press(KEY_ENTER)

    static func enter_visual_mode(args: Dictionary, ed: EditorAdaptor, vim: Vim) -> void:
        var line_wise : bool = args.get('line_wise', false)
        vim.current.enter_visual_mode(line_wise)

    static func search(args: Dictionary, ed: EditorAdaptor, vim: Vim) -> void:
        if OS.get_name() == "macOS":
            ed.simulate_press(KEY_F, 0, false, false, false, true)
        else:
            ed.simulate_press(KEY_F, 0, true, false, false, false)
        vim.last_search_command = "/"

    static func jump_list_walk(args: Dictionary, ed: EditorAdaptor, vim: Vim) -> void:
        var offset : int = args.repeat * (1 if args.forward else -1)
        var pos : Position = vim.current.jump_list.move(offset)
        if pos != null:
            if not args.forward:
                vim.current.jump_list.set_next(ed.curr_position())
            ed.jump_to(pos.line, pos.column)

    static func toggle_folding(args: Dictionary, ed: EditorAdaptor, vim: Vim) -> void:
        ed.toggle_folding(ed.curr_line())

    static func fold_all(args: Dictionary, ed: EditorAdaptor, vim: Vim) -> void:
        ed.fold_all()

    static func unfold_all(args: Dictionary, ed: EditorAdaptor, vim: Vim) -> void:
        ed.unfold_all()

    static func repeat_last_edit(args: Dictionary, ed: EditorAdaptor, vim: Vim) -> void:
        var repeat : int = args.repeat
        vim.macro_manager.play_macro(repeat, ".", ed)
        
    static func record_macro(args: Dictionary, ed: EditorAdaptor, vim: Vim) -> void:
        var name = args.selected_character
        if name in ALPHANUMERIC:
            vim.macro_manager.start_record_macro(name)

    static func stop_record_macro(args: Dictionary, ed: EditorAdaptor, vim: Vim) -> void:
        vim.macro_manager.stop_record_macro()

    static func play_macro(args: Dictionary, ed: EditorAdaptor, vim: Vim) -> void:
        var name = args.selected_character
        var repeat : int = args.repeat
        if name in ALPHANUMERIC:
            vim.macro_manager.play_macro(repeat, name, ed)

    static func is_recording(ed: EditorAdaptor, vim: Vim) -> bool:
        return vim.macro_manager.is_recording()

    static func indent(args: Dictionary, ed: EditorAdaptor, vim: Vim) -> void:
        var repeat : int = args.repeat
        var forward : bool = args.get("forward", false)
        var range = ed.selection()

        if not range.is_single_line() and range.to.column == 0: # Don't select the last empty line
            ed.select(range.from.line, range.from.column, range.to.line-1, INF_COL)

        ed.begin_complex_operation()
        for i in range(repeat):
            if forward:
                ed.indent()
            else:
                ed.unindent()
        ed.end_complex_operation()

    static func join_lines(args: Dictionary, ed: EditorAdaptor, vim: Vim) -> void:
        if vim.current.normal_mode:
            var line := ed.curr_line()
            ed.select(line, 0, line + args.repeat, INF_COL)

        var range := ed.selection()
        ed.select(range.from.line, 0, range.to.line, INF_COL)
        var s := PackedStringArray()
        s.append(ed.line_text(range.from.line))
        for line in range(range.from.line + 1, range.to.line + 1):
            s.append(ed.line_text(line).lstrip(' \t\n'))
        ed.replace_selection(' '.join(s))

    static func set_bookmark(args: Dictionary, ed: EditorAdaptor, vim: Vim) -> void:
        var name = args.selected_character
        if name in LOWER_ALPHA:
            vim.current.bookmark_manager.set_bookmark(name, ed.curr_line())

    static func go_to_bookmark(cur: Position, args: Dictionary, ed: EditorAdaptor, vim: Vim) -> Position:
        var name = args.selected_character
        var line := vim.current.bookmark_manager.get_bookmark(name)
        if line < 0:
            return null
        return Position.new(line, 0)


    ###  HELPER FUNCTIONS

    ## Returns the boundaries of the next word. If the cursor in the middle of the word, then returns the boundaries of the current word, starting at the cursor.
    ## If the cursor is at the start/end of a word, and we are going forward/backward, respectively, find the boundaries of the next word.
    static func _find_word(cur: Position, ed: EditorAdaptor, forward: bool, big_word: bool, empty_line_is_word: bool, one_line: bool) -> TextRange:
        var char_tests := [ func(c): return c in ALPHANUMERIC or c in BREAKERS ] if big_word else [ func(c): return c in ALPHANUMERIC, func(c): return c in BREAKERS ]

        for p in ed.chars(cur.line, cur.column, forward):
            if one_line and p.char == '\n': # If we only allow search in one line and we met the line end
                return TextRange.from_num3(p.line, p.column, INF_COL)

            if p.line != cur.line and empty_line_is_word and p.line_text.strip_edges() == '':
                return TextRange.from_num3(p.line, 0, 0)

            for char_test in char_tests:
                if char_test.call(p.char):
                    var word_start := p.column
                    var word_end := word_start
                    for q in ed.chars(p.line, p.column, forward, true): # Advance to end of word.
                        if not char_test.call(q.char):
                            break
                        word_end = q.column

                    if p.line == cur.line and word_start == cur.column and word_end == word_start:
                        continue # We started at the end of a word. Find the next one.
                    else:
                        return TextRange.from_num3(p.line, min(word_start, word_end), max(word_start + 1, word_end + 1))
        return null


class Position:
    var line: int
    var column: int

    static var zero :Position:
        get:
            return Position.new(0, 0)

    func _init(l: int, c: int):
        line = l
        column = c

    func _to_string() -> String:
        return "(%s, %s)" % [line, column]

    func equals(other: Position) -> bool:
        return line == other.line and column == other.column

    func compares_to(other: Position) -> int:
        if line < other.line: return -1
        if line > other.line: return 1
        if column < other.column: return -1
        if column > other.column: return 1
        return 0

    func duplicate() -> Position: return Position.new(line, column)
    func up() -> Position: return Position.new(line-1, column)
    func down() -> Position: return Position.new(line+1, column)
    func left() -> Position: return Position.new(line, column-1)
    func right() -> Position: return Position.new(line, column+1)
    func next(ed: EditorAdaptor) -> Position: return ed.offset_pos(self, 1)
    func prev(ed: EditorAdaptor) -> Position: return ed.offset_pos(self, -1)


class TextRange:
    var from: Position
    var to: Position

    static var zero : TextRange:
        get:
            return TextRange.new(Position.zero, Position.zero)

    static func from_num4(from_line: int, from_column: int, to_line: int, to_column: int):
        return TextRange.new(Position.new(from_line, from_column), Position.new(to_line, to_column))

    static func from_num3(line: int, from_column: int, to_column: int):
        return from_num4(line, from_column, line, to_column)

    func _init(f: Position, t: Position):
        from = f
        to = t

    func _to_string() -> String:
        return "[%s - %s]" % [from, to]

    func is_single_line() -> bool:
        return from.line == to.line

    func is_empty() -> bool:
        return from.line == to.line and from.column == to.column


class CharPos extends Position:
    var line_text : String

    var char: String:
        get:
            return line_text[column] if column < len(line_text) else '\n'

    func _init(line_text: String, line: int, col: int):
        super(line, col)
        self.line_text = line_text


class JumpList:
    var buffer: Array[Position]
    var pointer: int = 0

    func _init(capacity: int = 20):
        buffer = []
        buffer.resize(capacity)

    func add(old_pos: Position, new_pos: Position) -> void:
        var current : Position = buffer[pointer]
        if current == null or not current.equals(old_pos):
            pointer = (pointer + 1) % len(buffer)
            buffer[pointer] = old_pos
        pointer = (pointer + 1) % len(buffer)
        buffer[pointer] = new_pos

    func set_next(pos: Position) -> void:
        buffer[(pointer + 1) % len(buffer)] = pos # This overrides next forward position (TODO: an insert might be better)

    func move(offset: int) -> Position:
        var t := (pointer + offset) % len(buffer)
        var r : Position = buffer[t]
        if r != null:
            pointer = t
        return r

    func on_lines_edited(from: int, to: int) -> void:
        for pos in buffer:
            if pos != null and pos.line > from: # Unfortunately we don't know which column changed
                pos.line += to - from


class InputState:
    var prefix_repeat: String
    var motion_repeat: String
    var operator: String
    var operator_args: Dictionary
    var buffer: Array[InputEventKey] = []

    func push_key(key: InputEventKey) -> void:
        buffer.append(key)

    func push_repeat_digit(d: String) -> void:
        if operator.is_empty():
            prefix_repeat += d
        else:
            motion_repeat += d

    func get_repeat() -> int:
        var repeat : int = 0
        if prefix_repeat:
            repeat = max(repeat, 1) * int(prefix_repeat)
        if motion_repeat:
            repeat = max(repeat, 1) * int(motion_repeat)
        return repeat

    func key_codes() -> Array[String]:
        var r : Array[String] = []
        for k in buffer:
            r.append(k.as_text_keycode())
        return r

    func clear() -> void:
        prefix_repeat = ""
        motion_repeat = ""
        operator = ""
        buffer.clear()


class GDScriptParser:
    const open_symbol := { "(": ")", "[": "]", "{": "}", "'": "'", '"': '"' }
    const close_symbol := { ")": "(", "]": "[", "}": "{", }

    var stack : Array[CharPos]
    var in_comment := false
    var escape_count := 0
    var valid: bool = true
    var eof : bool = false
    var pos: Position

    var stack_top_char : String:
        get:
            return "" if stack.is_empty() else stack.back().char

    var _it: CharIterator
    var _ed : EditorAdaptor

    func _init(ed: EditorAdaptor, from: Position):
        _ed = ed
        _it = ed.chars(from.line, from.column)
        if not _it._iter_init(null):
            eof = true

    func parse_until(to: Position) -> bool:
        while valid and not eof:
            parse_one_char()
            if _it.line == to.line and _it.column == to.column:
                break
        return valid and not eof


    func find_matching() -> Position:
        var depth := len(stack)
        while valid and not eof:
            parse_one_char()
            if len(stack) < depth:
                return pos
        return null

    func parse_one_char() -> String: # ChatGPT got credit here
        if eof or not valid:
            return ""

        var p := _it._iter_get(null)
        pos = p

        if not _it._iter_next(null):
            eof = true

        var char := p.char
        var top: String = '' if stack.is_empty() else stack.back().char
        if top in "'\"": # in string
            if char == top and escape_count % 2 == 0:
                stack.pop_back()
                escape_count = 0
                return char
            escape_count = escape_count + 1 if char == "\\" else 0
        elif in_comment:
            if char == "\n":
                in_comment = false
        elif char == "#":
            in_comment = true
        elif char in open_symbol:
            stack.append(p)
            return char
        elif char in close_symbol:
            if top == close_symbol[char]:
                stack.pop_back()
                return char
            else:
                valid = false
        return ""


class Register:
    var line_wise : bool = false
    var text : String:
        get:
            return DisplayServer.clipboard_get()

    func set_text(value: String, line_wise: bool) -> void:
        self.line_wise = line_wise
        DisplayServer.clipboard_set(value)


class BookmarkManager:
    var bookmarks : Dictionary

    func on_lines_edited(from: int, to: int) -> void:
        for b in bookmarks:
            var line : int = bookmarks[b]
            if line > from:
                bookmarks[b] += to - from

    func set_bookmark(name: String, line: int) -> void:
        bookmarks[name] = line

    func get_bookmark(name: String) -> int:
        return bookmarks.get(name, -1)


class CommandMatchResult:
    var full: Array[Dictionary] = []
    var partial: Array[Dictionary] = []


class VimSession:
    var ed : EditorAdaptor

    ## Mode         insert_mode | visual_mode | visual_line
    ## Insert       true        | false       | false
    ## Normal       false       | false       | false
    ## Visual       false       | true        | false
    ## Visual Line  false       | true        | true
    var insert_mode : bool = false
    var visual_mode : bool = false
    var visual_line : bool = false

    var normal_mode: bool:
        get:
            return not insert_mode and not visual_mode

    ## Pending input
    var input_state := InputState.new()

    ## The last motion occurred
    var last_motion : String

    ## When using jk for navigation, if you move from a longer line to a shorter line, the cursor may clip to the end of the shorter line.
    ## If j is pressed again and cursor goes to the next line, the cursor should go back to its horizontal position on the longer
    ## line if it can. This is to keep track of the horizontal position.
    var last_h_pos : int = 0

    ## How many times text are changed
    var text_change_number : int

    ## List of positions for C-I and C-O
    var jump_list := JumpList.new()

    ## The bookmark manager of the session
    var bookmark_manager := BookmarkManager.new()

    ## The start position of visual mode
    var visual_start_pos := Position.zero

    func enter_normal_mode() -> void:
        if insert_mode:
            ed.end_complex_operation() # Wrap up the undo operation when we get out of insert mode

        insert_mode = false
        visual_mode = false
        visual_line = false
        ed.set_block_caret(true)

    func enter_insert_mode() -> void:
        insert_mode = true
        visual_mode = false
        visual_line = false
        ed.set_block_caret(false)
        ed.begin_complex_operation()

    func enter_visual_mode(line_wise: bool) -> void:
        insert_mode = false
        visual_mode = true
        visual_line = line_wise
        ed.set_block_caret(true)

        visual_start_pos = ed.curr_position()
        if line_wise:
            ed.select(visual_start_pos.line, 0, visual_start_pos.line + 1, 0)
        else:
            ed.select_by_pos2(visual_start_pos, visual_start_pos.right())


class Macro:
    var keys : Array[InputEventKey] = []
    var enabled := false

    func _to_string() -> String:
        var s := PackedStringArray()
        for key in keys:
            s.append(key.as_text_keycode())
        return ",".join(s)

    func play(ed: EditorAdaptor) -> void:
        for key in keys:
            ed.simulate_press_key(key)
        ed.simulate_press(KEY_ESCAPE)


class MacroManager:
    var vim : Vim
    var macros : Dictionary = {}
    var recording_name : String
    var playing_names : Array[String] = []
    var command_buffer: Array[InputEventKey]

    func _init(vim: Vim):
        self.vim = vim

    func start_record_macro(name: String):
        print('Recording macro "%s"...' % name )
        macros[name] = Macro.new()
        recording_name = name

    func stop_record_macro() -> void:
        print('Stop recording macro "%s"' % recording_name)
        macros[recording_name].enabled = true
        recording_name = ""

    func is_recording() -> bool:
        return recording_name != ""

    func play_macro(n: int, name: String, ed: EditorAdaptor) -> void:
        var macro : Macro = macros.get(name, null)
        if (macro == null or not macro.enabled):
            return
        if name in playing_names:
            return # to avoid recursion

        playing_names.append(name)
        if len(playing_names) == 1:
            ed.begin_complex_operation()

        if DEBUGGING:
            print("Playing macro %s: %s" % [name, macro])

        for i in range(n):
            macro.play(ed)

        ed.simulate_press(KEY_NONE, CODE_MACRO_PLAY_END)  # This special marks the end of macro play
        
    func on_macro_finished(ed: EditorAdaptor):
        var name : String = playing_names.pop_back()
        if playing_names.is_empty():
            ed.end_complex_operation()

    func push_key(key: InputEventKey) -> void:
        command_buffer.append(key)
        if recording_name:
            macros[recording_name].keys.append(key)

    func on_command_processed(command: Dictionary, is_edit: bool) -> void:
        if is_edit and command.get('action', '') != "repeat_last_edit":
            var macro := Macro.new()
            macro.keys = command_buffer.duplicate()
            macro.enabled = true
            macros["."] = macro
        command_buffer.clear()


## Global VIM state; has multiple sessions
class Vim:
    var sessions : Dictionary
    var current: VimSession
    var register: Register = Register.new()
    var last_char_search: Dictionary = {}  # { selected_character, stop_before, forward, inclusive }
    var last_search_command: String
    var search_buffer: String
    var macro_manager := MacroManager.new(self)

    func set_current_session(s: Script, ed: EditorAdaptor):
        var session : VimSession = sessions.get(s)
        if not session:
            session = VimSession.new()
            session.ed = ed
            sessions[s] = session
        current = session

    func remove_session(s: Script):
        sessions.erase(s)


class CharIterator:
    var ed : EditorAdaptor
    var line : int
    var column : int
    var forward : bool
    var one_line : bool
    var line_text : String

    func _init(ed: EditorAdaptor, line: int, col: int, forward: bool, one_line: bool):
        self.ed = ed
        self.line = line
        self.column = col
        self.forward = forward
        self.one_line = one_line

    func _ensure_column_valid() -> bool:
        if column < 0 or column > len(line_text):
            line += 1 if forward else -1
            if one_line or line < 0 or line > ed.last_line():
                return false
            line_text  = ed.line_text(line)
            column = 0 if forward else len(line_text)
        return true

    func _iter_init(arg) -> bool:
        if line < 0 or line > ed.last_line():
            return false
        line_text = ed.line_text(line)
        return _ensure_column_valid()

    func _iter_next(arg) -> bool:
        column += 1 if forward else -1
        return _ensure_column_valid()

    func _iter_get(arg) -> CharPos:
        return CharPos.new(line_text, line, column)


class EditorAdaptor:
    var code_editor: CodeEdit
    var tab_width : int = 4
    var complex_ops : int = 0

    func set_code_editor(new_editor: CodeEdit) -> void:
        self.code_editor = new_editor

    func notify_settings_changed(settings: EditorSettings) -> void:
        tab_width = settings.get_setting("text_editor/behavior/indent/size") as int

    func curr_position() -> Position:
        return Position.new(code_editor.get_caret_line(), code_editor.get_caret_column())

    func curr_line() -> int:
        return code_editor.get_caret_line()

    func curr_column() -> int:
        return code_editor.get_caret_column()

    func set_curr_column(col: int) -> void:
        code_editor.set_caret_column(col)

    func jump_to(line: int, col: int) -> void:
        code_editor.unfold_line(line)

        if line < first_visible_line():
            code_editor.set_line_as_first_visible(max(0, line-8))
        elif line > last_visible_line():
            code_editor.set_line_as_last_visible(min(last_line(), line+8))
        code_editor.set_caret_line(line)
        code_editor.set_caret_column(col)


    func first_line() -> int:
        return 0

    func last_line() -> int :
        return code_editor.get_line_count() - 1

    func first_visible_line() -> int:
        return code_editor.get_first_visible_line()

    func last_visible_line() -> int:
        return code_editor.get_last_full_visible_line()

    func get_visible_line_count(from_line: int, to_line: int) -> int:
        return code_editor.get_visible_line_count_in_range(from_line, to_line)

    func next_unfolded_line(line: int, offset: int = 1, forward: bool = true) -> int:
        var step : int = 1 if forward else -1
        if line + step > last_line() or line + step  < first_line():
            return line
        var count := code_editor.get_next_visible_line_offset_from(line + step, offset * step)
        return line + count * (1 if forward else -1)

    func last_column(line: int = -1) -> int:
        if line == -1:
            line = curr_line()
        return len(line_text(line)) - 1

    func last_pos() -> Position:
        var line = last_line()
        return Position.new(line, last_column(line))

    func line_text(line: int) -> String:
        return code_editor.get_line(line)

    func range_text(range: TextRange) -> String:
        var s := PackedStringArray()
        for p in chars(range.from.line, range.from.column):
            if p.equals(range.to):
                break
            s.append(p.char)
        return "".join(s)

    func char_at(line: int, col: int) -> String:
        var s := line_text(line)
        return s[col] if col >= 0 and col < len(s) else ''

    func set_block_caret(block: bool) -> void:
        if block:
            if curr_column() == last_column() + 1:
                code_editor.caret_type = TextEdit.CARET_TYPE_LINE
                code_editor.add_theme_constant_override("caret_width", 8)
            else:
                code_editor.caret_type = TextEdit.CARET_TYPE_BLOCK
                code_editor.add_theme_constant_override("caret_width", 1)
        else:
            code_editor.add_theme_constant_override("caret_width", 1)
            code_editor.caret_type = TextEdit.CARET_TYPE_LINE

    func deselect() -> void:
        code_editor.deselect()

    func select_range(r: TextRange) -> void:
        select(r.from.line, r.from.column, r.to.line, r.to.column)

    func select_by_pos2(from: Position, to: Position) -> void:
        select(from.line, from.column, to.line, to.column)

    func select(from_line: int, from_col: int, to_line: int, to_col: int) -> void:
        if to_line > last_line(): # If we try to select pass the last line, select till the last char
            to_line = last_line()
            to_col = INF_COL

        code_editor.select(from_line, from_col, to_line, to_col)

    func delete_selection() -> void:
        code_editor.delete_selection()

    func selected_text() -> String:
        return code_editor.get_selected_text()

    func selection() -> TextRange:
        var from := Position.new(code_editor.get_selection_from_line(), code_editor.get_selection_from_column())
        var to := Position.new(code_editor.get_selection_to_line(), code_editor.get_selection_to_column())
        return TextRange.new(from, to)

    func replace_selection(text: String) -> void:
        var col := curr_column()
        begin_complex_operation()
        delete_selection()
        insert_text(text)
        end_complex_operation()
        set_curr_column(col)

    func toggle_folding(line_or_above: int) -> void:
        if code_editor.is_line_folded(line_or_above):
            code_editor.unfold_line(line_or_above)
        else:
            while line_or_above >= 0:
                if code_editor.can_fold_line(line_or_above):
                    code_editor.fold_line(line_or_above)
                    break
                line_or_above -= 1

    func fold_all() -> void:
        code_editor.fold_all_lines()

    func unfold_all() -> void:
        code_editor.unfold_all_lines()

    func insert_text(text: String) -> void:
        code_editor.insert_text_at_caret(text)

    func offset_pos(pos: Position, offset: int) -> Position:
        var count : int = abs(offset) + 1
        for p in chars(pos.line, pos.column, offset > 0):
            count -= 1
            if count == 0:
                return p
        return null

    func undo() -> void:
        code_editor.undo()

    func redo() -> void:
        code_editor.redo()

    func indent() -> void:
        code_editor.indent_lines()

    func unindent() -> void:
        code_editor.unindent_lines()

    func simulate_press_key(key: InputEventKey):
        for pressed in [true, false]:
            var key2 := key.duplicate()
            key2.pressed = pressed
            Input.parse_input_event(key2)

    func simulate_press(keycode: Key, unicode: int=0, ctrl=false, alt=false, shift=false, meta=false) -> void:
        var k = InputEventKey.new()
        if ctrl:
            k.ctrl_pressed = true
        if shift:
            k.shift_pressed = true
        if alt:
            k.alt_pressed = true
        if meta:
            k.meta_pressed = true
        k.keycode = keycode
        k.key_label = keycode
        k.unicode = unicode
        simulate_press_key(k)

    func begin_complex_operation() -> void:
        complex_ops += 1
        if complex_ops == 1:
            if DEBUGGING:
                print("Complex operation begins")
            code_editor.begin_complex_operation()

    func end_complex_operation() -> void:
        complex_ops -= 1
        if complex_ops == 0:
            if DEBUGGING:
                print("Complex operation ends")
            code_editor.end_complex_operation()

    ## Return the index of the first non whtie space character in string
    func find_first_non_white_space_character(line: int) -> int:
        var s := line_text(line)
        return len(s) - len(s.lstrip(" \t\r\n"))

    ## Return the next (or previous) char from current position and update current position according. Return "" if not more char available
    func chars(line: int, col: int, forward: bool = true, one_line: bool = false) -> CharIterator:
        return CharIterator.new(self, line, col, forward, one_line)

    func find_forward(line: int, col: int, condition: Callable, one_line: bool = false) -> CharPos:
        for p in chars(line, col, true, one_line):
            if condition.call(p):
                return p
        return null

    func find_backforward(line: int, col: int, condition: Callable, one_line: bool = false) -> CharPos:
        for p in chars(line, col, false, one_line):
            if condition.call(p):
                return p
        return null

    func get_word_at_pos(line: int, col: int) -> TextRange:
        var end := find_forward(line, col, func(p): return p.char not in ALPHANUMERIC, true);
        var start := find_backforward(line, col, func(p): return p.char not in ALPHANUMERIC, true);
        return TextRange.new(start.right(), end)

    func search(text: String, line: int, col: int, match_case: bool, whole_word: bool, forward: bool) -> Position:
        var flags : int = 0
        if match_case: flags |= TextEdit.SEARCH_MATCH_CASE
        if whole_word: flags |= TextEdit.SEARCH_WHOLE_WORDS
        if not forward: flags |= TextEdit.SEARCH_BACKWARDS
        var result = code_editor.search(text, flags, line, col)
        if result.x < 0 or result. y < 0:
            return null

        code_editor.set_search_text(text)
        return Position.new(result.y, result.x)

    func has_focus() -> bool:
        return code_editor.has_focus()


class CommandDispatcher:
    var key_map : Array[Dictionary]

    func _init(km: Array[Dictionary]):
        self.key_map = km

    func dispatch(key: InputEventKey, vim: Vim, ed: EditorAdaptor) -> bool:
        var key_code := key.as_text_keycode()
        var input_state := vim.current.input_state

        vim.macro_manager.push_key(key)

        if key_code == "Escape":
            input_state.clear()
            vim.macro_manager.on_command_processed({}, vim.current.insert_mode)  # From insert mode to normal mode, this marks the end of an edit command
            vim.current.enter_normal_mode()
            return false # Let godot get the Esc as well to dispose code completion pops, etc

        if vim.current.insert_mode: # We are in insert mode
            return false # Let Godot CodeEdit handle it

        if key_code not in ["Shift", "Ctrl", "Alt", "Escape"]: # Don't add these to input buffer
            # Handle digits
            if key_code.is_valid_int() and input_state.buffer.is_empty():
                input_state.push_repeat_digit(key_code)
                if input_state.get_repeat() > 0: # No more handding if it is only repeat digit
                    return true

            # Save key to buffer
            input_state.push_key(key)

            # Match the command
            var context = Context.VISUAL if vim.current.visual_mode else Context.NORMAL
            var result = match_commands(context, vim.current.input_state, ed, vim)
            if not result.full.is_empty():
                var command = result.full[0]
                var change_num := vim.current.text_change_number
                if process_command(command, ed, vim):
                    input_state.clear()
                    if vim.current.normal_mode:
                        vim.macro_manager.on_command_processed(command, vim.current.text_change_number > change_num)  # Notify macro manager about the finished command
            elif result.partial.is_empty():
                input_state.clear()

        return true # We handled the input

    func match_commands(context: Context, input_state: InputState, ed: EditorAdaptor, vim: Vim) -> CommandMatchResult:
        # Partial matches are not applied. They inform the key handler
        # that the current key sequence is a subsequence of a valid key
        # sequence, so that the key buffer is not cleared.
        var result := CommandMatchResult.new()
        var pressed := input_state.key_codes()

        for command in key_map:
            if not is_command_available(command, context, ed, vim):
                continue

            var mapped : Array = command.keys
            if mapped[-1] == "{char}":
                if pressed.slice(0, -1) == mapped.slice(0, -1) and len(pressed) == len(mapped):
                    result.full.append(command)
                elif mapped.slice(0, len(pressed)-1) == pressed.slice(0, -1):
                    result.partial.append(command)
                else:
                    continue
            else:
                if pressed == mapped:
                    result.full.append(command)
                elif mapped.slice(0, len(pressed)) == pressed:
                    result.partial.append(command)
                else:
                    continue

        return result

    func is_command_available(command: Dictionary, context: Context, ed: EditorAdaptor, vim: Vim) -> bool:
            if command.get("context") not in [null, context]:
                return false

            var when : String = command.get("when", '')
            if when and not Callable(Command, when).call(ed, vim):
                return false

            var when_not: String = command.get("when_not", '')
            if when_not and Callable(Command, when_not).call(ed, vim):
                return false

            return true

    func process_command(command: Dictionary, ed: EditorAdaptor, vim: Vim) -> bool:
        var vim_session := vim.current
        var input_state := vim_session.input_state
        var start := Position.new(ed.curr_line(), ed.curr_column())

        # If there is an operator pending, then we do need a motion or operator (for linewise operation)
        if not input_state.operator.is_empty() and (command.type != MOTION and command.type != OPERATOR):
            return false

        if command.type == ACTION:
            var action_args = command.get("action_args", {})
            if command.keys[-1] == "{char}":
                action_args.selected_character = char(input_state.buffer.back().unicode)
            process_action(command.action, action_args, ed, vim)
            return true
        elif command.type == MOTION or command.type == OPERATOR_MOTION:
            var motion_args = command.get("motion_args", {})

            if command.type == OPERATOR_MOTION:
                var operator_args = command.get("operator_args", {})
                input_state.operator = command.operator
                input_state.operator_args = operator_args

            if command.keys[-1] == "{char}":
                motion_args.selected_character = char(input_state.buffer.back().unicode)

            var new_pos = process_motion(command.motion, motion_args, ed, vim)
            if new_pos == null:
                return true

            if vim_session.visual_mode:  # Visual mode
                start = vim_session.visual_start_pos
                if new_pos is TextRange:
                    start = new_pos.from # In some cases (text object), we need to override the start position
                    new_pos = new_pos.to
                ed.jump_to(new_pos.line, new_pos.column)
                if start.compares_to(new_pos) > 0: # swap
                    start = new_pos
                    new_pos = vim_session.visual_start_pos
                if vim_session.visual_line:
                    ed.select(start.line, 0, new_pos.line + 1, 0)
                else:
                    ed.select_by_pos2(start, new_pos.right())
            elif input_state.operator.is_empty():  # Normal mode motion only
                ed.jump_to(new_pos.line, new_pos.column)
            else:  # Normal mode operator motion
                if new_pos is TextRange:
                    start = new_pos.from # In some cases (text object), we need to override the start position
                    new_pos = new_pos.to
                var inclusive : bool = motion_args.get("inclusive", false)
                ed.select_by_pos2(start, new_pos.right() if inclusive else new_pos)
                process_operator(input_state.operator, input_state.operator_args, ed, vim)
            return true
        elif command.type == OPERATOR:
            var operator_args = command.get("operator_args", {})
            if vim.current.visual_mode:
                operator_args.line_wise = vim.current.visual_line
                process_operator(command.operator, operator_args, ed, vim)
                vim.current.enter_normal_mode()
                return true
            elif input_state.operator.is_empty(): # We are not fully done yet, need to wait for the motion
                input_state.operator = command.operator
                input_state.operator_args = operator_args
                input_state.buffer.clear()
                return false
            else:
                if input_state.operator == command.operator: # Line wise operation
                    operator_args.line_wise = true
                    var new_pos : Position = process_motion("expand_to_line", {}, ed, vim)
                    if new_pos.compares_to(start) > 0:
                        ed.select(start.line, 0, new_pos.line + 1, 0)
                    else:
                        ed.select(new_pos.line, 0, start.line + 1, 0)
                    process_operator(command.operator, operator_args, ed, vim)
                return true
        
        return false

    func process_action(action: String, action_args: Dictionary, ed: EditorAdaptor, vim: Vim) -> void:
        if DEBUGGING:
            print("  Action: %s %s" % [action, action_args])

        action_args.repeat = max(1, vim.current.input_state.get_repeat())
        Callable(Command, action).call(action_args, ed, vim)

        if vim.current.visual_mode and action != "enter_visual_mode":
            vim.current.enter_normal_mode()

    func process_operator(operator: String, operator_args: Dictionary, ed: EditorAdaptor, vim: Vim) -> void:
        if DEBUGGING:
            print("  Operator %s %s on %s" % [operator, operator_args, ed.selection()])

        # Perform operation
        Callable(Command, operator).call(operator_args, ed, vim)


    func process_motion(motion: String, motion_args: Dictionary, ed: EditorAdaptor, vim: Vim) -> Variant:
        # Get current position
        var cur := Position.new(ed.curr_line(), ed.curr_column())

        # Prepare motion args
        var user_repeat = vim.current.input_state.get_repeat()
        if user_repeat > 0:
            motion_args.repeat = user_repeat
            motion_args.repeat_is_explicit = true
        else:
            motion_args.repeat = 1
            motion_args.repeat_is_explicit = false

        # Calculate new position
        var result = Callable(Command, motion).call(cur, motion_args, ed, vim)
        if result is Position:
            var new_pos : Position = result
            if new_pos.column == INF_COL: # INF_COL means the last column
                new_pos.column = ed.last_column(new_pos.line)

            if motion_args.get('to_jump_list', false):
                vim.current.jump_list.add(cur, new_pos)

        # Save last motion
        vim.current.last_motion = motion

        if DEBUGGING:
            print("  Motion: %s %s to %s" % [motion, motion_args, result])

        return result

