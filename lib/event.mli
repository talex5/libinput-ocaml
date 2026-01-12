(** Events (e.g. keypresses) reported to the application from libinput. *)

type +_ t
(** An event notification related to a device.

    Use {!get} to get the next event from libinput.

    See {{: https://wayland.freedesktop.org/libinput/doc/latest/api/group__base.html }}
*)

val get : [`Udev | `Path] Context.t -> [`Unclassified] t option
(** [get context] retrieves the next event from libinput's internal event queue.

    Events are added to the queue by {!Context.dispatch}.
    Use {!get_type} to examine the event. *)

val destroy : _ t -> unit
(** [destroy t] frees the C event and marks the OCaml wrapper as destroyed.

    This will be called automatically when the event gets GC'd anyway,
    but you may prefer to free the event manually earlier. *)

val pp : _ t Fmt.t [@@ocaml.toplevel_printer]

val get_context : _ t -> [`Udev | `Path] Context.t
val get_device : _ t -> Device.t

(** Events about devices being added and removed. *)
module Device : sig
  type ty = [
    | `Device_added of [`Device_added] t
    | `Device_removed of [`Device_removed] t
  ]
end

(** Events from keyboard devices. *)
module Keyboard : sig
  type ty = [
    | `Keyboard_key of [`Keyboard_key] t
  ]

  val get_key : [`Keyboard_key] t -> Keycode.t
  val get_key_state : [`Keyboard_key] t -> [`Released | `Pressed]
  val get_time : [`Keyboard_key] t -> Timestamp.t

  val get_seat_key_count : [`Keyboard_key] t -> int
  (** [get_seat_key_count t] is the total number of instances of this key being pressed across all devices

      This is typically either 0 (for a release) or 1 (for a press).
      It's useful if you have e.g. two keyboards and press Shift on both,
      then release on one of them, to know that Shift is still pressed somewhere. *)
end

(** Events from mice, touchpads, etc. *)
module Pointer : sig
  type ty = [
    | `Pointer_motion of [`Pointer_motion] t
    | `Pointer_motion_absolute of [`Pointer_motion_absolute] t
    | `Pointer_button of [`Pointer_button] t
    | `Pointer_axis of [`Pointer_axis] t        (** Deprecated; use the scroll events below instead. *)
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

  val get_button : [`Pointer_button] t -> Keycode.t
  val get_button_state : [`Pointer_button] t -> [`Released | `Pressed]
  val get_seat_button_count : [`Pointer_button] t -> int

  val get_dx : [`Pointer_motion] t -> float
  val get_dy : [`Pointer_motion] t -> float

  val get_dx_unaccelerated : [`Pointer_motion] t -> float
  val get_dy_unaccelerated : [`Pointer_motion] t -> float

  val get_absolute_x : [`Pointer_motion_absolute] t -> float
  val get_absolute_y : [`Pointer_motion_absolute] t -> float

  val get_absolute_x_transformed : [`Pointer_motion_absolute] t -> width:int -> float
  val get_absolute_y_transformed : [`Pointer_motion_absolute] t -> height:int -> float

  val get_time : [< any] t -> Timestamp.t

  val has_axis :
    [< `Pointer_scroll_wheel | `Pointer_scroll_finger | `Pointer_scroll_continuous] t ->
    [`Scroll_vertical | `Scroll_horizontal] ->
    bool

  val get_scroll_value :
    [< `Pointer_scroll_wheel | `Pointer_scroll_finger | `Pointer_scroll_continuous] t ->
    [`Scroll_vertical | `Scroll_horizontal] ->
    float option
  (** For scroll wheels, using {!get_scroll_value_v120} is preferred. *)

  val get_scroll_value_v120 :
    [`Pointer_scroll_wheel] t ->
    [`Scroll_vertical | `Scroll_horizontal] ->
    float option
  (** High-resolution scroll events, normalized to the -120..+120 range.

      e.g. +/- 120 represents one logical click of the wheel. *)
end

(** Events from touch screens (but not graphics tablets or touchpads). *)
module Touch : sig
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

  val get_time : [< any] t -> Timestamp.t

  val get_slot : [< `Touch_down | `Touch_up | `Touch_motion | `Touch_cancel] t -> int
  val get_seat_slot : [< `Touch_down | `Touch_up | `Touch_motion | `Touch_cancel] t -> int

  val get_x : [< `Touch_down | `Touch_motion] t -> float
  val get_y : [< `Touch_down | `Touch_motion] t -> float

  val get_x_transformed : [< `Touch_down | `Touch_motion] t -> width:int -> float
  val get_y_transformed : [< `Touch_down | `Touch_motion] t -> height:int -> float
end

(** Events from graphics tablet tools (e.g. pens). *)
module Tablet_tool : sig
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

  val get_time : [< any] t -> Timestamp.t

  val x_has_changed : [< any] t -> bool
  val y_has_changed : [< any] t -> bool
  val pressure_has_changed : [< any] t -> bool
  val distance_has_changed : [< any] t -> bool
  val tilt_x_has_changed : [< any] t -> bool
  val tilt_y_has_changed : [< any] t -> bool
  val rotation_has_changed : [< any] t -> bool
  val slider_has_changed : [< any] t -> bool
  val size_major_has_changed : [< any] t -> bool
  val size_minor_has_changed : [< any] t -> bool
  val wheel_has_changed : [< any] t -> bool

  val get_x : [< any] t -> float
  val get_y : [< any] t -> float
  val get_dx : [< any] t -> float
  val get_dy : [< any] t -> float
  val get_pressure : [< any] t -> float
  val get_distance : [< any] t -> float
  val get_tilt_x : [< any] t -> float
  val get_tilt_y : [< any] t -> float
  val get_rotation : [< any] t -> float
  val get_slider_position : [< any] t -> float
  val get_size_major : [< any] t -> float
  val get_size_minor : [< any] t -> float
  val get_wheel_delta : [< any] t -> float
  val get_wheel_delta_discrete : [< any] t -> int
  val get_x_transformed : [< any] t -> width:int -> float
  val get_y_transformed : [< any] t -> height:int -> float
  val get_tool : [< any] t -> Tablet_tool.t
  val get_proximity_state : [< any] t -> [`In | `Out]
  val get_tip_state : [< any] t -> [`Up | `Down]
  val get_button : [`Tablet_tool_button] t -> int
  val get_button_state : [`Tablet_tool_button] t -> [`Released | `Pressed]
  val get_seat_button_count : [`Tablet_tool_button] t -> int
end

(** Events from graphics tablet controls. *)
module Tablet_pad : sig
  type ty = [
    | `Tablet_pad_button of [`Tablet_pad_button] t
    | `Tablet_pad_ring of [`Tablet_pad_ring] t
    | `Tablet_pad_strip of [`Tablet_pad_strip] t
    | `Tablet_pad_key of [`Tablet_pad_key] t
    | `Tablet_pad_dial of [`Tablet_pad_dial] t
  ]

  type any = [
    | `Tablet_pad_button
    | `Tablet_pad_ring
    | `Tablet_pad_strip
    | `Tablet_pad_key
    | `Tablet_pad_dial
  ]

  val get_time : [< any] t -> Timestamp.t

  val get_ring_position : [`Tablet_pad_ring] t -> float
  val get_ring_number : [`Tablet_pad_ring] t -> int
  val get_ring_source : [`Tablet_pad_ring] t -> [`Finger | `Unknown]

  val get_strip_position : [`Tablet_pad_strip] t -> float
  val get_strip_number : [`Tablet_pad_strip] t -> int
  val get_strip_source : [`Tablet_pad_strip] t -> [`Finger | `Unknown]

  val get_button_number : [`Tablet_pad_button] t -> int
  val get_button_state : [`Tablet_pad_button] t -> [`Released | `Pressed]

  val get_key : [`Tablet_pad_key] t -> Keycode.t
  val get_key_state : [`Tablet_pad_key] t -> [`Released | `Pressed]

  val get_dial_delta_v120 : [`Tablet_pad_dial] t -> float
  val get_dial_number : [`Tablet_pad_dial] t -> int

  val get_mode : [< `Tablet_pad_button | `Tablet_pad_ring | `Tablet_pad_strip | `Tablet_pad_dial] t -> int
  val get_mode_group : [< `Tablet_pad_button | `Tablet_pad_ring | `Tablet_pad_strip | `Tablet_pad_dial] t -> Mode_group.t
end

(** Gestures (e.g. pinch-to-zoom on a touchpad). *)
module Gesture : sig
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

  val get_time : [< any] t -> Timestamp.t

  val get_finger_count : [< any] t -> int
  val get_cancelled : [< `Gesture_swipe_end | `Gesture_pinch_end] t -> bool
  val get_dx : [< `Gesture_swipe_update | `Gesture_pinch_update] t -> float
  val get_dy : [< `Gesture_swipe_update | `Gesture_pinch_update] t -> float
  val get_dx_unaccelerated : [< `Gesture_swipe_update | `Gesture_pinch_update] t -> float
  val get_dy_unaccelerated : [< `Gesture_swipe_update | `Gesture_pinch_update] t -> float

  val get_scale : [< `Gesture_pinch_begin | `Gesture_pinch_update | `Gesture_pinch_end] t -> float
  val get_angle_delta : [`Gesture_pinch_update] t -> float
end

(** Simple on/off switches. *)
module Switch : sig
  type ty = [
    | `Switch_toggle of [`Switch_toggle] t
  ]

  type any = [`Switch_toggle]

  val get_time : [< any] t -> Timestamp.t

  val get_type : [`Switch_toggle] t -> [ `Lid | `Tablet_mode | `Unknown of int64 ]
  val get_state : [`Switch_toggle] t -> [`Off | `On]
end

type ty = [
  | Device.ty
  | Keyboard.ty
  | Pointer.ty
  | Touch.ty
  | Tablet_tool.ty
  | Tablet_pad.ty
  | Gesture.ty
  | Switch.ty
  | `Unknown of [`Unknown] t
]

val get_type : _ t -> ty
(** [get_type t] classifies an event by its type, and provides access to type-specific details. *)

val pp_ty : [< ty] Fmt.t
