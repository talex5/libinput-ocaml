open Event0

type ty = [
  | `Keyboard_key of [`Keyboard_key] t
]

let kev t =
  match C.Functions.Event.Keyboard.get_event (use t) with
  | Some kev -> kev
  | None -> failwith "Not a keyboard event!"

let get_time t = C.Functions.Event.Keyboard.get_time_usec (kev t)
let get_key t = C.Functions.Event.Keyboard.get_key (kev t)
let get_key_state t = C.Functions.Event.Keyboard.get_key_state (kev t)
let get_seat_key_count t = C.Functions.Event.Keyboard.get_seat_key_count (kev t)

let pp_payload f (`Keyboard_key e) =
  Fmt.pf f "{@[<v>time = %a;@;key = %a;@;state = %s;@;seat_key_count = %d@]}"
    Timestamp.pp (get_time e)
    Keycode.pp (get_key e)
    (match get_key_state e with `Pressed -> "`Pressed" | `Released -> "`Released")
    (get_seat_key_count e)
