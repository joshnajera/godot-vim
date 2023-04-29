# godot-vim
VIM bindings for godot 4

Most typically used by myself, open to suggestions on missing bindings :) 

Supports number prefixes for moving (h,j,k,l, gg, G), e.g.: 

12+gg will do vim's jump to line (12) 

5+j will move down 5 times 

etc. 


## Bindings

| Key Combination | Action |
| --- | --- |
| Escape | Disable insert |
| i | Enable insert |
| h | Move left |
| j | Move down |
| k | Move up |
| l | Move right |
| Ctrl + u | Page Up |
| Ctrl + d | Page Down |
| e | Move to end of word |
| Shift + e | Move to next whitespace |
| b | Move to start of back word |
| Shift + b | Move to previous whitespace |
| w | Move to start of next word |
| Shift + w | Move to next word after whitespace |
| gg | Move to beginning of file |
| Shift + g | Move to end of file |
| $ | Move to end of line |
| ^ | Move to start of line (stops before whitespace) |
| 0 | Move to zero column |
| * | Find next occurrence of word |
| n | Find again |
| Shift + n | Find again backwards |
| Shift + i | Insert at beginning of line |
| a | Insert after |
| Shift + a | Insert at end of line |
| o | Newline insert |
| Shift + o | Previous line insert |
| Ctrl + o | Jump to last buffered position |
| p | Paste after |
| Shift + p | Paste before |
| r ANY | Replace one character (TODO: not working) |
| s | Replace selection |
| x | Delete at cursor |
| d | Visual mode delete |
| Shift+d | Delete to end of line |
| dd | Delete line |
| db | Delete backward one word |
| dw | Delete to start of next word |
| de | Delete to end of word |
| u | Undo |
| Ctrl + r | Redo |
| :w Enter | Save |
| y | Visual mode yank |
| yy | Yank line |
| v | Enter visual selection |
| Shift + v | Enter visual line selection |
| / | Search function |
| << | Dedent |
| >> | Indent |
| zm | Fold all |
| zr | Unfold all |
| zc | Fold line |
| zo | Unfold line |
