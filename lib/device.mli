(** Input devices. *)

type t
(** An input device. *)

val pp : t Fmt.t
(** Summary information about a device. *)

val dump : t Fmt.t
(** Show verbose information about a device. *)

(** {2 Device metadata} *)

val get_sysname : t -> string
(** [get_sysname t] is the system name of [t], e.g. "event1". *)

val get_name : t -> string
(** [get_name t] is the descriptive device name as advertised by the kernel and/or the hardware itself (e.g. "Logitech USB Optical Mouse").

    It may return the empty string. *)

val get_context : t -> [`Udev | `Path] Context0.t

val get_id_bustype : t -> int
val get_id_product : t -> int
val get_id_vendor : t -> int
val get_output_name : t -> string option

val get_size : t -> (float * float) option

val get_device_group : t -> Device_group.t

(** {2 Seats} *)

val get_seat : t -> Seat.t

val set_seat_logical_name : t -> string -> unit
(** Change the logical seat associated with this device by removing the device and adding it to the new seat. *)

(** {2 Capabilities} *)

(** A device may have one or more "capabilities" at a time. Capabilities remain static for the lifetime of the device. *)
module Capability : sig
  type t =
    | Keyboard
    | Pointer
    | Touch
    | Tablet_tool
    | Tablet_pad
    | Gesture
    | Switch
    | Unknown of int64
end

val has_capability : t -> Capability.t -> bool

module Keyboard : sig
  val has_key : t -> Keycode.t -> (bool, unit) result
end

module Pointer : sig
  val has_button : t -> Keycode.t -> (bool, unit) result
end

module Touch : sig
  val get_touch_count : t -> (int, unit) result
end

module Switch : sig
  val has_switch : t -> [ `Lid | `Tablet_mode ] -> (bool, unit) result
end

module Tablet_pad : sig
  val get_num_mode_groups : t -> int
  val get_mode_group : t -> int -> Mode_group.t option

  val get_num_buttons : t -> (int, unit) result
  val get_num_dials : t -> (int, unit) result
  val get_num_rings : t -> (int, unit) result
  val get_num_strips : t -> (int, unit) result
  val has_key : t -> Keycode.t -> (bool, unit) result
end

(** {2 LEDs} *)

module Led : sig
  type t

  val none : t

  val num_lock : t
  val caps_lock : t
  val scroll_lock : t
  val compose : t
  val kana : t

  val ( + ) : t -> t -> t
end

val led_update : t -> Led.t -> unit

(** {2 Configuration} *)

(** Enable, disable, change and/or check for device-specific features.

    See {{: https://wayland.freedesktop.org/libinput/doc/latest/api/group__config.html }}. *)
module Config : sig
  type 'a setting

  val set : t -> 'a setting -> 'a -> Config_status.t
  val get : t -> 'a setting -> 'a
  val get_default : t -> 'a setting -> 'a

  module Tap : sig
    val enabled : [`Disabled | `Enabled] setting
    val get_finger_count : t -> int
    val button_map : [ `LMR | `LRM ] setting
    val drag_enabled : [ `Disabled | `Enabled ] setting
    val drag_lock_enabled : [ `Disabled | `Enabled_sticky | `Enabled_timeout ] setting
  end

  module Calibration_matrix : sig
    type matrix = (float * float * float) * (float * float * float)

    val is_supported : t -> bool

    val matrix : matrix setting

    val get : t -> matrix * bool
    (** Returns the current matrix and a bool saying whether it's the identity matrix. *)

    val get_default : t -> matrix * bool

    val pp_matrix : matrix Fmt.t
  end

  module Three_finger_drag_state : sig
    val get_finger_count : t -> int
    val enabled : [ `Disabled | `Enabled_3fg | `Enabled_4fg ] setting
  end

  module Area : sig
    type rectangle = {
      x1 : float;
      y1 : float;
      x2 : float;
      y2 : float;
    }

    val rectangle : rectangle setting
  end

  module Send_events : sig
    module Mode : sig
      type t = Unsigned.UInt32.t

      val enabled : t
      val disabled : t
      val disabled_on_external_mouse : t
    end

    val get_modes : t -> Mode.t
    val mode : Mode.t setting
  end

  module Accel : sig
    module Profile : sig
      type t = private Unsigned.UInt32.t
      val none : t
      val flat : t
      val adaptive : t
      val custom : t
    end

    val is_available : t -> bool
    val speed : float setting
    val accel_get_profiles : t -> Profile.t
    val profile : Profile.t setting

    type custom = {
      ty : [ `Fallback | `Motion | `Scroll ];
      step : float;
      points : float list;
    }

    val set_accel : t -> [ `Flat | `Adaptive | `Custom of custom list ] -> Config_status.t
  end

  module Left_handled : sig
    val is_available : t -> bool
    val enabled : bool setting
  end

  module Click : sig
    module Method : sig
      type t = private Unsigned.UInt32.t
      val none : t
      val button_areas : t
      val clickfinger : t
    end

    val get_methods : t -> Method.t
    val meth : Method.t setting
    val clickfinger_button_map : [ `LMR | `LRM ] setting
  end

  module Middle_emulation : sig
    val is_available : t -> bool
    val enabled : bool setting
  end

  module Scroll : sig
    module Method : sig
      type t = private int64

      val no_scroll : t
      val two_fg : t
      val edge : t
      val on_button_down : t
    end

    val get_methods : t -> Method.t
    val meth : Method.t setting
    val button : Keycode.t setting
    val button_lock : [`Disabled | `Enabled] setting
  end

  (** Disable-while-typing *)
  module Dwt : sig
    val is_available : t -> bool
    val enabled : [`Disabled | `Enabled] setting
  end

  (** Disable-while-trackpointing *)
  module Dwtp : sig
    val is_available : t -> bool
    val enabled : [`Disabled | `Enabled] setting
  end

  module Rotation : sig
    val is_available : t -> bool
    val angle : int setting
  end
end

(** {2 Internals} *)

val import : [< `Udev | `Path] Context0.t -> [`Libinput_device] Ctypes.structure Ctypes.ptr -> t
val use : t -> [`Libinput_device] Ctypes.structure Ctypes.ptr
