include Event0

let get_device t =
  let cptr = C.Functions.Event.get_device (use t) in
  C.Functions.Device.ref cptr;
  Device.import t.context cptr

module Keyboard = Event_keyboard
module Pointer = Event_pointer
module Touch = Event_touch
module Tablet_pad = Event_tablet_pad
module Gesture = Event_gesture
module Switch = Event_switch
module Tablet_tool = Event_tablet_tool

type ty = [
  | Event_device.ty
  | Keyboard.ty
  | Pointer.ty
  | Touch.ty
  | Tablet_tool.ty
  | Tablet_pad.ty
  | Gesture.ty
  | Switch.ty
  | `Unknown of [`Unknown] t
]

let get_type t : ty =
  let t = (t :> _ t) in
  match C.Functions.Event.get_type (use t) with
  | None -> assert false
  | Device_added -> `Device_added t
  | Device_removed -> `Device_removed t
  | Keyboard_key -> `Keyboard_key t
  | Pointer_motion -> `Pointer_motion t
  | Pointer_motion_absolute -> `Pointer_motion_absolute t
  | Pointer_button -> `Pointer_button t
  | Pointer_axis -> `Pointer_axis t
  | Pointer_scroll_wheel -> `Pointer_scroll_wheel t
  | Pointer_scroll_finger -> `Pointer_scroll_finger t
  | Pointer_scroll_continuous -> `Pointer_scroll_continuous t
  | Touch_down -> `Touch_down t
  | Touch_up -> `Touch_up t
  | Touch_motion -> `Touch_motion t
  | Touch_cancel -> `Touch_cancel t
  | Touch_frame -> `Touch_frame t
  | Tablet_tool_axis -> `Tablet_tool_axis t
  | Tablet_tool_proximity -> `Tablet_tool_proximity t
  | Tablet_tool_tip -> `Tablet_tool_tip t
  | Tablet_tool_button -> `Tablet_tool_button t
  | Tablet_pad_button -> `Tablet_pad_button t
  | Tablet_pad_ring -> `Tablet_pad_ring t
  | Tablet_pad_strip -> `Tablet_pad_strip t
  | Tablet_pad_key -> `Tablet_pad_key t
  | Tablet_pad_dial -> `Tablet_pad_dial t
  | Gesture_swipe_begin -> `Gesture_swipe_begin t
  | Gesture_swipe_update -> `Gesture_swipe_update t
  | Gesture_swipe_end -> `Gesture_swipe_end t
  | Gesture_pinch_begin -> `Gesture_pinch_begin t
  | Gesture_pinch_update -> `Gesture_pinch_update t
  | Gesture_pinch_end -> `Gesture_pinch_end t
  | Gesture_hold_begin -> `Gesture_hold_begin t
  | Gesture_hold_end -> `Gesture_hold_end t
  | Switch_toggle -> `Switch_toggle t
  | Unknown _ -> `Unknown t

let event (ty : [< ty]) : _ t =
  let r t = (t :> [`Unclassified] t) in
  match ty with
  | `Device_added t -> r t
  | `Device_removed t -> r t
  | `Keyboard_key t -> r t
  | `Pointer_motion t -> r t
  | `Pointer_motion_absolute t -> r t
  | `Pointer_button t -> r t
  | `Pointer_axis t -> r t
  | `Pointer_scroll_wheel t -> r t
  | `Pointer_scroll_finger t -> r t
  | `Pointer_scroll_continuous t -> r t
  | `Touch_down t -> r t
  | `Touch_up t -> r t
  | `Touch_motion t -> r t
  | `Touch_cancel t -> r t
  | `Touch_frame t -> r t
  | `Tablet_tool_axis t -> r t
  | `Tablet_tool_proximity t -> r t
  | `Tablet_tool_tip t -> r t
  | `Tablet_tool_button t -> r t
  | `Tablet_pad_button t -> r t
  | `Tablet_pad_ring t -> r t
  | `Tablet_pad_strip t -> r t
  | `Tablet_pad_key t -> r t
  | `Tablet_pad_dial t -> r t
  | `Gesture_swipe_begin t -> r t
  | `Gesture_swipe_update t -> r t
  | `Gesture_swipe_end t -> r t
  | `Gesture_pinch_begin t -> r t
  | `Gesture_pinch_update t -> r t
  | `Gesture_pinch_end t -> r t
  | `Gesture_hold_begin t -> r t
  | `Gesture_hold_end t -> r t
  | `Switch_toggle t -> r t
  | `Unknown t -> r t

let pp_payload f : [< ty] -> unit = function
  | #Event_device.ty as e -> Event_device.pp_payload f e
  | #Keyboard.ty as e -> Keyboard.pp_payload f e
  | #Pointer.ty as e -> Pointer.pp_payload f e
  | #Tablet_tool.ty as e -> Tablet_tool.pp_payload f e
  | #Tablet_pad.ty as e -> Tablet_pad.pp_payload f e
  | #Gesture.ty as e -> Gesture.pp_payload f e
  | #Touch.ty as e -> Touch.pp_payload f e
  | #Switch.ty as e -> Switch.pp_payload f e
  | `Unknown _ -> Fmt.string f "..."

let pp f t =
  let ty = C.Functions.Event.get_type (use t) in
  let pp_device = if ty = Device_added then Device.dump else Device.pp in
  Fmt.pf f "{@[<v>type = `%a %a;@;device = %a]}"
    C.Types.Event.Type.pp ty
    pp_payload (get_type t)
    pp_device (get_device t)

let pp_ty f ty = pp f (event ty)

module Device = Event_device
