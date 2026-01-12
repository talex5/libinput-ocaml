open Event0

type ty = [
  | `Tablet_tool_axis of [`Tablet_tool_axis] t
  | `Tablet_tool_proximity of [`Tablet_tool_proximity] t
  | `Tablet_tool_tip of [`Tablet_tool_tip] t
  | `Tablet_tool_button of [`Tablet_tool_button] t
]

type any = [
  | `Tablet_tool_axis
  | `Tablet_tool_proximity
  | `Tablet_tool_tip
  | `Tablet_tool_button
]

let ev t =
  match C.Functions.Event.Tablet_tool.get_event (use t) with
  | Some kev -> kev
  | None -> failwith "Not a tablet-tool event!"

let get_time t = C.Functions.Event.Tablet_tool.get_time_usec (ev t)

let x_has_changed t = C.Functions.Event.Tablet_tool.x_has_changed (ev t)
let y_has_changed t = C.Functions.Event.Tablet_tool.y_has_changed (ev t)
let pressure_has_changed t = C.Functions.Event.Tablet_tool.pressure_has_changed (ev t)
let distance_has_changed t = C.Functions.Event.Tablet_tool.distance_has_changed (ev t)
let tilt_x_has_changed t = C.Functions.Event.Tablet_tool.tilt_x_has_changed (ev t)
let tilt_y_has_changed t = C.Functions.Event.Tablet_tool.tilt_y_has_changed (ev t)
let rotation_has_changed t = C.Functions.Event.Tablet_tool.rotation_has_changed (ev t)
let slider_has_changed t = C.Functions.Event.Tablet_tool.slider_has_changed (ev t)
let size_major_has_changed t = C.Functions.Event.Tablet_tool.size_major_has_changed (ev t)
let size_minor_has_changed t = C.Functions.Event.Tablet_tool.size_minor_has_changed (ev t)
let wheel_has_changed t = C.Functions.Event.Tablet_tool.wheel_has_changed (ev t)
let get_x t = C.Functions.Event.Tablet_tool.get_x (ev t)
let get_y t = C.Functions.Event.Tablet_tool.get_y (ev t)
let get_dx t = C.Functions.Event.Tablet_tool.get_dx (ev t)
let get_dy t = C.Functions.Event.Tablet_tool.get_dy (ev t)
let get_pressure t = C.Functions.Event.Tablet_tool.get_pressure (ev t)
let get_distance t = C.Functions.Event.Tablet_tool.get_distance (ev t)
let get_tilt_x t = C.Functions.Event.Tablet_tool.get_tilt_x (ev t)
let get_tilt_y t = C.Functions.Event.Tablet_tool.get_tilt_y (ev t)
let get_rotation t = C.Functions.Event.Tablet_tool.get_rotation (ev t)
let get_slider_position t = C.Functions.Event.Tablet_tool.get_slider_position (ev t)
let get_size_major t = C.Functions.Event.Tablet_tool.get_size_major (ev t)
let get_size_minor t = C.Functions.Event.Tablet_tool.get_size_minor (ev t)
let get_wheel_delta t = C.Functions.Event.Tablet_tool.get_wheel_delta (ev t)
let get_wheel_delta_discrete t = C.Functions.Event.Tablet_tool.get_wheel_delta_discrete (ev t)
let get_x_transformed t ~width = C.Functions.Event.Tablet_tool.get_x_transformed (ev t) width
let get_y_transformed t ~height = C.Functions.Event.Tablet_tool.get_y_transformed (ev t) height

let get_tool t =
  let cptr = C.Functions.Event.Tablet_tool.get_tool (ev t) in
  C.Functions.Tool.ref cptr;
  Context0.import_tool t.context cptr

let get_proximity_state t = C.Functions.Event.Tablet_tool.get_proximity_state (ev t)
let get_tip_state t = C.Functions.Event.Tablet_tool.get_tip_state (ev t)
let get_button t = C.Functions.Event.Tablet_tool.get_button (ev t)
let get_button_state t = C.Functions.Event.Tablet_tool.get_button_state (ev t)
let get_seat_button_count t = C.Functions.Event.Tablet_tool.get_seat_button_count (ev t)

let pp_generic f e =
  Fmt.pf f "time = %a;@;tool = %a;@;x = %.2f;@;y = %.2f;@;pressure = %.2f;@;distance = %.2f"
    Timestamp.pp (get_time e)
    Tablet_tool.pp (get_tool e)
    (get_x e)
    (get_y e)
    (get_pressure e)
    (get_distance e)

let pp_payload f = function
  | `Tablet_tool_axis e ->
    Fmt.pf f "{@[<v>%a;@;dx = %.2f;@;dy = %.2f@]}"
      pp_generic e
      (get_dx e)
      (get_dy e)
  | `Tablet_tool_proximity e ->
    Fmt.pf f "{@[<v>%a;@;proximity_state = %s@]}"
      pp_generic e
      (match get_proximity_state e with `In -> "In" | `Out -> "Out")
  | `Tablet_tool_tip e ->
    Fmt.pf f "{@[<v>%a;@;tip_state = %s@]}"
      pp_generic e
      (match get_tip_state e with `Down -> "Down" | `Up -> "Up")
  | `Tablet_tool_button e ->
    Fmt.pf f "{@[<v>%a;@;button = %d;@;state = %s;@;seat_key_count = %d@]}"
      pp_generic e
      (get_button e)
      (match get_button_state e with `Pressed -> "`Pressed" | `Released -> "`Released")
      (get_seat_button_count e)
