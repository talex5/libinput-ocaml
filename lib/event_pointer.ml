open Event0

type ty = [
  | `Pointer_motion of [`Pointer_motion] t
  | `Pointer_motion_absolute of [`Pointer_motion_absolute] t
  | `Pointer_button of [`Pointer_button] t
  | `Pointer_axis of [`Pointer_axis] t
  | `Pointer_scroll_wheel of [`Pointer_scroll_wheel] t
  | `Pointer_scroll_finger of [`Pointer_scroll_finger] t
  | `Pointer_scroll_continuous of [`Pointer_scroll_continuous] t
]

type any = [
  | `Pointer_motion
  | `Pointer_motion_absolute
  | `Pointer_button
  | `Pointer_axis
  | `Pointer_scroll_wheel
  | `Pointer_scroll_finger
  | `Pointer_scroll_continuous
]

let ev t =
  match C.Functions.Event.Pointer.get_event (use t) with
  | Some kev -> kev
  | None -> failwith "Not a pointer event!"

let get_time t = C.Functions.Event.Pointer.get_time_usec (ev t)

let get_dx t = C.Functions.Event.Pointer.get_dx (ev t)
let get_dy t = C.Functions.Event.Pointer.get_dy (ev t)

let get_dx_unaccelerated t = C.Functions.Event.Pointer.get_dx_unaccelerated (ev t)
let get_dy_unaccelerated t = C.Functions.Event.Pointer.get_dy_unaccelerated (ev t)

let get_absolute_x t = C.Functions.Event.Pointer.get_absolute_x (ev t)
let get_absolute_y t = C.Functions.Event.Pointer.get_absolute_y (ev t)

let get_absolute_x_transformed t ~width = C.Functions.Event.Pointer.get_absolute_x_transformed (ev t) width
let get_absolute_y_transformed t ~height = C.Functions.Event.Pointer.get_absolute_y_transformed (ev t) height

let get_button t = C.Functions.Event.Pointer.get_button (ev t)
let get_button_state t = C.Functions.Event.Pointer.get_button_state (ev t)

let get_seat_button_count t = C.Functions.Event.Pointer.get_seat_button_count (ev t)

let has_axis t axis =
  C.Functions.Event.Pointer.has_axis (ev t) axis <> 0

let get_scroll_value t axis =
  let t = ev t in
  if C.Functions.Event.Pointer.has_axis t axis = 0 then None
  else Some (C.Functions.Event.Pointer.get_scroll_value t axis)

let get_scroll_value_v120 t axis =
  let t = ev t in
  if C.Functions.Event.Pointer.has_axis t axis = 0 then None
  else Some (C.Functions.Event.Pointer.get_scroll_value_v120 t axis)

let pp_scroll f e =
  Fmt.pf f "{@[<v>time = %a; value = (%a, %a)@]}"
    Timestamp.pp (get_time e)
    Fmt.(option ~none:(any "-") float) (get_scroll_value e `Scroll_horizontal)
    Fmt.(option ~none:(any "-") float) (get_scroll_value e `Scroll_vertical)

let pp_payload f : ty -> unit = function
  | `Pointer_motion e ->
    Fmt.pf f "{@[<v>time = %a;@;dx = %f;@;dy = %f@]}"
      Timestamp.pp (get_time e)
      (get_dx e)
      (get_dy e)
  | `Pointer_motion_absolute e ->
    Fmt.pf f "{@[<v>time = %a;@;absolute_x = %f;@;absolute_y = %f@]}"
      Timestamp.pp (get_time e)
      (get_absolute_x e)
      (get_absolute_y e)
  | `Pointer_button e ->
    Fmt.pf f "{@[<v>time = %a;@;button = %a;@;state = %s;@;seat_key_count = %d@]}"
      Timestamp.pp (get_time e)
      Keycode.pp (get_button e)
      (match get_button_state e with `Pressed -> "`Pressed" | `Released -> "`Released")
      (get_seat_button_count e)
  | `Pointer_axis e ->
    Fmt.pf f "{@[<v>time = %a; ...@]} (* Obsolete event type *)"
      Timestamp.pp (get_time e)
  | `Pointer_scroll_wheel e ->
    Fmt.pf f "{@[<v>time = %a; value120 = (%a, %a)@]}"
      Timestamp.pp (get_time e)
      Fmt.(option ~none:(any "0") float) (get_scroll_value_v120 e `Scroll_horizontal)
      Fmt.(option ~none:(any "0") float) (get_scroll_value_v120 e `Scroll_vertical)
  | `Pointer_scroll_finger e -> pp_scroll f e
  | `Pointer_scroll_continuous e -> pp_scroll f e
