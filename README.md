VIM bindings for Godot 4

recently improved thanks to wenqiangwang
If you would like ctrl+F to be move-forward by page then uncomment the following line

#"Ctrl+F": 1, ## Uncomment if you want Ctrl+F for move forward by page

### Supported Mode

    - Normal mode
    - Insert mode
    - Visual mode
    - Visual line mode

### Supported motions

    h, l, j, k, +, -
    ^, 0, $, |
    H, L, M,
    c-f, c-b, c-d, c-u,
    G, gg
    w, W, e, E, b, ge
    %, f, F, t, T, ;
    *, #, /, n, N
    aw, a(, a{, a[, a", a'
    iw, i(, i{, i[, i", i'

### Supported operator

    c, C,
    d, D, x, X,
    y, Y,
    u, U, ~

### Supported actions

    p,
    u, c-r,
    c-o, c-i,
    za, zM, zR,
    q, @, .,
    >, <
    m, '

### Override Default Godot Shortcuts with `godot-vim`'s ones

Note that all non-ascii character mappings that are already mapped in the default Godot editor have to be unmapped from the Editor settings (Editor >> Editor Settings >> Shorcuts) before being usable with `godot-vim`.

This currently goes for:

- `Ctrl+R`
- `Ctrl+U`
- `Ctrl+D`

See the full list of non-ascii shortucts that may already be mapped by Godot and thus wouldn't work in `godot-vim` before releasing them in Godot settings: https://github.com/joshnajera/godot-vim/blob/main/addons/godot-vim/godot-vim.gd#L135
