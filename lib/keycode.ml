type t = int

let of_int x = x
let of_uint32 = Unsigned.UInt32.to_int
let to_uint32 = Unsigned.UInt32.of_int
let pp = Fmt.int

let key_esc = 1
let key_backspace = 14
let key_tab = 15
let key_enter = 28
let key_space = 57
let key_home = 102
let key_up = 103
let key_pageup = 104
let key_left = 105
let key_right = 106
let key_end = 107
let key_down = 108
let key_pagedown = 109
let key_delete = 111

let btn_left   = 0x110
let btn_right  = 0x111
let btn_middle = 0x112
