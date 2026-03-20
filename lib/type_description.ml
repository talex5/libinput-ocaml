open Ctypes

(* Not checked with cstubs as it was only added in 1.27.0 *)
module Area_rectangle = struct
  type t = [`Libinput_config_area_rectangle] structure
  let t : t typ = Ctypes.structure "libinput_config_area_rectangle"
  let x1 = field t "x1" double
  let y1 = field t "y1" double
  let x2 = field t "x2" double
  let y2 = field t "y2" double
  let () = seal t
end

module Types (F : Ctypes.TYPE) = struct
  open F

  let pp_version f (x, y) = Fmt.pf f "%d.%d" x y

  let () =
    let min_version = (1, 20) in
    if Config.version < min_version then
      Fmt.failwith "libinput-ocaml requires C libinput version %a or later (have %a)" pp_version min_version pp_version Config.version

  module Struct(X : sig type t val name : string end) = struct
    type t = X.t structure
    let t : t typ = structure X.name
  end

  module Struct_opt(X : sig type t val name : string val requires : int * int end) = struct
    type t = X.t structure
    let t : t typ option = if Config.version >= X.requires then Some (structure X.name) else None
  end

  let funptr x = lift_typ (Foreign.funptr x)

  (* Supporting libraries *)

  let fd =
    let int_of_unix (fd : Unix.file_descr) : int = Obj.magic fd in
    let unix_of_int (fd : int) : Unix.file_descr = assert (fd >= 0); Obj.magic fd in
    view ~read:unix_of_int ~write:int_of_unix int

  module Open_flags = struct
    let o_accmode = constant "O_ACCMODE" int
    let o_rdonly = constant "O_RDONLY" int
    let o_wronly = constant "O_WRONLY" int
    let o_rdwr = constant "O_RDWR" int

    let o_cloexec = constant "O_CLOEXEC" int
    let o_nonblock = constant "O_NONBLOCK" int
  end

  module Udev = Struct(struct type t = [`Udev] let name = "udev" end)

  (* libinput types *)

  let constant_opt ~requires x t =
    if Config.version >= requires then Some (constant x t)
    else None

  let enum_val x = constant x int64_t
  let enum_val_opt ~requires x = constant_opt ~requires x int64_t

  let user_data = ptr void

  let make_enum ?unexpected ?requires enum_name items =
    match requires with
    | Some min_version when min_version > Config.version ->
      let error _ = Fmt.failwith "Requires libinput >= %a" pp_version min_version in
      view uint64_t ~read:error ~write:error
    | _ ->
      let unexpected =
        match unexpected with
        | None -> fun x -> Fmt.failwith "Unknown %s value %Ld!" enum_name x
        | Some x -> x
      in
      enum enum_name ~typedef:false ~unexpected
        (List.map (fun (a, b) -> (b, enum_val a)) items)

  module Libinput     = Struct(struct type t = [`Libinput]                       let name = "libinput"                       end)
  module Device_group = Struct(struct type t = [`Libinput_device_group]          let name = "libinput_device_group"          end)
  module Seat         = Struct(struct type t = [`Libinput_seat]                  let name = "libinput_seat"                  end)
  module Mode_group   = Struct(struct type t = [`Libinput_tablet_pad_mode_group] let name = "libinput_tablet_pad_mode_group" end)
  module Device       = Struct(struct type t = [`Libinput_device]                let name = "libinput_device"                end)
  module Tool         = Struct(struct type t = [`Libinput_tablet_tool]           let name = "libinput_tablet_tool"           end)

  module Interface = struct
    include Struct(struct type t = [`Libinput_interface] let name = "libinput_interface" end)

    let open_restricted = field t "open_restricted" @@ funptr @@ const (ptr char) @-> int @-> user_data @-> returning int
    let close_restricted = field t "close_restricted" @@ funptr @@ int @-> user_data @-> returning void
    let () = seal t
  end

  module Device_capability = struct
    type t =
      | Keyboard
      | Pointer
      | Touch
      | Tablet_tool
      | Tablet_pad
      | Gesture
      | Switch
      | Unknown of int64

    let t = make_enum ~unexpected:(fun x -> Unknown x) "libinput_device_capability" [
        "LIBINPUT_DEVICE_CAP_KEYBOARD", Keyboard;
        "LIBINPUT_DEVICE_CAP_POINTER", Pointer;
        "LIBINPUT_DEVICE_CAP_TOUCH", Touch;
        "LIBINPUT_DEVICE_CAP_TABLET_TOOL", Tablet_tool;
        "LIBINPUT_DEVICE_CAP_TABLET_PAD", Tablet_pad;
        "LIBINPUT_DEVICE_CAP_GESTURE", Gesture;
        "LIBINPUT_DEVICE_CAP_SWITCH", Switch;
      ]
  end

  module Led = struct
    let t = int64_t

    let num_lock = enum_val "LIBINPUT_LED_NUM_LOCK"
    let caps_lock = enum_val "LIBINPUT_LED_CAPS_LOCK"
    let scroll_lock = enum_val "LIBINPUT_LED_SCROLL_LOCK"
    let compose = enum_val_opt ~requires:(1, 26) "LIBINPUT_LED_COMPOSE"
    let kana = enum_val_opt ~requires:(1, 26) "LIBINPUT_LED_KANA"
  end

  module Switch = struct
    type t = [
      | `Lid
      | `Tablet_mode
      | `Unknown of int64
    ]

    let t : t typ = make_enum "libinput_switch" ~unexpected:(fun x -> `Unknown x) [
        "LIBINPUT_SWITCH_LID", `Lid;
        "LIBINPUT_SWITCH_TABLET_MODE", `Tablet_mode;
      ]
  end

  module Tool_type = struct
    type t =
      | Pen
      | Eraser
      | Brush
      | Pencil
      | Airbrush
      | Mouse
      | Lens
      | Totem
      | Unknown of int64

    let t = make_enum "libinput_tablet_tool_type" ~unexpected:(fun x -> Unknown x) [
        "LIBINPUT_TABLET_TOOL_TYPE_PEN", Pen;
        "LIBINPUT_TABLET_TOOL_TYPE_ERASER", Eraser;
        "LIBINPUT_TABLET_TOOL_TYPE_BRUSH", Brush;
        "LIBINPUT_TABLET_TOOL_TYPE_PENCIL", Pencil;
        "LIBINPUT_TABLET_TOOL_TYPE_AIRBRUSH", Airbrush;
        "LIBINPUT_TABLET_TOOL_TYPE_MOUSE", Mouse;
        "LIBINPUT_TABLET_TOOL_TYPE_LENS", Lens;
        "LIBINPUT_TABLET_TOOL_TYPE_TOTEM", Totem;
      ]
  end

  module Eraser_button_mode = struct
    type t =
      | Default
      | Button
      | Unknown of int64

    let supported = Config.version > (1, 29)

    let t =
      make_enum "libinput_config_eraser_button_mode"
        ~unexpected:(fun x -> Unknown x)
        ~requires:(1, 29)
        [
          "LIBINPUT_CONFIG_ERASER_BUTTON_DEFAULT", Default;
          "LIBINPUT_CONFIG_ERASER_BUTTON_BUTTON", Button;
        ]
  end

  let proximity_state : [`Out|`In] typ =
    make_enum "libinput_tablet_tool_proximity_state" [
      "LIBINPUT_TABLET_TOOL_PROXIMITY_STATE_OUT", `Out;
      "LIBINPUT_TABLET_TOOL_PROXIMITY_STATE_IN", `In;
    ]

  let tip_state : [`Up|`Down] typ =
    make_enum "libinput_tablet_tool_tip_state" [
      "LIBINPUT_TABLET_TOOL_TIP_UP", `Up;
      "LIBINPUT_TABLET_TOOL_TIP_DOWN", `Down;
    ]

  let ring_axis_source : [`Unknown|`Finger] typ =
    make_enum "libinput_tablet_pad_ring_axis_source" [
      "LIBINPUT_TABLET_PAD_RING_SOURCE_UNKNOWN", `Unknown;
      "LIBINPUT_TABLET_PAD_RING_SOURCE_FINGER", `Finger;
    ]

  let strip_axis_source : [`Unknown|`Finger] typ =
    make_enum "libinput_tablet_pad_strip_axis_source" [
      "LIBINPUT_TABLET_PAD_STRIP_SOURCE_UNKNOWN", `Unknown;
      "LIBINPUT_TABLET_PAD_STRIP_SOURCE_FINGER", `Finger;
    ]

  type press_state = [`Released|`Pressed]
  let key_state : press_state typ =
    make_enum "libinput_key_state" [
      "LIBINPUT_KEY_STATE_RELEASED", `Released;
      "LIBINPUT_KEY_STATE_PRESSED", `Pressed;
    ]

  let button_state : press_state typ =
    make_enum "libinput_button_state" [
      "LIBINPUT_BUTTON_STATE_RELEASED", `Released;
      "LIBINPUT_BUTTON_STATE_PRESSED", `Pressed;
    ]

  let axis : [`Scroll_vertical|`Scroll_horizontal] typ =
    make_enum "libinput_pointer_axis" [
      "LIBINPUT_POINTER_AXIS_SCROLL_VERTICAL", `Scroll_vertical;
      "LIBINPUT_POINTER_AXIS_SCROLL_HORIZONTAL", `Scroll_horizontal;
    ]

  let switch_state : [`Off|`On] typ =
    make_enum "libinput_switch_state" [
      "LIBINPUT_SWITCH_STATE_OFF", `Off;
      "LIBINPUT_SWITCH_STATE_ON", `On;
    ]

  module Event = struct
    module Type = struct
      type t =
        | None
        | Device_added
        | Device_removed
        | Keyboard_key
        | Pointer_motion
        | Pointer_motion_absolute
        | Pointer_button
        | Pointer_axis
        | Pointer_scroll_wheel
        | Pointer_scroll_finger
        | Pointer_scroll_continuous
        | Touch_down
        | Touch_up
        | Touch_motion
        | Touch_cancel
        | Touch_frame
        | Tablet_tool_axis
        | Tablet_tool_proximity
        | Tablet_tool_tip
        | Tablet_tool_button
        | Tablet_pad_button
        | Tablet_pad_ring
        | Tablet_pad_strip
        | Tablet_pad_key
        | Tablet_pad_dial
        | Gesture_swipe_begin
        | Gesture_swipe_update
        | Gesture_swipe_end
        | Gesture_pinch_begin
        | Gesture_pinch_update
        | Gesture_pinch_end
        | Gesture_hold_begin
        | Gesture_hold_end
        | Switch_toggle
        | Unknown of int64

      let t = make_enum "libinput_event_type" ~unexpected:(fun x -> Unknown x) ([
          "LIBINPUT_EVENT_NONE", None;
          "LIBINPUT_EVENT_DEVICE_ADDED", Device_added;
          "LIBINPUT_EVENT_DEVICE_REMOVED", Device_removed;
          "LIBINPUT_EVENT_KEYBOARD_KEY", Keyboard_key;
          "LIBINPUT_EVENT_POINTER_MOTION", Pointer_motion;
          "LIBINPUT_EVENT_POINTER_MOTION_ABSOLUTE", Pointer_motion_absolute;
          "LIBINPUT_EVENT_POINTER_BUTTON", Pointer_button;
          "LIBINPUT_EVENT_POINTER_AXIS", Pointer_axis;
          "LIBINPUT_EVENT_POINTER_SCROLL_WHEEL", Pointer_scroll_wheel;
          "LIBINPUT_EVENT_POINTER_SCROLL_FINGER", Pointer_scroll_finger;
          "LIBINPUT_EVENT_POINTER_SCROLL_CONTINUOUS", Pointer_scroll_continuous;
          "LIBINPUT_EVENT_TOUCH_DOWN", Touch_down;
          "LIBINPUT_EVENT_TOUCH_UP", Touch_up;
          "LIBINPUT_EVENT_TOUCH_MOTION", Touch_motion;
          "LIBINPUT_EVENT_TOUCH_CANCEL", Touch_cancel;
          "LIBINPUT_EVENT_TOUCH_FRAME", Touch_frame;
          "LIBINPUT_EVENT_TABLET_TOOL_AXIS", Tablet_tool_axis;
          "LIBINPUT_EVENT_TABLET_TOOL_PROXIMITY", Tablet_tool_proximity;
          "LIBINPUT_EVENT_TABLET_TOOL_TIP", Tablet_tool_tip;
          "LIBINPUT_EVENT_TABLET_TOOL_BUTTON", Tablet_tool_button;
          "LIBINPUT_EVENT_TABLET_PAD_BUTTON", Tablet_pad_button;
          "LIBINPUT_EVENT_TABLET_PAD_RING", Tablet_pad_ring;
          "LIBINPUT_EVENT_TABLET_PAD_STRIP", Tablet_pad_strip;
          "LIBINPUT_EVENT_TABLET_PAD_KEY", Tablet_pad_key;
          "LIBINPUT_EVENT_GESTURE_SWIPE_BEGIN", Gesture_swipe_begin;
          "LIBINPUT_EVENT_GESTURE_SWIPE_UPDATE", Gesture_swipe_update;
          "LIBINPUT_EVENT_GESTURE_SWIPE_END", Gesture_swipe_end;
          "LIBINPUT_EVENT_GESTURE_PINCH_BEGIN", Gesture_pinch_begin;
          "LIBINPUT_EVENT_GESTURE_PINCH_UPDATE", Gesture_pinch_update;
          "LIBINPUT_EVENT_GESTURE_PINCH_END", Gesture_pinch_end;
          "LIBINPUT_EVENT_GESTURE_HOLD_BEGIN", Gesture_hold_begin;
          "LIBINPUT_EVENT_GESTURE_HOLD_END", Gesture_hold_end;
          "LIBINPUT_EVENT_SWITCH_TOGGLE", Switch_toggle;
        ] @ (
            if Config.version > (1, 26) then [
              "LIBINPUT_EVENT_TABLET_PAD_DIAL", Tablet_pad_dial;
            ] else []
          )
        )

      let pp f = function
        | None -> Fmt.pf f "None"
        | Device_added -> Fmt.pf f "Device_added"
        | Device_removed -> Fmt.pf f "Device_removed"
        | Keyboard_key -> Fmt.pf f "Keyboard_key"
        | Pointer_motion -> Fmt.pf f "Pointer_motion"
        | Pointer_motion_absolute -> Fmt.pf f "Pointer_motion_absolute"
        | Pointer_button -> Fmt.pf f "Pointer_button"
        | Pointer_axis -> Fmt.pf f "Pointer_axis"
        | Pointer_scroll_wheel -> Fmt.pf f "Pointer_scroll_wheel"
        | Pointer_scroll_finger -> Fmt.pf f "Pointer_scroll_finger"
        | Pointer_scroll_continuous -> Fmt.pf f "Pointer_scroll_continuous"
        | Touch_down -> Fmt.pf f "Touch_down"
        | Touch_up -> Fmt.pf f "Touch_up"
        | Touch_motion -> Fmt.pf f "Touch_motion"
        | Touch_cancel -> Fmt.pf f "Touch_cancel"
        | Touch_frame -> Fmt.pf f "Touch_frame"
        | Tablet_tool_axis -> Fmt.pf f "Tablet_tool_axis"
        | Tablet_tool_proximity -> Fmt.pf f "Tablet_tool_proximity"
        | Tablet_tool_tip -> Fmt.pf f "Tablet_tool_tip"
        | Tablet_tool_button -> Fmt.pf f "Tablet_tool_button"
        | Tablet_pad_button -> Fmt.pf f "Tablet_pad_button"
        | Tablet_pad_ring -> Fmt.pf f "Tablet_pad_ring"
        | Tablet_pad_strip -> Fmt.pf f "Tablet_pad_strip"
        | Tablet_pad_key -> Fmt.pf f "Tablet_pad_key"
        | Tablet_pad_dial -> Fmt.pf f "Tablet_pad_dial"
        | Gesture_swipe_begin -> Fmt.pf f "Gesture_swipe_begin"
        | Gesture_swipe_update -> Fmt.pf f "Gesture_swipe_update"
        | Gesture_swipe_end -> Fmt.pf f "Gesture_swipe_end"
        | Gesture_pinch_begin -> Fmt.pf f "Gesture_pinch_begin"
        | Gesture_pinch_update -> Fmt.pf f "Gesture_pinch_update"
        | Gesture_pinch_end -> Fmt.pf f "Gesture_pinch_end"
        | Gesture_hold_begin -> Fmt.pf f "Gesture_hold_begin"
        | Gesture_hold_end -> Fmt.pf f "Gesture_hold_end"
        | Switch_toggle -> Fmt.pf f "Switch_toggle"
        | Unknown ty -> Fmt.pf f "Unknown type %Ld" ty
    end

    include Struct(struct type t = [`Libinput_event] let name = "libinput_event" end)

    module Device_notify = Struct(struct type t = [`Libinput_event_device_notify] let name = "libinput_event_device_notify" end)
    module Keyboard      = Struct(struct type t = [`Libinput_event_keyboard]      let name = "libinput_event_keyboard"      end)
    module Pointer       = Struct(struct type t = [`Libinput_event_pointer]       let name = "libinput_event_pointer"       end)
    module Touch         = Struct(struct type t = [`Libinput_event_touch]         let name = "libinput_event_touch"         end)
    module Gesture       = Struct(struct type t = [`Libinput_event_gesture]       let name = "libinput_event_gesture"       end)
    module Tablet_tool   = Struct(struct type t = [`Libinput_event_tablet_tool]   let name = "libinput_event_tablet_tool"   end)
    module Tablet_pad    = Struct(struct type t = [`Libinput_event_tablet_pad]    let name = "libinput_event_tablet_pad"    end)
    module Switch        = Struct(struct type t = [`Libinput_event_switch]        let name = "libinput_event_switch"        end)
  end

  module Log_priority = struct
    type t =
      | Debug
      | Info
      | Error
      | Unknown of int64

    let t = make_enum ~unexpected:(fun x -> Unknown x) "libinput_log_priority" [
        "LIBINPUT_LOG_PRIORITY_DEBUG", Debug;
        "LIBINPUT_LOG_PRIORITY_INFO", Info;
        "LIBINPUT_LOG_PRIORITY_ERROR", Error;
      ]
  end

  let log_handler_simple = funptr @@ Log_priority.t @-> string @-> returning void

  module Config = struct
    type status = [ `Success | `Unsupported | `Invalid ]
    let status : status typ =
      make_enum "libinput_config_status" [
        "LIBINPUT_CONFIG_STATUS_SUCCESS", `Success;
        "LIBINPUT_CONFIG_STATUS_UNSUPPORTED", `Unsupported;
        "LIBINPUT_CONFIG_STATUS_INVALID", `Invalid;
      ]

    module Accel = Struct_opt(struct type t = [`Libinput_config_accel] let name = "libinput_config_accel" let requires = (1, 23) end)

    let make_enabled_enum prefix : [`Enabled|`Disabled] typ =
      let enum_name = String.lowercase_ascii prefix ^ "_state" in
      make_enum enum_name [
        prefix ^ "_ENABLED", `Enabled;
        prefix ^ "_DISABLED", `Disabled;
      ]

    let make_enabled_enum_opt ~requires prefix =
      if Config.version >= requires then Some (make_enabled_enum prefix)
      else None

    let tap_state                = make_enabled_enum "LIBINPUT_CONFIG_TAP"
    let drag_state               = make_enabled_enum "LIBINPUT_CONFIG_DRAG"
    let middle_emulation_state   = make_enabled_enum "LIBINPUT_CONFIG_MIDDLE_EMULATION"
    let scroll_button_lock_state = make_enabled_enum "LIBINPUT_CONFIG_SCROLL_BUTTON_LOCK"
    let dwt_state                = make_enabled_enum "LIBINPUT_CONFIG_DWT"
    let dwtp_state               = make_enabled_enum_opt ~requires:(1, 21) "LIBINPUT_CONFIG_DWTP"

    let tap_button_map : [ `LRM | `LMR ] typ =
      make_enum "libinput_config_tap_button_map" [
        "LIBINPUT_CONFIG_TAP_MAP_LRM", `LRM;
        "LIBINPUT_CONFIG_TAP_MAP_LMR", `LMR;
      ]

    let clickfinger_button_map : [ `LRM | `LMR ] typ =
      make_enum "libinput_config_clickfinger_button_map" ~requires:(1, 26) [
        "LIBINPUT_CONFIG_CLICKFINGER_MAP_LRM", `LRM;
        "LIBINPUT_CONFIG_CLICKFINGER_MAP_LMR", `LMR;
      ]

    let drag_lock_state : [ `Disabled | `Enabled_timeout | `Enabled_sticky ] typ =
      make_enum "libinput_config_drag_lock_state" ~requires:(1, 27) [
        "LIBINPUT_CONFIG_DRAG_LOCK_DISABLED", `Disabled;
        "LIBINPUT_CONFIG_DRAG_LOCK_ENABLED_TIMEOUT", `Enabled_timeout;
        "LIBINPUT_CONFIG_DRAG_LOCK_ENABLED_STICKY", `Enabled_sticky;
      ]

    let three_finger_drag_state : [ `Disabled | `Enabled_3fg | `Enabled_4fg ] typ =
      make_enum "libinput_config_3fg_drag_state" ~requires:(1, 28) [
        "LIBINPUT_CONFIG_3FG_DRAG_DISABLED", `Disabled;
        "LIBINPUT_CONFIG_3FG_DRAG_ENABLED_3FG", `Enabled_3fg;
        "LIBINPUT_CONFIG_3FG_DRAG_ENABLED_4FG", `Enabled_4fg;
      ]

    module Area_rectangle = Area_rectangle

    module Send_events_mode = struct
      type t = Unsigned.UInt32.t
      let enum_val x = constant x uint32_t
      let enabled = enum_val "LIBINPUT_CONFIG_SEND_EVENTS_ENABLED"
      let disabled = enum_val "LIBINPUT_CONFIG_SEND_EVENTS_DISABLED"
      let disabled_on_external_mouse = enum_val "LIBINPUT_CONFIG_SEND_EVENTS_DISABLED_ON_EXTERNAL_MOUSE"
      let t = uint32_t
    end

    module Accel_profile = struct
      type t = Unsigned.UInt32.t
      let t = uint32_t
      let enum_val x = constant x uint32_t
      let enum_val_opt ~requires x = constant_opt ~requires x uint32_t
      let none = enum_val "LIBINPUT_CONFIG_ACCEL_PROFILE_NONE"
      let flat = enum_val "LIBINPUT_CONFIG_ACCEL_PROFILE_FLAT"
      let adaptive = enum_val "LIBINPUT_CONFIG_ACCEL_PROFILE_ADAPTIVE"
      let custom = enum_val_opt ~requires:(1, 23) "LIBINPUT_CONFIG_ACCEL_PROFILE_CUSTOM"
    end

    type accel_type = [`Fallback | `Motion | `Scroll ]
    let accel_type : accel_type typ =
      make_enum ~requires:(1, 23) "libinput_config_accel_type" [
        "LIBINPUT_ACCEL_TYPE_FALLBACK", `Fallback;
        "LIBINPUT_ACCEL_TYPE_MOTION", `Motion;
        "LIBINPUT_ACCEL_TYPE_SCROLL", `Scroll;
      ]

    module Click_method = struct
      type t = Unsigned.UInt32.t
      let t = uint32_t
      let enum_val x = constant x uint32_t

      let none = enum_val "LIBINPUT_CONFIG_CLICK_METHOD_NONE"
      let button_areas = enum_val "LIBINPUT_CONFIG_CLICK_METHOD_BUTTON_AREAS"
      let clickfinger = enum_val "LIBINPUT_CONFIG_CLICK_METHOD_CLICKFINGER"
    end

    module Scroll_method = struct
      type t = int64
      let t = int64_t

      let no_scroll = enum_val "LIBINPUT_CONFIG_SCROLL_NO_SCROLL"
      let two_fg = enum_val "LIBINPUT_CONFIG_SCROLL_2FG"
      let edge = enum_val "LIBINPUT_CONFIG_SCROLL_EDGE"
      let on_button_down = enum_val "LIBINPUT_CONFIG_SCROLL_ON_BUTTON_DOWN"
    end
  end
end
