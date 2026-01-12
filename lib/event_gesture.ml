open Event0

type ty = [
  | `Gesture_swipe_begin of [`Gesture_swipe_begin] t
  | `Gesture_swipe_update of [`Gesture_swipe_update] t
  | `Gesture_swipe_end of [`Gesture_swipe_end] t
  | `Gesture_pinch_begin of [`Gesture_pinch_begin] t
  | `Gesture_pinch_update of [`Gesture_pinch_update] t
  | `Gesture_pinch_end of [`Gesture_pinch_end] t
  | `Gesture_hold_begin of [`Gesture_hold_begin] t
  | `Gesture_hold_end of [`Gesture_hold_end] t
]

type any = [
  | `Gesture_swipe_begin
  | `Gesture_swipe_update
  | `Gesture_swipe_end
  | `Gesture_pinch_begin
  | `Gesture_pinch_update
  | `Gesture_pinch_end
  | `Gesture_hold_begin
  | `Gesture_hold_end
]

let ev t =
  match C.Functions.Event.Gesture.get_event (use t) with
  | Some kev -> kev
  | None -> failwith "Not a gesture event!"

module F = C.Functions.Event.Gesture

let get_time t = F.get_time_usec (ev t)

let get_finger_count t = F.get_finger_count (ev t)
let get_cancelled t = F.get_cancelled (ev t)
let get_dx t = F.get_dx (ev t)
let get_dy t = F.get_dy (ev t)
let get_dx_unaccelerated t = F.get_dx_unaccelerated (ev t)
let get_dy_unaccelerated t = F.get_dy_unaccelerated (ev t)
let get_scale t = F.get_scale (ev t)
let get_angle_delta t = F.get_angle_delta (ev t)

let pp_generic f e =
  Fmt.pf f "time = %a;@;finger_count = %d"
    Timestamp.pp (get_time e)
    (get_finger_count e)

let pp_update f e =
  Fmt.pf f "{@[<v>%a;@;dx = %.2f;@;dy = %.2f@]}"
    pp_generic e
    (get_dx e)
    (get_dy e)

let pp_cancellable f e =
  Fmt.pf f "{@[<v>%a;@;cancelled = %b@]}"
    pp_generic e
    (get_cancelled e)

let pp_payload f = function
  | `Gesture_swipe_update e -> pp_update f e
  | `Gesture_pinch_update e -> pp_update f e
  | `Gesture_pinch_begin e -> pp_cancellable f e
  | `Gesture_swipe_end e -> pp_cancellable f e
  | `Gesture_pinch_end e -> pp_cancellable f e
  | `Gesture_hold_begin e -> pp_generic f e
  | `Gesture_hold_end e -> pp_generic f e
  | `Gesture_swipe_begin e -> pp_generic f e
