open Event0

type ty = [
  | `Touch_down of [`Touch_down] t
  | `Touch_up of [`Touch_up] t
  | `Touch_motion of [`Touch_motion] t
  | `Touch_cancel of [`Touch_cancel] t
  | `Touch_frame of [`Touch_frame] t
]

type any = [
  | `Touch_down
  | `Touch_up
  | `Touch_motion
  | `Touch_cancel
  | `Touch_frame
]

let ev t =
  match C.Functions.Event.Touch.get_event (use t) with
  | Some kev -> kev
  | None -> failwith "Not a touch event!"

let get_time t = C.Functions.Event.Touch.get_time_usec (ev t)

let get_slot t = C.Functions.Event.Touch.get_slot (ev t)
let get_seat_slot t = C.Functions.Event.Touch.get_seat_slot (ev t)

let get_x t = C.Functions.Event.Touch.get_x (ev t)
let get_y t = C.Functions.Event.Touch.get_y (ev t)

let get_x_transformed t ~width = C.Functions.Event.Touch.get_x_transformed (ev t) width
let get_y_transformed t ~height = C.Functions.Event.Touch.get_y_transformed (ev t) height

let pp_generic f e =
  Fmt.pf f "time = %a;@;slot = %d;@;seat_slot = %d"
    Timestamp.pp (get_time e)
    (get_slot e)
    (get_seat_slot e)

let pp_xy f e =
  Fmt.pf f "{@[<v>%a;@;x = %.2f;@;y = %.2f@]}"
    pp_generic e
    (get_x e)
    (get_y e)

let pp_payload f = function
  | `Touch_down e -> pp_xy f e
  | `Touch_motion e -> pp_xy f e
  | `Touch_up e -> pp_generic f e
  | `Touch_cancel e -> pp_generic f e
  | `Touch_frame e -> Fmt.pf f "{@[<v>time = %a@]}" Timestamp.pp (get_time e)
