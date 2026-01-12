module F = C.Functions.Mode_group

type t = C.Types.Mode_group.t Ctypes.ptr Droppable.t

let use t = Droppable.use t

let get_index t = F.get_index (use t)
let get_num_modes t = F.get_num_modes (use t)
let get_mode t = F.get_mode (use t)
let has_button t = F.has_button (use t)
let has_dial t = F.has_dial (use t)
let has_ring t = F.has_ring (use t)
let has_strip t = F.has_strip (use t)
let button_is_toggle t = F.button_is_toggle (use t)
